-- Fix Storage Bucket RLS Policies for case-assets
-- This allows families to upload photos to their assigned cases

-- Enable RLS on the storage.objects table
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Families can upload case assets" ON storage.objects;
DROP POLICY IF EXISTS "Families can view case assets" ON storage.objects;
DROP POLICY IF EXISTS "Directors can upload case assets" ON storage.objects;
DROP POLICY IF EXISTS "Directors can view case assets" ON storage.objects;
DROP POLICY IF EXISTS "Admins full access to case assets" ON storage.objects;

-- Admins have full access
CREATE POLICY "Admins full access to case assets"
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

-- Directors can upload and view assets in their org's cases
CREATE POLICY "Directors can upload case assets"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM public.cases
      WHERE cases.id = (string_to_array(name, '/'))[1]::uuid
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

CREATE POLICY "Directors can view case assets"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM public.cases
      WHERE cases.id = (string_to_array(name, '/'))[1]::uuid
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

-- Families can upload and view assets for their assigned cases
CREATE POLICY "Families can upload case assets"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM public.cases
      WHERE cases.id = (string_to_array(name, '/'))[1]::uuid
      AND cases.assigned_family_user_id = auth.uid()
    )
  );

CREATE POLICY "Families can view case assets"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM public.cases
      WHERE cases.id = (string_to_array(name, '/'))[1]::uuid
      AND cases.assigned_family_user_id = auth.uid()
    )
  );

-- Verify the policies
SELECT 
  schemaname,
  tablename,
  policyname,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
ORDER BY policyname;

