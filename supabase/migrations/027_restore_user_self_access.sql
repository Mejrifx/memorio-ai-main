-- ============================================================================
-- URGENT FIX: Restore User Self-Access Policies
-- ============================================================================
-- Problem: Users can't log in - "Failed to fetch user data" 500 error
-- Root Cause: Migration 026 dropped "Users read their own profile" policy
--             but didn't recreate it. ALL users need to read their own data!
-- Solution: Add back the self-access policies for all authenticated users

-- ============================================================================
-- USERS TABLE - Self Access Policies
-- ============================================================================

-- All authenticated users can read their own profile
-- This is CRITICAL for login to work!
CREATE POLICY "Users read their own profile"
  ON users FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- All authenticated users can update their own profile
CREATE POLICY "Users update their own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

COMMENT ON POLICY "Users read their own profile" ON users IS 
  'Critical policy: All authenticated users must be able to read their own profile data for login to work';

COMMENT ON POLICY "Users update their own profile" ON users IS 
  'Critical policy: All authenticated users must be able to update their own profile data (e.g., password changes)';

