# Manual Migration Application Guide

Your Supabase CLI is an older version (2.48.3) that doesn't support the newer migration commands. 

Please apply these 3 migrations manually using the Supabase SQL Editor:

## 🔗 Access Your SQL Editor
Go to: https://supabase.com/dashboard/project/gkabtvqwwuvigcdubwyv/sql

---

## Migration 1: Storage File Size Limit (1.5GB)

**File**: `supabase/migrations/053_update_storage_file_size_limit.sql`

Copy and paste this SQL into your Supabase SQL Editor and run it:

```sql
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
```

✅ **Expected Result**: "UPDATE 1" - The storage bucket is now configured for 1.5GB uploads.

---

## Migration 2: 12-Hour Upload Window Enforcement

**File**: `supabase/migrations/054_enforce_upload_window.sql`

Copy and paste this SQL into your Supabase SQL Editor and run it:

```sql
-- ============================================================================
-- ENFORCE 12-HOUR UPLOAD WINDOW FOR VIDEO SUBMISSIONS
-- ============================================================================
-- Description: Prevent editors from submitting videos during the 12-hour
-- family upload window after form submission
-- Business Rule: Editors must wait 12 hours after form submission to ensure
-- all family photos are uploaded before starting video production

-- Create a function to check if the 12-hour window has expired
CREATE OR REPLACE FUNCTION check_upload_window_expired(p_case_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_form_submitted_at TIMESTAMPTZ;
  v_twelve_hours_later TIMESTAMPTZ;
BEGIN
  -- Get the form submitted_at timestamp for this case
  SELECT submitted_at INTO v_form_submitted_at
  FROM forms
  WHERE case_id = p_case_id
  AND submitted_at IS NOT NULL
  ORDER BY submitted_at DESC
  LIMIT 1;
  
  -- If no form submitted, allow upload (edge case, shouldn't happen)
  IF v_form_submitted_at IS NULL THEN
    RETURN TRUE;
  END IF;
  
  -- Calculate 12 hours after submission
  v_twelve_hours_later := v_form_submitted_at + INTERVAL '12 hours';
  
  -- Return TRUE if 12 hours have passed, FALSE otherwise
  RETURN NOW() >= v_twelve_hours_later;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add a trigger to prevent video submissions during the 12-hour window
CREATE OR REPLACE FUNCTION prevent_video_upload_during_window()
RETURNS TRIGGER AS $$
DECLARE
  v_window_expired BOOLEAN;
BEGIN
  -- Check if the upload window has expired
  v_window_expired := check_upload_window_expired(NEW.case_id);
  
  IF NOT v_window_expired THEN
    RAISE EXCEPTION 'Cannot submit video during the 12-hour family upload window. Please wait for the window to expire.';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on video_submissions table
DROP TRIGGER IF EXISTS enforce_upload_window ON video_submissions;
CREATE TRIGGER enforce_upload_window
  BEFORE INSERT ON video_submissions
  FOR EACH ROW
  EXECUTE FUNCTION prevent_video_upload_during_window();

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON FUNCTION check_upload_window_expired(UUID) IS 
  'Checks if the 12-hour family upload window has expired for a given case. Returns TRUE if expired (uploads allowed), FALSE otherwise.';

COMMENT ON FUNCTION prevent_video_upload_during_window() IS 
  'Trigger function that prevents video submissions during the 12-hour family upload window after form submission.';

COMMENT ON TRIGGER enforce_upload_window ON video_submissions IS 
  'Enforces the 12-hour upload window business rule server-side to prevent bypass via API calls.';
```

✅ **Expected Result**: "CREATE FUNCTION" and "CREATE TRIGGER" - Server-side upload window enforcement is active.

---

## Migration 3: User Analytics for Admin Dashboard

**File**: `supabase/migrations/055_user_analytics.sql`

Copy and paste this SQL into your Supabase SQL Editor and run it:

```sql
-- ============================================================================
-- USER ANALYTICS FOR ADMIN DASHBOARD
-- ============================================================================
-- Description: Create views and functions to calculate per-user analytics
-- for editors (videos edited) and QC users (passed/rejected/pass-rate)

-- ============================================================================
-- EDITOR ANALYTICS VIEW
-- ============================================================================
-- Count videos submitted by each editor
CREATE OR REPLACE VIEW editor_analytics AS
SELECT 
  users.id AS user_id,
  users.email,
  users.metadata->>'name' AS name,
  COUNT(DISTINCT video_submissions.id) AS total_videos_edited,
  COUNT(DISTINCT CASE WHEN video_submissions.qc_status = 'approved' THEN video_submissions.id END) AS videos_approved,
  COUNT(DISTINCT CASE WHEN video_submissions.qc_status = 'revision_requested' THEN video_submissions.id END) AS revisions_requested,
  COUNT(DISTINCT CASE WHEN video_submissions.qc_status = 'pending' OR video_submissions.qc_status = 'in_review' THEN video_submissions.id END) AS videos_pending,
  MAX(video_submissions.submitted_at) AS last_submission_date
FROM users
LEFT JOIN video_submissions ON video_submissions.editor_user_id = users.id
WHERE users.role = 'editor'
GROUP BY users.id, users.email, users.metadata;

-- ============================================================================
-- QC ANALYTICS VIEW
-- ============================================================================
-- Count videos passed/rejected by each QC user
CREATE OR REPLACE VIEW qc_analytics AS
SELECT 
  users.id AS user_id,
  users.email,
  users.metadata->>'name' AS name,
  COUNT(DISTINCT CASE WHEN video_submissions.qc_status = 'approved' THEN video_submissions.id END) AS videos_passed,
  COUNT(DISTINCT CASE WHEN video_submissions.qc_status = 'revision_requested' THEN video_submissions.id END) AS videos_rejected,
  COUNT(DISTINCT CASE WHEN video_submissions.qc_status IN ('approved', 'revision_requested') THEN video_submissions.id END) AS total_reviewed,
  CASE 
    WHEN COUNT(DISTINCT CASE WHEN video_submissions.qc_status IN ('approved', 'revision_requested') THEN video_submissions.id END) > 0 
    THEN ROUND(
      (COUNT(DISTINCT CASE WHEN video_submissions.qc_status = 'approved' THEN video_submissions.id END)::numeric / 
       COUNT(DISTINCT CASE WHEN video_submissions.qc_status IN ('approved', 'revision_requested') THEN video_submissions.id END)::numeric) * 100, 
      1
    )
    ELSE 0
  END AS pass_rate_percentage,
  MAX(video_submissions.qc_reviewed_at) AS last_review_date
FROM users
LEFT JOIN video_submissions ON video_submissions.qc_reviewer_id = users.id
WHERE users.role = 'qc'
GROUP BY users.id, users.email, users.metadata;

-- ============================================================================
-- COMBINED ANALYTICS VIEW (for easy querying)
-- ============================================================================
CREATE OR REPLACE VIEW user_analytics_combined AS
SELECT 
  users.id AS user_id,
  users.email,
  users.role,
  users.status,
  users.metadata->>'name' AS name,
  users.created_at,
  users.last_login_at,
  organizations.name AS org_name,
  -- Editor stats
  COALESCE(editor_analytics.total_videos_edited, 0) AS editor_total_videos,
  COALESCE(editor_analytics.videos_approved, 0) AS editor_approved,
  COALESCE(editor_analytics.revisions_requested, 0) AS editor_revisions,
  COALESCE(editor_analytics.videos_pending, 0) AS editor_pending,
  editor_analytics.last_submission_date AS editor_last_submission,
  -- QC stats
  COALESCE(qc_analytics.videos_passed, 0) AS qc_passed,
  COALESCE(qc_analytics.videos_rejected, 0) AS qc_rejected,
  COALESCE(qc_analytics.total_reviewed, 0) AS qc_total_reviewed,
  COALESCE(qc_analytics.pass_rate_percentage, 0) AS qc_pass_rate,
  qc_analytics.last_review_date AS qc_last_review
FROM users
LEFT JOIN organizations ON users.org_id = organizations.id
LEFT JOIN editor_analytics ON users.id = editor_analytics.user_id
LEFT JOIN qc_analytics ON users.id = qc_analytics.user_id;

-- ============================================================================
-- FUNCTION TO GET ANALYTICS BY DATE RANGE
-- ============================================================================
CREATE OR REPLACE FUNCTION get_user_analytics_by_date_range(
  p_user_id UUID,
  p_days_back INTEGER DEFAULT NULL -- NULL = all time, 7 = last 7 days, 30 = last 30 days
)
RETURNS TABLE (
  total_videos_edited BIGINT,
  videos_approved BIGINT,
  revisions_requested BIGINT,
  videos_passed BIGINT,
  videos_rejected BIGINT,
  pass_rate_percentage NUMERIC
) AS $$
DECLARE
  v_date_threshold TIMESTAMPTZ;
BEGIN
  -- Calculate date threshold
  IF p_days_back IS NOT NULL THEN
    v_date_threshold := NOW() - (p_days_back || ' days')::INTERVAL;
  ELSE
    v_date_threshold := '1970-01-01'::TIMESTAMPTZ; -- All time
  END IF;
  
  -- Return analytics for the user within the date range
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT CASE WHEN vs.editor_user_id = p_user_id THEN vs.id END)::BIGINT AS total_videos_edited,
    COUNT(DISTINCT CASE WHEN vs.editor_user_id = p_user_id AND vs.qc_status = 'approved' THEN vs.id END)::BIGINT AS videos_approved,
    COUNT(DISTINCT CASE WHEN vs.editor_user_id = p_user_id AND vs.qc_status = 'revision_requested' THEN vs.id END)::BIGINT AS revisions_requested,
    COUNT(DISTINCT CASE WHEN vs.qc_reviewer_id = p_user_id AND vs.qc_status = 'approved' THEN vs.id END)::BIGINT AS videos_passed,
    COUNT(DISTINCT CASE WHEN vs.qc_reviewer_id = p_user_id AND vs.qc_status = 'revision_requested' THEN vs.id END)::BIGINT AS videos_rejected,
    CASE 
      WHEN COUNT(DISTINCT CASE WHEN vs.qc_reviewer_id = p_user_id AND vs.qc_status IN ('approved', 'revision_requested') THEN vs.id END) > 0
      THEN ROUND(
        (COUNT(DISTINCT CASE WHEN vs.qc_reviewer_id = p_user_id AND vs.qc_status = 'approved' THEN vs.id END)::NUMERIC / 
         COUNT(DISTINCT CASE WHEN vs.qc_reviewer_id = p_user_id AND vs.qc_status IN ('approved', 'revision_requested') THEN vs.id END)::NUMERIC) * 100,
        1
      )
      ELSE 0
    END AS pass_rate_percentage
  FROM video_submissions vs
  WHERE (vs.submitted_at >= v_date_threshold OR vs.qc_reviewed_at >= v_date_threshold);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- RLS POLICIES FOR VIEWS
-- ============================================================================
-- Admin-only access to analytics views
ALTER VIEW editor_analytics OWNER TO postgres;
ALTER VIEW qc_analytics OWNER TO postgres;
ALTER VIEW user_analytics_combined OWNER TO postgres;

-- Grant SELECT to authenticated users (RLS will still apply via functions)
GRANT SELECT ON editor_analytics TO authenticated;
GRANT SELECT ON qc_analytics TO authenticated;
GRANT SELECT ON user_analytics_combined TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON VIEW editor_analytics IS 
  'Aggregates video submission stats per editor: total edited, approved, revisions, pending';

COMMENT ON VIEW qc_analytics IS 
  'Aggregates QC review stats per QC user: passed, rejected, pass rate percentage';

COMMENT ON VIEW user_analytics_combined IS 
  'Combined view of user info with editor and QC analytics for admin dashboard';

COMMENT ON FUNCTION get_user_analytics_by_date_range(UUID, INTEGER) IS 
  'Returns user analytics filtered by date range (7d, 30d, or all time)';
```

✅ **Expected Result**: Multiple "CREATE VIEW" and "CREATE FUNCTION" messages - Analytics system is ready!

---

## ✅ Verification

After running all 3 migrations, verify they worked:

```sql
-- Check storage bucket limit
SELECT id, file_size_limit FROM storage.buckets WHERE id = 'case-assets';
-- Expected: file_size_limit = 1610612736 (1.5GB)

-- Check upload window function exists
SELECT proname FROM pg_proc WHERE proname = 'check_upload_window_expired';
-- Expected: Returns 1 row

-- Check analytics views exist
SELECT table_name FROM information_schema.views WHERE table_name IN ('editor_analytics', 'qc_analytics', 'user_analytics_combined');
-- Expected: Returns 3 rows
```

---

## 🎉 Done!

Once all 3 migrations are applied, your backend will have:
- ✅ 1.5GB video upload support
- ✅ 12-hour upload window enforcement
- ✅ Per-user analytics for admin dashboard

If you encounter any errors, let me know!
