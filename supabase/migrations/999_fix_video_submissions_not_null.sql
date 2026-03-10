-- ============================================================================
-- Migration: Fix video_submissions NOT NULL constraint on editor_user_id
-- ============================================================================
-- Purpose: Allow editor_user_id to be NULL so editors can be deleted
--          Migration 023 updated the FK to SET NULL but forgot to drop NOT NULL
-- ============================================================================

-- Make editor_user_id nullable
ALTER TABLE video_submissions ALTER COLUMN editor_user_id DROP NOT NULL;

-- Verify the constraint is properly set to SET NULL (redundant but safe)
ALTER TABLE video_submissions DROP CONSTRAINT IF EXISTS video_submissions_editor_user_id_fkey;
ALTER TABLE video_submissions ADD CONSTRAINT video_submissions_editor_user_id_fkey 
  FOREIGN KEY (editor_user_id) REFERENCES users(id) ON DELETE SET NULL;
