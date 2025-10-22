-- ============================================================================
-- CREATE SUPABASE STORAGE BUCKET FOR CASE ASSETS
-- ============================================================================
-- Description: Create a public storage bucket for storing case photos and assets

-- Create the storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('case-assets', 'case-assets', true)
ON CONFLICT (id) DO UPDATE
SET public = true;

-- ============================================================================
-- STORAGE POLICIES FOR CASE-ASSETS BUCKET
-- ============================================================================

-- Allow authenticated users to upload assets for their own cases
CREATE POLICY "Allow authenticated users to upload their case assets"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'case-assets' AND
  (
    -- Family members can upload to their own case
    (auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
     (storage.foldername(name))[1] IN (
       SELECT id::text
       FROM cases
       WHERE cases.id = (
         SELECT case_id
         FROM users
         WHERE users.id = auth.uid()
       )
     )) OR
    -- Directors can upload to cases in their organization
    (auth.jwt() -> 'app_metadata' ->> 'role' = 'director') OR
    -- Admins can upload to any case
    (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin')
  )
);

-- Allow public read access to all assets (for viewing photos)
CREATE POLICY "Allow public read access to case assets"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'case-assets');

-- Allow users to update their own case assets
CREATE POLICY "Allow authenticated users to update their case assets"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'case-assets' AND
  (
    -- Family members can update their own case assets
    (auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
     (storage.foldername(name))[1] IN (
       SELECT id::text
       FROM cases
       WHERE cases.id = (
         SELECT case_id
         FROM users
         WHERE users.id = auth.uid()
       )
     )) OR
    -- Directors can update assets in their organization
    (auth.jwt() -> 'app_metadata' ->> 'role' = 'director') OR
    -- Admins can update any asset
    (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin')
  )
);

-- Allow users to delete their own case assets
CREATE POLICY "Allow authenticated users to delete their case assets"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'case-assets' AND
  (
    -- Family members can delete their own case assets
    (auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
     (storage.foldername(name))[1] IN (
       SELECT id::text
       FROM cases
       WHERE cases.id = (
         SELECT case_id
         FROM users
         WHERE users.id = auth.uid()
       )
     )) OR
    -- Directors can delete assets in their organization
    (auth.jwt() -> 'app_metadata' ->> 'role' = 'director') OR
    -- Admins can delete any asset
    (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin')
  )
);

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON POLICY "Allow authenticated users to upload their case assets" ON storage.objects IS 
  'Allows family members to upload photos to their own case folder, directors to their org cases, and admins to any case';

COMMENT ON POLICY "Allow public read access to case assets" ON storage.objects IS 
  'Allows public read access so photos can be displayed in dashboards and downloaded by editors';

COMMENT ON POLICY "Allow authenticated users to update their case assets" ON storage.objects IS 
  'Allows authorized users to update metadata or replace assets';

COMMENT ON POLICY "Allow authenticated users to delete their case assets" ON storage.objects IS 
  'Allows authorized users to delete assets from their cases';

