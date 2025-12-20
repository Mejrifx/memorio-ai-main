-- Diagnostic Query: Check Family User Setup
-- Run this to diagnose why family users get 406 errors

-- Family user ID: dda56a32-d5f5-4f5b-af97-818b8e2217fd
-- Email: imran@gmail.com

SELECT '=== 1. Check if family user exists in auth.users ===' as section;
SELECT 
  id,
  email,
  raw_app_meta_data->>'role' as jwt_role,
  raw_app_meta_data->>'org_id' as jwt_org_id,
  raw_user_meta_data->>'name' as user_name,
  created_at,
  email_confirmed_at
FROM auth.users
WHERE id = 'dda56a32-d5f5-4f5b-af97-818b8e2217fd';

SELECT '=== 2. Check if family user exists in public.users ===' as section;
SELECT 
  id,
  email,
  role,
  org_id,
  status,
  metadata
FROM users
WHERE id = 'dda56a32-d5f5-4f5b-af97-818b8e2217fd';

SELECT '=== 3. Check if case is assigned to family user ===' as section;
SELECT 
  id,
  deceased_name,
  org_id,
  assigned_family_user_id,
  status,
  created_at
FROM cases
WHERE assigned_family_user_id = 'dda56a32-d5f5-4f5b-af97-818b8e2217fd';

SELECT '=== 4. Check RLS policies for users table ===' as section;
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

SELECT '=== 5. Check RLS policies for cases table (family) ===' as section;
SELECT 
  policyname,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'cases'
  AND policyname LIKE '%Famil%'
ORDER BY policyname;

SELECT '=== 6. Check if organization exists ===' as section;
SELECT 
  id,
  name,
  status,
  created_at
FROM organizations
WHERE id = (
  SELECT org_id FROM users WHERE id = 'dda56a32-d5f5-4f5b-af97-818b8e2217fd'
);

SELECT '=== DIAGNOSIS SUMMARY ===' as section;
SELECT '
Look for:
1. jwt_role should be "family" in auth.users (Section 1)
2. role should be "family" in public.users (Section 2)
3. org_id should match in both tables (Sections 1 & 2)
4. assigned_family_user_id should match user id in cases table (Section 3)
5. RLS policies should allow authenticated users to read their own profile (Section 4)
6. Organization should exist and be active (Section 6)
' as diagnosis_checklist;

