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
