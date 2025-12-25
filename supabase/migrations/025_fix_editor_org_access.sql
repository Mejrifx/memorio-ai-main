-- ============================================================================
-- FIX EDITOR ACCESS TO ORGANIZATIONS
-- ============================================================================
-- Problem: Editor can see cases but organizations join returns null
-- Root Cause: RLS policy checks JWT app_metadata.role which doesn't exist
-- Solution: Check users.role from database instead

-- Drop old policy using JWT app_metadata
DROP POLICY IF EXISTS "Editors read orgs for assigned cases" ON organizations;

-- Create new policy checking database users.role
CREATE POLICY "Editors read orgs for assigned cases"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'editor'
      AND users.status = 'active'
    )
    AND
    id IN (
      SELECT cases.org_id
      FROM cases
      INNER JOIN editor_assignments ON editor_assignments.case_id = cases.id
      WHERE editor_assignments.editor_user_id = auth.uid()
      AND editor_assignments.unassigned_at IS NULL
    )
  );

-- ============================================================================
-- VERIFICATION QUERY
-- ============================================================================
-- Test as editor user:
-- SELECT id, name FROM organizations WHERE id = 'dc3bfd32-81af-439e-b9f3-5cb18639b6b6';
-- Should return the organization name if editor is assigned to a case in that org

