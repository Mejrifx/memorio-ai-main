-- ============================================================================
-- UPDATE STORAGE FILE SIZE LIMIT TO 1.5GB
-- ============================================================================
-- Description: Update case-assets bucket to allow uploads up to 1.5GB for video files
-- Previous limit: 500MB (default/implicit)
-- New limit: 1.5GB (1610612736 bytes)

-- Update the bucket configuration to set file size limit to 1.5GB
UPDATE storage.buckets
SET 
  file_size_limit = 1610612736,  -- 1.5GB in bytes (1.5 * 1024 * 1024 * 1024)
  allowed_mime_types = ARRAY[
    'image/jpeg',
    'image/jpg', 
    'image/png',
    'image/gif',
    'image/webp',
    'video/mp4',
    'video/quicktime',
    'video/x-msvideo',
    'video/mpeg',
    'video/x-matroska'
  ]::text[]
WHERE id = 'case-assets';

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON COLUMN storage.buckets.file_size_limit IS 
  'Maximum file size in bytes. Set to 1.5GB (1610612736 bytes) to allow large video uploads from editors';
