-- Migration 057: Add cooldown_expires_at and cooldown_overridden to admin_video_submissions_view
-- These columns were added to video_submissions in migration 056 but were not included in the view.
-- NOTE: Must DROP first — CREATE OR REPLACE VIEW cannot add new columns mid-list.

DROP VIEW IF EXISTS admin_video_submissions_view CASCADE;

CREATE VIEW admin_video_submissions_view
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
  video_submissions.cooldown_expires_at,
  video_submissions.cooldown_overridden,
  
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
  -- QC users see all submissions
  (public.get_my_role() = 'qc')
  OR
  -- Editors see their own submissions
  (
    public.get_my_role() = 'editor'
    AND video_submissions.editor_user_id = auth.uid()
  );

GRANT SELECT ON admin_video_submissions_view TO authenticated;
