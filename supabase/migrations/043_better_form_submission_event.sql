-- ============================================================================
-- Migration: 043 - Better Form Submission Event Logging
-- ============================================================================
-- Purpose: Log specific "form_submitted" event when family completes intake form
-- ============================================================================

-- Update the form submission trigger to log a better event
CREATE OR REPLACE FUNCTION update_case_on_form_submission()
RETURNS TRIGGER AS $$
BEGIN
  -- If form is being submitted for the first time
  IF NEW.submitted_json IS NOT NULL AND OLD.submitted_at IS NULL THEN
    -- Update case status
    UPDATE cases
    SET 
      status = 'submitted',
      sla_start_at = COALESCE(sla_start_at, NOW()),
      sla_state = 'on_time',
      first_submission_at = NOW()
    WHERE id = NEW.case_id;
    
    -- Log specific form submission event
    INSERT INTO events (
      actor_user_id,
      actor_role,
      action_type,
      target_type,
      target_id,
      payload
    )
    VALUES (
      auth.uid(),
      (auth.jwt() -> 'app_metadata' ->> 'role'),
      'form_submitted',
      'case',
      NEW.case_id,
      jsonb_build_object(
        'form_id', NEW.id,
        'submission_timestamp', NEW.submitted_at
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_case_on_form_submission IS 'Transitions case status and logs form_submitted event';

