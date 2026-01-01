-- Test what the timeline_view is actually returning
SELECT 
  timestamp,
  action_type,
  description,
  actor_role,
  actor_name,
  actor_email,
  payload
FROM timeline_view
ORDER BY timestamp DESC
LIMIT 10;
