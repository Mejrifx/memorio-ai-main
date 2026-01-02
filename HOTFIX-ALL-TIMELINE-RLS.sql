-- ============================================================================
-- HOTFIX: Apply All Security Fixes for Timeline Migrations
-- ============================================================================
-- This fixes RLS errors for form submissions and video/QC events
-- Run this to restore full functionality
-- ============================================================================

-- Fix 1: Form submission function
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fix 2: Video submission events function
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

-- ============================================================================
-- Verify the fixes
-- ============================================================================
SELECT 
  proname as function_name,
  prosecdef as is_security_definer,
  CASE 
    WHEN prosecdef THEN '✅ FIXED'
    ELSE '❌ STILL BROKEN'
  END as status
FROM pg_proc 
WHERE proname IN ('update_case_on_form_submission', 'log_video_submission_events')
ORDER BY proname;

-- Expected output:
-- Both functions should show is_security_definer = true and status = '✅ FIXED'

