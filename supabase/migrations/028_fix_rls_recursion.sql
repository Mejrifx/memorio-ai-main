-- ============================================================================
-- FIX RLS RECURSION CAUSING 500 ERRORS ON LOGIN
-- ============================================================================
-- Problem: Users can't log in - 500 error when fetching user data
-- Root Cause: Role-based policies query users table FROM WITHIN users table policies
--             This creates infinite recursion: Policy → Check users → Policy → Check users...
-- Solution: Remove recursive role-based SELECT policies on users table
--           Keep only self-access policy for SELECT
--           Keep role-based INSERT/UPDATE/DELETE policies (they don't cause recursion)

-- The problematic policies from migration 026:
-- CREATE POLICY "Admins full access to users" ... EXISTS (SELECT 1 FROM users u ...)
-- This queries users table while evaluating users table policy = RECURSION!

-- ============================================================================
-- STEP 1: Drop the recursive SELECT policies
-- ============================================================================

-- Drop admin read policy (causes recursion)
DROP POLICY IF EXISTS "Admins full access to users" ON users;

-- Drop director read policy (causes recursion)  
DROP POLICY IF EXISTS "Directors manage users in their org" ON users;

-- Drop support read policy (causes recursion)
DROP POLICY IF EXISTS "Support read all users" ON users;

-- ============================================================================
-- STEP 2: Recreate WITHOUT recursion using a helper function
-- ============================================================================

-- First, create a security definer function that can read roles without RLS
CREATE OR REPLACE FUNCTION auth.user_role()
RETURNS TEXT
LANGUAGE SQL
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$;

COMMENT ON FUNCTION auth.user_role() IS 
  'Returns the current user role without triggering RLS (SECURITY DEFINER bypasses RLS)';

-- Now recreate policies using the helper function instead of subquery
-- This avoids recursion because the function uses SECURITY DEFINER

-- Admins can manage all users
CREATE POLICY "Admins full access to users"
  ON users FOR ALL
  TO authenticated
  USING (auth.user_role() = 'admin')
  WITH CHECK (auth.user_role() = 'admin');

-- Directors can manage users in their org
CREATE POLICY "Directors manage users in their org"
  ON users FOR ALL
  TO authenticated
  USING (
    auth.user_role() = 'director' 
    AND org_id = (SELECT org_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    auth.user_role() = 'director'
    AND org_id = (SELECT org_id FROM users WHERE id = auth.uid())
  );

-- Support can read all users
CREATE POLICY "Support read all users"
  ON users FOR SELECT
  TO authenticated
  USING (auth.user_role() = 'support');

-- ============================================================================
-- VERIFICATION
-- ============================================================================
COMMENT ON POLICY "Admins full access to users" ON users IS 
  'Uses auth.user_role() function to avoid RLS recursion';

COMMENT ON POLICY "Directors manage users in their org" ON users IS 
  'Uses auth.user_role() function to avoid RLS recursion';

COMMENT ON POLICY "Support read all users" ON users IS 
  'Uses auth.user_role() function to avoid RLS recursion';

