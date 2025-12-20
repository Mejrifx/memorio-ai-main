-- Migration: Make QC Users Global (Not Org-Scoped)
-- Version: 1.0.0
-- Description: QC users should process videos for ALL funeral homes, not be tied to one org

-- ============================================================================
-- STEP 1: Update Existing QC Users to Have NULL org_id
-- ============================================================================

UPDATE users
SET org_id = NULL
WHERE role = 'qc';

COMMENT ON COLUMN users.org_id IS 
  'Organization ID - NULL for global roles (admin, qc), required for org-scoped roles (director, family, editor)';

-- ============================================================================
-- STEP 2: Drop Existing QC RLS Policies (Org-Scoped)
-- ============================================================================

-- Cases table
DROP POLICY IF EXISTS "QC users read cases in their org" ON cases;
DROP POLICY IF EXISTS "QC users update case status" ON cases;

-- Forms table
DROP POLICY IF EXISTS "QC users read forms in their org" ON forms;

-- Assets table
DROP POLICY IF EXISTS "QC users read assets in their org" ON assets;

-- Organizations table
DROP POLICY IF EXISTS "QC users read their organization" ON organizations;

-- Users table
DROP POLICY IF EXISTS "QC users read users in their org" ON users;

-- ============================================================================
-- STEP 3: Create New GLOBAL QC RLS Policies
-- ============================================================================

-- ====================
-- CASES TABLE
-- ====================

-- QC can read ALL cases (global access)
CREATE POLICY "QC users read all cases"
  ON cases FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc'
  );

-- QC can update case status for workflow (global access)
CREATE POLICY "QC users update case status"
  ON cases FOR UPDATE
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc'
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc'
  );

COMMENT ON POLICY "QC users read all cases" ON cases IS 
  'QC users are global, can see ALL cases across all funeral homes';

COMMENT ON POLICY "QC users update case status" ON cases IS 
  'QC users can update case status for ALL cases when approving/rejecting videos';

-- ====================
-- FORMS TABLE
-- ====================

-- QC can read ALL forms (to view obituary content)
CREATE POLICY "QC users read all forms"
  ON forms FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc'
  );

COMMENT ON POLICY "QC users read all forms" ON forms IS 
  'QC users can read all forms to review obituary content for quality control';

-- ====================
-- ASSETS TABLE
-- ====================

-- QC can read ALL assets (to view photos/videos)
CREATE POLICY "QC users read all assets"
  ON assets FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc'
  );

COMMENT ON POLICY "QC users read all assets" ON assets IS 
  'QC users can view all assets across all cases for quality review';

-- ====================
-- ORGANIZATIONS TABLE
-- ====================

-- QC can read ALL organizations (to see which funeral home a case belongs to)
CREATE POLICY "QC users read all organizations"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc'
  );

COMMENT ON POLICY "QC users read all organizations" ON organizations IS 
  'QC users can view all organizations to see funeral home context for cases';

-- ====================
-- USERS TABLE
-- ====================

-- QC can read ALL users (to see directors, editors, families)
CREATE POLICY "QC users read all users"
  ON users FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc'
  );

COMMENT ON POLICY "QC users read all users" ON users IS 
  'QC users can view all users to understand case context and communication';

-- ====================
-- VIDEO_SUBMISSIONS TABLE (No Change Needed)
-- ====================
-- Existing policies already allow QC full access to video_submissions
-- No changes required

-- ====================
-- OBITUARY_CONTENT TABLE (No Change Needed)
-- ====================
-- Existing policies already allow QC full access to obituary_content
-- No changes required

-- ============================================================================
-- STEP 4: Update Case Notes RLS for QC (Global Access)
-- ============================================================================

-- QC can read ALL case notes (global access)
DROP POLICY IF EXISTS "QC users read case notes in their org" ON case_notes;

CREATE POLICY "QC users read all case notes"
  ON case_notes FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc'
  );

-- QC can create case notes on any case
DROP POLICY IF EXISTS "QC users create case notes in their org" ON case_notes;

CREATE POLICY "QC users create all case notes"
  ON case_notes FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc' AND
    user_id = auth.uid()
  );

COMMENT ON POLICY "QC users read all case notes" ON case_notes IS 
  'QC users can read notes on all cases globally';

COMMENT ON POLICY "QC users create all case notes" ON case_notes IS 
  'QC users can create notes on any case for quality feedback';

-- ============================================================================
-- STEP 5: Update Events/Audit Log RLS for QC (Global Access)
-- ============================================================================

DROP POLICY IF EXISTS "QC users read events in their org" ON events;

CREATE POLICY "QC users read all events"
  ON events FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc'
  );

COMMENT ON POLICY "QC users read all events" ON events IS 
  'QC users can view audit events across all organizations for quality tracking';

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verify QC users now have NULL org_id
-- SELECT id, email, role, org_id FROM users WHERE role = 'qc';

-- Verify QC policies exist
-- SELECT schemaname, tablename, policyname 
-- FROM pg_policies 
-- WHERE policyname LIKE '%QC%' OR policyname LIKE '%qc%'
-- ORDER BY tablename, policyname;

-- Test QC access (run as QC user):
-- SET request.jwt.claims = '{"role": "qc", "sub": "<qc_user_id>"}';
-- SELECT COUNT(*) FROM cases; -- Should see all cases
-- SELECT COUNT(*) FROM organizations; -- Should see all organizations

