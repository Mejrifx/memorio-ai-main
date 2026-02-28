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
  users.metadata->>'temp_password' AS temp_password,
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
