-- Fix Admin Account Immediately
-- Run this SQL right now in Supabase Dashboard → SQL Editor

-- Step 1: Find your admin account
-- (Replace 'your-admin-email@example.com' with your actual admin email)

-- Step 2: Update admin account with proper app_metadata
UPDATE auth.users
SET raw_app_meta_data = jsonb_build_object('role', 'admin')
WHERE id IN (
  SELECT id 
  FROM public.users 
  WHERE role = 'admin'
);

-- Step 3: Verify it worked
SELECT 
  au.email,
  u.role as db_role,
  au.raw_app_meta_data->>'role' as jwt_role,
  CASE 
    WHEN au.raw_app_meta_data->>'role' = 'admin' THEN '✅ FIXED'
    ELSE '❌ NEEDS FIX'
  END as status
FROM auth.users au
JOIN public.users u ON u.id = au.id
WHERE u.role = 'admin';

-- You should see:
-- email                    | db_role | jwt_role | status
-- ------------------------|---------|----------|----------
-- your-admin@example.com  | admin   | admin    | ✅ FIXED

