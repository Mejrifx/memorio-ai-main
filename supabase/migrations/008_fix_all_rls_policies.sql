-- Fix ALL RLS Policies to use correct JWT paths
-- Version: 1.0.0
-- Description: Update all RLS policies to check app_metadata.role and app_metadata.org_id

-- The JWT structure is:
-- {
--   "app_metadata": {
--     "role": "admin|director|family|editor|support",
--     "org_id": "uuid"
--   }
-- }

-- ============================================================================
-- ORGANIZATIONS TABLE - RLS POLICIES
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Admins full access to organizations" ON organizations;
DROP POLICY IF EXISTS "Directors read their organization" ON organizations;
DROP POLICY IF EXISTS "Support read all organizations" ON organizations;

-- Recreate with correct JWT paths
CREATE POLICY "Admins full access to organizations"
  ON organizations FOR ALL
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin');

CREATE POLICY "Directors read their organization"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
  );

CREATE POLICY "Support read all organizations"
  ON organizations FOR SELECT
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'support');

-- ============================================================================
-- USERS TABLE - RLS POLICIES
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Admins full access to users" ON users;
DROP POLICY IF EXISTS "Directors manage users in their org" ON users;
DROP POLICY IF EXISTS "Users read their own profile" ON users;
DROP POLICY IF EXISTS "Users update their own profile" ON users;
DROP POLICY IF EXISTS "Support read all users" ON users;

-- Recreate with correct JWT paths
CREATE POLICY "Admins full access to users"
  ON users FOR ALL
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin');

CREATE POLICY "Directors manage users in their org"
  ON users FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
  );

CREATE POLICY "Users read their own profile"
  ON users FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Users update their own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "Support read all users"
  ON users FOR SELECT
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'support');

-- ============================================================================
-- CASES TABLE - RLS POLICIES
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Admins full access to cases" ON cases;
DROP POLICY IF EXISTS "Directors manage cases in their org" ON cases;
DROP POLICY IF EXISTS "Families read their assigned cases" ON cases;
DROP POLICY IF EXISTS "Families update their assigned cases" ON cases;
DROP POLICY IF EXISTS "Editors read assigned cases" ON cases;
DROP POLICY IF EXISTS "Editors update assigned cases" ON cases;
DROP POLICY IF EXISTS "Support read all cases" ON cases;

-- Recreate with correct JWT paths
CREATE POLICY "Admins full access to cases"
  ON cases FOR ALL
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin');

CREATE POLICY "Directors manage cases in their org"
  ON cases FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
  );

CREATE POLICY "Families read their assigned cases"
  ON cases FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    assigned_family_user_id = auth.uid()
  );

CREATE POLICY "Families update their assigned cases"
  ON cases FOR UPDATE
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    assigned_family_user_id = auth.uid()
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    assigned_family_user_id = auth.uid()
  );

CREATE POLICY "Editors read assigned cases"
  ON cases FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    EXISTS (
      SELECT 1 FROM editor_assignments
      WHERE case_id = cases.id
      AND editor_user_id = auth.uid()
      AND unassigned_at IS NULL
    )
  );

CREATE POLICY "Editors update assigned cases"
  ON cases FOR UPDATE
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    EXISTS (
      SELECT 1 FROM editor_assignments
      WHERE case_id = cases.id
      AND editor_user_id = auth.uid()
      AND unassigned_at IS NULL
    )
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    EXISTS (
      SELECT 1 FROM editor_assignments
      WHERE case_id = cases.id
      AND editor_user_id = auth.uid()
      AND unassigned_at IS NULL
    )
  );

CREATE POLICY "Support read all cases"
  ON cases FOR SELECT
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'support');

-- ============================================================================
-- FORMS TABLE - RLS POLICIES
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Admins full access to forms" ON forms;
DROP POLICY IF EXISTS "Directors access forms in their org" ON forms;
DROP POLICY IF EXISTS "Families manage their case forms" ON forms;
DROP POLICY IF EXISTS "Editors update assigned case forms" ON forms;

-- Recreate with correct JWT paths
CREATE POLICY "Admins full access to forms"
  ON forms FOR ALL
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin');

CREATE POLICY "Directors access forms in their org"
  ON forms FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = forms.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = forms.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

CREATE POLICY "Families manage their case forms"
  ON forms FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = forms.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = forms.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  );

CREATE POLICY "Editors update assigned case forms"
  ON forms FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    EXISTS (
      SELECT 1 FROM cases
      JOIN editor_assignments ON editor_assignments.case_id = cases.id
      WHERE cases.id = forms.case_id
      AND editor_assignments.editor_user_id = auth.uid()
      AND editor_assignments.unassigned_at IS NULL
    )
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    EXISTS (
      SELECT 1 FROM cases
      JOIN editor_assignments ON editor_assignments.case_id = cases.id
      WHERE cases.id = forms.case_id
      AND editor_assignments.editor_user_id = auth.uid()
      AND editor_assignments.unassigned_at IS NULL
    )
  );

-- ============================================================================
-- ASSETS TABLE - RLS POLICIES
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Admins full access to assets" ON assets;
DROP POLICY IF EXISTS "Directors access assets in their org" ON assets;
DROP POLICY IF EXISTS "Families manage their case assets" ON assets;
DROP POLICY IF EXISTS "Editors access assigned case assets" ON assets;

-- Recreate with correct JWT paths
CREATE POLICY "Admins full access to assets"
  ON assets FOR ALL
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin');

CREATE POLICY "Directors access assets in their org"
  ON assets FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = assets.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = assets.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

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

CREATE POLICY "Editors access assigned case assets"
  ON assets FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    EXISTS (
      SELECT 1 FROM editor_assignments
      WHERE editor_assignments.case_id = assets.case_id
      AND editor_assignments.editor_user_id = auth.uid()
      AND editor_assignments.unassigned_at IS NULL
    )
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    EXISTS (
      SELECT 1 FROM editor_assignments
      WHERE editor_assignments.case_id = assets.case_id
      AND editor_assignments.editor_user_id = auth.uid()
      AND editor_assignments.unassigned_at IS NULL
    )
  );

-- ============================================================================
-- EDITOR_ASSIGNMENTS TABLE - RLS POLICIES
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Admins full access to editor assignments" ON editor_assignments;
DROP POLICY IF EXISTS "Directors manage assignments in their org" ON editor_assignments;
DROP POLICY IF EXISTS "Editors read their own assignments" ON editor_assignments;

-- Recreate with correct JWT paths
CREATE POLICY "Admins full access to editor assignments"
  ON editor_assignments FOR ALL
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin');

CREATE POLICY "Directors manage assignments in their org"
  ON editor_assignments FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = editor_assignments.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = editor_assignments.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

CREATE POLICY "Editors read their own assignments"
  ON editor_assignments FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    editor_user_id = auth.uid()
  );

-- ============================================================================
-- EVENTS TABLE - RLS POLICIES  
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Admins read all events" ON events;
DROP POLICY IF EXISTS "Directors read events in their org" ON events;
DROP POLICY IF EXISTS "Support read all events" ON events;

-- Recreate with correct JWT paths
CREATE POLICY "Admins read all events"
  ON events FOR SELECT
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin');

CREATE POLICY "Directors read events in their org"
  ON events FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    (
      actor_user_id IN (
        SELECT id FROM users WHERE org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
      )
      OR
      target_type IN ('cases', 'forms', 'assets') AND
      target_id IN (
        SELECT id FROM cases WHERE org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
      )
    )
  );

CREATE POLICY "Support read all events"
  ON events FOR SELECT
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'support');

-- ============================================================================
-- NOTIFICATIONS TABLE - RLS POLICIES
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Admins full access to notifications" ON notifications;
DROP POLICY IF EXISTS "Directors access notifications in their org" ON notifications;

-- Recreate with correct JWT paths
CREATE POLICY "Admins full access to notifications"
  ON notifications FOR ALL
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin');

CREATE POLICY "Directors access notifications in their org"
  ON notifications FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = notifications.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = notifications.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

-- ============================================================================
-- EXPORTS TABLE - RLS POLICIES
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Admins full access to exports" ON exports;
DROP POLICY IF EXISTS "Directors access exports in their org" ON exports;
DROP POLICY IF EXISTS "Users read their own exports" ON exports;

-- Recreate with correct JWT paths
CREATE POLICY "Admins full access to exports"
  ON exports FOR ALL
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin');

CREATE POLICY "Directors access exports in their org"
  ON exports FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
  );

CREATE POLICY "Users read their own exports"
  ON exports FOR SELECT
  TO authenticated
  USING (created_by = auth.uid());

COMMENT ON POLICY "Admins full access to organizations" ON organizations IS 
  'Updated to use app_metadata.role instead of root role claim';

