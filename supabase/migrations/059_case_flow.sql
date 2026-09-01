-- ============================================================================
-- Migration 059: Case-flow improvements
-- Date: 2026-09-01 · Apply AFTER 058_logic_hardening.sql
-- What it does:
--   1. Families can close the photo window early ("I'm finished adding photos")
--   2. QC cooldown becomes a setting (set to 0 to decouple video delivery from
--      obituary editing)
--   3. Editor assignment fires from the database when the form lands, not from
--      the family's browser
--   4. Stuck-case detection (view + hourly sweep) for the admin dashboard
-- ============================================================================

-- ============================================================================
-- 1. EXPLICIT PHOTO-WINDOW CLOSE
-- ============================================================================
ALTER TABLE forms ADD COLUMN IF NOT EXISTS photos_closed_at TIMESTAMPTZ;
COMMENT ON COLUMN forms.photos_closed_at IS
  'Set when the family confirms they are finished adding photos. Ends the 12-hour window early.';

-- The server-side gate (migration 054) now honors an explicit close too.
CREATE OR REPLACE FUNCTION check_upload_window_expired(p_case_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_submitted_at TIMESTAMPTZ;
  v_closed_at TIMESTAMPTZ;
BEGIN
  SELECT submitted_at, photos_closed_at INTO v_submitted_at, v_closed_at
  FROM forms
  WHERE case_id = p_case_id AND submitted_at IS NOT NULL
  ORDER BY submitted_at DESC
  LIMIT 1;

  IF v_submitted_at IS NULL THEN RETURN TRUE; END IF;   -- nothing submitted: allow
  IF v_closed_at IS NOT NULL THEN RETURN TRUE; END IF;  -- family said "done"
  RETURN NOW() >= v_submitted_at + INTERVAL '12 hours';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Families may only ever SET this (never unset), and only on their own case.
-- Existing family RLS on forms already scopes rows to their case; this trigger
-- prevents reopening.
CREATE OR REPLACE FUNCTION protect_photos_closed_at()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.photos_closed_at IS NOT NULL AND NEW.photos_closed_at IS DISTINCT FROM OLD.photos_closed_at THEN
    NEW.photos_closed_at := OLD.photos_closed_at;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS protect_photos_closed_at_trigger ON forms;
CREATE TRIGGER protect_photos_closed_at_trigger
  BEFORE UPDATE ON forms
  FOR EACH ROW
  EXECUTE FUNCTION protect_photos_closed_at();

-- ============================================================================
-- 2. CONFIGURABLE QC COOLDOWN
-- The 40-hour hold exists so families can edit the obituary before the video
-- ships. If the video does NOT render obituary text, set qc_cooldown_hours to 0
-- and finished videos deliver the moment QC approves.
-- ============================================================================
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "settings readable by signed-in users" ON app_settings;
CREATE POLICY "settings readable by signed-in users" ON app_settings
  FOR SELECT TO authenticated USING (true);
-- writes: service role / SQL editor only (no insert/update policy for clients)

INSERT INTO app_settings (key, value) VALUES
  ('qc_cooldown_hours', '40'::jsonb),
  ('photo_window_hours', '12'::jsonb)
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION get_setting_numeric(p_key TEXT, p_default NUMERIC)
RETURNS NUMERIC AS $$
  SELECT COALESCE((SELECT (value #>> '{}')::numeric FROM app_settings WHERE key = p_key), p_default);
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION should_apply_cooldown(p_case_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_first_submission_at TIMESTAMPTZ;
  v_hours NUMERIC := get_setting_numeric('qc_cooldown_hours', 40);
BEGIN
  IF v_hours <= 0 THEN RETURN FALSE; END IF;
  SELECT first_submission_at INTO v_first_submission_at FROM cases WHERE id = p_case_id;
  IF v_first_submission_at IS NULL THEN RETURN FALSE; END IF;
  RETURN EXTRACT(EPOCH FROM (NOW() - v_first_submission_at)) / 3600 < v_hours;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION calculate_cooldown_expiration(p_case_id UUID)
RETURNS TIMESTAMPTZ AS $$
DECLARE
  v_first_submission_at TIMESTAMPTZ;
  v_hours NUMERIC := get_setting_numeric('qc_cooldown_hours', 40);
BEGIN
  SELECT first_submission_at INTO v_first_submission_at FROM cases WHERE id = p_case_id;
  RETURN v_first_submission_at + (v_hours || ' hours')::interval;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 3. EDITOR ASSIGNMENT FROM THE DATABASE
-- Fires when submitted_at is first set on a form. The auto-assign-editor edge
-- function stays (it is idempotent: "already has an editor") so a browser
-- that still calls it is harmless.
-- Trigger name starts with zz_ so it runs after update_case_on_form_submit.
-- ============================================================================
CREATE OR REPLACE FUNCTION auto_assign_editor_on_submit()
RETURNS TRIGGER AS $$
DECLARE
  v_case cases%ROWTYPE;
  v_editor RECORD;
  v_admin_emails JSONB;
BEGIN
  IF NEW.submitted_at IS NULL OR OLD.submitted_at IS NOT NULL THEN
    RETURN NEW;  -- not a first submission
  END IF;

  SELECT * INTO v_case FROM cases WHERE id = NEW.case_id;
  IF NOT FOUND THEN RETURN NEW; END IF;

  -- already assigned?
  IF EXISTS (SELECT 1 FROM editor_assignments WHERE case_id = NEW.case_id AND unassigned_at IS NULL) THEN
    RETURN NEW;
  END IF;

  SELECT * INTO v_editor FROM get_editor_with_least_cases();

  IF v_editor.id IS NULL THEN
    SELECT COALESCE(jsonb_agg(email), '[]'::jsonb) INTO v_admin_emails
    FROM users WHERE role = 'admin' AND status = 'active';
    INSERT INTO notifications (case_id, event_type, recipients, status)
    VALUES (NEW.case_id, 'no_editors_available', v_admin_emails, 'pending');
    INSERT INTO events (actor_user_id, actor_role, action_type, target_type, target_id, payload)
    VALUES (NULL, 'system', 'NO_EDITORS_AVAILABLE', 'case', NEW.case_id,
            jsonb_build_object('deceased_name', v_case.deceased_name, 'source', 'db_trigger'));
    RETURN NEW;
  END IF;

  INSERT INTO editor_assignments (case_id, editor_user_id, assigned_by, assigned_at)
  VALUES (NEW.case_id, v_editor.id, COALESCE(v_case.assigned_family_user_id, v_case.created_by), NOW());

  UPDATE cases SET status = 'in_production' WHERE id = NEW.case_id;

  INSERT INTO events (actor_user_id, actor_role, action_type, target_type, target_id, payload)
  VALUES (v_case.assigned_family_user_id, 'system', 'AUTO_ASSIGN_EDITOR', 'case', NEW.case_id,
          jsonb_build_object('editor_id', v_editor.id, 'editor_email', v_editor.email,
                             'deceased_name', v_case.deceased_name,
                             'active_case_count', v_editor.active_case_count, 'source', 'db_trigger'));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS zz_auto_assign_editor_on_submit ON forms;
CREATE TRIGGER zz_auto_assign_editor_on_submit
  AFTER UPDATE ON forms
  FOR EACH ROW
  EXECUTE FUNCTION auto_assign_editor_on_submit();

-- ============================================================================
-- 4. STUCK-CASE DETECTION
-- "Who has been holding the ball too long." Thresholds are settings too.
-- ============================================================================
INSERT INTO app_settings (key, value) VALUES
  ('stuck_hours_waiting_on_family', '72'::jsonb),
  ('stuck_hours_in_production', '30'::jsonb),
  ('stuck_hours_awaiting_review', '12'::jsonb),
  ('stuck_hours_revision', '24'::jsonb)
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE VIEW stuck_cases WITH (security_barrier = true) AS
SELECT
  c.id AS case_id,
  c.case_number,
  c.deceased_name,
  c.org_id,
  o.name AS organization_name,
  c.status,
  c.updated_at AS status_since,
  ROUND(EXTRACT(EPOCH FROM (NOW() - c.updated_at)) / 3600, 1) AS hours_in_status,
  CASE c.status
    WHEN 'waiting_on_family' THEN 'family'
    WHEN 'submitted' THEN 'system (no editor assigned)'
    WHEN 'in_production' THEN 'editor'
    WHEN 'awaiting_review' THEN 'qc'
    WHEN 'revision_requested' THEN 'editor'
    WHEN 'family_revision_requested' THEN 'editor'
    ELSE c.status
  END AS holding_the_ball
FROM cases c
LEFT JOIN organizations o ON o.id = c.org_id
WHERE c.status NOT IN ('delivered', 'closed', 'created')
  AND EXTRACT(EPOCH FROM (NOW() - c.updated_at)) / 3600 >
    CASE c.status
      WHEN 'waiting_on_family' THEN get_setting_numeric('stuck_hours_waiting_on_family', 72)
      WHEN 'submitted' THEN 2
      WHEN 'in_production' THEN get_setting_numeric('stuck_hours_in_production', 30)
      WHEN 'awaiting_review' THEN get_setting_numeric('stuck_hours_awaiting_review', 12)
      ELSE get_setting_numeric('stuck_hours_revision', 24)
    END
ORDER BY hours_in_status DESC;

GRANT SELECT ON stuck_cases TO authenticated;
-- (admin portal reads this; RLS on cases still applies through the barrier view)

-- Hourly sweep: one STUCK event per case per 24h + an admin notification row
SELECT cron.schedule(
  'stuck-case-sweep',
  '0 * * * *',
  $$
  INSERT INTO events (actor_user_id, actor_role, action_type, target_type, target_id, payload)
  SELECT NULL, 'system', 'CASE_STUCK', 'case', s.case_id,
         jsonb_build_object('status', s.status, 'hours_in_status', s.hours_in_status,
                            'holding_the_ball', s.holding_the_ball, 'case_number', s.case_number)
  FROM stuck_cases s
  WHERE NOT EXISTS (
    SELECT 1 FROM events e
    WHERE e.action_type = 'CASE_STUCK' AND e.target_id = s.case_id
      AND e.timestamp > NOW() - INTERVAL '24 hours'
  );
  $$
);

-- ============================================================================
-- ROLLBACK NOTES
-- 1: ALTER TABLE forms DROP COLUMN photos_closed_at; re-run 054's check_upload_window_expired
-- 2: DROP TABLE app_settings; re-run 056's should_apply_cooldown / calculate_cooldown_expiration
-- 3: DROP TRIGGER zz_auto_assign_editor_on_submit ON forms; DROP FUNCTION auto_assign_editor_on_submit
-- 4: DROP VIEW stuck_cases; SELECT cron.unschedule('stuck-case-sweep')
-- ============================================================================
