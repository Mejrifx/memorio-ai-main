-- ============================================================================
-- FIX RLS RECURSION CAUSING 500 ERRORS ON LOGIN (v2)
-- ============================================================================
-- Problem: Users can't log in - 500 error when fetching user data
-- Root Cause: Role-based policies query users table FROM WITHIN users table policies
-- Solution: Use helper function in PUBLIC schema (not auth schema)

-- ============================================================================
-- STEP 1: Drop the recursive SELECT policies
-- ============================================================================

DROP POLICY IF EXISTS "Admins full access to users" ON users;
DROP POLICY IF EXISTS "Directors manage users in their org" ON users;
DROP POLICY IF EXISTS "Support read all users" ON users;

-- ============================================================================
-- STEP 2: Create helper function in PUBLIC schema
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS TEXT
LANGUAGE SQL
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$;

COMMENT ON FUNCTION public.get_current_user_role() IS 
  'Returns the current user role without triggering RLS (SECURITY DEFINER bypasses RLS)';

-- ============================================================================
-- STEP 3: Recreate policies using helper function
-- ============================================================================

-- Admins can manage all users
CREATE POLICY "Admins full access to users"
  ON users FOR ALL
  TO authenticated
  USING (public.get_current_user_role() = 'admin')
  WITH CHECK (public.get_current_user_role() = 'admin');

-- Directors can manage users in their org
CREATE POLICY "Directors manage users in their org"
  ON users FOR ALL
  TO authenticated
  USING (
    public.get_current_user_role() = 'director' 
    AND org_id = (SELECT org_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    public.get_current_user_role() = 'director'
    AND org_id = (SELECT org_id FROM users WHERE id = auth.uid())
  );

-- Support can read all users
CREATE POLICY "Support read all users"
  ON users FOR SELECT
  TO authenticated
  USING (public.get_current_user_role() = 'support');

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON POLICY "Admins full access to users" ON users IS 
  'Uses get_current_user_role() function to avoid RLS recursion';

COMMENT ON POLICY "Directors manage users in their org" ON users IS 
  'Uses get_current_user_role() function to avoid RLS recursion';

COMMENT ON POLICY "Support read all users" ON users IS 
  'Uses get_current_user_role() function to avoid RLS recursion';

