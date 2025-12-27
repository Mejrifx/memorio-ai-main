-- Migration: Add last_login_at to admin_users_view
-- Purpose: Fix the "Last Login" showing as "Never" for editors and QC users in Manage Accounts
-- Issue: The admin_users_view was missing the last_login_at column

-- ============================================================================
-- UPDATE admin_users_view to include last_login_at
-- ============================================================================

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
  last_login_at  -- ADDED: This was missing!
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
   Includes last_login_at for tracking user activity.
   Uses security_barrier = true to prevent information leakage.';

