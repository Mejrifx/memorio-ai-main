-- Memorio Database Schema - Initial Migration
-- Version: 1.0.0
-- Description: Core tables for multi-tenant funeral home SaaS platform

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLE 1: Organizations (Funeral Homes)
-- ============================================================================
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  contact_email TEXT NOT NULL,
  contact_phone TEXT,
  region TEXT,
  branding_metadata JSONB DEFAULT '{}'::jsonb,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'archived')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE organizations IS 'Funeral homes using the Memorio platform';
COMMENT ON COLUMN organizations.branding_metadata IS 'JSON object containing logo URLs, color schemes, etc.';

-- ============================================================================
-- TABLE 2: Users (All Roles)
-- ============================================================================
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'director', 'family', 'editor', 'support')),
  org_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('invited', 'active', 'suspended', 'archived')),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_login_at TIMESTAMPTZ
);

COMMENT ON TABLE users IS 'All user accounts across all roles';
COMMENT ON COLUMN users.role IS 'admin: global access, director: org-scoped, family: case-scoped, editor: assignment-scoped';
COMMENT ON COLUMN users.metadata IS 'Extended profile data: name, phone, preferences, etc.';

-- ============================================================================
-- TABLE 3: Cases (Deceased Individuals)
-- ============================================================================
CREATE TABLE cases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  deceased_name TEXT NOT NULL,
  created_by UUID NOT NULL REFERENCES users(id),
  assigned_family_user_id UUID REFERENCES users(id),
  status TEXT DEFAULT 'created' CHECK (status IN (
    'created', 
    'waiting_on_family', 
    'intake_in_progress', 
    'submitted', 
    'in_production', 
    'awaiting_review', 
    'delivered', 
    'closed'
  )),
  sla_start_at TIMESTAMPTZ,
  sla_state TEXT CHECK (sla_state IN ('on_time', 'warning', 'breach')),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE cases IS 'Individual cases for obituary/tribute creation';
COMMENT ON COLUMN cases.status IS 'Workflow state tracking';
COMMENT ON COLUMN cases.sla_start_at IS 'When the SLA clock started (usually on family submission)';
COMMENT ON COLUMN cases.metadata IS 'Additional case data: service date, special notes, etc.';

-- ============================================================================
-- TABLE 4: Forms (Intake Data)
-- ============================================================================
CREATE TABLE forms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  json_schema_version TEXT NOT NULL DEFAULT 'v1',
  draft_json JSONB,
  submitted_json JSONB,
  submitted_at TIMESTAMPTZ,
  immutable_version_history JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE forms IS 'Family intake form data - stores all form submissions';
COMMENT ON COLUMN forms.draft_json IS 'In-progress form data (autosave)';
COMMENT ON COLUMN forms.submitted_json IS 'Final submitted form data (immutable after submission)';
COMMENT ON COLUMN forms.immutable_version_history IS 'Array of previous versions with timestamps';

-- ============================================================================
-- TABLE 5: Assets (Images/Videos)
-- ============================================================================
CREATE TABLE assets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  uploader_user_id UUID NOT NULL REFERENCES users(id),
  file_key TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  size_bytes BIGINT NOT NULL,
  dedupe_hash TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'::jsonb
);

COMMENT ON TABLE assets IS 'Media files uploaded by families (photos, videos)';
COMMENT ON COLUMN assets.file_key IS 'Path/key in Supabase Storage bucket';
COMMENT ON COLUMN assets.dedupe_hash IS 'SHA-256 hash for duplicate detection';
COMMENT ON COLUMN assets.metadata IS 'EXIF data, original filename, etc.';

-- ============================================================================
-- TABLE 6: Editor Assignments
-- ============================================================================
CREATE TABLE editor_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  editor_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assigned_by UUID NOT NULL REFERENCES users(id),
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  unassigned_at TIMESTAMPTZ,
  UNIQUE(case_id, editor_user_id, assigned_at)
);

COMMENT ON TABLE editor_assignments IS 'Tracks which editors are assigned to which cases';
COMMENT ON COLUMN editor_assignments.unassigned_at IS 'NULL = still assigned, timestamp = unassignment time';

-- ============================================================================
-- TABLE 7: Audit Events
-- ============================================================================
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_user_id UUID REFERENCES users(id),
  actor_role TEXT,
  action_type TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id UUID,
  payload JSONB DEFAULT '{}'::jsonb,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE events IS 'Immutable audit log of all significant actions';
COMMENT ON COLUMN events.action_type IS 'INSERT, UPDATE, DELETE, or custom action names';
COMMENT ON COLUMN events.target_type IS 'Table name or resource type';
COMMENT ON COLUMN events.payload IS 'Full context of the action (old/new values, etc.)';

-- ============================================================================
-- TABLE 8: Notifications
-- ============================================================================
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID REFERENCES cases(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  recipients JSONB NOT NULL,
  sent_at TIMESTAMPTZ,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE notifications IS 'Email/SMS notification queue and delivery tracking';
COMMENT ON COLUMN notifications.recipients IS 'Array of email addresses or phone numbers';
COMMENT ON COLUMN notifications.event_type IS 'case_created, form_submitted, delivery_ready, etc.';

-- ============================================================================
-- TABLE 9: Exports
-- ============================================================================
CREATE TABLE exports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID REFERENCES cases(id),
  org_id UUID REFERENCES organizations(id),
  export_type TEXT NOT NULL CHECK (export_type IN ('csv', 'zip', 'pdf')),
  file_url TEXT,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

COMMENT ON TABLE exports IS 'Bulk data exports and report generation';
COMMENT ON COLUMN exports.file_url IS 'Signed URL to download the export file';
COMMENT ON COLUMN exports.expires_at IS 'When the download link expires (security)';

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Users table indexes
CREATE INDEX idx_users_org_id ON users(org_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_email ON users(email);

-- Cases table indexes
CREATE INDEX idx_cases_org_id ON cases(org_id);
CREATE INDEX idx_cases_status ON cases(status);
CREATE INDEX idx_cases_assigned_family ON cases(assigned_family_user_id);
CREATE INDEX idx_cases_created_by ON cases(created_by);
CREATE INDEX idx_cases_created_at ON cases(created_at DESC);

-- Forms table indexes
CREATE INDEX idx_forms_case_id ON forms(case_id);
CREATE INDEX idx_forms_submitted_at ON forms(submitted_at DESC);

-- Assets table indexes
CREATE INDEX idx_assets_case_id ON assets(case_id);
CREATE INDEX idx_assets_uploader ON assets(uploader_user_id);
CREATE INDEX idx_assets_dedupe_hash ON assets(dedupe_hash);

-- Editor assignments indexes
CREATE INDEX idx_editor_assignments_case_id ON editor_assignments(case_id);
CREATE INDEX idx_editor_assignments_editor ON editor_assignments(editor_user_id);
CREATE INDEX idx_editor_assignments_active ON editor_assignments(case_id, editor_user_id) 
  WHERE unassigned_at IS NULL;

-- Events table indexes
CREATE INDEX idx_events_target ON events(target_type, target_id);
CREATE INDEX idx_events_actor ON events(actor_user_id);
CREATE INDEX idx_events_timestamp ON events(timestamp DESC);

-- Notifications table indexes
CREATE INDEX idx_notifications_case_id ON notifications(case_id);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- Exports table indexes
CREATE INDEX idx_exports_case_id ON exports(case_id);
CREATE INDEX idx_exports_org_id ON exports(org_id);
CREATE INDEX idx_exports_created_by ON exports(created_by);
CREATE INDEX idx_exports_created_at ON exports(created_at DESC);

-- ============================================================================
-- COMPLETION
-- ============================================================================
COMMENT ON SCHEMA public IS 'Memorio database schema v1.0.0 - Initial migration completed';

