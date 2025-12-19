-- Migration 020: Add SLA tracking and case notes
-- This migration adds SLA (Service Level Agreement) tracking fields to cases
-- and creates a case_notes table for internal collaboration

-- ============================================================================
-- 1. Add SLA fields to cases table
-- ============================================================================

-- Add first_submission_at timestamp (when SLA clock starts)
ALTER TABLE cases 
ADD COLUMN IF NOT EXISTS first_submission_at TIMESTAMPTZ;

-- Add sla_hours_elapsed for quick filtering/sorting
ALTER TABLE cases 
ADD COLUMN IF NOT EXISTS sla_hours_elapsed NUMERIC(10,2);

-- Update sla_state constraint to include new states
ALTER TABLE cases 
DROP CONSTRAINT IF EXISTS cases_sla_state_check;

ALTER TABLE cases 
ADD CONSTRAINT cases_sla_state_check 
CHECK (sla_state IN ('on_time', 'warning', 'breach', 'green', 'yellow', 'orange', 'red'));

-- Create index for SLA queries
CREATE INDEX IF NOT EXISTS idx_cases_sla_state ON cases(sla_state);
CREATE INDEX IF NOT EXISTS idx_cases_first_submission ON cases(first_submission_at);

-- ============================================================================
-- 2. Create case_notes table for collaboration
-- ============================================================================

CREATE TABLE IF NOT EXISTS case_notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  author_user_id UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  note_type TEXT NOT NULL DEFAULT 'general' CHECK (note_type IN ('general', 'support', 'revision', 'internal')),
  content TEXT NOT NULL,
  is_pinned BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for case_notes
CREATE INDEX IF NOT EXISTS idx_case_notes_case_id ON case_notes(case_id);
CREATE INDEX IF NOT EXISTS idx_case_notes_author ON case_notes(author_user_id);
CREATE INDEX IF NOT EXISTS idx_case_notes_created ON case_notes(created_at DESC);

-- Enable RLS on case_notes
ALTER TABLE case_notes ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 3. RLS Policies for case_notes
-- ============================================================================

-- Admins: Full access
CREATE POLICY "Admins full access to case_notes"
  ON case_notes FOR ALL
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );

-- Directors: Access notes for cases in their organization
CREATE POLICY "Directors access case_notes in their org"
  ON case_notes FOR ALL
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'director' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = case_notes.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

-- Editors: Read/write notes for their assigned cases
CREATE POLICY "Editors access notes for assigned cases"
  ON case_notes FOR ALL
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'editor' AND
    EXISTS (
      SELECT 1 FROM editor_assignments
      WHERE editor_assignments.case_id = case_notes.case_id
      AND editor_assignments.editor_user_id = auth.uid()
      AND editor_assignments.unassigned_at IS NULL
    )
  );

-- QC: Read/write notes for cases in their organization
CREATE POLICY "QC access case_notes in their org"
  ON case_notes FOR ALL
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'qc' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = case_notes.case_id
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

-- Family: Read notes for their assigned case (optional - can be restricted)
CREATE POLICY "Family read case_notes for their case"
  ON case_notes FOR SELECT
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'family' AND
    note_type != 'internal' AND -- Hide internal notes from families
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = case_notes.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  );

-- ============================================================================
-- 4. Function to calculate and update SLA status
-- ============================================================================

CREATE OR REPLACE FUNCTION update_case_sla()
RETURNS TRIGGER AS $$
BEGIN
  -- Only calculate SLA if first_submission_at is set
  IF NEW.first_submission_at IS NOT NULL THEN
    -- Calculate hours elapsed since submission
    NEW.sla_hours_elapsed := EXTRACT(EPOCH FROM (NOW() - NEW.first_submission_at)) / 3600;
    
    -- Update sla_state based on hours elapsed
    IF NEW.sla_hours_elapsed < 24 THEN
      NEW.sla_state := 'green';
    ELSIF NEW.sla_hours_elapsed >= 24 AND NEW.sla_hours_elapsed < 36 THEN
      NEW.sla_state := 'yellow';
    ELSIF NEW.sla_hours_elapsed >= 36 AND NEW.sla_hours_elapsed < 48 THEN
      NEW.sla_state := 'orange';
    ELSE
      NEW.sla_state := 'red';
    END IF;
  ELSE
    -- No submission yet, no SLA tracking
    NEW.sla_hours_elapsed := NULL;
    NEW.sla_state := NULL;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update SLA on insert/update
DROP TRIGGER IF EXISTS trigger_update_case_sla ON cases;
CREATE TRIGGER trigger_update_case_sla
  BEFORE INSERT OR UPDATE ON cases
  FOR EACH ROW
  EXECUTE FUNCTION update_case_sla();

-- ============================================================================
-- 5. Auto-update updated_at for case_notes
-- ============================================================================

DROP TRIGGER IF EXISTS update_case_notes_updated_at ON case_notes;
CREATE TRIGGER update_case_notes_updated_at
  BEFORE UPDATE ON case_notes
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 6. Backfill first_submission_at for existing cases
-- ============================================================================

-- Set first_submission_at from forms.submitted_at for cases that have submitted forms
UPDATE cases
SET first_submission_at = (
  SELECT forms.submitted_at 
  FROM forms 
  WHERE forms.case_id = cases.id 
  AND forms.submitted_at IS NOT NULL
  ORDER BY forms.submitted_at ASC
  LIMIT 1
)
WHERE first_submission_at IS NULL
AND EXISTS (
  SELECT 1 FROM forms 
  WHERE forms.case_id = cases.id 
  AND forms.submitted_at IS NOT NULL
);

-- ============================================================================
-- 7. Create view for case analytics (for quick stats)
-- ============================================================================

CREATE OR REPLACE VIEW case_analytics AS
SELECT 
  c.org_id,
  o.name as org_name,
  COUNT(*) FILTER (WHERE c.status IN ('waiting_on_family', 'intake_in_progress', 'submitted', 'in_production', 'awaiting_review')) as active_cases,
  COUNT(*) FILTER (WHERE c.created_at >= NOW() - INTERVAL '30 days') as cases_last_30_days,
  COUNT(*) FILTER (WHERE c.sla_state IN ('green', 'yellow') AND c.status NOT IN ('delivered', 'closed')) as on_time_cases,
  COUNT(*) FILTER (WHERE c.sla_state IN ('orange', 'red') AND c.status NOT IN ('delivered', 'closed')) as breach_cases,
  ROUND(
    (COUNT(*) FILTER (WHERE c.sla_state IN ('green', 'yellow') AND c.status NOT IN ('delivered', 'closed'))::NUMERIC / 
    NULLIF(COUNT(*) FILTER (WHERE c.status NOT IN ('delivered', 'closed')), 0)) * 100, 
    1
  ) as sla_percentage
FROM cases c
JOIN organizations o ON c.org_id = o.id
GROUP BY c.org_id, o.name;

-- Grant access to view
GRANT SELECT ON case_analytics TO authenticated;

COMMENT ON VIEW case_analytics IS 'Provides quick analytics per organization for SLA monitoring';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Summary:
-- ✅ Added SLA tracking fields to cases (first_submission_at, sla_hours_elapsed, sla_state)
-- ✅ Created case_notes table with RLS policies for all roles
-- ✅ Added automatic SLA calculation trigger
-- ✅ Backfilled existing cases with submission timestamps
-- ✅ Created analytics view for organization stats

