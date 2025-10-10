-- Memorio Database Functions & Triggers
-- Version: 1.0.0
-- Description: Automated audit logging and timestamp management

-- ============================================================================
-- FUNCTION: Auto-update updated_at timestamp
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_updated_at_column IS 'Automatically updates the updated_at column on row updates';

-- ============================================================================
-- FUNCTION: Log audit events
-- ============================================================================
CREATE OR REPLACE FUNCTION log_audit_event()
RETURNS TRIGGER AS $$
DECLARE
  old_data JSONB;
  new_data JSONB;
BEGIN
  -- Handle DELETE operations (NEW is NULL)
  IF TG_OP = 'DELETE' THEN
    old_data := to_jsonb(OLD);
    new_data := NULL;
  -- Handle INSERT operations (OLD is NULL)
  ELSIF TG_OP = 'INSERT' THEN
    old_data := NULL;
    new_data := to_jsonb(NEW);
  -- Handle UPDATE operations (both exist)
  ELSE
    old_data := to_jsonb(OLD);
    new_data := to_jsonb(NEW);
  END IF;

  -- Insert audit event
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
    auth.jwt() ->> 'role',
    TG_OP,
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    jsonb_build_object(
      'old', old_data,
      'new', new_data,
      'table', TG_TABLE_NAME,
      'operation', TG_OP
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

COMMENT ON FUNCTION log_audit_event IS 'Creates immutable audit trail of all important table changes';

-- ============================================================================
-- FUNCTION: Update last_login_at on user login
-- ============================================================================
CREATE OR REPLACE FUNCTION update_last_login()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users
  SET last_login_at = NOW()
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION update_last_login IS 'Updates last_login_at timestamp when user authenticates';

-- ============================================================================
-- FUNCTION: Append form submission to version history
-- ============================================================================
CREATE OR REPLACE FUNCTION append_form_version_history()
RETURNS TRIGGER AS $$
BEGIN
  -- Only append if submitted_json was updated
  IF NEW.submitted_json IS NOT NULL AND 
     (OLD.submitted_json IS NULL OR NEW.submitted_json != OLD.submitted_json) THEN
    
    NEW.immutable_version_history := COALESCE(NEW.immutable_version_history, '[]'::jsonb) || 
      jsonb_build_array(
        jsonb_build_object(
          'version', (
            SELECT COALESCE(MAX((version->>'version')::int), 0) + 1
            FROM jsonb_array_elements(COALESCE(OLD.immutable_version_history, '[]'::jsonb)) AS version
          ),
          'submitted_at', NOW(),
          'submitted_by', auth.uid(),
          'data', NEW.submitted_json
        )
      );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION append_form_version_history IS 'Maintains immutable version history of form submissions';

-- ============================================================================
-- FUNCTION: Update case status on form submission
-- ============================================================================
CREATE OR REPLACE FUNCTION update_case_on_form_submission()
RETURNS TRIGGER AS $$
BEGIN
  -- If form is being submitted for the first time
  IF NEW.submitted_json IS NOT NULL AND OLD.submitted_at IS NULL THEN
    UPDATE cases
    SET 
      status = 'submitted',
      sla_start_at = COALESCE(sla_start_at, NOW()),
      sla_state = 'on_time'
    WHERE id = NEW.case_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_case_on_form_submission IS 'Automatically transitions case status when family submits form';

-- ============================================================================
-- TRIGGERS: Apply updated_at automation
-- ============================================================================

CREATE TRIGGER update_organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cases_updated_at
  BEFORE UPDATE ON cases
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_forms_updated_at
  BEFORE UPDATE ON forms
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGERS: Apply audit logging
-- ============================================================================

CREATE TRIGGER audit_organizations_changes
  AFTER INSERT OR UPDATE OR DELETE ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION log_audit_event();

CREATE TRIGGER audit_users_changes
  AFTER INSERT OR UPDATE OR DELETE ON users
  FOR EACH ROW
  EXECUTE FUNCTION log_audit_event();

CREATE TRIGGER audit_cases_changes
  AFTER INSERT OR UPDATE OR DELETE ON cases
  FOR EACH ROW
  EXECUTE FUNCTION log_audit_event();

CREATE TRIGGER audit_forms_changes
  AFTER INSERT OR UPDATE OR DELETE ON forms
  FOR EACH ROW
  EXECUTE FUNCTION log_audit_event();

CREATE TRIGGER audit_editor_assignments_changes
  AFTER INSERT OR UPDATE OR DELETE ON editor_assignments
  FOR EACH ROW
  EXECUTE FUNCTION log_audit_event();

-- ============================================================================
-- TRIGGERS: Form-specific automation
-- ============================================================================

CREATE TRIGGER maintain_form_version_history
  BEFORE UPDATE ON forms
  FOR EACH ROW
  EXECUTE FUNCTION append_form_version_history();

CREATE TRIGGER update_case_on_form_submit
  AFTER UPDATE ON forms
  FOR EACH ROW
  EXECUTE FUNCTION update_case_on_form_submission();

-- ============================================================================
-- TRIGGER: Update last login on auth.users table (Supabase Auth)
-- ============================================================================
-- Note: This trigger is applied to auth.users table if accessible
-- Otherwise, implement via Edge Function on auth webhook

CREATE OR REPLACE FUNCTION handle_auth_user_login()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users
  SET last_login_at = NOW()
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply if auth.users is accessible, otherwise skip
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE schemaname = 'auth' AND tablename = 'users'
  ) THEN
    EXECUTE 'CREATE TRIGGER update_last_login_on_auth
      AFTER UPDATE ON auth.users
      FOR EACH ROW
      WHEN (OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at)
      EXECUTE FUNCTION handle_auth_user_login()';
  END IF;
END $$;

-- ============================================================================
-- COMPLETION
-- ============================================================================
COMMENT ON SCHEMA public IS 'Memorio functions & triggers v1.0.0 - Automation enabled';

