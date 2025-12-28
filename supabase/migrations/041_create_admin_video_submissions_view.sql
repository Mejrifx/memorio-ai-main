-- ============================================================================
-- CREATE admin_video_submissions_view WITH QC REVIEWER INFO
-- ============================================================================
-- Problem: Admin portal can't see QC reviewer info because it queries
-- video_submissions with a foreign key join to users table, but admins
-- can't directly access users table (only via admin_users_view).
--
-- Solution: Create a view that pre-joins video_submissions with QC reviewer
-- info, bypassing RLS by using security_barrier = true.
-- ============================================================================

-- Drop existing view if it exists
DROP VIEW IF EXISTS admin_video_submissions_view CASCADE;

-- Create the view with QC reviewer information
CREATE OR REPLACE VIEW admin_video_submissions_view
WITH (security_invoker = false, security_barrier = true)
AS
SELECT 
  video_submissions.id,
  video_submissions.case_id,
  video_submissions.editor_user_id,
  video_submissions.video_url,
  video_submissions.thumbnail_url,
  video_submissions.duration_seconds,
  video_submissions.file_size_bytes,
  video_submissions.mime_type,
  video_submissions.editor_notes,
  video_submissions.submitted_at,
  video_submissions.qc_reviewer_id,
  video_submissions.qc_status,
  video_submissions.qc_notes,
  video_submissions.qc_reviewed_at,
  video_submissions.revision_number,
  video_submissions.previous_submission_id,
  video_submissions.created_at,
  video_submissions.updated_at,
  
  -- QC Reviewer user info (joined from users)
  qc_reviewer.email as qc_reviewer_email,
  qc_reviewer.metadata as qc_reviewer_metadata,
  qc_reviewer.status as qc_reviewer_status,
  
  -- Editor user info (joined from users)
  editor.email as editor_email,
  editor.metadata as editor_metadata,
  editor.status as editor_status
  
FROM video_submissions
LEFT JOIN users qc_reviewer ON qc_reviewer.id = video_submissions.qc_reviewer_id
LEFT JOIN users editor ON editor.id = video_submissions.editor_user_id
WHERE
  -- Admins see all submissions
  (public.get_my_role() = 'admin')
  OR
  -- Directors see submissions for cases in their org
  (
    public.get_my_role() = 'director'
    AND EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = video_submissions.case_id
      AND cases.org_id = (SELECT org_id FROM users WHERE id = auth.uid())
    )
  )
  OR
  -- QC users see all submissions (they're global)
  (public.get_my_role() = 'qc')
  OR
  -- Editors see their own submissions
  (
    public.get_my_role() = 'editor'
    AND video_submissions.editor_user_id = auth.uid()
  )
  OR
  -- Family sees approved submissions for their case
  (
    public.get_my_role() = 'family'
    AND video_submissions.qc_status = 'approved'
    AND EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = video_submissions.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  );

-- Grant access to authenticated users
GRANT SELECT ON admin_video_submissions_view TO authenticated;

-- Add helpful comment
COMMENT ON VIEW admin_video_submissions_view IS 
  'Admin/Director/QC view for video submissions with QC reviewer info.
   Uses security_barrier = true to bypass RLS and pre-join with users table.
   This allows admins to see QC reviewer names without direct users table access.
   
   Key fields:
   - qc_reviewer_email: Email of assigned QC reviewer
   - qc_reviewer_metadata: Contains name and other QC reviewer info
   - editor_email: Email of video editor
   - editor_metadata: Contains name and other editor info
   
   Example usage:
   SELECT case_id, qc_status, qc_reviewer_metadata->''name'' as qc_name
   FROM admin_video_submissions_view
   WHERE qc_status = ''in_review'';';

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Test as admin:
-- SELECT id, case_id, qc_status, qc_reviewer_email, qc_reviewer_metadata->>'name' as qc_name
-- FROM admin_video_submissions_view
-- WHERE qc_reviewer_id IS NOT NULL;
--
-- Should show QC reviewer name and email for assigned submissions
-- ============================================================================

