-- Check the ACTUAL family user's JWT metadata
-- User ID: e51d732f-70f2-473a-a927-ed9ad303894c
-- Email: DavesFamily@gmail.com

-- Check 1: public.users table
SELECT 
  'PUBLIC USERS TABLE' as source,
  id,
  email,
  role,
  org_id::text as org_id,
  status,
  metadata
FROM users
WHERE id = 'e51d732f-70f2-473a-a927-ed9ad303894c';

-- Check 2: auth.users table (JWT data)
SELECT 
  'AUTH USERS TABLE (JWT SOURCE)' as source,
  id,
  email,
  raw_app_meta_data->>'role' as jwt_role,
  raw_app_meta_data->>'org_id' as jwt_org_id,
  raw_app_meta_data as full_app_metadata,
  raw_user_meta_data->>'name' as user_name,
  email_confirmed_at
FROM auth.users
WHERE id = 'e51d732f-70f2-473a-a927-ed9ad303894c';

-- Check 3: Verify the case assignment
SELECT 
  'CASE ASSIGNMENT CHECK' as source,
  id as case_id,
  deceased_name,
  org_id::text as case_org_id,
  assigned_family_user_id::text as family_user_id,
  status
FROM cases
WHERE id = 'dda56a32-d5f5-4f5b-af97-818b8e2217fd';

