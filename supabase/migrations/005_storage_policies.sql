-- Memorio Storage Bucket Policies
-- Version: 1.0.0
-- Description: RLS policies for case-assets storage bucket

-- ============================================================================
-- STORAGE BUCKET POLICIES FOR case-assets
-- ============================================================================

-- Policy 1: Admins have full access to all files
CREATE POLICY "Admins full access to storage"
ON storage.objects FOR ALL
USING (
  bucket_id = 'case-assets' AND
  auth.jwt() ->> 'role' = 'admin'
);

-- Policy 2: Directors can access files in their organization
CREATE POLICY "Directors access org files"
ON storage.objects FOR ALL
USING (
  bucket_id = 'case-assets' AND
  auth.jwt() ->> 'role' = 'director' AND
  (storage.foldername(name))[1] = (auth.jwt() ->> 'org_id')
);

-- Policy 3: Families can manage files for their assigned cases
CREATE POLICY "Families manage their case files"
ON storage.objects FOR ALL
USING (
  bucket_id = 'case-assets' AND
  auth.jwt() ->> 'role' = 'family' AND
  EXISTS (
    SELECT 1 FROM cases
    WHERE cases.id::text = (storage.foldername(name))[2]
    AND cases.assigned_family_user_id = auth.uid()
  )
);

-- Policy 4: Editors can read files for assigned cases
CREATE POLICY "Editors read assigned case files"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'case-assets' AND
  auth.jwt() ->> 'role' = 'editor' AND
  EXISTS (
    SELECT 1 FROM cases
    JOIN editor_assignments ON editor_assignments.case_id = cases.id
    WHERE cases.id::text = (storage.foldername(name))[2]
    AND editor_assignments.editor_user_id = auth.uid()
    AND editor_assignments.unassigned_at IS NULL
  )
);

-- Policy 5: Support can read all files
CREATE POLICY "Support read all files"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'case-assets' AND
  auth.jwt() ->> 'role' = 'support'
);

-- ============================================================================
-- COMPLETION
-- ============================================================================
COMMENT ON SCHEMA public IS 'Memorio storage policies v1.0.0 - Multi-tenant file access enabled';
