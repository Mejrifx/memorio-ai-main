-- ============================================================================
-- RESTORE ADMIN ACCOUNT
-- UUID: 3a223560-ff1e-49ed-914f-09c693ff47f4
-- ============================================================================

-- Step 1: Check if the auth user still exists
SELECT 
  id,
  email,
  created_at,
  raw_app_meta_data,
  raw_user_meta_data
FROM auth.users 
WHERE id = '3a223560-ff1e-49ed-914f-09c693ff47f4';

-- Step 2: Delete the wrong family user ID first
DELETE FROM events WHERE actor_user_id = '2540eb1b-21ec-49f0-955f-488732a92c90';
DELETE FROM users WHERE id = '2540eb1b-21ec-49f0-955f-488732a92c90';

-- Step 3: Restore the admin user in public.users
INSERT INTO users (
  id,
  email,
  role,
  org_id,
  status,
  metadata,
  created_at,
  updated_at
) VALUES (
  '3a223560-ff1e-49ed-914f-09c693ff47f4',
  'admin@memorio.test',  -- Update this if different
  'admin',
  NULL,
  'active',
  jsonb_build_object('name', 'Admin User'),
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE
SET 
  role = 'admin',
  org_id = NULL,
  status = 'active',
  updated_at = NOW();

-- Step 4: Update the auth user's app_metadata to ensure role is set correctly
UPDATE auth.users
SET raw_app_meta_data = jsonb_build_object('role', 'admin')
WHERE id = '3a223560-ff1e-49ed-914f-09c693ff47f4';

-- Step 5: Verify the admin account
SELECT 
  u.id,
  u.email,
  u.role,
  u.org_id,
  u.status,
  au.raw_app_meta_data->>'role' as app_metadata_role
FROM users u
JOIN auth.users au ON au.id = u.id
WHERE u.id = '3a223560-ff1e-49ed-914f-09c693ff47f4';

-- Done! Your admin account should be restored.
-- If the email shown in Step 1 is different, update the email in Step 3.

