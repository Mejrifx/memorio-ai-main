-- ============================================================================
-- Migration 058: Logic hardening
-- Date: 2026-08-31
-- Apply via Supabase SQL editor (or supabase db push after copying into
-- supabase/migrations/). Everything here is additive or a defensive fix;
-- nothing changes what the current frontends send.
-- ============================================================================

-- ============================================================================
-- 1. HUMAN-READABLE CASE NUMBERS
-- Cases are identified only by UUID today. This adds MEM-YYYY-NNNN numbers,
-- assigned on insert and backfilled for existing cases in creation order.
-- ============================================================================

ALTER TABLE cases ADD COLUMN IF NOT EXISTS case_number TEXT UNIQUE;

CREATE SEQUENCE IF NOT EXISTS case_number_seq;

CREATE OR REPLACE FUNCTION assign_case_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.case_number IS NULL THEN
    NEW.case_number := 'MEM-' || to_char(NOW(), 'YYYY') || '-' ||
      lpad(nextval('case_number_seq')::text, 4, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS assign_case_number_trigger ON cases;
CREATE TRIGGER assign_case_number_trigger
  BEFORE INSERT ON cases
  FOR EACH ROW
  EXECUTE FUNCTION assign_case_number();

-- Backfill existing cases in creation order
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT id, created_at FROM cases WHERE case_number IS NULL ORDER BY created_at LOOP
    UPDATE cases
    SET case_number = 'MEM-' || to_char(r.created_at, 'YYYY') || '-' ||
      lpad(nextval('case_number_seq')::text, 4, '0')
    WHERE id = r.id;
  END LOOP;
END $$;

-- NOTE: admin_cases_view and the other security-barrier views will not include
-- case_number until they are recreated. When you want it surfaced in portals,
-- recreate the views adding the column (see migrations 035-041 for their defs).

-- ============================================================================
-- 2. CLOSE THE approve_video_with_cooldown PRIVILEGE HOLE
-- Migration 056 created this SECURITY DEFINER function and granted EXECUTE to
-- ALL authenticated users with no role check inside - any signed-in family or
-- editor could approve and deliver their own video (and p_qc_user_id is
-- caller-supplied). This version verifies the caller.
-- ============================================================================

CREATE OR REPLACE FUNCTION approve_video_with_cooldown(
  p_submission_id UUID,
  p_qc_user_id UUID,
  p_qc_notes TEXT DEFAULT NULL,
  p_override_cooldown BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  cooldown_applied BOOLEAN,
  cooldown_expires_at TIMESTAMPTZ,
  immediate_delivery BOOLEAN
) AS $$
DECLARE
  v_case_id UUID;
  v_caller_role TEXT;
  v_should_apply_cooldown BOOLEAN;
  v_cooldown_expiration TIMESTAMPTZ;
  v_final_status TEXT;
BEGIN
  -- Verify the CALLER (not the caller-supplied p_qc_user_id) is QC or admin
  SELECT role INTO v_caller_role FROM users WHERE id = auth.uid();
  IF v_caller_role IS NULL OR v_caller_role NOT IN ('qc', 'admin') THEN
    RETURN QUERY SELECT FALSE, 'Forbidden: only QC reviewers can approve videos'::TEXT, FALSE, NULL::TIMESTAMPTZ, FALSE;
    RETURN;
  END IF;

  SELECT case_id INTO v_case_id FROM video_submissions WHERE id = p_submission_id;
  IF v_case_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Submission not found'::TEXT, FALSE, NULL::TIMESTAMPTZ, FALSE;
    RETURN;
  END IF;

  v_should_apply_cooldown := should_apply_cooldown(v_case_id) AND NOT p_override_cooldown;

  IF v_should_apply_cooldown THEN
    v_cooldown_expiration := calculate_cooldown_expiration(v_case_id);
    v_final_status := 'awaiting_review';
  ELSE
    v_cooldown_expiration := NULL;
    v_final_status := 'delivered';
  END IF;

  UPDATE video_submissions
  SET
    qc_status = 'approved',
    qc_reviewer_id = auth.uid(),   -- recorded reviewer is the real caller
    qc_notes = p_qc_notes,
    qc_reviewed_at = NOW(),
    cooldown_expires_at = v_cooldown_expiration,
    cooldown_overridden = p_override_cooldown
  WHERE id = p_submission_id;

  UPDATE cases SET status = v_final_status WHERE id = v_case_id;

  RETURN QUERY SELECT
    TRUE,
    CASE
      WHEN v_should_apply_cooldown THEN 'Video approved. Will be delivered to family after cooldown expires.'
      WHEN p_override_cooldown THEN 'Video approved and delivered immediately (cooldown overridden).'
      ELSE 'Video approved and delivered immediately (no cooldown needed).'
    END::TEXT,
    v_should_apply_cooldown,
    v_cooldown_expiration,
    NOT v_should_apply_cooldown;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 3. THE MISSING LOAD-BALANCER RPC
-- auto-assign-editor tries get_editor_with_least_cases and has ALWAYS fallen
-- back to a manual N+1 loop because the RPC never existed. One query instead.
-- Runs as definer; called from the edge function (service role) only.
-- ============================================================================

CREATE OR REPLACE FUNCTION get_editor_with_least_cases()
RETURNS TABLE (id UUID, email TEXT, metadata JSONB, created_at TIMESTAMPTZ, active_case_count BIGINT) AS $$
  SELECT u.id, u.email, u.metadata, u.created_at,
         COUNT(ea.id) FILTER (WHERE ea.unassigned_at IS NULL) AS active_case_count
  FROM users u
  LEFT JOIN editor_assignments ea ON ea.editor_user_id = u.id AND ea.unassigned_at IS NULL
  WHERE u.role = 'editor' AND u.status IN ('active', 'invited')
  GROUP BY u.id, u.email, u.metadata, u.created_at
  ORDER BY active_case_count ASC, u.created_at ASC
  LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION get_editor_with_least_cases() FROM anon, authenticated;

-- ============================================================================
-- 4. ATOMIC EDITOR REASSIGNMENT
-- The admin portal currently reassigns via 3 separate client-side writes
-- (unassign, assign, update case) which can strand a case with 0 or 2 editors.
-- This RPC makes it one transaction. Frontend can switch to it incrementally.
-- ============================================================================

CREATE OR REPLACE FUNCTION reassign_editor(p_case_id UUID, p_new_editor_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_caller_role TEXT;
BEGIN
  SELECT role INTO v_caller_role FROM users WHERE id = auth.uid();
  IF v_caller_role IS NULL OR v_caller_role NOT IN ('admin') THEN
    RAISE EXCEPTION 'Forbidden: only admins can reassign editors';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_new_editor_id AND role = 'editor' AND status IN ('active','invited')) THEN
    RAISE EXCEPTION 'Target user is not an active editor';
  END IF;

  UPDATE editor_assignments
  SET unassigned_at = NOW()
  WHERE case_id = p_case_id AND unassigned_at IS NULL;

  INSERT INTO editor_assignments (case_id, editor_user_id, assigned_by, assigned_at)
  VALUES (p_case_id, p_new_editor_id, auth.uid(), NOW());

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 5. KEEP SLA STATE FRESH
-- update_case_sla (migration 048) only recomputes on row UPDATE, so an
-- untouched case never leaves 'green' - the original complaint that migration
-- tried to fix. This cron touches only rows whose bucket actually changed
-- (so the audit log is not spammed every 10 minutes).
-- ============================================================================

SELECT cron.schedule(
  'refresh-sla-state',
  '*/15 * * * *',
  $$
  UPDATE cases
  SET updated_at = NOW()
  WHERE first_submission_at IS NOT NULL
    AND status NOT IN ('delivered', 'closed', 'waiting_on_family')
    AND COALESCE(sla_state, '') <> (
      CASE
        WHEN EXTRACT(EPOCH FROM (NOW() - first_submission_at)) / 3600 < 24 THEN 'green'
        WHEN EXTRACT(EPOCH FROM (NOW() - first_submission_at)) / 3600 < 36 THEN 'orange'
        WHEN EXTRACT(EPOCH FROM (NOW() - first_submission_at)) / 3600 < 48 THEN 'red'
        ELSE 'black'
      END
    );
  $$
);

-- ============================================================================
-- 6. HYGIENE
-- ============================================================================

-- The temp_password duplicated into users.metadata by invite functions is the
-- riskier of the two copies (it rides along into more query results). Clear
-- historical copies; invite functions should stop writing it (see repo change).
UPDATE users
SET metadata = metadata - 'temp_password'
WHERE metadata ? 'temp_password'
  AND status <> 'invited';   -- keep it only for invitees who have never logged in

-- ============================================================================
-- ROLLBACK NOTES
-- 1: ALTER TABLE cases DROP COLUMN case_number; DROP TRIGGER assign_case_number_trigger ON cases; DROP FUNCTION assign_case_number; DROP SEQUENCE case_number_seq;
-- 2: re-run migration 056's version of approve_video_with_cooldown
-- 3/4: DROP FUNCTION get_editor_with_least_cases; DROP FUNCTION reassign_editor;
-- 5: SELECT cron.unschedule('refresh-sla-state');
-- ============================================================================
