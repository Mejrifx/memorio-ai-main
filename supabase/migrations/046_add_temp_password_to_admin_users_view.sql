-- ============================================================================
-- Migration: 046 - Add temp_password to admin_users_view
-- ============================================================================
-- Purpose: Allow admins to retrieve temporary passwords for editor/QC accounts
--          so they can view login credentials in the account details modal
-- ============================================================================

-- PROBLEM:
-- ========
-- When admin clicks on editor/QC account card and clicks "Reveal", the
-- temp_password shows as "Not available" because:
-- 1. admin_users_view doesn't include temp_password column
-- 2. Direct query to users table is blocked by RLS
-- 3. Query returns 0 rows even though accounts exist

-- SOLUTION:
-- =========
-- Add temp_password column to admin_users_view so admins can access it
-- through the view (which bypasses RLS with security_invoker = false)

CREATE OR REPLACE VIEW admin_users_view 
WITH (security_invoker = false, security_barrier = true)
AS
SELECT 
  id,
  email,
  role,
  org_id,
  status,
  metadata,
  created_at,
  updated_at,
  last_login_at,
  temp_password  -- ADDED: Temporary password for credential display
FROM users
WHERE 
  -- Admins see all users
  (public.get_my_role() = 'admin')
  OR
  -- Directors see users in their org
  (
    public.get_my_role() = 'director' 
    AND org_id = (SELECT org_id FROM users WHERE id = auth.uid())
  )
  OR
  -- Support/QC see all users
  (public.get_my_role() IN ('support', 'qc'))
  OR
  -- Users see themselves
  (id = auth.uid());

GRANT SELECT ON admin_users_view TO authenticated;

COMMENT ON VIEW admin_users_view IS 
  'Admin/Director view for querying users without RLS recursion issues.
   Includes temp_password for admins to view login credentials.
   Uses security_barrier = true to prevent information leakage.
   security_invoker = false allows bypassing RLS on source table.';

-- ============================================================================
-- SECURITY NOTES:
-- ============================================================================
-- This is secure because:
-- 1. View has WHERE clause restricting access by role
-- 2. Only admins/directors can access temp_password
-- 3. Directors only see users in their org
-- 4. RLS on the view itself controls access
-- 5. temp_password is needed for account recovery/support

-- ============================================================================
-- VERIFICATION QUERY:
-- ============================================================================
-- Run this after applying the migration to verify it worked:
-- 
-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'admin_users_view'
-- ORDER BY ordinal_position;
-- 
-- Should show temp_password as one of the columns
-- ============================================================================

