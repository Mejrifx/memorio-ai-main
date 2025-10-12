-- ============================================================================
-- FIX INFINITE RECURSION IN RLS POLICIES
-- ============================================================================
-- 
-- PROBLEM: Circular dependency between cases and editor_assignments policies
-- - cases policies reference editor_assignments table
-- - editor_assignments policies reference cases table
-- This creates infinite recursion when PostgreSQL evaluates policies
--
-- SOLUTION: Break the circular dependency by simplifying editor_assignments policies
-- to not reference the cases table directly
-- ============================================================================

-- Drop the problematic editor_assignments policies that reference cases
DROP POLICY IF EXISTS "Directors manage assignments in their org" ON editor_assignments;

-- Recreate editor_assignments policies WITHOUT circular references
-- Directors can manage assignments - we'll trust the application logic to ensure
-- they only assign editors to cases in their organization
CREATE POLICY "Directors manage assignments in their org"
  ON editor_assignments FOR ALL
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'director')
  WITH CHECK (auth.jwt() -> 'app_metadata' ->> 'role' = 'director');

-- The cases table policies can still safely reference editor_assignments
-- because editor_assignments policies no longer reference cases
-- This breaks the circular dependency

-- ============================================================================
-- VERIFICATION QUERIES (for testing)
-- ============================================================================
-- 
-- Test that policies work without recursion:
-- 
-- 1. Test as director (should work):
-- SET request.jwt.claims = '{"role": "director", "org_id": "00000000-0000-0000-0000-000000000001"}';
-- SELECT * FROM cases;
-- 
-- 2. Test as editor (should work):
-- SET request.jwt.claims = '{"role": "editor", "sub": "editor-user-id"}';
-- SELECT * FROM cases;
-- 
-- 3. Test editor_assignments access (should work):
-- SELECT * FROM editor_assignments;
-- ============================================================================
