-- Find the family user by correct email
-- Email: DavesFamily@gmail.com

-- Check 1: Find in public.users
SELECT 
  id,
  email,
  role,
  org_id,
  status,
  metadata,
  created_at
FROM users
WHERE email = 'DavesFamily@gmail.com';

-- Check 2: Find in auth.users
SELECT 
  id,
  email,
  raw_app_meta_data,
  raw_user_meta_data,
  email_confirmed_at,
  created_at
FROM auth.users
WHERE email = 'DavesFamily@gmail.com';

-- Check 3: Find their case
SELECT 
  c.id,
  c.deceased_name,
  c.org_id,
  c.assigned_family_user_id,
  c.status,
  c.created_at,
  u.email as assigned_to_email
FROM cases c
LEFT JOIN users u ON u.id = c.assigned_family_user_id
WHERE u.email = 'DavesFamily@gmail.com'
   OR c.assigned_family_user_id IN (
     SELECT id FROM users WHERE email = 'DavesFamily@gmail.com'
   );

