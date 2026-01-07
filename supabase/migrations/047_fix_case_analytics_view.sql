-- ============================================================================
-- Migration: 047 - Fix case_analytics view to include all required fields
-- ============================================================================
-- Purpose: Organization details modal shows 0 for all stats and 100% SLA
--          because case_analytics view is missing required fields
-- ============================================================================

-- PROBLEM:
-- ========
-- When viewing organization details in admin portal:
--   - Active Cases: 0 (should show real count)
--   - Cases in Last 30 Days: 0 (should show real count)
--   - On-Time Cases: 0 (should show real count)
--   - Breach Cases: 0 (should show real count)
--   - SLA Performance: 100% (should show real percentage)
--
-- Root Cause:
--   The current case_analytics view (from migration 038) only includes:
--     - total_cases
--     - completed_cases
--     - active_cases
--     - avg_completion_hours
--
--   But the frontend expects:
--     - active_cases ✅
--     - cases_last_30_days ❌ (missing)
--     - on_time_cases ❌ (missing)
--     - breach_cases ❌ (missing)
--     - sla_percentage ❌ (missing)
--
--   When the view doesn't have these fields, the query fails and falls back
--   to hardcoded defaults: all zeros and 100% SLA.

-- SOLUTION:
-- =========
-- Recreate case_analytics view with ALL required fields
-- Based on the original definition from migration 020

-- Drop existing view
DROP VIEW IF EXISTS case_analytics CASCADE;

-- Recreate with all required fields
CREATE OR REPLACE VIEW case_analytics
WITH (security_invoker = false, security_barrier = true)
AS
SELECT 
  org_id,
  
  -- Total and completed cases
  COUNT(*) as total_cases,
  COUNT(*) FILTER (WHERE status = 'delivered') as completed_cases,
  
  -- Active cases (any status that's not delivered/closed)
  COUNT(*) FILTER (
    WHERE status IN (
      'created',
      'waiting_on_family', 
      'intake_in_progress', 
      'submitted', 
      'in_production', 
      'awaiting_review'
    )
  ) as active_cases,
  
  -- Cases created in the last 30 days
  COUNT(*) FILTER (
    WHERE created_at >= NOW() - INTERVAL '30 days'
  ) as cases_last_30_days,
  
  -- On-Time Cases: green or yellow SLA state
  -- Note: Only count active cases (exclude delivered/closed)
  COUNT(*) FILTER (
    WHERE sla_state IN ('green', 'yellow', 'on_time') 
    AND status NOT IN ('delivered', 'closed')
  ) as on_time_cases,
  
  -- Breach Cases: orange or red SLA state
  -- Note: Only count active cases (exclude delivered/closed)
  COUNT(*) FILTER (
    WHERE sla_state IN ('orange', 'red', 'warning', 'breach')
    AND status NOT IN ('delivered', 'closed')
  ) as breach_cases,
  
  -- SLA Performance Percentage
  -- Formula: (on_time_cases / total_active_cases) * 100
  -- Returns NULL if no active cases (avoid division by zero)
  CASE 
    WHEN COUNT(*) FILTER (WHERE status NOT IN ('delivered', 'closed')) = 0 THEN 100
    ELSE ROUND(
      (
        COUNT(*) FILTER (
          WHERE sla_state IN ('green', 'yellow', 'on_time') 
          AND status NOT IN ('delivered', 'closed')
        )::NUMERIC 
        / 
        NULLIF(
          COUNT(*) FILTER (WHERE status NOT IN ('delivered', 'closed')), 
          0
        )
      ) * 100, 
      1
    )
  END as sla_percentage,
  
  -- Average completion hours (for reference)
  ROUND(
    AVG(
      EXTRACT(EPOCH FROM (updated_at - created_at)) / 3600
    )::NUMERIC, 
    2
  ) as avg_completion_hours

FROM cases
WHERE
  -- RLS: Admins see all analytics
  (public.get_my_role() = 'admin')
  OR
  -- RLS: Directors see analytics for their org
  (
    public.get_my_role() = 'director'
    AND org_id = (SELECT org_id FROM users WHERE id = auth.uid())
  )
  OR
  -- RLS: Support/QC see all analytics
  (public.get_my_role() IN ('support', 'qc'))
GROUP BY org_id;

-- Grant access
GRANT SELECT ON case_analytics TO authenticated;

-- Add helpful comment
COMMENT ON VIEW case_analytics IS 
  'Comprehensive case analytics by organization including SLA metrics.
   Fields: total_cases, completed_cases, active_cases, cases_last_30_days, 
   on_time_cases, breach_cases, sla_percentage, avg_completion_hours.
   Uses security_barrier for RLS enforcement.';

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- After applying this migration, run these queries to verify:

-- 1. Check view columns
-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'case_analytics'
-- ORDER BY ordinal_position;
-- Expected: Should show all 8 columns including the missing ones

-- 2. Test data retrieval (as admin)
-- SELECT * FROM case_analytics LIMIT 5;
-- Expected: Should show real data with proper counts and percentages

-- 3. Test specific org analytics
-- SELECT 
--   org_id,
--   active_cases,
--   cases_last_30_days,
--   on_time_cases,
--   breach_cases,
--   sla_percentage
-- FROM case_analytics
-- WHERE org_id = '<your-org-id>';
-- Expected: Should show non-zero values if org has cases

-- ============================================================================
-- SLA STATE VALUES REFERENCE
-- ============================================================================
-- The cases table sla_state column can have these values:
--   - 'green'    : < 24 hours (on-time)
--   - 'yellow'   : 24-36 hours (on-time but warning)
--   - 'orange'   : 36-48 hours (breach warning)
--   - 'red'      : 48+ hours (breach)
--   - 'on_time'  : Generic on-time state
--   - 'warning'  : Generic warning state
--   - 'breach'   : Generic breach state
--   - NULL       : No SLA tracking yet (family hasn't submitted)
--
-- For analytics:
--   ON-TIME = green, yellow, on_time
--   BREACH  = orange, red, warning, breach
-- ============================================================================

