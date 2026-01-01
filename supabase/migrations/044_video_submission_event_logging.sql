-- ============================================================================
-- Migration: 044 - Video Submission Event Logging
-- ============================================================================
-- Purpose: Log specific events for video submissions and QC reviews
-- ============================================================================

-- ============================================================================
-- TRIGGER: Log video submission events
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
    
    -- QC Requested Revision
    ELSIF NEW.qc_status = 'revision' THEN
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

COMMENT ON FUNCTION log_video_submission_events IS 'Logs specific events for video submissions and QC reviews';

-- Create trigger
DROP TRIGGER IF EXISTS video_submission_events ON video_submissions;
CREATE TRIGGER video_submission_events
  AFTER INSERT OR UPDATE ON video_submissions
  FOR EACH ROW
  EXECUTE FUNCTION log_video_submission_events();

-- ============================================================================
-- COMPLETION
-- ============================================================================
COMMENT ON SCHEMA public IS 'Memorio video submission event logging v1.0.0 - Migration 044 complete';

