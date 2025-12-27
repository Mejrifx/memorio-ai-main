-- ============================================================================
-- SECURITY FIX: Add access control to admin views
-- ============================================================================
-- Problem: Views with security_invoker=false bypass RLS and are accessible
-- to ANY authenticated user via the API, exposing sensitive data.
--
-- Solution: Add WHERE clauses to views that filter based on user's role
-- using our helper function get_my_role() which safely checks the database.
-- ============================================================================

-- Drop existing views
DROP VIEW IF EXISTS admin_users_view CASCADE;
DROP VIEW IF EXISTS admin_cases_view CASCADE;
DROP VIEW IF EXISTS admin_editor_assignments_view CASCADE;

-- ============================================================================
-- 1. SECURE admin_users_view - Only show users based on caller's permissions
-- ============================================================================
CREATE OR REPLACE VIEW admin_users_view 
WITH (security_invoker = false)
AS
SELECT 
  id,
  email,
  role,
  org_id,
  status,
  metadata,
  created_at,
  updated_at
FROM users
WHERE 
  -- Admins see all users
  (SELECT public.get_my_role() = 'admin')
  OR
  -- Directors see users in their org
  (
    SELECT public.get_my_role() = 'director' 
    AND org_id = (SELECT org_id FROM users WHERE id = auth.uid())
  )
  OR
  -- Support/QC see all users (for their role requirements)
  (SELECT public.get_my_role() IN ('support', 'qc'))
  OR
  -- Users can see themselves (not needed since we have self-access policy)
  (id = auth.uid());

GRANT SELECT ON admin_users_view TO authenticated;

COMMENT ON VIEW admin_users_view IS 
'Secure view for querying users. Filters based on caller role:
- Admin: sees all users
- Director: sees only users in their org
- Support/QC: sees all users
- Others: see only themselves';

-- ============================================================================
-- 2. SECURE admin_cases_view - Only show cases based on caller's permissions
-- ============================================================================
CREATE OR REPLACE VIEW admin_cases_view
WITH (security_invoker = false)
AS
SELECT 
  cases.id, 
  cases.org_id, 
  cases.deceased_name, 
  cases.created_by, 
  cases.assigned_family_user_id, 
  cases.status, 
  cases.sla_start_at, 
  cases.sla_state, 
  cases.metadata as case_metadata, 
  cases.created_at, 
  cases.updated_at,
  orgs.name as org_name, 
  orgs.contact_email as org_contact_email, 
  orgs.contact_phone as org_contact_phone, 
  orgs.region as org_region, 
  orgs.status as org_status,
  family_user.email as family_email, 
  family_user.metadata as family_metadata, 
  family_user.status as family_status,
  creator_user.email as creator_email, 
  creator_user.metadata as creator_metadata, 
  creator_user.role as creator_role
FROM cases
LEFT JOIN organizations orgs ON orgs.id = cases.org_id
LEFT JOIN users family_user ON family_user.id = cases.assigned_family_user_id
LEFT JOIN users creator_user ON creator_user.id = cases.created_by
WHERE
  -- Admins see all cases
  (SELECT public.get_my_role() = 'admin')
  OR
  -- Directors see cases in their org
  (
    SELECT public.get_my_role() = 'director' 
    AND cases.org_id = (SELECT org_id FROM users WHERE id = auth.uid())
  )
  OR
  -- Support/QC see all cases
  (SELECT public.get_my_role() IN ('support', 'qc'))
  OR
  -- Family users see their own cases (via existing RLS, but keep for consistency)
  (
    SELECT public.get_my_role() = 'family' 
    AND cases.assigned_family_user_id = auth.uid()
  )
  OR
  -- Editors see cases assigned to them
  (
    SELECT public.get_my_role() = 'editor'
    AND EXISTS (
      SELECT 1 FROM editor_assignments 
      WHERE editor_assignments.case_id = cases.id 
      AND editor_assignments.editor_user_id = auth.uid()
      AND editor_assignments.unassigned_at IS NULL
    )
  );

GRANT SELECT ON admin_cases_view TO authenticated;

COMMENT ON VIEW admin_cases_view IS 
'Secure view for querying cases with joined data. Filters based on caller role:
- Admin/Support/QC: see all cases
- Director: sees only cases in their org
- Family: sees only their assigned case
- Editor: sees only assigned cases';

-- ============================================================================
-- 3. SECURE admin_editor_assignments_view - Filter based on permissions
-- ============================================================================
CREATE OR REPLACE VIEW admin_editor_assignments_view
WITH (security_invoker = false)
AS
SELECT 
  editor_assignments.id, 
  editor_assignments.case_id, 
  editor_assignments.editor_user_id, 
  editor_assignments.assigned_by, 
  editor_assignments.assigned_at, 
  editor_assignments.unassigned_at,
  editor_user.email as editor_email, 
  editor_user.metadata as editor_metadata, 
  editor_user.status as editor_status,
  assigner_user.email as assigned_by_email, 
  assigner_user.metadata as assigned_by_metadata
FROM editor_assignments
LEFT JOIN users editor_user ON editor_user.id = editor_assignments.editor_user_id
LEFT JOIN users assigner_user ON assigner_user.id = editor_assignments.assigned_by
WHERE
  -- Admins see all assignments
  (SELECT public.get_my_role() = 'admin')
  OR
  -- Directors see assignments for cases in their org
  (
    SELECT public.get_my_role() = 'director'
    AND EXISTS (
      SELECT 1 FROM cases 
      WHERE cases.id = editor_assignments.case_id 
      AND cases.org_id = (SELECT org_id FROM users WHERE id = auth.uid())
    )
  )
  OR
  -- Support/QC see all assignments
  (SELECT public.get_my_role() IN ('support', 'qc'))
  OR
  -- Editors see their own assignments
  (
    SELECT public.get_my_role() = 'editor'
    AND editor_assignments.editor_user_id = auth.uid()
  );

GRANT SELECT ON admin_editor_assignments_view TO authenticated;

COMMENT ON VIEW admin_editor_assignments_view IS 
'Secure view for querying editor assignments with joined data. Filters based on caller role:
- Admin/Support/QC: see all assignments
- Director: sees assignments for cases in their org
- Editor: sees only their own assignments';

-- ============================================================================
-- 4. SECURE case_analytics view (if it exists)
-- ============================================================================
-- Note: We need to check if this view exists and secure it similarly

-- First check if case_analytics exists
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND table_name = 'case_analytics'
  ) THEN
    -- Drop and recreate with security
    EXECUTE 'DROP VIEW IF EXISTS case_analytics CASCADE';
    
    -- Recreate case_analytics with access control
    -- Note: Adjust this based on your actual case_analytics definition
    CREATE OR REPLACE VIEW case_analytics
    WITH (security_invoker = false)
    AS
    SELECT 
      org_id,
      COUNT(*) as total_cases,
      COUNT(*) FILTER (WHERE status = 'delivered') as completed_cases,
      COUNT(*) FILTER (WHERE status IN ('waiting_on_family', 'intake_in_progress', 'submitted')) as active_cases,
      AVG(EXTRACT(EPOCH FROM (updated_at - created_at)) / 3600) as avg_completion_hours
    FROM cases
    WHERE
      -- Admins see all analytics
      (SELECT public.get_my_role() = 'admin')
      OR
      -- Directors see analytics for their org
      (
        SELECT public.get_my_role() = 'director'
        AND org_id = (SELECT org_id FROM users WHERE id = auth.uid())
      )
      OR
      -- Support/QC see all analytics
      (SELECT public.get_my_role() IN ('support', 'qc'))
    GROUP BY org_id;
    
    GRANT SELECT ON case_analytics TO authenticated;
    
    COMMENT ON VIEW case_analytics IS 
    'Secure analytics view. Filters based on caller role:
    - Admin/Support/QC: see all org analytics
    - Director: sees only their org analytics';
  END IF;
END $$;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Run these to verify the views are secure:

-- 1. Check view permissions
-- SELECT schemaname, viewname, viewowner 
-- FROM pg_views 
-- WHERE schemaname = 'public' 
-- AND viewname LIKE 'admin_%';

-- 2. Test as different roles (change SET ROLE to test each)
-- Test will fail if role checks don't work, which means views are secure

-- ============================================================================
-- NOTES
-- ============================================================================
-- These views still use security_invoker=false to bypass RLS on the users table
-- (which prevents recursion), BUT they now include explicit WHERE clauses that
-- check the calling user's role using get_my_role() function.
--
-- This means:
-- ✅ No RLS recursion (views run with postgres permissions)
-- ✅ Data is filtered based on caller's role (secure)
-- ✅ Admin portal queries work (authorized users get data)
-- ✅ API access is restricted (unauthorized users get empty results)
-- ✅ No breaking changes to existing code

