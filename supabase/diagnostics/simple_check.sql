-- Simple Diagnostic: Check Family User
-- User ID: dda56a32-d5f5-4f5b-af97-818b8e2217fd

-- Query 1: Check auth.users
SELECT 
  'AUTH USER CHECK' as check_type,
  id,
  email,
  raw_app_meta_data->>'role' as jwt_role,
  raw_app_meta_data->>'org_id' as jwt_org_id,
  raw_user_meta_data->>'name' as user_name,
  email_confirmed_at
FROM auth.users
WHERE id = 'dda56a32-d5f5-4f5b-af97-818b8e2217fd';

-- Query 2: Check public.users
SELECT 
  'PUBLIC USER CHECK' as check_type,
  id,
  email,
  role,
  org_id::text as org_id,
  status,
  metadata
FROM users
WHERE id = 'dda56a32-d5f5-4f5b-af97-818b8e2217fd';

-- Query 3: Check cases
SELECT 
  'CASE CHECK' as check_type,
  id,
  deceased_name,
  org_id::text as case_org_id,
  assigned_family_user_id::text as assigned_to,
  status
FROM cases
WHERE assigned_family_user_id = 'dda56a32-d5f5-4f5b-af97-818b8e2217fd';

-- Query 4: Check if user exists at all in auth
SELECT 
  'ALL AUTH USERS COUNT' as check_type,
  COUNT(*) as total_users,
  COUNT(*) FILTER (WHERE email = 'imran@gmail.com') as matching_email
FROM auth.users;

-- Query 5: Check if user exists at all in public
SELECT 
  'ALL PUBLIC USERS COUNT' as check_type,
  COUNT(*) as total_users,
  COUNT(*) FILTER (WHERE email = 'imran@gmail.com') as matching_email
FROM users;

