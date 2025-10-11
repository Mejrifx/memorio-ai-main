-- Fix Organizations INSERT Policy
-- Version: 1.0.0
-- Description: Allow admins to create new organizations

-- The current "Admins full access to organizations" policy uses FOR ALL
-- but RLS treats INSERT differently - we need to ensure the WITH CHECK clause works

-- Drop the existing policy
DROP POLICY IF EXISTS "Admins full access to organizations" ON organizations;

-- Recreate with explicit WITH CHECK for INSERT operations
CREATE POLICY "Admins full access to organizations"
  ON organizations FOR ALL
  TO authenticated
  USING (auth.jwt() ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

COMMENT ON POLICY "Admins full access to organizations" ON organizations IS 
  'Allows admin users full CRUD access to all organizations';

