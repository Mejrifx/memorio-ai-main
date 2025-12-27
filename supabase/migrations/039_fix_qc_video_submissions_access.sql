-- ============================================================================
-- FIX: QC Users Cannot See Video Submissions
-- ============================================================================
-- Problem: QC portal shows "No pending reviews" even after editor submits videos
--
-- Root Cause:
-- Migration 021 made QC users global (org_id = NULL) BUT forgot to update
-- the video_submissions RLS policy. The policy from migration 019 still
-- checks for org_id match, which fails for QC users (they have NULL org_id).
--
-- Additionally, the policy uses deprecated auth.jwt() -> 'app_metadata'
-- which should be replaced with get_my_role() for consistency.
-- ============================================================================

-- Drop the old org-scoped QC policy
DROP POLICY IF EXISTS "QC users manage submissions in their org" ON video_submissions;

-- Create new GLOBAL QC policy using get_my_role()
CREATE POLICY "QC users manage all video submissions"
  ON video_submissions FOR ALL
  TO authenticated
  USING (
    public.get_my_role() = 'qc'
  )
  WITH CHECK (
    public.get_my_role() = 'qc'
  );

COMMENT ON POLICY "QC users manage all video submissions" ON video_submissions IS 
  'QC users are global - can review, approve, reject videos from ALL organizations';

-- ============================================================================
-- OPTIONAL: Update other video_submissions policies to use get_my_role()
-- ============================================================================
-- This ensures consistency across all policies and avoids JWT issues

-- Drop existing policies
DROP POLICY IF EXISTS "Admins full access to video_submissions" ON video_submissions;
DROP POLICY IF EXISTS "Editors manage their submissions" ON video_submissions;
DROP POLICY IF EXISTS "Directors view submissions in their org" ON video_submissions;
DROP POLICY IF EXISTS "Family view approved video for their case" ON video_submissions;

-- Recreate with get_my_role()

-- Admins have full access
CREATE POLICY "Admins full access to video_submissions"
  ON video_submissions FOR ALL
  TO authenticated
  USING (public.get_my_role() = 'admin')
  WITH CHECK (public.get_my_role() = 'admin');

-- Editors manage their own submissions
CREATE POLICY "Editors manage their submissions"
  ON video_submissions FOR ALL
  TO authenticated
  USING (
    public.get_my_role() = 'editor' AND
    editor_user_id = auth.uid()
  )
  WITH CHECK (
    public.get_my_role() = 'editor' AND
    editor_user_id = auth.uid()
  );

-- Directors view submissions in their org
CREATE POLICY "Directors view submissions in their org"
  ON video_submissions FOR SELECT
  TO authenticated
  USING (
    public.get_my_role() = 'director' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = video_submissions.case_id
      AND cases.org_id IN (SELECT org_id FROM users WHERE id = auth.uid())
    )
  );

-- Family members can view only approved videos for their assigned case
CREATE POLICY "Family view approved video for their case"
  ON video_submissions FOR SELECT
  TO authenticated
  USING (
    public.get_my_role() = 'family' AND
    qc_status = 'approved' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = video_submissions.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  );

-- Support users can view all submissions (like QC)
CREATE POLICY "Support users view all video submissions"
  ON video_submissions FOR SELECT
  TO authenticated
  USING (
    public.get_my_role() = 'support'
  );

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Run these as QC user to verify fix:
-- SELECT COUNT(*) FROM video_submissions WHERE qc_status = 'pending';
-- Should return count of pending submissions, not 0

-- Check policies exist:
-- SELECT policyname, cmd, qual 
-- FROM pg_policies 
-- WHERE tablename = 'video_submissions' 
-- ORDER BY policyname;

-- ============================================================================
-- EXPECTED RESULT
-- ============================================================================
-- QC portal should now display all pending video submissions across all orgs
-- QC users can review, approve, reject, or request revisions on any video

