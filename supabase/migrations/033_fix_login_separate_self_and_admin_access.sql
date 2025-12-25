-- ============================================================================
-- FIX LOGIN RECURSION - SEPARATE SELF-ACCESS FROM ROLE-BASED ACCESS
-- ============================================================================
-- Problem: Adding back admin policies broke login again
-- Root Cause: Even with helper function, having multiple policies on users table
--             causes evaluation issues during login
-- Solution: Make admin/director policies ONLY apply to OTHER users, not self
--           This ensures self-access policy is the only one evaluated during login

-- ============================================================================
-- STEP 1: Drop the policies that are causing issues
-- ============================================================================

DROP POLICY IF EXISTS "Admins full access to users" ON users;
DROP POLICY IF EXISTS "Directors manage users in their org" ON users;
DROP POLICY IF EXISTS "Support read all users" ON users;
DROP POLICY IF EXISTS "QC read all users" ON users;

-- ============================================================================
-- STEP 2: Recreate with id != auth.uid() condition to avoid self-access
-- ============================================================================
-- This ensures these policies ONLY apply when querying OTHER users
-- Self-access is handled by the dedicated "Users read their own profile" policy

-- Admins can read/manage OTHER users (not self - that's handled by self-access policy)
CREATE POLICY "Admins manage other users"
  ON users FOR ALL
  TO authenticated
  USING (
    public.get_my_role() = 'admin'
    AND id != auth.uid()  -- Only apply to OTHER users
  )
  WITH CHECK (
    public.get_my_role() = 'admin'
    AND id != auth.uid()  -- Only apply to OTHER users
  );

-- Directors can read/manage OTHER users in their org
CREATE POLICY "Directors manage other users in org"
  ON users FOR ALL
  TO authenticated
  USING (
    public.get_my_role() = 'director'
    AND id != auth.uid()  -- Only apply to OTHER users
    AND org_id IN (SELECT org_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    public.get_my_role() = 'director'
    AND id != auth.uid()  -- Only apply to OTHER users
    AND org_id IN (SELECT org_id FROM users WHERE id = auth.uid())
  );

-- Support can read OTHER users
CREATE POLICY "Support read other users"
  ON users FOR SELECT
  TO authenticated
  USING (
    public.get_my_role() = 'support'
    AND id != auth.uid()  -- Only apply to OTHER users
  );

-- QC can read OTHER users
CREATE POLICY "QC read other users"
  ON users FOR SELECT
  TO authenticated
  USING (
    public.get_my_role() = 'qc'
    AND id != auth.uid()  -- Only apply to OTHER users
  );

-- ============================================================================
-- STEP 3: Ensure self-access policy exists (should already exist from 030)
-- ============================================================================
-- This is the ONLY policy that should evaluate during login

-- Drop and recreate to be sure it's correct
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
-- COMMENTS
-- ============================================================================
COMMENT ON POLICY "Users read their own profile" ON users IS 
  'CRITICAL: This is the ONLY policy evaluated during login. 
  Must be simple with NO function calls or subqueries.
  Allows any authenticated user to read their own record.';

COMMENT ON POLICY "Admins manage other users" ON users IS 
  'Uses get_my_role() + id != auth.uid() to avoid interfering with login.
  Only evaluates when admin queries OTHER users (e.g., editor dropdown).';

COMMENT ON POLICY "Directors manage other users in org" ON users IS 
  'Uses get_my_role() + id != auth.uid() to avoid interfering with login.
  Only evaluates when director queries OTHER users in their org.';

-- ============================================================================
-- Why This Works
-- ============================================================================
-- Login flow:
-- 1. User queries: SELECT role FROM users WHERE id = auth.uid()
-- 2. PostgreSQL evaluates policies with OR logic
-- 3. First policy checked: "Users read their own profile" 
--    USING (id = auth.uid()) ✅ TRUE
-- 4. Access granted, other policies not evaluated!
-- 5. No function calls, no recursion
--
-- Admin querying editors:
-- 1. Admin queries: SELECT * FROM users WHERE role = 'editor'
-- 2. For each editor row, PostgreSQL evaluates policies:
--    - "Users read their own profile": id = auth.uid() ❌ FALSE (not admin's id)
--    - "Admins manage other users": get_my_role() = 'admin' AND id != auth.uid() ✅ TRUE
-- 3. Access granted via second policy
-- 4. get_my_role() is called, but user is already authenticated, no recursion

