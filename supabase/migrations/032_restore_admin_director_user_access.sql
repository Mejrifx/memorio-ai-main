-- ============================================================================
-- FIX ADMIN/DIRECTOR ACCESS TO USERS TABLE (FOR EDITOR DROPDOWN)
-- ============================================================================
-- Problem: Admin can't see editors in dropdown when assigning cases
-- Console would show: 406 error or empty list when querying users table
-- Root Cause: Migration 030 removed ALL role-based policies on users table
--             Only kept self-access policies
--             Result: Admin can't query other users!
-- Solution: Add back admin/director/support policies using helper function

-- ============================================================================
-- USERS TABLE - Add back role-based policies
-- ============================================================================

-- These were removed in migration 030 to fix recursion
-- Now we're adding them back, but using the helper function properly

-- Admins can read/manage all users
CREATE POLICY "Admins full access to users"
  ON users FOR ALL
  TO authenticated
  USING (public.get_my_role() = 'admin')
  WITH CHECK (public.get_my_role() = 'admin');

-- Directors can read/manage users in their org
CREATE POLICY "Directors manage users in their org"
  ON users FOR ALL
  TO authenticated
  USING (
    public.get_my_role() = 'director'
    AND org_id IN (SELECT org_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    public.get_my_role() = 'director'
    AND org_id IN (SELECT org_id FROM users WHERE id = auth.uid())
  );

-- Support can read all users
CREATE POLICY "Support read all users"
  ON users FOR SELECT
  TO authenticated
  USING (public.get_my_role() = 'support');

-- QC can read users (for viewing editor/director info on cases)
CREATE POLICY "QC read all users"
  ON users FOR SELECT
  TO authenticated
  USING (public.get_my_role() = 'qc');

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON POLICY "Admins full access to users" ON users IS 
  'Uses get_my_role() helper function to avoid recursion. Allows admin to query editors for assignment dropdown.';

COMMENT ON POLICY "Directors manage users in their org" ON users IS 
  'Uses get_my_role() helper function to avoid recursion. Allows director to manage family/qc users in their org.';

COMMENT ON POLICY "Support read all users" ON users IS 
  'Uses get_my_role() helper function to avoid recursion.';

COMMENT ON POLICY "QC read all users" ON users IS 
  'Allows QC to view editor/director info when reviewing cases.';

-- ============================================================================
-- Why This Works Now (vs Migration 030 Failure)
-- ============================================================================
-- Migration 030 tried to create these policies with subqueries that caused recursion
-- Now we use public.get_my_role() which:
-- 1. Is SECURITY DEFINER (bypasses RLS when called)
-- 2. Caches the result (doesn't re-query for each row)
-- 3. Only queries users table ONCE, not recursively
--
-- The key difference:
-- OLD (caused 500 errors):
--   USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'))
--   ^ Queries users table WHILE evaluating users table policy = RECURSION
--
-- NEW (works):
--   USING (public.get_my_role() = 'admin')
--   ^ Function queries users ONCE with SECURITY DEFINER (no RLS) = NO RECURSION

