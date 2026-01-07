-- ============================================================================
-- Migration: 049 - Add SLA fields to admin_cases_view
-- ============================================================================
-- Purpose: Frontend needs first_submission_at and sla_hours_elapsed to 
--          calculate and display real-time SLA badges
-- ============================================================================

-- PROBLEM:
-- ========
-- The getSLABadge() function in the frontend needs:
--   - first_submission_at (to know when SLA clock started)
--   - sla_hours_elapsed (optional, for reference)
--   - sla_state (already exists)
--
-- But admin_cases_view is missing first_submission_at!

-- SOLUTION:
-- =========
-- Add first_submission_at and sla_hours_elapsed to the view
-- NOTE: Must add at END of SELECT list to avoid PostgreSQL error about
--       changing column order (cannot reorder existing columns with CREATE OR REPLACE)

CREATE OR REPLACE VIEW admin_cases_view
WITH (security_invoker = false, security_barrier = true)
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
  creator_user.role as creator_role,
  cases.first_submission_at,        -- ADDED: When family submitted form (at end to avoid column reordering)
  cases.sla_hours_elapsed           -- ADDED: Hours since submission (at end to avoid column reordering)
FROM cases
LEFT JOIN organizations orgs ON orgs.id = cases.org_id
LEFT JOIN users family_user ON family_user.id = cases.assigned_family_user_id
LEFT JOIN users creator_user ON creator_user.id = cases.created_by
WHERE
  -- RLS: Admins see all cases
  (public.get_my_role() = 'admin')
  OR
  -- RLS: Directors see cases in their org
  (
    public.get_my_role() = 'director'
    AND cases.org_id = (SELECT org_id FROM users WHERE id = auth.uid())
  )
  OR
  -- RLS: Support/QC see all cases
  (public.get_my_role() IN ('support', 'qc'))
  OR
  -- RLS: Family users see their assigned cases
  (
    public.get_my_role() = 'family'
    AND cases.assigned_family_user_id = auth.uid()
  )
  OR
  -- RLS: Editors see cases they're assigned to
  (
    public.get_my_role() = 'editor'
    AND EXISTS (
      SELECT 1 FROM editor_assignments
      WHERE editor_assignments.case_id = cases.id
      AND editor_assignments.editor_user_id = auth.uid()
      AND editor_assignments.unassigned_at IS NULL
    )
  );

GRANT SELECT ON admin_cases_view TO authenticated;

COMMENT ON VIEW admin_cases_view IS 
  'Comprehensive case view with organization, family, and creator details.
   Includes first_submission_at and sla_hours_elapsed for real-time SLA display.
   Uses security_barrier for RLS enforcement.';

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Check that new columns exist:
-- SELECT column_name
-- FROM information_schema.columns
-- WHERE table_name = 'admin_cases_view'
-- AND column_name IN ('first_submission_at', 'sla_hours_elapsed')
-- ORDER BY column_name;
--
-- Expected: Should return 2 rows (both columns)
-- ============================================================================

