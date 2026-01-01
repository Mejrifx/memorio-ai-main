-- ============================================================================
-- Migration: 042 - Enhance Timeline Events with Detailed Descriptions
-- ============================================================================
-- Purpose: Improve the audit trail by capturing specific action details
-- instead of generic "Case updated" messages
--
-- What this fixes:
-- Before: "Case updated By: authenticated" (not descriptive)
-- After: "Status changed from 'created' to 'submitted' By: John Doe (family)"
-- ============================================================================

-- ============================================================================
-- FUNCTION: Enhanced audit logging with specific action details
-- ============================================================================
CREATE OR REPLACE FUNCTION log_enhanced_audit_event()
RETURNS TRIGGER AS $$
DECLARE
  old_data JSONB;
  new_data JSONB;
  action_description TEXT;
  changes JSONB := '{}';
BEGIN
  -- Handle DELETE operations (NEW is NULL)
  IF TG_OP = 'DELETE' THEN
    old_data := to_jsonb(OLD);
    new_data := NULL;
    action_description := TG_TABLE_NAME || '_deleted';
    
  -- Handle INSERT operations (OLD is NULL)
  ELSIF TG_OP = 'INSERT' THEN
    old_data := NULL;
    new_data := to_jsonb(NEW);
    action_description := TG_TABLE_NAME || '_created';
    
  -- Handle UPDATE operations (both exist) - detect specific changes
  ELSE
    old_data := to_jsonb(OLD);
    new_data := to_jsonb(NEW);
    
    -- For CASES table, detect what specifically changed
    IF TG_TABLE_NAME = 'cases' THEN
      -- Status change
      IF OLD.status IS DISTINCT FROM NEW.status THEN
        action_description := 'status_changed';
        changes := changes || jsonb_build_object(
          'field', 'status',
          'from', OLD.status,
          'to', NEW.status
        );
      
      -- Family assignment
      ELSIF OLD.assigned_family_user_id IS DISTINCT FROM NEW.assigned_family_user_id THEN
        action_description := 'family_assigned';
        changes := changes || jsonb_build_object(
          'field', 'assigned_family_user_id',
          'from', OLD.assigned_family_user_id,
          'to', NEW.assigned_family_user_id
        );
      
      -- SLA changes
      ELSIF OLD.sla_state IS DISTINCT FROM NEW.sla_state THEN
        action_description := 'sla_updated';
        changes := changes || jsonb_build_object(
          'field', 'sla_state',
          'from', OLD.sla_state,
          'to', NEW.sla_state
        );
      
      -- Generic case update
      ELSE
        action_description := 'case_updated';
      END IF;
    
    -- For FORMS table
    ELSIF TG_TABLE_NAME = 'forms' THEN
      -- Form submission
      IF OLD.submitted_json IS NULL AND NEW.submitted_json IS NOT NULL THEN
        action_description := 'form_submitted';
        changes := changes || jsonb_build_object(
          'field', 'submitted_json',
          'submitted', true
        );
      
      -- Draft update
      ELSIF OLD.draft_json IS DISTINCT FROM NEW.draft_json THEN
        action_description := 'form_draft_updated';
      
      ELSE
        action_description := 'form_updated';
      END IF;
    
    -- For EDITOR_ASSIGNMENTS table
    ELSIF TG_TABLE_NAME = 'editor_assignments' THEN
      IF OLD.unassigned_at IS NULL AND NEW.unassigned_at IS NOT NULL THEN
        action_description := 'editor_unassigned';
      ELSE
        action_description := 'editor_updated';
      END IF;
    
    -- Generic update for other tables
    ELSE
      action_description := TG_TABLE_NAME || '_updated';
    END IF;
  END IF;

  -- Insert enhanced audit event
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
    (auth.jwt() -> 'app_metadata' ->> 'role'), -- Use app_metadata path
    action_description,
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    jsonb_build_object(
      'old', old_data,
      'new', new_data,
      'table', TG_TABLE_NAME,
      'operation', TG_OP,
      'changes', changes
    )
  );

  -- Return appropriate row based on operation
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION log_enhanced_audit_event IS 'Creates detailed audit trail with specific action descriptions';

-- ============================================================================
-- REPLACE EXISTING TRIGGERS WITH ENHANCED VERSION
-- ============================================================================

-- Cases table
DROP TRIGGER IF EXISTS audit_cases_changes ON cases;
CREATE TRIGGER audit_cases_changes
  AFTER INSERT OR UPDATE OR DELETE ON cases
  FOR EACH ROW
  EXECUTE FUNCTION log_enhanced_audit_event();

-- Forms table
DROP TRIGGER IF EXISTS audit_forms_changes ON forms;
CREATE TRIGGER audit_forms_changes
  AFTER INSERT OR UPDATE OR DELETE ON forms
  FOR EACH ROW
  EXECUTE FUNCTION log_enhanced_audit_event();

-- Editor assignments table
DROP TRIGGER IF EXISTS audit_editor_assignments_changes ON editor_assignments;
CREATE TRIGGER audit_editor_assignments_changes
  AFTER INSERT OR UPDATE OR DELETE ON editor_assignments
  FOR EACH ROW
  EXECUTE FUNCTION log_enhanced_audit_event();

-- ============================================================================
-- HELPER FUNCTION: Get human-readable event description
-- ============================================================================
CREATE OR REPLACE FUNCTION get_event_description(
  action_type TEXT,
  payload JSONB,
  actor_role TEXT
)
RETURNS TEXT AS $$
DECLARE
  description TEXT;
  changes JSONB;
BEGIN
  changes := payload -> 'changes';
  
  CASE action_type
    WHEN 'cases_created' THEN
      description := 'Case created';
    
    WHEN 'status_changed' THEN
      description := format(
        'Status changed from "%s" to "%s"',
        changes ->> 'from',
        changes ->> 'to'
      );
    
    WHEN 'family_assigned' THEN
      description := 'Family member assigned to case';
    
    WHEN 'form_submitted' THEN
      description := 'Intake form submitted by family';
    
    WHEN 'form_draft_updated' THEN
      description := 'Form draft saved';
    
    WHEN 'editor_assigned' THEN
      description := 'Editor assigned to case';
    
    WHEN 'editor_unassigned' THEN
      description := 'Editor unassigned from case';
    
    WHEN 'editor_reassigned' THEN
      description := 'Editor reassigned';
    
    WHEN 'sla_updated' THEN
      description := format(
        'SLA status changed to %s',
        changes ->> 'to'
      );
    
    WHEN 'AUTO_ASSIGN_EDITOR' THEN
      description := 'Editor automatically assigned';
    
    WHEN 'CREATE_CASE' THEN
      description := 'Case created';
    
    WHEN 'qc_reassigned' THEN
      description := 'QC reviewer reassigned';
    
    WHEN 'pushed_to_revision' THEN
      description := 'Case pushed to revision';
    
    WHEN 'link_regenerated' THEN
      description := 'Family login link regenerated';
    
    WHEN 'link_resent' THEN
      description := 'Family login link resent';
    
    WHEN 'note_added' THEN
      description := 'Note added to case';
    
    WHEN 'case_updated' THEN
      description := 'Case details updated';
    
    WHEN 'form_updated' THEN
      description := 'Form updated';
    
    ELSE
      -- Default: Clean up the action_type
      description := replace(replace(action_type, '_', ' '), 'INSERT', 'Created');
      description := replace(description, 'UPDATE', 'Updated');
      description := replace(description, 'DELETE', 'Deleted');
      description := initcap(description);
  END CASE;
  
  RETURN description;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION get_event_description IS 'Converts action_type into human-readable description';

-- ============================================================================
-- VIEW: Enhanced timeline view with actor details
-- ============================================================================
CREATE OR REPLACE VIEW timeline_view AS
SELECT 
  e.id,
  e.timestamp,
  e.action_type,
  e.target_type,
  e.target_id,
  e.actor_role,
  e.payload,
  get_event_description(e.action_type, e.payload, e.actor_role) as description,
  u.email as actor_email,
  u.metadata->>'name' as actor_name
FROM events e
LEFT JOIN users u ON e.actor_user_id = u.id
ORDER BY e.timestamp DESC;

COMMENT ON VIEW timeline_view IS 'Enhanced timeline with human-readable descriptions and actor details';

-- Grant access to authenticated users
GRANT SELECT ON timeline_view TO authenticated;

-- ============================================================================
-- COMPLETION
-- ============================================================================
COMMENT ON SCHEMA public IS 'Memorio enhanced timeline events v1.0.0 - Migration 042 complete';

