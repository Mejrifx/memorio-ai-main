-- Memorio Quality Control System - Database Schema
-- Version: 1.0.0
-- Description: Add QC role, video submissions, and obituary content tables

-- ============================================================================
-- STEP 1: Update Users Table to Add 'qc' Role
-- ============================================================================

-- Drop existing constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;

-- Recreate with 'qc' role added
ALTER TABLE users ADD CONSTRAINT users_role_check 
  CHECK (role IN ('admin', 'director', 'family', 'editor', 'support', 'qc'));

COMMENT ON CONSTRAINT users_role_check ON users IS 
  'Valid roles: admin (global), director (org-scoped), family (case-scoped), editor (assignment-scoped), support (read-only), qc (org-scoped quality control)';

-- ============================================================================
-- STEP 2: Update Cases Table Status to Add 'revision_requested'
-- ============================================================================

-- Drop existing constraint
ALTER TABLE cases DROP CONSTRAINT IF EXISTS cases_status_check;

-- Recreate with 'revision_requested' status added
ALTER TABLE cases ADD CONSTRAINT cases_status_check 
  CHECK (status IN (
    'created',              -- Director created case
    'waiting_on_family',    -- Family member invited
    'intake_in_progress',   -- Family is filling form
    'submitted',            -- Form submitted, AI processing
    'in_production',        -- Editor assigned, creating video
    'awaiting_review',      -- Video submitted to QC
    'revision_requested',   -- QC requested changes from editor
    'delivered',            -- QC approved, family can view
    'closed'                -- Case archived
  ));

COMMENT ON CONSTRAINT cases_status_check ON cases IS 
  'Workflow status tracking from case creation to delivery';

-- ============================================================================
-- STEP 3: Create Video Submissions Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS video_submissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  editor_user_id UUID NOT NULL REFERENCES users(id),
  
  -- Video file details
  video_url TEXT NOT NULL,              -- Full Supabase Storage public URL
  thumbnail_url TEXT,                   -- Video thumbnail (optional)
  duration_seconds INT,                 -- Video length in seconds
  file_size_bytes BIGINT NOT NULL,      -- File size for tracking
  mime_type TEXT DEFAULT 'video/mp4',   -- Video format
  
  -- Submission metadata
  editor_notes TEXT,                    -- Notes from editor to QC
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- QC Review fields
  qc_reviewer_id UUID REFERENCES users(id),
  qc_status TEXT DEFAULT 'pending' CHECK (qc_status IN (
    'pending',              -- Awaiting QC review
    'in_review',            -- QC is actively reviewing
    'approved',             -- QC approved, ready for family
    'revision_requested',   -- Needs changes from editor
    'rejected'              -- Rejected (escalate to admin)
  )),
  qc_notes TEXT,                        -- Feedback from QC reviewer
  qc_reviewed_at TIMESTAMPTZ,           -- When QC completed review
  
  -- Revision tracking
  revision_number INT DEFAULT 1,        -- Track resubmission count
  previous_submission_id UUID REFERENCES video_submissions(id),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE video_submissions IS 'Memorial tribute videos submitted by editors for QC review';
COMMENT ON COLUMN video_submissions.video_url IS 'Full public URL from Supabase Storage bucket';
COMMENT ON COLUMN video_submissions.qc_status IS 'Current status in QC workflow';
COMMENT ON COLUMN video_submissions.revision_number IS 'Incremented each time editor resubmits after revision request';
COMMENT ON COLUMN video_submissions.previous_submission_id IS 'Links to previous submission if this is a revision';

-- ============================================================================
-- STEP 4: Create Obituary Content Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS obituary_content (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE UNIQUE,
  
  -- Content in multiple formats
  content_html TEXT NOT NULL,           -- Formatted obituary HTML
  content_plain TEXT NOT NULL,          -- Plain text version
  
  -- Metadata
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  generated_by TEXT DEFAULT 'AI',       -- 'AI' or user_id if manually edited
  approved_by UUID REFERENCES users(id),
  approved_at TIMESTAMPTZ,
  version INT DEFAULT 1,                -- Track version history
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE obituary_content IS 'AI-generated obituary text for each case';
COMMENT ON COLUMN obituary_content.content_html IS 'Formatted HTML for display on family portal';
COMMENT ON COLUMN obituary_content.content_plain IS 'Plain text version for emails/exports';
COMMENT ON COLUMN obituary_content.generated_by IS 'Indicates if AI-generated or manually edited';

-- ============================================================================
-- STEP 5: Create Indexes for Performance
-- ============================================================================

-- Video submissions indexes
CREATE INDEX IF NOT EXISTS idx_video_submissions_case 
  ON video_submissions(case_id);

CREATE INDEX IF NOT EXISTS idx_video_submissions_editor 
  ON video_submissions(editor_user_id);

CREATE INDEX IF NOT EXISTS idx_video_submissions_qc_status 
  ON video_submissions(qc_status);

CREATE INDEX IF NOT EXISTS idx_video_submissions_reviewer 
  ON video_submissions(qc_reviewer_id);

CREATE INDEX IF NOT EXISTS idx_video_submissions_pending 
  ON video_submissions(case_id, qc_status) 
  WHERE qc_status IN ('pending', 'in_review');

CREATE INDEX IF NOT EXISTS idx_video_submissions_created_at 
  ON video_submissions(created_at DESC);

-- Obituary content indexes
CREATE INDEX IF NOT EXISTS idx_obituary_content_case 
  ON obituary_content(case_id);

-- ============================================================================
-- STEP 6: Create Trigger for Auto-updating updated_at
-- ============================================================================

-- Video submissions auto-update trigger
CREATE TRIGGER update_video_submissions_updated_at
  BEFORE UPDATE ON video_submissions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Obituary content auto-update trigger
CREATE TRIGGER update_obituary_content_updated_at
  BEFORE UPDATE ON obituary_content
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- STEP 7: Enable Row Level Security
-- ============================================================================

ALTER TABLE video_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE obituary_content ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- COMPLETION
-- ============================================================================

COMMENT ON SCHEMA public IS 'Memorio database schema - Migration 018: QC System added successfully';

