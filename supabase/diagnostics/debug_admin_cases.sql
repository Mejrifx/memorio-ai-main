-- ============================================================================
-- DIAGNOSTIC: Why can't admin see cases in "All Cases" section?
-- ============================================================================
-- Run these queries as the admin user to debug the issue
--
-- Instructions:
-- 1. Log into admin portal
-- 2. Open browser console
-- 3. Copy each query below and run via Supabase client
-- 4. Share results with developer

-- ============================================================================
-- STEP 1: Check if cases exist in database
-- ============================================================================
-- This bypasses RLS to see raw data
-- Run this in Supabase Dashboard SQL Editor (uses service role)

SELECT 
  id,
  deceased_name,
  status,
  org_id,
  assigned_family_user_id,
  created_at
FROM cases
ORDER BY created_at DESC
LIMIT 10;

-- Expected: Should show all cases regardless of RLS
-- If empty: No cases exist, need to create some
-- If has data: Cases exist, RLS is blocking them

-- ============================================================================
-- STEP 2: Check if admin user exists and role is correct
-- ============================================================================

SELECT 
  id,
  email,
  role,
  org_id,
  status,
  metadata
FROM users
WHERE id = auth.uid();

-- Expected: Should show admin user with role = 'admin'
-- If role != 'admin': Fix role in database
-- If no result: User not in users table (serious issue)

-- ============================================================================
-- STEP 3: Test get_my_role() function
-- ============================================================================

SELECT public.get_my_role() as my_role;

-- Expected: Should return 'admin'
-- If NULL: Function can't read users table (RLS issue)
-- If different role: User's role is wrong

-- ============================================================================
-- STEP 4: Test if admin can see cases directly
-- ============================================================================

SELECT 
  id,
  deceased_name,
  status,
  created_at
FROM cases
LIMIT 10;

-- Expected: Should show cases if RLS policy is working
-- If empty: RLS policy is blocking admin
-- If has data: Admin can see cases, issue is with query

-- ============================================================================
-- STEP 5: Test the full query with all JOINs
-- ============================================================================

SELECT 
  cases.id,
  cases.deceased_name,
  cases.status,
  organizations.name as org_name
FROM cases
LEFT JOIN organizations ON organizations.id = cases.org_id
ORDER BY cases.created_at DESC
LIMIT 10;

-- Expected: Should show cases with org names
-- If empty but step 4 works: Issue with organizations JOIN
-- If has data: Query works, issue is in frontend

-- ============================================================================
-- STEP 6: Check organizations table access
-- ============================================================================

SELECT 
  id,
  name,
  status
FROM organizations
LIMIT 10;

-- Expected: Admin should see all organizations
-- If empty: RLS blocking organizations table

-- ============================================================================
-- STEP 7: Check RLS policies on cases table
-- ============================================================================
-- Run this in Supabase Dashboard SQL Editor

SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'cases'
ORDER BY policyname;

-- Expected: Should see "Admins full access to cases" policy
-- Check if USING clause matches: public.get_my_role() = 'admin'

-- ============================================================================
-- STEP 8: Check RLS policies on organizations table
-- ============================================================================
-- Run this in Supabase Dashboard SQL Editor

SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'organizations'
ORDER BY policyname;

-- Expected: Should see "Admins full access to organizations" policy

-- ============================================================================
-- STEP 9: Test with explicit role check
-- ============================================================================

SELECT 
  id,
  deceased_name,
  status,
  (SELECT role FROM users WHERE id = auth.uid()) as my_role_direct
FROM cases
WHERE (SELECT role FROM users WHERE id = auth.uid()) = 'admin'
LIMIT 10;

-- Expected: Should show cases if role check works
-- If empty: Role check is failing

-- ============================================================================
-- STEP 10: Check if there are any errors in PostgreSQL logs
-- ============================================================================
-- Run this in Supabase Dashboard SQL Editor

SELECT 
  log_time,
  message,
  detail
FROM pg_stat_statements
WHERE query LIKE '%cases%'
ORDER BY log_time DESC
LIMIT 20;

-- This might not work depending on Supabase plan
-- Check Supabase Dashboard > Database > Logs for errors

-- ============================================================================
-- EXPECTED OUTPUT ANALYSIS
-- ============================================================================
/*
Scenario 1: get_my_role() returns NULL
  - Problem: RLS recursion on users table
  - Solution: Check migration 034 was applied correctly
  
Scenario 2: Cases exist but step 4 returns empty
  - Problem: RLS policy on cases table not working
  - Solution: Re-apply migration 031 or fix policy
  
Scenario 3: Step 4 works but step 5 returns empty
  - Problem: organizations table RLS blocking LEFT JOIN
  - Solution: Check organizations RLS policy for admin
  
Scenario 4: All queries work in Dashboard but frontend empty
  - Problem: JavaScript query in cases.html
  - Solution: Check browser console for errors
  - Check network tab for failed requests
*/

