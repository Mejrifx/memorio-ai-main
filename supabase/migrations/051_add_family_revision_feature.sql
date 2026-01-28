-- Family Revision Request Feature
-- Allows families to request ONE revision on their delivered video tribute
-- Tracks revision source (QC vs Family) and stores family feedback notes

-- ============================================================================
-- STEP 1: Add 'family_revision_requested' status to cases table
-- ============================================================================

-- Drop existing constraint
ALTER TABLE cases DROP CONSTRAINT IF EXISTS cases_status_check;

-- Recreate with new 'family_revision_requested' status
ALTER TABLE cases ADD CONSTRAINT cases_status_check 
  CHECK (status IN (
    'created',                    -- Director created case
    'waiting_on_family',          -- Family member invited
    'intake_in_progress',         -- Family is filling form
    'submitted',                  -- Form submitted, AI processing
    'in_production',              -- Editor assigned, creating video
    'awaiting_review',            -- Video submitted to QC
    'revision_requested',         -- QC requested changes from editor
    'family_revision_requested',  -- Family requested changes from editor
    'delivered',                  -- QC approved, family can view
    'closed'                      -- Case archived
  ));

COMMENT ON CONSTRAINT cases_status_check ON cases IS 
  'Workflow status tracking from case creation to delivery. family_revision_requested = family used their ONE revision request.';

-- ============================================================================
-- STEP 2: Add columns to video_submissions table
-- ============================================================================

-- Add family revision notes column (stores family's feedback)
ALTER TABLE video_submissions 
ADD COLUMN IF NOT EXISTS family_revision_notes TEXT;

COMMENT ON COLUMN video_submissions.family_revision_notes IS 
  'Notes from family when they request a revision on their delivered video. Only one revision allowed per family.';

-- Add revision source column (tracks who requested the revision)
ALTER TABLE video_submissions 
ADD COLUMN IF NOT EXISTS revision_source TEXT CHECK (revision_source IN ('qc', 'family'));

COMMENT ON COLUMN video_submissions.revision_source IS 
  'Tracks the source of a revision request: qc = QC reviewer requested changes, family = Family used their one revision request';

-- ============================================================================
-- STEP 3: Create index for performance
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_video_submissions_revision_source 
  ON video_submissions(revision_source) 
  WHERE revision_source IS NOT NULL;

-- ============================================================================
-- STEP 4: Update RLS policies for new columns
-- ============================================================================

-- Family can update their own video submission with revision notes
-- (They can only update family_revision_notes, not other fields)
CREATE POLICY "Families can add revision notes to their case videos"
  ON video_submissions
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = video_submissions.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = video_submissions.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  );

-- ============================================================================
-- VERIFICATION QUERIES (for testing)
-- ============================================================================

-- Verify new status is available
DO $$
BEGIN
  RAISE NOTICE 'Family revision feature migration completed successfully!';
  RAISE NOTICE 'New case status added: family_revision_requested';
  RAISE NOTICE 'New video_submissions columns: family_revision_notes, revision_source';
END $$;
