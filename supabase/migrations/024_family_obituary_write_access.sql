-- ============================================================================
-- MIGRATION: 024_family_obituary_write_access
-- Description: Allow family members to insert/update obituary content for their case
-- ============================================================================

-- Drop existing family policy (read-only)
DROP POLICY IF EXISTS "Family read obituary_content for their case" ON obituary_content;

-- Create new policy with INSERT and UPDATE permissions
CREATE POLICY "Family manage obituary_content for their case"
  ON obituary_content FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = obituary_content.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = obituary_content.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  );

COMMENT ON POLICY "Family manage obituary_content for their case" ON obituary_content IS 
  'Family members can insert/update/read obituary content for their assigned case';

