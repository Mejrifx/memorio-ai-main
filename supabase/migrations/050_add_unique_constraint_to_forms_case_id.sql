-- ============================================================================
-- Migration: 050 - Add UNIQUE constraint to forms.case_id
-- ============================================================================
-- Purpose: Fix autosave upsert error when saving family form drafts
-- ============================================================================

-- PROBLEM:
-- ========
-- Family form autosave is failing with error:
--   42P10: there is no unique or exclusion constraint matching 
--   the ON CONFLICT specification
--
-- The upsert query uses:
--   .upsert({ case_id: ..., draft_json: ... }, { onConflict: 'case_id' })
--
-- But forms.case_id doesn't have a UNIQUE constraint, only a foreign key.

-- SOLUTION:
-- =========
-- Add UNIQUE constraint to forms.case_id
-- Each case can only have ONE form (one-to-one relationship)

-- Check if constraint already exists (idempotent)
DO $$ 
BEGIN
  -- Check if unique constraint exists
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_constraint 
    WHERE conname = 'forms_case_id_unique'
  ) THEN
    -- Check for duplicate case_ids before adding constraint
    -- If duplicates exist, keep the most recent one
    WITH duplicates AS (
      SELECT case_id, id, 
        ROW_NUMBER() OVER (PARTITION BY case_id ORDER BY updated_at DESC, created_at DESC) as rn
      FROM forms
    )
    DELETE FROM forms
    WHERE id IN (
      SELECT id FROM duplicates WHERE rn > 1
    );
    
    -- Add unique constraint
    ALTER TABLE forms
    ADD CONSTRAINT forms_case_id_unique UNIQUE (case_id);
    
    RAISE NOTICE 'Added UNIQUE constraint forms_case_id_unique';
  ELSE
    RAISE NOTICE 'Unique constraint forms_case_id_unique already exists';
  END IF;
END $$;

-- Create index for performance (if not exists)
CREATE INDEX IF NOT EXISTS idx_forms_case_id ON forms(case_id);

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Check that constraint was added:
-- SELECT conname, contype 
-- FROM pg_constraint 
-- WHERE conrelid = 'forms'::regclass 
-- AND conname = 'forms_case_id_unique';
--
-- Expected: Should show 'forms_case_id_unique' with contype = 'u' (unique)

-- Test upsert (should work now):
-- INSERT INTO forms (case_id, draft_json, json_schema_version)
-- VALUES ('<some-case-id>', '{"test": "data"}'::jsonb, 'v1')
-- ON CONFLICT (case_id) DO UPDATE
-- SET draft_json = EXCLUDED.draft_json, updated_at = NOW();

-- ============================================================================
-- NOTES
-- ============================================================================
-- This migration:
-- 1. Removes duplicate forms (keeps most recent)
-- 2. Adds UNIQUE constraint on case_id
-- 3. Creates index for query performance
-- 4. Is idempotent (safe to run multiple times)
--
-- After this migration, the family form autosave will work correctly with:
--   await supabaseClient
--     .from('forms')
--     .upsert({ case_id: ..., draft_json: ... }, { onConflict: 'case_id' })
--
-- The onConflict will now match the unique constraint.
-- ============================================================================

