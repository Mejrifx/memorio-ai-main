-- ============================================================================
-- VERIFY ADMIN VIEWS SECURITY
-- Run these queries to verify the views are properly secured
-- ============================================================================

-- 1. Check that views exist and are owned by postgres
SELECT 
  schemaname, 
  viewname, 
  viewowner,
  definition
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname IN ('admin_users_view', 'admin_cases_view', 'admin_editor_assignments_view', 'case_analytics')
ORDER BY viewname;

-- 2. Check view grants (should be granted to authenticated)
SELECT 
  table_schema,
  table_name,
  grantee,
  privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
AND table_name IN ('admin_users_view', 'admin_cases_view', 'admin_editor_assignments_view', 'case_analytics')
AND grantee = 'authenticated';

-- ============================================================================
-- TEST SCENARIOS (Run as different users via API or set session)
-- ============================================================================

-- Scenario 1: Admin should see all data
-- (Run this query from admin portal - should return all users)
SELECT COUNT(*) as user_count FROM admin_users_view;
SELECT COUNT(*) as case_count FROM admin_cases_view;

-- Scenario 2: Director should only see their org's data
-- (Run this query from director portal - should return only their org's data)
SELECT COUNT(*) as user_count FROM admin_users_view;
SELECT COUNT(*) as case_count FROM admin_cases_view;

-- Scenario 3: Family user should see very limited data
-- (Run this query from family portal - should return only themselves + their case)
SELECT COUNT(*) as user_count FROM admin_users_view;
SELECT COUNT(*) as case_count FROM admin_cases_view;

-- Scenario 4: Editor should see only assigned cases
-- (Run this query from editor portal - should return only assigned cases)
SELECT COUNT(*) as case_count FROM admin_cases_view;

-- ============================================================================
-- MANUAL SECURITY TEST
-- ============================================================================
-- To thoroughly test, try accessing these views via Supabase API as different users:

-- 1. Test as Admin (should see all)
-- curl -X GET 'https://YOUR_PROJECT.supabase.co/rest/v1/admin_users_view' \
--   -H "apikey: YOUR_ANON_KEY" \
--   -H "Authorization: Bearer ADMIN_JWT_TOKEN"

-- 2. Test as Director (should see only their org)
-- curl -X GET 'https://YOUR_PROJECT.supabase.co/rest/v1/admin_users_view' \
--   -H "apikey: YOUR_ANON_KEY" \
--   -H "Authorization: Bearer DIRECTOR_JWT_TOKEN"

-- 3. Test as Family (should see very limited data)
-- curl -X GET 'https://YOUR_PROJECT.supabase.co/rest/v1/admin_cases_view' \
--   -H "apikey: YOUR_ANON_KEY" \
--   -H "Authorization: Bearer FAMILY_JWT_TOKEN"

-- 4. Test as Editor (should see only assigned cases)
-- curl -X GET 'https://YOUR_PROJECT.supabase.co/rest/v1/admin_cases_view' \
--   -H "apikey: YOUR_ANON_KEY" \
--   -H "Authorization: Bearer EDITOR_JWT_TOKEN"

-- ============================================================================
-- EXPECTED RESULTS
-- ============================================================================
-- Admin: Full access to all views
-- Director: Access to users/cases in their org only
-- Support/QC: Full access to all views
-- Family: Access only to themselves and their case
-- Editor: Access only to assigned cases
-- Unauthenticated: No access (401 error)

-- ============================================================================
-- If any unauthorized user can see data they shouldn't, the migration failed
-- ============================================================================

