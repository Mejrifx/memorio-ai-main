-- Fix Storage Bucket Policies - Update to use correct JWT path (app_metadata)
-- This replaces the old policies from migration 005 that used the wrong JWT path

-- Drop the OLD policies that use auth.jwt() ->> 'role' (incorrect)
DROP POLICY IF EXISTS "Admins full access to storage" ON storage.objects;
DROP POLICY IF EXISTS "Directors access org files" ON storage.objects;
DROP POLICY IF EXISTS "Families manage their case files" ON storage.objects;
DROP POLICY IF EXISTS "Editors read assigned case files" ON storage.objects;
DROP POLICY IF EXISTS "Support read all files" ON storage.objects;

-- Create NEW policies with correct JWT path: auth.jwt() -> 'app_metadata' ->> 'role'

-- Policy 1: Admins have full access
CREATE POLICY "Admins full access to storage"
  ON storage.objects FOR ALL
  TO authenticated
  USING (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'admin'
  )
  WITH CHECK (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'admin'
  );

-- Policy 2: Directors can upload and view files in their organization
CREATE POLICY "Directors access org files"
  ON storage.objects FOR ALL
  TO authenticated
  USING (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM public.cases
      WHERE cases.id = (string_to_array(name, '/'))[1]::uuid
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  )
  WITH CHECK (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM public.cases
      WHERE cases.id = (string_to_array(name, '/'))[1]::uuid
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

-- Policy 3: Families can upload and view files for their assigned cases
CREATE POLICY "Families manage their case files"
  ON storage.objects FOR ALL
  TO authenticated
  USING (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM public.cases
      WHERE cases.id = (string_to_array(name, '/'))[1]::uuid
      AND cases.assigned_family_user_id = auth.uid()
    )
  )
  WITH CHECK (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM public.cases
      WHERE cases.id = (string_to_array(name, '/'))[1]::uuid
      AND cases.assigned_family_user_id = auth.uid()
    )
  );

-- Policy 4: Editors can read files for assigned cases
CREATE POLICY "Editors read assigned case files"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'editor' AND
    EXISTS (
      SELECT 1 FROM public.cases
      JOIN public.editor_assignments ON editor_assignments.case_id = cases.id
      WHERE cases.id = (string_to_array(name, '/'))[1]::uuid
      AND editor_assignments.editor_user_id = auth.uid()
      AND editor_assignments.unassigned_at IS NULL
    )
  );

-- Policy 5: Support can read all files
CREATE POLICY "Support read all files"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'support'
  );

-- Verify the policies were created
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual IS NOT NULL as has_using,
  with_check IS NOT NULL as has_with_check
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
  AND bucket_id = 'case-assets'
ORDER BY policyname;

