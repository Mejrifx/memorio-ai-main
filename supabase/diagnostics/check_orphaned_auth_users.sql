-- ============================================================================
-- DIAGNOSTIC: Check for orphaned auth users
-- ============================================================================
-- Purpose: Find auth.users that exist but have no corresponding public.users record
-- This helps diagnose "user already registered" errors when inviting families

-- Run this query to see if there are orphaned auth users:
-- Note: This query must be run with service role access or in the Supabase dashboard

SELECT 
  au.id as auth_user_id,
  au.email,
  au.created_at as auth_created,
  au.deleted_at,
  pu.id as db_user_id,
  pu.role,
  pu.status,
  CASE 
    WHEN au.deleted_at IS NOT NULL THEN 'Soft Deleted in Auth'
    WHEN pu.id IS NULL THEN 'Orphaned (No DB Record)'
    ELSE 'OK'
  END as status_check
FROM auth.users au
LEFT JOIN public.users pu ON pu.id = au.id
WHERE 
  -- Show only problematic records
  au.deleted_at IS NOT NULL 
  OR pu.id IS NULL
ORDER BY au.created_at DESC;

-- If you find orphaned auth users, you can clean them up with:
-- (Replace <user_id> with the actual UUID from the query above)
-- 
-- SELECT auth.admin_delete_user('<user_id>');
--
-- Or permanently delete (bypassing soft delete):
-- This requires calling the Edge Function or using the Supabase dashboard

COMMENT ON TABLE users IS 
  'If family invitation fails with "user already registered" error:
  1. Run the diagnostic query above
  2. Find the orphaned auth user with that email
  3. Manually delete them from auth.users via Supabase dashboard
  4. Or use the auth.admin API to force delete them';

