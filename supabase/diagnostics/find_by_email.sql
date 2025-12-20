-- Find the family user by email
SELECT 
  id,
  email,
  role,
  org_id,
  status,
  metadata,
  created_at
FROM users
WHERE email = 'imran@gmail.com';

-- Also check in auth.users
SELECT 
  id,
  email,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at
FROM auth.users
WHERE email = 'imran@gmail.com';

