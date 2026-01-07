-- ============================================================================
-- Migration: 048 - Fix SLA Thresholds and Logic
-- ============================================================================
-- Purpose: Fix SLA timer/tracker to show correct status badges on cases
-- ============================================================================

-- PROBLEM:
-- ========
-- 1. Cases created 2+ days ago still showing green "On Time"
-- 2. Frontend has hardcoded SLA badge (always green)
-- 3. Current thresholds use yellow (client wants 4 colors: green/orange/red/black)
-- 4. SLA counting even when case is waiting_on_family or already delivered
--
-- REQUIREMENTS (from client):
-- ===========================
-- START: When family submits the form (first_submission_at)
-- STOP:  When QC approves and delivers to family (status = 'delivered')
-- PAUSE: Should NOT count when status = 'waiting_on_family'
--
-- Thresholds:
--   🟢 Green:  < 24 hours
--   🟠 Orange: 24-36 hours
--   🔴 Red:    36-48 hours
--   ⚫ Black:  48+ hours (BREACH)

-- ============================================================================
-- SOLUTION: Update SLA calculation function
-- ============================================================================

CREATE OR REPLACE FUNCTION update_case_sla()
RETURNS TRIGGER AS $$
BEGIN
  -- Only calculate SLA if first_submission_at is set (family has submitted)
  -- AND case is not yet delivered (still in progress)
  IF NEW.first_submission_at IS NOT NULL 
     AND NEW.status NOT IN ('delivered', 'closed') THEN
    
    -- Calculate hours elapsed since family submission
    NEW.sla_hours_elapsed := EXTRACT(EPOCH FROM (NOW() - NEW.first_submission_at)) / 3600;
    
    -- Update sla_state based on NEW thresholds (4 colors)
    IF NEW.sla_hours_elapsed < 24 THEN
      NEW.sla_state := 'green';       -- On Time: < 24 hours
    ELSIF NEW.sla_hours_elapsed >= 24 AND NEW.sla_hours_elapsed < 36 THEN
      NEW.sla_state := 'orange';      -- Warning: 24-36 hours
    ELSIF NEW.sla_hours_elapsed >= 36 AND NEW.sla_hours_elapsed < 48 THEN
      NEW.sla_state := 'red';         -- Critical: 36-48 hours
    ELSE
      NEW.sla_state := 'black';       -- BREACH: 48+ hours
    END IF;
    
  ELSIF NEW.status IN ('delivered', 'closed') THEN
    -- Case is complete - freeze SLA at final state
    -- Don't update sla_hours_elapsed or sla_state
    -- Keep the values from when it was delivered
    NULL; -- No-op, keep existing values
    
  ELSE
    -- No submission yet (waiting_on_family) - no SLA tracking
    NEW.sla_hours_elapsed := NULL;
    NEW.sla_state := NULL;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Note: Trigger already exists from migration 020, no need to recreate
-- DROP TRIGGER IF EXISTS trigger_update_case_sla ON cases;
-- CREATE TRIGGER trigger_update_case_sla
--   BEFORE INSERT OR UPDATE ON cases
--   FOR EACH ROW
--   EXECUTE FUNCTION update_case_sla();

-- ============================================================================
-- Update constraint to include 'black' as valid sla_state
-- ============================================================================

-- Drop old constraint
ALTER TABLE cases 
DROP CONSTRAINT IF EXISTS cases_sla_state_check;

-- Add new constraint with all valid states
ALTER TABLE cases 
ADD CONSTRAINT cases_sla_state_check 
CHECK (sla_state IN (
  'on_time', 'warning', 'breach',  -- Legacy values
  'green', 'yellow', 'orange', 'red', 'black'  -- New values (including black)
));

-- ============================================================================
-- Backfill: Recalculate SLA for all active cases
-- ============================================================================

-- Force recalculation of SLA for all active cases (not delivered/closed)
-- This updates cases that are currently showing wrong SLA state
UPDATE cases
SET updated_at = NOW()  -- This triggers the update_case_sla() function
WHERE status NOT IN ('delivered', 'closed')
  AND first_submission_at IS NOT NULL;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- 1. Check SLA distribution
-- SELECT 
--   sla_state,
--   COUNT(*) as count,
--   ROUND(AVG(sla_hours_elapsed), 1) as avg_hours
-- FROM cases
-- WHERE first_submission_at IS NOT NULL
-- GROUP BY sla_state
-- ORDER BY 
--   CASE sla_state
--     WHEN 'green' THEN 1
--     WHEN 'orange' THEN 2
--     WHEN 'red' THEN 3
--     WHEN 'black' THEN 4
--     ELSE 5
--   END;

-- 2. Check for cases that should be black (48+ hours)
-- SELECT 
--   id,
--   deceased_name,
--   status,
--   sla_state,
--   ROUND(sla_hours_elapsed, 1) as hours_elapsed,
--   first_submission_at
-- FROM cases
-- WHERE sla_hours_elapsed >= 48
--   AND status NOT IN ('delivered', 'closed')
-- ORDER BY sla_hours_elapsed DESC;

-- 3. Verify delivered cases don't continue counting
-- SELECT 
--   id,
--   deceased_name,
--   status,
--   sla_state,
--   ROUND(sla_hours_elapsed, 1) as hours_at_delivery
-- FROM cases
-- WHERE status = 'delivered'
--   AND sla_hours_elapsed IS NOT NULL
-- ORDER BY updated_at DESC
-- LIMIT 5;

-- ============================================================================
-- SLA LOGIC SUMMARY
-- ============================================================================
-- 
-- START CONDITION:
--   - first_submission_at IS NOT NULL (family submitted form)
--   - AND status NOT IN ('delivered', 'closed')
--
-- THRESHOLDS:
--   < 24 hours    → green  (On Time)
--   24-36 hours   → orange (Warning)
--   36-48 hours   → red    (Critical)
--   48+ hours     → black  (BREACH)
--
-- STOP CONDITION:
--   - status = 'delivered' (QC approved, sent to family)
--   - status = 'closed' (case archived)
--   → SLA freezes at final state
--
-- PAUSE CONDITION:
--   - status = 'waiting_on_family' (no submission yet)
--   - first_submission_at IS NULL
--   → sla_state = NULL, sla_hours_elapsed = NULL
--
-- ============================================================================

