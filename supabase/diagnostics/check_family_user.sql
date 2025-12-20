-- Diagnostic Query: Check Family User Setup
-- Run this to diagnose why family users get 406 errors

-- Replace these with actual values from your test:
-- Family user ID: 7df3a0e1-0803-46c2-abdd-5a3ac6a33823 (from your console log)

\echo '=== 1. Check if family user exists in auth.users ==='
SELECT 
  id,
  email,
  raw_app_meta_data->>'role' as jwt_role,
  raw_app_meta_data->>'org_id' as jwt_org_id,
  raw_user_meta_data->>'name' as user_name,
  created_at,
  email_confirmed_at
FROM auth.users
WHERE id = '7df3a0e1-0803-46c2-abdd-5a3ac6a33823';

\echo '=== 2. Check if family user exists in public.users ==='
SELECT 
  id,
  email,
  role,
  org_id,
  status,
  metadata
FROM users
WHERE id = '7df3a0e1-0803-46c2-abdd-5a3ac6a33823';

\echo '=== 3. Check if case is assigned to family user ==='
SELECT 
  id,
  deceased_name,
  org_id,
  assigned_family_user_id,
  status,
  created_at
FROM cases
WHERE assigned_family_user_id = '7df3a0e1-0803-46c2-abdd-5a3ac6a33823';

\echo '=== 4. Check RLS policies for users table ==='
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
WHERE tablename = 'users'
ORDER BY policyname;

\echo '=== 5. Check RLS policies for cases table (family) ==='
SELECT 
  policyname,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'cases'
  AND policyname LIKE '%Famil%'
ORDER BY policyname;

\echo '=== 6. Test RLS as family user (simulated) ==='
-- This simulates what happens when the family user makes a request
SET LOCAL role = authenticated;
SET LOCAL request.jwt.claims = '{
  "sub": "7df3a0e1-0803-46c2-abdd-5a3ac6a33823",
  "role": "authenticated",
  "app_metadata": {
    "role": "family",
    "org_id": "REPLACE_WITH_ORG_ID"
  }
}';

-- Try to read user's own profile
SELECT 'Attempting to read own profile...' as test;
SELECT id, email, role FROM users WHERE id = '7df3a0e1-0803-46c2-abdd-5a3ac6a33823';

-- Try to read assigned case
SELECT 'Attempting to read assigned case...' as test;
SELECT id, deceased_name FROM cases WHERE assigned_family_user_id = '7df3a0e1-0803-46c2-abdd-5a3ac6a33823';

-- Reset
RESET role;
RESET request.jwt.claims;

\echo '=== 7. Check if organization exists ==='
SELECT 
  id,
  name,
  status,
  created_at
FROM organizations
WHERE id = (
  SELECT org_id FROM users WHERE id = '7df3a0e1-0803-46c2-abdd-5a3ac6a33823'
);

\echo '=== DIAGNOSIS COMPLETE ==='
\echo 'Look for:'
\echo '1. jwt_role should be "family" in auth.users'
\echo '2. role should be "family" in public.users'
\echo '3. org_id should match in both tables'
\echo '4. assigned_family_user_id should match user id in cases table'
\echo '5. RLS policies should allow authenticated users to read their own profile'
\echo '6. Simulated RLS test should return results (not empty)'

