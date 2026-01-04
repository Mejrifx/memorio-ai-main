-- ============================================================================
-- Migration: 045 - Fix QC Revision Event Trigger
-- ============================================================================
-- Purpose: Fix the qc_status value check in log_video_submission_events()
--          to match the actual column constraint value 'revision_requested'
--          instead of incorrect 'revision'
-- ============================================================================

-- Bug: The trigger was checking for qc_status = 'revision', but the actual
--      valid value in the database constraint is 'revision_requested'
--      This caused the qc_revision event (with notes) to NEVER be logged!

-- ============================================================================
-- FIX: Update the trigger function to check for correct status value
-- ============================================================================

CREATE OR REPLACE FUNCTION log_video_submission_events()
RETURNS TRIGGER AS $$
DECLARE
  case_deceased_name TEXT;
  editor_email TEXT;
  qc_email TEXT;
BEGIN
  -- Get case info
  SELECT deceased_name INTO case_deceased_name
  FROM cases
  WHERE id = NEW.case_id;
  
  -- Get editor info
  SELECT email INTO editor_email
  FROM users
  WHERE id = NEW.editor_user_id;
  
  -- INSERT: Video submitted to QC
  IF TG_OP = 'INSERT' THEN
    INSERT INTO events (
      actor_user_id,
      actor_role,
      action_type,
      target_type,
      target_id,
      payload
    )
    VALUES (
      NEW.editor_user_id,
      'editor',
      'video_submitted',
      'case',
      NEW.case_id,
      jsonb_build_object(
        'submission_id', NEW.id,
        'editor_email', editor_email,
        'deceased_name', case_deceased_name,
        'revision_number', NEW.revision_number,
        'editor_notes', NEW.editor_notes
      )
    );
    
  -- UPDATE: QC review completed
  ELSIF TG_OP = 'UPDATE' AND OLD.qc_status IS DISTINCT FROM NEW.qc_status THEN
    
    -- Get QC reviewer info
    IF NEW.qc_reviewer_id IS NOT NULL THEN
      SELECT email INTO qc_email
      FROM users
      WHERE id = NEW.qc_reviewer_id;
    END IF;
    
    -- QC Approved
    IF NEW.qc_status = 'approved' THEN
      INSERT INTO events (
        actor_user_id,
        actor_role,
        action_type,
        target_type,
        target_id,
        payload
      )
      VALUES (
        NEW.qc_reviewer_id,
        'qc',
        'qc_approved',
        'case',
        NEW.case_id,
        jsonb_build_object(
          'submission_id', NEW.id,
          'qc_reviewer_email', qc_email,
          'deceased_name', case_deceased_name,
          'qc_notes', NEW.qc_notes
        )
      );
    
    -- QC Requested Revision (FIXED: was 'revision', now 'revision_requested')
    ELSIF NEW.qc_status = 'revision_requested' THEN
      INSERT INTO events (
        actor_user_id,
        actor_role,
        action_type,
        target_type,
        target_id,
        payload
      )
      VALUES (
        NEW.qc_reviewer_id,
        'qc',
        'qc_revision',
        'case',
        NEW.case_id,
        jsonb_build_object(
          'submission_id', NEW.id,
          'qc_reviewer_email', qc_email,
          'deceased_name', case_deceased_name,
          'qc_notes', NEW.qc_notes
        )
      );
    
    -- QC Rejected
    ELSIF NEW.qc_status = 'rejected' THEN
      INSERT INTO events (
        actor_user_id,
        actor_role,
        action_type,
        target_type,
        target_id,
        payload
      )
      VALUES (
        NEW.qc_reviewer_id,
        'qc',
        'qc_rejected',
        'case',
        NEW.case_id,
        jsonb_build_object(
          'submission_id', NEW.id,
          'qc_reviewer_email', qc_email,
          'deceased_name', case_deceased_name,
          'qc_notes', NEW.qc_notes
        )
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION log_video_submission_events IS 'Logs specific events for video submissions and QC reviews - FIXED qc_status check';

-- ============================================================================
-- VERIFICATION QUERY
-- ============================================================================
-- Run this after applying the migration to verify it worked:
-- 
-- SELECT routine_name, routine_definition
-- FROM information_schema.routines
-- WHERE routine_name = 'log_video_submission_events'
-- AND routine_definition LIKE '%revision_requested%';
-- 
-- Should return the function definition containing 'revision_requested'
-- ============================================================================

