-- Migration 056: Add 40-hour cooldown on QC video approval delivery
-- 
-- Business Logic:
-- - When QC approves a video, check if 40+ hours have elapsed since first_submission_at
-- - If YES (40+ hours elapsed): deliver immediately to family
-- - If NO (< 40 hours): approve video but delay delivery until 40-hour mark
-- - QC can manually override cooldown with warning confirmation
-- 
-- This gives families time to edit the obituary before receiving the final video

-- ============================================================================
-- STEP 1: Add cooldown tracking fields to video_submissions
-- ============================================================================

ALTER TABLE video_submissions 
ADD COLUMN IF NOT EXISTS cooldown_expires_at TIMESTAMPTZ;

ALTER TABLE video_submissions 
ADD COLUMN IF NOT EXISTS cooldown_overridden BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN video_submissions.cooldown_expires_at IS 
  'Timestamp when the 40-hour cooldown expires and video can be delivered to family. NULL if no cooldown applies.';

COMMENT ON COLUMN video_submissions.cooldown_overridden IS 
  'TRUE if QC manually overrode the cooldown timer to deliver immediately';

-- Create index for efficient querying of videos pending cooldown delivery
CREATE INDEX IF NOT EXISTS idx_video_submissions_cooldown_pending 
  ON video_submissions(cooldown_expires_at) 
  WHERE qc_status = 'approved' AND cooldown_expires_at IS NOT NULL;

-- ============================================================================
-- STEP 2: Create function to check if cooldown should apply
-- ============================================================================

CREATE OR REPLACE FUNCTION should_apply_cooldown(p_case_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_first_submission_at TIMESTAMPTZ;
  v_hours_elapsed NUMERIC;
BEGIN
  -- Get the first submission timestamp for this case
  SELECT first_submission_at INTO v_first_submission_at
  FROM cases
  WHERE id = p_case_id;
  
  -- If no submission timestamp, no cooldown needed
  IF v_first_submission_at IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Calculate hours elapsed since first submission
  v_hours_elapsed := EXTRACT(EPOCH FROM (NOW() - v_first_submission_at)) / 3600;
  
  -- Apply cooldown if less than 40 hours have elapsed
  RETURN v_hours_elapsed < 40;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION should_apply_cooldown(UUID) IS 
  'Checks if the 40-hour cooldown should apply based on first_submission_at timestamp';

-- ============================================================================
-- STEP 3: Create function to calculate cooldown expiration time
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_cooldown_expiration(p_case_id UUID)
RETURNS TIMESTAMPTZ AS $$
DECLARE
  v_first_submission_at TIMESTAMPTZ;
BEGIN
  -- Get the first submission timestamp
  SELECT first_submission_at INTO v_first_submission_at
  FROM cases
  WHERE id = p_case_id;
  
  -- Return first_submission_at + 40 hours
  RETURN v_first_submission_at + INTERVAL '40 hours';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION calculate_cooldown_expiration(UUID) IS 
  'Calculates when the 40-hour cooldown expires (first_submission_at + 40 hours)';

-- ============================================================================
-- STEP 4: Create function to handle QC approval with cooldown logic
-- ============================================================================

CREATE OR REPLACE FUNCTION approve_video_with_cooldown(
  p_submission_id UUID,
  p_qc_user_id UUID,
  p_qc_notes TEXT DEFAULT NULL,
  p_override_cooldown BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  cooldown_applied BOOLEAN,
  cooldown_expires_at TIMESTAMPTZ,
  immediate_delivery BOOLEAN
) AS $$
DECLARE
  v_case_id UUID;
  v_should_apply_cooldown BOOLEAN;
  v_cooldown_expiration TIMESTAMPTZ;
  v_final_status TEXT;
BEGIN
  -- Get case_id for this submission
  SELECT case_id INTO v_case_id
  FROM video_submissions
  WHERE id = p_submission_id;
  
  IF v_case_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Submission not found'::TEXT, FALSE, NULL::TIMESTAMPTZ, FALSE;
    RETURN;
  END IF;
  
  -- Check if cooldown should apply (unless manually overridden)
  v_should_apply_cooldown := should_apply_cooldown(v_case_id) AND NOT p_override_cooldown;
  
  -- Calculate cooldown expiration if applicable
  IF v_should_apply_cooldown THEN
    v_cooldown_expiration := calculate_cooldown_expiration(v_case_id);
    v_final_status := 'awaiting_review'; -- Keep case in awaiting_review during cooldown
  ELSE
    v_cooldown_expiration := NULL;
    v_final_status := 'delivered'; -- Deliver immediately
  END IF;
  
  -- Update the video submission
  UPDATE video_submissions
  SET 
    qc_status = 'approved',
    qc_reviewer_id = p_qc_user_id,
    qc_notes = p_qc_notes,
    qc_reviewed_at = NOW(),
    cooldown_expires_at = v_cooldown_expiration,
    cooldown_overridden = p_override_cooldown
  WHERE id = p_submission_id;
  
  -- Update case status
  UPDATE cases
  SET status = v_final_status
  WHERE id = v_case_id;
  
  -- Return result
  RETURN QUERY SELECT 
    TRUE,
    CASE 
      WHEN v_should_apply_cooldown THEN 'Video approved. Will be delivered to family after cooldown expires.'
      WHEN p_override_cooldown THEN 'Video approved and delivered immediately (cooldown overridden).'
      ELSE 'Video approved and delivered immediately (no cooldown needed).'
    END::TEXT,
    v_should_apply_cooldown,
    v_cooldown_expiration,
    NOT v_should_apply_cooldown;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION approve_video_with_cooldown IS 
  'Handles QC video approval with automatic cooldown logic. Delivers immediately if 40+ hours elapsed, otherwise schedules delivery.';

-- Grant execute to authenticated users (QC role will use this)
GRANT EXECUTE ON FUNCTION approve_video_with_cooldown TO authenticated;
GRANT EXECUTE ON FUNCTION should_apply_cooldown TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_cooldown_expiration TO authenticated;

-- ============================================================================
-- STEP 5: Create pg_cron job to auto-deliver videos when cooldown expires
-- ============================================================================

-- Enable pg_cron extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Grant usage on cron schema to postgres
GRANT USAGE ON SCHEMA cron TO postgres;

-- Schedule job to run every 10 minutes to check for expired cooldowns
-- This will automatically deliver videos to families when the 40-hour window expires
SELECT cron.schedule(
  'auto-deliver-cooldown-videos',           -- Job name
  '*/10 * * * *',                           -- Every 10 minutes
  $$
  -- Update cases to 'delivered' status when cooldown has expired
  UPDATE cases
  SET status = 'delivered'
  WHERE id IN (
    SELECT vs.case_id
    FROM video_submissions vs
    WHERE vs.qc_status = 'approved'
    AND vs.cooldown_expires_at IS NOT NULL
    AND vs.cooldown_expires_at <= NOW()
    AND EXISTS (
      SELECT 1 FROM cases c
      WHERE c.id = vs.case_id
      AND c.status = 'awaiting_review'
    )
  );
  $$
);

COMMENT ON EXTENSION pg_cron IS 
  'PostgreSQL job scheduler - used for auto-delivering videos when cooldown expires';

-- ============================================================================
-- STEP 6: Create helper view for monitoring cooldown status
-- ============================================================================

CREATE OR REPLACE VIEW qc_cooldown_status AS
SELECT 
  vs.id as submission_id,
  vs.case_id,
  c.deceased_name,
  c.first_submission_at,
  vs.qc_reviewed_at,
  vs.cooldown_expires_at,
  vs.cooldown_overridden,
  c.status as case_status,
  CASE 
    WHEN vs.cooldown_expires_at IS NULL THEN 'No cooldown'
    WHEN vs.cooldown_overridden THEN 'Cooldown overridden'
    WHEN vs.cooldown_expires_at <= NOW() THEN 'Cooldown expired (pending delivery)'
    ELSE 'Cooldown active'
  END as cooldown_status,
  CASE 
    WHEN vs.cooldown_expires_at IS NOT NULL AND vs.cooldown_expires_at > NOW() 
    THEN ROUND(EXTRACT(EPOCH FROM (vs.cooldown_expires_at - NOW())) / 3600, 1)
    ELSE 0
  END as hours_until_delivery
FROM video_submissions vs
JOIN cases c ON vs.case_id = c.id
WHERE vs.qc_status = 'approved'
ORDER BY vs.qc_reviewed_at DESC;

COMMENT ON VIEW qc_cooldown_status IS 
  'Monitoring view for QC cooldown status - shows which videos are pending delivery and when they will be delivered';

GRANT SELECT ON qc_cooldown_status TO authenticated;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Summary:
-- ✅ Added cooldown_expires_at and cooldown_overridden columns to video_submissions
-- ✅ Created should_apply_cooldown() function to check if 40+ hours have elapsed
-- ✅ Created calculate_cooldown_expiration() function to calculate delivery time
-- ✅ Created approve_video_with_cooldown() function to handle approval logic
-- ✅ Created pg_cron job to auto-deliver videos every 10 minutes when cooldown expires
-- ✅ Created qc_cooldown_status view for monitoring
-- 
-- QC users can now:
-- 1. Approve videos with automatic cooldown if < 40 hours since first_submission_at
-- 2. Manually override cooldown to deliver immediately with confirmation
-- 3. Videos auto-deliver to family when cooldown expires (checked every 10 minutes)
