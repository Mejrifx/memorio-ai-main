-- Fix Assets RLS Policies - Add WITH CHECK Clause
-- This fixes the "new row violates row-level security policy" error when families upload photos

-- Drop existing family assets policy
DROP POLICY IF EXISTS "Families manage their case assets" ON assets;

-- Recreate with proper WITH CHECK clause
CREATE POLICY "Families manage their case assets"
  ON assets FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = assets.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = assets.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  );

-- Verify the policy
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual IS NOT NULL as has_using,
  with_check IS NOT NULL as has_with_check
FROM pg_policies
WHERE tablename = 'assets'
  AND policyname = 'Families manage their case assets';

