-- ============================================================================
-- FIX ALL RLS POLICIES TO USE DATABASE ROLE INSTEAD OF JWT
-- ============================================================================
-- Problem: Cases not showing in admin portal, and other role-based access issues
-- Root Cause: RLS policies check JWT app_metadata.role which doesn't exist
-- Solution: Check users.role from database instead (like migration 025 for editors)

-- Background:
-- We moved from storing roles in JWT app_metadata to database users.role column.
-- Migration 025 fixed editor access to organizations, but admin/director/family
-- policies still use JWT, blocking access when JWT doesn't have app_metadata.role.

-- ============================================================================
-- ORGANIZATIONS TABLE
-- ============================================================================

DROP POLICY IF EXISTS "Admins full access to organizations" ON organizations;
DROP POLICY IF EXISTS "Directors read their organization" ON organizations;
DROP POLICY IF EXISTS "Support read all organizations" ON organizations;

-- Admin full access using database role
CREATE POLICY "Admins full access to organizations"
  ON organizations FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
      AND users.status = 'active'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
      AND users.status = 'active'
    )
  );

-- Directors read their own org using database role
CREATE POLICY "Directors read their organization"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'director'
      AND users.status = 'active'
      AND users.org_id = organizations.id
    )
  );

-- Support read all orgs using database role
CREATE POLICY "Support read all organizations"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'support'
      AND users.status = 'active'
    )
  );

-- ============================================================================
-- CASES TABLE
-- ============================================================================

DROP POLICY IF EXISTS "Admins full access to cases" ON cases;
DROP POLICY IF EXISTS "Directors manage cases in their org" ON cases;
DROP POLICY IF EXISTS "Families read their assigned cases" ON cases;
DROP POLICY IF EXISTS "Families update their assigned cases" ON cases;
DROP POLICY IF EXISTS "Editors read assigned cases" ON cases;
DROP POLICY IF EXISTS "Editors update assigned cases" ON cases;
DROP POLICY IF EXISTS "Support read all cases" ON cases;
DROP POLICY IF EXISTS "QC users read cases in their org" ON cases;
DROP POLICY IF EXISTS "QC users read all cases" ON cases;
DROP POLICY IF EXISTS "QC users update case status" ON cases;

-- Admin full access to all cases using database role
CREATE POLICY "Admins full access to cases"
  ON cases FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
      AND users.status = 'active'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
      AND users.status = 'active'
    )
  );

-- Directors manage cases in their org using database role
CREATE POLICY "Directors manage cases in their org"
  ON cases FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'director'
      AND users.status = 'active'
      AND users.org_id = cases.org_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'director'
      AND users.status = 'active'
      AND users.org_id = cases.org_id
    )
  );

-- Families read their assigned cases using database role
CREATE POLICY "Families read their assigned cases"
  ON cases FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'family'
      AND users.status = 'active'
    )
    AND cases.assigned_family_user_id = auth.uid()
  );

-- Families update their assigned cases using database role
CREATE POLICY "Families update their assigned cases"
  ON cases FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'family'
      AND users.status = 'active'
    )
    AND cases.assigned_family_user_id = auth.uid()
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'family'
      AND users.status = 'active'
    )
    AND cases.assigned_family_user_id = auth.uid()
  );

-- Editors read assigned cases using database role
CREATE POLICY "Editors read assigned cases"
  ON cases FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'editor'
      AND users.status = 'active'
    )
    AND cases.id IN (
      SELECT case_id 
      FROM editor_assignments 
      WHERE editor_user_id = auth.uid() 
      AND unassigned_at IS NULL
    )
  );

-- Editors update assigned cases using database role
CREATE POLICY "Editors update assigned cases"
  ON cases FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'editor'
      AND users.status = 'active'
    )
    AND cases.id IN (
      SELECT case_id 
      FROM editor_assignments 
      WHERE editor_user_id = auth.uid() 
      AND unassigned_at IS NULL
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'editor'
      AND users.status = 'active'
    )
    AND cases.id IN (
      SELECT case_id 
      FROM editor_assignments 
      WHERE editor_user_id = auth.uid() 
      AND unassigned_at IS NULL
    )
  );

-- Support read all cases using database role
CREATE POLICY "Support read all cases"
  ON cases FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'support'
      AND users.status = 'active'
    )
  );

-- QC users read cases (global access) using database role
CREATE POLICY "QC users read all cases"
  ON cases FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'qc'
      AND users.status = 'active'
    )
  );

-- QC users update case status using database role
CREATE POLICY "QC users update case status"
  ON cases FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'qc'
      AND users.status = 'active'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'qc'
      AND users.status = 'active'
    )
  );

-- ============================================================================
-- USERS TABLE
-- ============================================================================

DROP POLICY IF EXISTS "Admins full access to users" ON users;
DROP POLICY IF EXISTS "Directors manage users in their org" ON users;
DROP POLICY IF EXISTS "Support read all users" ON users;

-- Admin full access to users using database role
CREATE POLICY "Admins full access to users"
  ON users FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.id = auth.uid() 
      AND u.role = 'admin'
      AND u.status = 'active'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.id = auth.uid() 
      AND u.role = 'admin'
      AND u.status = 'active'
    )
  );

-- Directors manage users in their org using database role
CREATE POLICY "Directors manage users in their org"
  ON users FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users director 
      WHERE director.id = auth.uid() 
      AND director.role = 'director'
      AND director.status = 'active'
      AND director.org_id = users.org_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users director 
      WHERE director.id = auth.uid() 
      AND director.role = 'director'
      AND director.status = 'active'
      AND director.org_id = users.org_id
    )
  );

-- Support read all users using database role
CREATE POLICY "Support read all users"
  ON users FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u 
      WHERE u.id = auth.uid() 
      AND u.role = 'support'
      AND u.status = 'active'
    )
  );

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Test as admin user:
-- SELECT * FROM cases LIMIT 10;
-- Should return all cases

-- Test as director user:
-- SELECT * FROM cases WHERE org_id = '<their_org_id>' LIMIT 10;
-- Should return only their org's cases

-- Test as family user:
-- SELECT * FROM cases WHERE assigned_family_user_id = auth.uid();
-- Should return only their assigned case

