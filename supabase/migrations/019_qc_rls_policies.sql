-- Memorio Quality Control System - RLS Policies
-- Version: 1.0.0
-- Description: Row Level Security policies for QC users and video submissions

-- ============================================================================
-- CASES TABLE - Add QC User Policies
-- ============================================================================

-- QC users can read cases in their organization
CREATE POLICY "QC users read cases in their org"
  ON cases FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc' AND
    org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
  );

-- QC users can update case status for workflow management
CREATE POLICY "QC users update case status"
  ON cases FOR UPDATE
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc' AND
    org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc' AND
    org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
  );

COMMENT ON POLICY "QC users read cases in their org" ON cases IS 
  'QC users are org-scoped, can see all cases in their funeral home';

COMMENT ON POLICY "QC users update case status" ON cases IS 
  'QC users can update case status when approving/rejecting videos';

-- ============================================================================
-- FORMS TABLE - Add QC User Policies
-- ============================================================================

-- QC users can read forms in their organization (to view obituary content)
CREATE POLICY "QC users read forms in their org"
  ON forms FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = forms.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

COMMENT ON POLICY "QC users read forms in their org" ON forms IS 
  'QC users need to view form data to verify video accuracy';

-- ============================================================================
-- ASSETS TABLE - Add QC User Policies
-- ============================================================================

-- QC users can read assets in their organization (to see original photos)
CREATE POLICY "QC users read assets in their org"
  ON assets FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = assets.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

COMMENT ON POLICY "QC users read assets in their org" ON assets IS 
  'QC users can view original photos to compare with video';

-- ============================================================================
-- VIDEO_SUBMISSIONS TABLE - RLS Policies
-- ============================================================================

-- Admins have full access to all video submissions
CREATE POLICY "Admins full access to video_submissions"
  ON video_submissions FOR ALL
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin');

-- Editors can create and view their own submissions
CREATE POLICY "Editors manage their submissions"
  ON video_submissions FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    editor_user_id = auth.uid()
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    editor_user_id = auth.uid()
  );

-- QC users can manage submissions in their organization
CREATE POLICY "QC users manage submissions in their org"
  ON video_submissions FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = video_submissions.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = video_submissions.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

-- Directors can view submissions in their organization
CREATE POLICY "Directors view submissions in their org"
  ON video_submissions FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = video_submissions.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

-- Family members can view only approved videos for their assigned case
CREATE POLICY "Family view approved video for their case"
  ON video_submissions FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    qc_status = 'approved' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = video_submissions.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  );

COMMENT ON POLICY "Admins full access to video_submissions" ON video_submissions IS 
  'Admins can manage all video submissions across all organizations';

COMMENT ON POLICY "Editors manage their submissions" ON video_submissions IS 
  'Editors can create and update their own video submissions';

COMMENT ON POLICY "QC users manage submissions in their org" ON video_submissions IS 
  'QC users can review, approve, or request revisions for videos in their org';

COMMENT ON POLICY "Family view approved video for their case" ON video_submissions IS 
  'Family members can only see approved videos for their assigned case';

-- ============================================================================
-- OBITUARY_CONTENT TABLE - RLS Policies
-- ============================================================================

-- Admins have full access
CREATE POLICY "Admins full access to obituary_content"
  ON obituary_content FOR ALL
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin');

-- Directors can manage obituary content for their organization's cases
CREATE POLICY "Directors manage obituary_content in their org"
  ON obituary_content FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = obituary_content.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = obituary_content.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

-- QC users can read obituary content to verify accuracy
CREATE POLICY "QC users read obituary_content in their org"
  ON obituary_content FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = obituary_content.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

-- Editors can read obituary content for cases they're assigned to
CREATE POLICY "Editors read obituary_content for assigned cases"
  ON obituary_content FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    EXISTS (
      SELECT 1 FROM editor_assignments
      WHERE editor_assignments.case_id = obituary_content.case_id
      AND editor_assignments.editor_user_id = auth.uid()
      AND editor_assignments.unassigned_at IS NULL
    )
  );

-- Family members can read obituary content for their assigned case
CREATE POLICY "Family read obituary_content for their case"
  ON obituary_content FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = obituary_content.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  );

COMMENT ON POLICY "QC users read obituary_content in their org" ON obituary_content IS 
  'QC users need to view obituary text to verify video accuracy';

COMMENT ON POLICY "Family read obituary_content for their case" ON obituary_content IS 
  'Family members can view the final obituary text for their loved one';

-- ============================================================================
-- USERS TABLE - Add QC User Policies
-- ============================================================================

-- QC users can read users in their organization
CREATE POLICY "QC users read users in their org"
  ON users FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc' AND
    org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
  );

COMMENT ON POLICY "QC users read users in their org" ON users IS 
  'QC users can see other users in their organization (for collaboration)';

-- ============================================================================
-- ORGANIZATIONS TABLE - Add QC User Policies
-- ============================================================================

-- QC users can read their own organization
CREATE POLICY "QC users read their organization"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc' AND
    id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
  );

COMMENT ON POLICY "QC users read their organization" ON organizations IS 
  'QC users can view their funeral home organization details';

-- ============================================================================
-- COMPLETION
-- ============================================================================

COMMENT ON SCHEMA public IS 'Memorio database schema - Migration 019: QC RLS policies added successfully';

