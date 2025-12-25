-- ============================================================================
-- SIMPLIFY USER RLS POLICIES - REMOVE ALL RECURSION
-- ============================================================================
-- Problem: Login still fails with 500 error even after helper function
-- Root Cause: Director policy STILL has recursive subquery:
--   AND org_id = (SELECT org_id FROM users WHERE id = auth.uid())
--   This queries users table, triggering RLS again!
-- Solution: Remove ALL role-based policies on users table
--           Keep ONLY self-access policy for login to work
--           Admin/Director user management will work via service role on backend

-- ============================================================================
-- STEP 1: Drop ALL role-based policies (they all cause issues)
-- ============================================================================

DROP POLICY IF EXISTS "Admins full access to users" ON users;
DROP POLICY IF EXISTS "Directors manage users in their org" ON users;
DROP POLICY IF EXISTS "Support read all users" ON users;

-- ============================================================================
-- STEP 2: Verify self-access policy exists (critical for login)
-- ============================================================================

-- This should already exist, but recreate if missing
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
-- STEP 3: Create admin access via service role (not RLS)
-- ============================================================================
-- Admin/Director portals should use service role key for managing users
-- This bypasses RLS entirely, avoiding recursion issues

COMMENT ON TABLE users IS 
  'RLS Policy Strategy:
  - Self-access: Users can read/update their own profile (for login/auth)
  - Admin access: Use service role key on backend (bypasses RLS)
  - Director access: Use service role key on backend (bypasses RLS)
  
  Why no role-based RLS policies?
  - Checking roles requires querying users table
  - Querying users table triggers RLS policies
  - RLS policies check roles → RECURSION
  - Result: 500 errors and infinite loops
  
  Solution: Self-access only via RLS, admin functions via service role';

-- ============================================================================
-- OPTIONAL: Add helper function for other tables to check user roles
-- ============================================================================
-- This function can be used by OTHER tables' RLS policies (not users table)
-- It's safe because it uses SECURITY DEFINER to bypass RLS when called

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE SQL
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$;

COMMENT ON FUNCTION public.get_my_role() IS 
  'Returns current user role. Safe to use in OTHER tables RLS policies.
  DO NOT use this in users table policies (causes recursion)!
  Use cases: Check if user is admin in cases/organizations/etc policies';

