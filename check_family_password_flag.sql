-- Check if family users have the password change flag set
SELECT 
  id,
  email,
  role,
  status,
  metadata->>'requires_password_change' as requires_password_change,
  metadata->>'name' as family_name,
  created_at
FROM users
WHERE role = 'family'
ORDER BY created_at DESC
LIMIT 5;
