-- Check 1: Show ALL users in the system
SELECT 
  id,
  email,
  role,
  org_id,
  status,
  created_at
FROM users
ORDER BY created_at DESC
LIMIT 20;

-- Check 2: Show ALL cases
SELECT 
  id,
  deceased_name,
  org_id,
  assigned_family_user_id,
  status,
  created_at
FROM cases
ORDER BY created_at DESC
LIMIT 10;

-- Check 3: Show recent audit events for family invites
SELECT 
  id,
  actor_role,
  action_type,
  payload,
  timestamp
FROM events
WHERE action_type = 'INVITE_FAMILY'
ORDER BY timestamp DESC
LIMIT 5;

