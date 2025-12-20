-- Migration: Fix Family User RLS Access Issues
-- Version: 1.0.0
-- Description: Ensure family users can properly access their data through RLS policies

-- This migration addresses 406 errors when family users try to access their data
-- Root cause: Missing or improperly configured RLS policies for family role

-- ============================================================================
-- STEP 1: Verify and Fix Users Table Policies for Family
-- ============================================================================

-- Drop and recreate to ensure they're correct
DROP POLICY IF EXISTS "Users read their own profile" ON users;

CREATE POLICY "Users read their own profile"
  ON users FOR SELECT
  TO authenticated
  USING (id = auth.uid());

COMMENT ON POLICY "Users read their own profile" ON users IS 
  'All authenticated users (including family) can read their own profile data';

-- ============================================================================
-- STEP 2: Verify Cases Table Policies for Family
-- ============================================================================

-- These should already exist from migration 008, but let's ensure they're correct
DROP POLICY IF EXISTS "Families read their assigned cases" ON cases;
DROP POLICY IF EXISTS "Families update their assigned cases" ON cases;

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

COMMENT ON POLICY "Families read their assigned cases" ON cases IS 
  'Family members can read cases where they are assigned as assigned_family_user_id';

COMMENT ON POLICY "Families update their assigned cases" ON cases IS 
  'Family members can update their assigned cases (limited fields via app logic)';

-- ============================================================================
-- STEP 3: Verify Forms Table Policies for Family
-- ============================================================================

DROP POLICY IF EXISTS "Families manage their case forms" ON forms;

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

COMMENT ON POLICY "Families manage their case forms" ON forms IS 
  'Family members can create, read, and update forms for their assigned case';

-- ============================================================================
-- STEP 4: Verify Assets Table Policies for Family
-- ============================================================================

DROP POLICY IF EXISTS "Families manage assets for their case" ON assets;

CREATE POLICY "Families manage assets for their case"
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

COMMENT ON POLICY "Families manage assets for their case" ON assets IS 
  'Family members can upload and view photos for their assigned case';

-- ============================================================================
-- STEP 5: Verify Organizations Table Policies for Family
-- ============================================================================

DROP POLICY IF EXISTS "Families read their organization" ON organizations;

CREATE POLICY "Families read their organization"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
  );

COMMENT ON POLICY "Families read their organization" ON organizations IS 
  'Family members can view their funeral home organization details';

-- ============================================================================
-- STEP 6: Add Video Submissions Read Policy for Family (if not exists)
-- ============================================================================

DROP POLICY IF EXISTS "Family read video_submissions for their case" ON video_submissions;

CREATE POLICY "Family read video_submissions for their case"
  ON video_submissions FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = video_submissions.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  );

COMMENT ON POLICY "Family read video_submissions for their case" ON video_submissions IS 
  'Family members can view approved video submissions for their case';

-- ============================================================================
-- VERIFICATION QUERIES (Run these to test)
-- ============================================================================

-- Verify all family policies exist
-- SELECT schemaname, tablename, policyname 
-- FROM pg_policies 
-- WHERE policyname LIKE '%Famil%'
-- ORDER BY tablename, policyname;

-- Test family access (replace <family_user_id> and <case_id> with actual values)
-- SET request.jwt.claims = '{"role": "family", "sub": "<family_user_id>", "app_metadata": {"role": "family"}}';
-- SELECT * FROM cases WHERE assigned_family_user_id = '<family_user_id>';
-- SELECT * FROM users WHERE id = '<family_user_id>';

