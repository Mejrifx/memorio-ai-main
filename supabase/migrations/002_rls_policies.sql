-- Memorio Row Level Security Policies
-- Version: 1.0.0
-- Description: Multi-tenant security enforcement at database level

-- ============================================================================
-- ORGANIZATIONS TABLE - RLS POLICIES
-- ============================================================================
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- Admins have full access to all organizations
CREATE POLICY "Admins full access to organizations"
  ON organizations FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');

-- Directors can read their own organization
CREATE POLICY "Directors read their organization"
  ON organizations FOR SELECT
  USING (
    auth.jwt() ->> 'role' = 'director' AND
    id = (auth.jwt() ->> 'org_id')::uuid
  );

-- Support users can read all organizations (read-only)
CREATE POLICY "Support read all organizations"
  ON organizations FOR SELECT
  USING (auth.jwt() ->> 'role' = 'support');

-- ============================================================================
-- USERS TABLE - RLS POLICIES
-- ============================================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Admins have full access to all users
CREATE POLICY "Admins full access to users"
  ON users FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');

-- Directors can manage users in their organization
CREATE POLICY "Directors manage users in their org"
  ON users FOR ALL
  USING (
    auth.jwt() ->> 'role' = 'director' AND
    org_id = (auth.jwt() ->> 'org_id')::uuid
  );

-- Users can read their own profile
CREATE POLICY "Users read their own profile"
  ON users FOR SELECT
  USING (id = auth.uid());

-- Users can update their own profile (limited fields via app logic)
CREATE POLICY "Users update their own profile"
  ON users FOR UPDATE
  USING (id = auth.uid());

-- Support can read all users
CREATE POLICY "Support read all users"
  ON users FOR SELECT
  USING (auth.jwt() ->> 'role' = 'support');

-- ============================================================================
-- CASES TABLE - RLS POLICIES
-- ============================================================================
ALTER TABLE cases ENABLE ROW LEVEL SECURITY;

-- Admins have full access to all cases
CREATE POLICY "Admins full access to cases"
  ON cases FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');

-- Directors manage cases in their organization
CREATE POLICY "Directors manage cases in their org"
  ON cases FOR ALL
  USING (
    auth.jwt() ->> 'role' = 'director' AND
    org_id = (auth.jwt() ->> 'org_id')::uuid
  );

-- Families can read their assigned cases
CREATE POLICY "Families read their assigned cases"
  ON cases FOR SELECT
  USING (
    auth.jwt() ->> 'role' = 'family' AND
    assigned_family_user_id = auth.uid()
  );

-- Families can update their assigned cases (limited fields via app logic)
CREATE POLICY "Families update their assigned cases"
  ON cases FOR UPDATE
  USING (
    auth.jwt() ->> 'role' = 'family' AND
    assigned_family_user_id = auth.uid()
  );

-- Editors can read cases assigned to them
CREATE POLICY "Editors read assigned cases"
  ON cases FOR SELECT
  USING (
    auth.jwt() ->> 'role' = 'editor' AND
    EXISTS (
      SELECT 1 FROM editor_assignments
      WHERE case_id = cases.id
      AND editor_user_id = auth.uid()
      AND unassigned_at IS NULL
    )
  );

-- Editors can update cases assigned to them
CREATE POLICY "Editors update assigned cases"
  ON cases FOR UPDATE
  USING (
    auth.jwt() ->> 'role' = 'editor' AND
    EXISTS (
      SELECT 1 FROM editor_assignments
      WHERE case_id = cases.id
      AND editor_user_id = auth.uid()
      AND unassigned_at IS NULL
    )
  );

-- Support can read all cases
CREATE POLICY "Support read all cases"
  ON cases FOR SELECT
  USING (auth.jwt() ->> 'role' = 'support');

-- ============================================================================
-- FORMS TABLE - RLS POLICIES
-- ============================================================================
ALTER TABLE forms ENABLE ROW LEVEL SECURITY;

-- Admins have full access to all forms
CREATE POLICY "Admins full access to forms"
  ON forms FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');

-- Directors can access forms in their organization
CREATE POLICY "Directors access forms in their org"
  ON forms FOR ALL
  USING (
    auth.jwt() ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = forms.case_id
      AND cases.org_id = (auth.jwt() ->> 'org_id')::uuid
    )
  );

-- Families can manage forms for their assigned cases
CREATE POLICY "Families manage their case forms"
  ON forms FOR ALL
  USING (
    auth.jwt() ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = forms.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  );

-- Editors can read forms for assigned cases
CREATE POLICY "Editors read assigned case forms"
  ON forms FOR SELECT
  USING (
    auth.jwt() ->> 'role' = 'editor' AND
    EXISTS (
      SELECT 1 FROM cases
      JOIN editor_assignments ON editor_assignments.case_id = cases.id
      WHERE cases.id = forms.case_id
      AND editor_assignments.editor_user_id = auth.uid()
      AND editor_assignments.unassigned_at IS NULL
    )
  );

-- Support can read all forms
CREATE POLICY "Support read all forms"
  ON forms FOR SELECT
  USING (auth.jwt() ->> 'role' = 'support');

-- ============================================================================
-- ASSETS TABLE - RLS POLICIES
-- ============================================================================
ALTER TABLE assets ENABLE ROW LEVEL SECURITY;

-- Admins have full access to all assets
CREATE POLICY "Admins full access to assets"
  ON assets FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');

-- Directors can manage assets in their organization
CREATE POLICY "Directors manage assets in their org"
  ON assets FOR ALL
  USING (
    auth.jwt() ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = assets.case_id
      AND cases.org_id = (auth.jwt() ->> 'org_id')::uuid
    )
  );

-- Families can manage assets for their assigned cases
CREATE POLICY "Families manage their case assets"
  ON assets FOR ALL
  USING (
    auth.jwt() ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = assets.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  );

-- Editors can read assets for assigned cases
CREATE POLICY "Editors read assigned case assets"
  ON assets FOR SELECT
  USING (
    auth.jwt() ->> 'role' = 'editor' AND
    EXISTS (
      SELECT 1 FROM cases
      JOIN editor_assignments ON editor_assignments.case_id = cases.id
      WHERE cases.id = assets.case_id
      AND editor_assignments.editor_user_id = auth.uid()
      AND editor_assignments.unassigned_at IS NULL
    )
  );

-- Support can read all assets
CREATE POLICY "Support read all assets"
  ON assets FOR SELECT
  USING (auth.jwt() ->> 'role' = 'support');

-- ============================================================================
-- EDITOR_ASSIGNMENTS TABLE - RLS POLICIES
-- ============================================================================
ALTER TABLE editor_assignments ENABLE ROW LEVEL SECURITY;

-- Admins have full access to all assignments
CREATE POLICY "Admins full access to editor assignments"
  ON editor_assignments FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');

-- Directors can manage assignments in their organization
CREATE POLICY "Directors manage assignments in their org"
  ON editor_assignments FOR ALL
  USING (
    auth.jwt() ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = editor_assignments.case_id
      AND cases.org_id = (auth.jwt() ->> 'org_id')::uuid
    )
  );

-- Editors can read their own assignments
CREATE POLICY "Editors read their own assignments"
  ON editor_assignments FOR SELECT
  USING (
    auth.jwt() ->> 'role' = 'editor' AND
    editor_user_id = auth.uid()
  );

-- Support can read all assignments
CREATE POLICY "Support read all assignments"
  ON editor_assignments FOR SELECT
  USING (auth.jwt() ->> 'role' = 'support');

-- ============================================================================
-- EVENTS TABLE - RLS POLICIES
-- ============================================================================
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Admins have full access to all events
CREATE POLICY "Admins full access to events"
  ON events FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');

-- Directors can read events related to their organization
CREATE POLICY "Directors read events in their org"
  ON events FOR SELECT
  USING (
    auth.jwt() ->> 'role' = 'director' AND
    (
      -- Events on cases in their org
      (target_type = 'cases' AND EXISTS (
        SELECT 1 FROM cases
        WHERE cases.id = events.target_id
        AND cases.org_id = (auth.jwt() ->> 'org_id')::uuid
      ))
      OR
      -- Events on users in their org
      (target_type = 'users' AND EXISTS (
        SELECT 1 FROM users
        WHERE users.id = events.target_id
        AND users.org_id = (auth.jwt() ->> 'org_id')::uuid
      ))
    )
  );

-- Support can read all events
CREATE POLICY "Support read all events"
  ON events FOR SELECT
  USING (auth.jwt() ->> 'role' = 'support');

-- ============================================================================
-- NOTIFICATIONS TABLE - RLS POLICIES
-- ============================================================================
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Admins have full access to all notifications
CREATE POLICY "Admins full access to notifications"
  ON notifications FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');

-- Directors can manage notifications in their organization
CREATE POLICY "Directors manage notifications in their org"
  ON notifications FOR ALL
  USING (
    auth.jwt() ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = notifications.case_id
      AND cases.org_id = (auth.jwt() ->> 'org_id')::uuid
    )
  );

-- Support can read all notifications
CREATE POLICY "Support read all notifications"
  ON notifications FOR SELECT
  USING (auth.jwt() ->> 'role' = 'support');

-- ============================================================================
-- EXPORTS TABLE - RLS POLICIES
-- ============================================================================
ALTER TABLE exports ENABLE ROW LEVEL SECURITY;

-- Admins have full access to all exports
CREATE POLICY "Admins full access to exports"
  ON exports FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');

-- Directors can manage exports in their organization
CREATE POLICY "Directors manage exports in their org"
  ON exports FOR ALL
  USING (
    auth.jwt() ->> 'role' = 'director' AND
    org_id = (auth.jwt() ->> 'org_id')::uuid
  );

-- Users can read their own exports
CREATE POLICY "Users read their own exports"
  ON exports FOR SELECT
  USING (created_by = auth.uid());

-- Support can read all exports
CREATE POLICY "Support read all exports"
  ON exports FOR SELECT
  USING (auth.jwt() ->> 'role' = 'support');

-- ============================================================================
-- COMPLETION
-- ============================================================================
COMMENT ON SCHEMA public IS 'Memorio RLS policies v1.0.0 - Multi-tenant security enabled';
