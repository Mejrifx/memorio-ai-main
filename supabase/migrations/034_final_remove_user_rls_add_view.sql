-- ============================================================================
-- FINAL FIX: Remove ALL role-based policies on users table
-- ============================================================================
-- Problem: Login still fails even with id != auth.uid() check
-- Root Cause: PostgreSQL evaluates get_my_role() function even when checking
--             if policy applies, causing recursion before id check happens
-- Solution: Keep ONLY self-access policies on users table
--           Admin/Director use Edge Functions for user management (already implemented)

-- ============================================================================
-- STEP 1: Remove ALL role-based policies (again)
-- ============================================================================

DROP POLICY IF EXISTS "Admins manage other users" ON users;
DROP POLICY IF EXISTS "Admins full access to users" ON users;
DROP POLICY IF EXISTS "Directors manage other users in org" ON users;
DROP POLICY IF EXISTS "Directors manage users in their org" ON users;
DROP POLICY IF EXISTS "Support read other users" ON users;
DROP POLICY IF EXISTS "Support read all users" ON users;
DROP POLICY IF EXISTS "QC read other users" ON users;
DROP POLICY IF EXISTS "QC read all users" ON users;

-- ============================================================================
-- STEP 2: Ensure ONLY self-access policies exist
-- ============================================================================

-- Drop and recreate to ensure they're correct
DROP POLICY IF EXISTS "Users read their own profile" ON users;
DROP POLICY IF EXISTS "Users update their own profile" ON users;

CREATE POLICY "Users read their own profile"
  ON users FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Users update their own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- ============================================================================
-- STEP 3: Create a view for admin to query users (bypasses RLS)
-- ============================================================================

CREATE OR REPLACE VIEW admin_users_view 
WITH (security_invoker = false)  -- Run with definer's permissions
AS
SELECT 
  id,
  email,
  role,
  org_id,
  status,
  metadata,
  created_at,
  updated_at
FROM users;

-- Grant access to authenticated users
GRANT SELECT ON admin_users_view TO authenticated;

-- Create a function to check if user is admin/director
CREATE OR REPLACE FUNCTION can_view_all_users()
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT role IN ('admin', 'director', 'support', 'qc') 
  FROM users 
  WHERE id = auth.uid();
$$;

COMMENT ON VIEW admin_users_view IS 
  'View for admins/directors to query users without RLS issues.
  Use this view in admin portal instead of querying users table directly.
  Example: SELECT * FROM admin_users_view WHERE role = ''editor''';

COMMENT ON FUNCTION can_view_all_users() IS 
  'Returns true if current user is admin/director/support/qc.
  Can be used in application logic to determine if user should access admin_users_view';

-- ============================================================================
-- ALTERNATIVE: Edge Function for querying users
-- ============================================================================

COMMENT ON TABLE users IS 
  'RLS Strategy for users table:
  
  1. ONLY self-access policies exist (for login/profile updates)
  2. Admin/Director user management uses ONE of:
     a) Edge Functions with service role (RECOMMENDED - already implemented)
     b) admin_users_view (for read-only queries like editor dropdown)
     c) Direct service role queries from backend
  
  Why no role-based RLS policies?
  - ANY policy that queries users table causes recursion
  - Even with SECURITY DEFINER functions, evaluation order causes issues
  - PostgreSQL may evaluate function before checking other conditions
  - Result: 500 errors and login failures
  
  Solution: 
  - Self-access only via RLS (enables login)
  - Admin functions via service role or views (bypasses RLS)
  
  Example usage in admin portal:
  // Get list of editors for dropdown
  const { data: editors } = await supabaseClient
    .from(''admin_users_view'')
    .select(''id, email, metadata'')
    .eq(''role'', ''editor'');
  ';

