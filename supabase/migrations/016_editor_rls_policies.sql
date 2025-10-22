-- ============================================================================
-- EDITOR RLS POLICIES
-- ============================================================================
-- Description: Add RLS policies for editor role to access assigned cases

-- ============================================================================
-- CASES TABLE - EDITOR POLICIES
-- ============================================================================
-- Editors can read cases they are assigned to
CREATE POLICY "Editors read assigned cases"
  ON cases FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    id IN (
      SELECT case_id 
      FROM editor_assignments 
      WHERE editor_user_id = auth.uid() 
      AND unassigned_at IS NULL
    )
  );

-- Editors can update cases they are assigned to (for status changes)
CREATE POLICY "Editors update assigned cases"
  ON cases FOR UPDATE
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    id IN (
      SELECT case_id 
      FROM editor_assignments 
      WHERE editor_user_id = auth.uid() 
      AND unassigned_at IS NULL
    )
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    id IN (
      SELECT case_id 
      FROM editor_assignments 
      WHERE editor_user_id = auth.uid() 
      AND unassigned_at IS NULL
    )
  );

-- ============================================================================
-- FORMS TABLE - EDITOR POLICIES
-- ============================================================================
-- Editors can read forms for assigned cases
CREATE POLICY "Editors read forms for assigned cases"
  ON forms FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    case_id IN (
      SELECT case_id 
      FROM editor_assignments 
      WHERE editor_user_id = auth.uid() 
      AND unassigned_at IS NULL
    )
  );

-- Editors can update forms for assigned cases
CREATE POLICY "Editors update forms for assigned cases"
  ON forms FOR UPDATE
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    case_id IN (
      SELECT case_id 
      FROM editor_assignments 
      WHERE editor_user_id = auth.uid() 
      AND unassigned_at IS NULL
    )
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    case_id IN (
      SELECT case_id 
      FROM editor_assignments 
      WHERE editor_user_id = auth.uid() 
      AND unassigned_at IS NULL
    )
  );

-- ============================================================================
-- ASSETS TABLE - EDITOR POLICIES
-- ============================================================================
-- Editors can read assets for assigned cases
CREATE POLICY "Editors read assets for assigned cases"
  ON assets FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    case_id IN (
      SELECT case_id 
      FROM editor_assignments 
      WHERE editor_user_id = auth.uid() 
      AND unassigned_at IS NULL
    )
  );

-- ============================================================================
-- EDITOR_ASSIGNMENTS TABLE - RLS POLICIES
-- ============================================================================
-- Enable RLS
ALTER TABLE editor_assignments ENABLE ROW LEVEL SECURITY;

-- Admins have full access to editor assignments
CREATE POLICY "Admins full access to editor_assignments"
  ON editor_assignments FOR ALL
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin');

-- Directors can create and read assignments for their org's cases
CREATE POLICY "Directors manage assignments for their cases"
  ON editor_assignments FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    case_id IN (
      SELECT id 
      FROM cases 
      WHERE org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    case_id IN (
      SELECT id 
      FROM cases 
      WHERE org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

-- Editors can read their own assignments
CREATE POLICY "Editors read their assignments"
  ON editor_assignments FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    editor_user_id = auth.uid()
  );

-- ============================================================================
-- ORGANIZATIONS TABLE - EDITOR POLICIES
-- ============================================================================
-- Editors can read organizations for their assigned cases
CREATE POLICY "Editors read orgs for assigned cases"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    id IN (
      SELECT org_id 
      FROM cases 
      WHERE id IN (
        SELECT case_id 
        FROM editor_assignments 
        WHERE editor_user_id = auth.uid() 
        AND unassigned_at IS NULL
      )
    )
  );

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON POLICY "Editors read assigned cases" ON cases IS 
  'Editors can view cases that are assigned to them via editor_assignments table';

COMMENT ON POLICY "Editors update assigned cases" ON cases IS 
  'Editors can update status and other fields for their assigned cases';

COMMENT ON POLICY "Editors read forms for assigned cases" ON forms IS 
  'Editors can read form submissions for cases assigned to them';

COMMENT ON POLICY "Editors update forms for assigned cases" ON forms IS 
  'Editors can update obituary content and other form fields for assigned cases';

COMMENT ON POLICY "Editors read assets for assigned cases" ON assets IS 
  'Editors can view photos and assets for cases assigned to them';

COMMENT ON POLICY "Admins full access to editor_assignments" ON editor_assignments IS 
  'Admins can manage all editor assignments';

COMMENT ON POLICY "Directors manage assignments for their cases" ON editor_assignments IS 
  'Directors can assign editors to cases in their organization';

COMMENT ON POLICY "Editors read their assignments" ON editor_assignments IS 
  'Editors can view their own case assignments';

