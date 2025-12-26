-- ============================================================================
-- CREATE ADMIN CASES VIEW - Bypass RLS for admin case queries
-- ============================================================================
-- Problem: Admin portal "All Cases" section shows no cases
-- Root Cause: Query tries to LEFT JOIN users table, but users table has 
--             ONLY self-access RLS policies. Admin can't see other users.
-- 
-- Query that fails:
--   SELECT *, 
--     users!cases_assigned_family_user_id_fkey (email, metadata)
--   FROM cases
-- 
-- This LEFT JOIN to users fails because admin can only see their own user record.
-- 
-- Solution: Create a VIEW with security_invoker = false that includes all 
--           necessary joined data. Admin queries this view instead of cases table.
-- ============================================================================

-- ============================================================================
-- STEP 1: Create comprehensive admin cases view
-- ============================================================================

CREATE OR REPLACE VIEW admin_cases_view
WITH (security_invoker = false)  -- Run with definer's permissions (bypasses RLS)
AS
SELECT 
  -- All case columns
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
  
  -- Organization info
  orgs.name as org_name,
  orgs.contact_email as org_contact_email,
  orgs.contact_phone as org_contact_phone,
  orgs.region as org_region,
  orgs.status as org_status,
  
  -- Family user info (LEFT JOIN - might be NULL if not assigned yet)
  family_user.email as family_email,
  family_user.metadata as family_metadata,
  family_user.status as family_status,
  
  -- Created by user info
  creator_user.email as creator_email,
  creator_user.metadata as creator_metadata,
  creator_user.role as creator_role

FROM cases
LEFT JOIN organizations orgs ON orgs.id = cases.org_id
LEFT JOIN users family_user ON family_user.id = cases.assigned_family_user_id
LEFT JOIN users creator_user ON creator_user.id = cases.created_by;

-- Grant access to authenticated users
GRANT SELECT ON admin_cases_view TO authenticated;

COMMENT ON VIEW admin_cases_view IS 
  'Comprehensive view of cases with all joined data for admin portal.
  Bypasses RLS to allow admin to see cases with family/creator user info.
  
  Use this view in admin portal instead of querying cases table directly.
  
  Example usage:
    const { data: cases } = await supabaseClient
      .from(''admin_cases_view'')
      .select(''*'')
      .order(''created_at'', { ascending: false });
  
  For editor assignments and video submissions, query those tables separately:
    const { data: assignments } = await supabaseClient
      .from(''editor_assignments'')
      .select(''*'')
      .eq(''case_id'', caseId);
  ';

-- ============================================================================
-- STEP 2: Create view for editor assignments (with editor info)
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
  
  -- Editor user info
  editor_user.email as editor_email,
  editor_user.metadata as editor_metadata,
  editor_user.status as editor_status,
  
  -- Assigned by user info
  assigner_user.email as assigned_by_email,
  assigner_user.metadata as assigned_by_metadata

FROM editor_assignments
LEFT JOIN users editor_user ON editor_user.id = editor_assignments.editor_user_id
LEFT JOIN users assigner_user ON assigner_user.id = editor_assignments.assigned_by;

GRANT SELECT ON admin_editor_assignments_view TO authenticated;

COMMENT ON VIEW admin_editor_assignments_view IS 
  'View of editor assignments with editor user info for admin portal.
  Bypasses RLS to allow admin to see editor details.
  
  Example usage:
    const { data: assignments } = await supabaseClient
      .from(''admin_editor_assignments_view'')
      .select(''*'')
      .eq(''case_id'', caseId)
      .is(''unassigned_at'', null);
  ';

-- ============================================================================
-- ALTERNATIVE: Simple approach - just modify the query in frontend
-- ============================================================================
-- If views don't work, the frontend can make multiple queries:
-- 
-- 1. Query cases (admin has access via RLS policy):
--    SELECT * FROM cases ORDER BY created_at DESC;
-- 
-- 2. Query organizations (admin has access):
--    SELECT id, name FROM organizations;
-- 
-- 3. Query users via admin_users_view (already exists):
--    SELECT id, email, metadata FROM admin_users_view;
-- 
-- 4. Query editor_assignments (admin has access):
--    SELECT * FROM editor_assignments;
-- 
-- 5. Join the data in JavaScript
-- 
-- This is less efficient but guaranteed to work.
-- ============================================================================


