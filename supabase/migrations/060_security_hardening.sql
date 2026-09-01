-- ============================================================================
-- Migration 060: Security hardening
-- Date: 2026-09-01 · Applied to production the same day (via management API)
-- Driven by the Supabase security advisor (87 findings) plus live tests of
-- what the anon / authenticated roles could read.
--
-- Findings this closes:
--   * timeline_view: 4,172 audit rows (full old/new row snapshots) readable by anon
--   * user_analytics_combined: all users incl. plaintext temp_password readable by anon
--   * 24 SECURITY DEFINER functions executable by anon/authenticated, incl.
--     delete_auth_user(uuid) (anyone could delete any user) and
--     clear_login_attempts(email) (anyone could reset the login rate limiter)
--   * anon holding SELECT on every view; anon/authenticated holding
--     INSERT/UPDATE/DELETE grants on views
--   * blanket "any authenticated user can update/delete any storage object"
--   * 29 functions with mutable search_path (privilege-escalation vector for
--     SECURITY DEFINER functions)
-- ============================================================================

-- ============================================================================
-- 1. VIEWS: anon gets nothing; authenticated gets SELECT only where the view
--    itself filters by role
-- ============================================================================
DO $$
DECLARE v TEXT;
BEGIN
  FOR v IN SELECT viewname FROM pg_views WHERE schemaname='public' LOOP
    EXECUTE format('REVOKE ALL ON public.%I FROM anon, PUBLIC', v);
    EXECUTE format('REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON public.%I FROM authenticated', v);
  END LOOP;
END $$;

-- Views no frontend uses and which had no role filter: authenticated loses them too.
REVOKE ALL ON public.timeline_view FROM authenticated;
REVOKE ALL ON public.editor_analytics FROM authenticated;
REVOKE ALL ON public.qc_analytics FROM authenticated;

-- user_analytics_combined: admin-only, and stop exposing temp_password through it
-- (the admin_users_view "reveal" feature is unaffected).
DROP VIEW IF EXISTS public.user_analytics_combined;
CREATE VIEW public.user_analytics_combined WITH (security_barrier = true) AS
 SELECT users.id AS user_id,
    users.email,
    users.role,
    users.status,
    users.metadata ->> 'name'::text AS name,
    NULL::text AS temp_password,
    users.created_at,
    users.last_login_at,
    organizations.name AS org_name,
    COALESCE(editor_analytics.total_videos_edited, 0::bigint) AS editor_total_videos,
    COALESCE(editor_analytics.videos_approved, 0::bigint) AS editor_approved,
    COALESCE(editor_analytics.revisions_requested, 0::bigint) AS editor_revisions,
    COALESCE(editor_analytics.videos_pending, 0::bigint) AS editor_pending,
    editor_analytics.last_submission_date AS editor_last_submission,
    COALESCE(qc_analytics.videos_passed, 0::bigint) AS qc_passed,
    COALESCE(qc_analytics.videos_rejected, 0::bigint) AS qc_rejected,
    COALESCE(qc_analytics.total_reviewed, 0::bigint) AS qc_total_reviewed,
    COALESCE(qc_analytics.pass_rate_percentage, 0::numeric) AS qc_pass_rate,
    qc_analytics.last_review_date AS qc_last_review
   FROM users
     LEFT JOIN organizations ON users.org_id = organizations.id
     LEFT JOIN editor_analytics ON users.id = editor_analytics.user_id
     LEFT JOIN qc_analytics ON users.id = qc_analytics.user_id
  WHERE get_my_role() = 'admin';
GRANT SELECT ON public.user_analytics_combined TO authenticated;

-- stuck_cases (migration 059): admin only
CREATE OR REPLACE VIEW public.stuck_cases WITH (security_barrier = true) AS
SELECT
  c.id AS case_id, c.case_number, c.deceased_name, c.org_id, o.name AS organization_name,
  c.status, c.updated_at AS status_since,
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
  AND get_my_role() = 'admin'
ORDER BY hours_in_status DESC;
GRANT SELECT ON public.stuck_cases TO authenticated;

-- ============================================================================
-- 2. SECURITY DEFINER FUNCTIONS: nothing callable from the API unless it must be
-- ============================================================================
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.prosecdef
  LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon, authenticated', r.sig);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO service_role', r.sig);
  END LOOP;
END $$;

-- The only definer functions a signed-in browser legitimately calls:
GRANT EXECUTE ON FUNCTION public.get_my_role() TO authenticated;                       -- used inside RLS policies
GRANT EXECUTE ON FUNCTION public.approve_video_with_cooldown(uuid, uuid, text, boolean) TO authenticated;  -- role-checked inside
GRANT EXECUTE ON FUNCTION public.reassign_editor(uuid, uuid) TO authenticated;         -- role-checked inside

-- ============================================================================
-- 3. PIN search_path ON EVERY public FUNCTION (advisor: 29 mutable)
-- ============================================================================
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.prokind = 'f'
  LOOP
    EXECUTE format('ALTER FUNCTION %s SET search_path = public', r.sig);
  END LOOP;
END $$;

-- ============================================================================
-- 4. STORAGE: remove the blanket update/delete for any signed-in user
--    (no frontend deletes or overwrites objects). Upload stays (family form,
--    editor video fallback). Public read stays for now: flipping the bucket to
--    private requires the signed-URL frontend change (tracked separately).
-- ============================================================================
DROP POLICY IF EXISTS "Authenticated users can delete case assets" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update case assets" ON storage.objects;

-- ============================================================================
-- 5. app_settings: readable by signed-in users only (was granted to anon by default)
-- ============================================================================
REVOKE ALL ON public.app_settings FROM anon;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON public.app_settings FROM authenticated;

-- ============================================================================
-- VERIFY (run as-is after applying)
--   set role anon; select count(*) from timeline_view;            -> permission denied
--   set role anon; select count(*) from user_analytics_combined;  -> permission denied
--   select has_function_privilege('anon','delete_auth_user(uuid)','execute');  -> false
-- ============================================================================
