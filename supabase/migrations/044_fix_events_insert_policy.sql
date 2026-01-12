-- ============================================================================
-- Fix Events Table RLS - Allow INSERT for Admins, Directors, Editors, QC
-- ============================================================================
-- 
-- ISSUE: Admins cannot insert into events table (403 Forbidden)
-- ERROR: "new row violates row-level security policy for table events"
-- 
-- ROOT CAUSE: Migration 008 replaced "FOR ALL" policy with "FOR SELECT" only
-- 
-- SOLUTION: Add INSERT policies for all roles that need to log events
-- ============================================================================

-- Add INSERT policy for Admins (full access to insert any event)
CREATE POLICY "Admins can insert events"
  ON events FOR INSERT
  TO authenticated
  WITH CHECK (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin');

-- Add INSERT policy for Directors (can insert events for their org's cases)
CREATE POLICY "Directors can insert events for their org"
  ON events FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    (
      -- Allow if event is about a case in their org
      target_type = 'case' AND
      target_id IN (
        SELECT id FROM cases WHERE org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
      )
    )
  );

-- Add INSERT policy for Editors (can insert events for cases assigned to them)
CREATE POLICY "Editors can insert events for their cases"
  ON events FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    (
      -- Allow if event is about a case assigned to them
      target_type = 'case' AND
      target_id IN (
        SELECT case_id FROM editor_assignments 
        WHERE editor_user_id = auth.uid() 
        AND unassigned_at IS NULL
      )
    )
  );

-- Add INSERT policy for QC (can insert events for any case they're reviewing)
CREATE POLICY "QC can insert events for cases"
  ON events FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'qc' AND
    target_type = 'case'
  );

-- Add INSERT policy for Family (can insert events for their assigned case)
CREATE POLICY "Family can insert events for their case"
  ON events FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    (
      -- Allow if event is about their assigned case
      target_type = 'case' AND
      target_id IN (
        SELECT id FROM cases WHERE assigned_family_user_id = auth.uid()
      )
    )
  );
