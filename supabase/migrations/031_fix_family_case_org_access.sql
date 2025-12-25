-- ============================================================================
-- FIX FAMILY AND OTHER ROLE ACCESS TO CASES AND ORGANIZATIONS
-- ============================================================================
-- Problem: Family users get 406 errors when trying to access cases
-- Console shows: "Failed to load resource: the server responded with a status of 406"
-- Root Cause: Migration 026 created policies that query users table in subqueries
--             This causes issues even though we have the helper function
-- Solution: Update ALL policies to use get_my_role() helper function

-- ============================================================================
-- CASES TABLE - Update all policies to use helper function
-- ============================================================================

-- Drop existing policies that have recursive subqueries
DROP POLICY IF EXISTS "Admins full access to cases" ON cases;
DROP POLICY IF EXISTS "Directors manage cases in their org" ON cases;
DROP POLICY IF EXISTS "Families read their assigned cases" ON cases;
DROP POLICY IF EXISTS "Families update their assigned cases" ON cases;
DROP POLICY IF EXISTS "Editors read assigned cases" ON cases;
DROP POLICY IF EXISTS "Editors update assigned cases" ON cases;
DROP POLICY IF EXISTS "Support read all cases" ON cases;
DROP POLICY IF EXISTS "QC users read all cases" ON cases;
DROP POLICY IF EXISTS "QC users update case status" ON cases;

-- Recreate using helper function to avoid recursion

-- Admins full access to all cases
CREATE POLICY "Admins full access to cases"
  ON cases FOR ALL
  TO authenticated
  USING (public.get_my_role() = 'admin')
  WITH CHECK (public.get_my_role() = 'admin');

-- Directors manage cases in their org
CREATE POLICY "Directors manage cases in their org"
  ON cases FOR ALL
  TO authenticated
  USING (
    public.get_my_role() = 'director' 
    AND org_id IN (SELECT org_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    public.get_my_role() = 'director'
    AND org_id IN (SELECT org_id FROM users WHERE id = auth.uid())
  );

-- Families read their assigned cases
CREATE POLICY "Families read their assigned cases"
  ON cases FOR SELECT
  TO authenticated
  USING (
    public.get_my_role() = 'family'
    AND assigned_family_user_id = auth.uid()
  );

-- Families update their assigned cases
CREATE POLICY "Families update their assigned cases"
  ON cases FOR UPDATE
  TO authenticated
  USING (
    public.get_my_role() = 'family'
    AND assigned_family_user_id = auth.uid()
  )
  WITH CHECK (
    public.get_my_role() = 'family'
    AND assigned_family_user_id = auth.uid()
  );

-- Editors read assigned cases
CREATE POLICY "Editors read assigned cases"
  ON cases FOR SELECT
  TO authenticated
  USING (
    public.get_my_role() = 'editor'
    AND id IN (
      SELECT case_id 
      FROM editor_assignments 
      WHERE editor_user_id = auth.uid() 
      AND unassigned_at IS NULL
    )
  );

-- Editors update assigned cases
CREATE POLICY "Editors update assigned cases"
  ON cases FOR UPDATE
  TO authenticated
  USING (
    public.get_my_role() = 'editor'
    AND id IN (
      SELECT case_id 
      FROM editor_assignments 
      WHERE editor_user_id = auth.uid() 
      AND unassigned_at IS NULL
    )
  )
  WITH CHECK (
    public.get_my_role() = 'editor'
    AND id IN (
      SELECT case_id 
      FROM editor_assignments 
      WHERE editor_user_id = auth.uid() 
      AND unassigned_at IS NULL
    )
  );

-- Support read all cases
CREATE POLICY "Support read all cases"
  ON cases FOR SELECT
  TO authenticated
  USING (public.get_my_role() = 'support');

-- QC users read all cases (global access)
CREATE POLICY "QC users read all cases"
  ON cases FOR SELECT
  TO authenticated
  USING (public.get_my_role() = 'qc');

-- QC users update case status
CREATE POLICY "QC users update case status"
  ON cases FOR UPDATE
  TO authenticated
  USING (public.get_my_role() = 'qc')
  WITH CHECK (public.get_my_role() = 'qc');

-- ============================================================================
-- ORGANIZATIONS TABLE - Add family/editor read access
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Admins full access to organizations" ON organizations;
DROP POLICY IF EXISTS "Directors read their organization" ON organizations;
DROP POLICY IF EXISTS "Support read all organizations" ON organizations;
DROP POLICY IF EXISTS "Editors read orgs for assigned cases" ON organizations;

-- Recreate with helper function

-- Admins full access
CREATE POLICY "Admins full access to organizations"
  ON organizations FOR ALL
  TO authenticated
  USING (public.get_my_role() = 'admin')
  WITH CHECK (public.get_my_role() = 'admin');

-- Directors read their organization
CREATE POLICY "Directors read their organization"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    public.get_my_role() = 'director'
    AND id IN (SELECT org_id FROM users WHERE id = auth.uid())
  );

-- Editors read orgs for assigned cases
CREATE POLICY "Editors read orgs for assigned cases"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    public.get_my_role() = 'editor'
    AND id IN (
      SELECT cases.org_id
      FROM cases
      INNER JOIN editor_assignments ON editor_assignments.case_id = cases.id
      WHERE editor_assignments.editor_user_id = auth.uid()
      AND editor_assignments.unassigned_at IS NULL
    )
  );

-- Family read org for their assigned case (NEW!)
CREATE POLICY "Family read org for their assigned case"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    public.get_my_role() = 'family'
    AND id IN (
      SELECT org_id 
      FROM cases 
      WHERE assigned_family_user_id = auth.uid()
    )
  );

-- Support read all organizations
CREATE POLICY "Support read all organizations"
  ON organizations FOR SELECT
  TO authenticated
  USING (public.get_my_role() = 'support');

-- QC read all organizations
CREATE POLICY "QC read all organizations"
  ON organizations FOR SELECT
  TO authenticated
  USING (public.get_my_role() = 'qc');

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON POLICY "Families read their assigned cases" ON cases IS 
  'Uses get_my_role() helper function to avoid RLS recursion';

COMMENT ON POLICY "Family read org for their assigned case" ON organizations IS 
  'Allows family users to see organization name when viewing their case (for funeral home display)';

