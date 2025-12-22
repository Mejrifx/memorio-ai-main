-- ============================================================================
-- Migration: Fix User Deletion CASCADE Constraints
-- ============================================================================
-- Purpose: Allow proper deletion of editor and QC users by setting appropriate
--          CASCADE/SET NULL rules on foreign keys that reference users table.
-- ============================================================================

-- Drop existing foreign key constraints and recreate with proper DELETE rules

-- 1. CASES TABLE - Set created_by and assigned_family_user_id to NULL on delete
ALTER TABLE cases DROP CONSTRAINT IF EXISTS cases_created_by_fkey;
ALTER TABLE cases ADD CONSTRAINT cases_created_by_fkey 
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE cases DROP CONSTRAINT IF EXISTS cases_assigned_family_user_id_fkey;
ALTER TABLE cases ADD CONSTRAINT cases_assigned_family_user_id_fkey 
  FOREIGN KEY (assigned_family_user_id) REFERENCES users(id) ON DELETE SET NULL;

-- 2. EDITOR_ASSIGNMENTS - CASCADE delete when user is deleted
ALTER TABLE editor_assignments DROP CONSTRAINT IF EXISTS editor_assignments_editor_user_id_fkey;
ALTER TABLE editor_assignments ADD CONSTRAINT editor_assignments_editor_user_id_fkey 
  FOREIGN KEY (editor_user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE editor_assignments DROP CONSTRAINT IF EXISTS editor_assignments_assigned_by_fkey;
ALTER TABLE editor_assignments ADD CONSTRAINT editor_assignments_assigned_by_fkey 
  FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE SET NULL;

-- 3. VIDEO_SUBMISSIONS - SET NULL for editor and QC reviewer
ALTER TABLE video_submissions DROP CONSTRAINT IF EXISTS video_submissions_editor_user_id_fkey;
ALTER TABLE video_submissions ADD CONSTRAINT video_submissions_editor_user_id_fkey 
  FOREIGN KEY (editor_user_id) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE video_submissions DROP CONSTRAINT IF EXISTS video_submissions_qc_reviewer_id_fkey;
ALTER TABLE video_submissions ADD CONSTRAINT video_submissions_qc_reviewer_id_fkey 
  FOREIGN KEY (qc_reviewer_id) REFERENCES users(id) ON DELETE SET NULL;

-- 4. OBITUARY_CONTENT - SET NULL for generated_by and approved_by
ALTER TABLE obituary_content DROP CONSTRAINT IF EXISTS obituary_content_generated_by_fkey;
ALTER TABLE obituary_content ADD CONSTRAINT obituary_content_generated_by_fkey 
  FOREIGN KEY (generated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE obituary_content DROP CONSTRAINT IF EXISTS obituary_content_approved_by_fkey;
ALTER TABLE obituary_content ADD CONSTRAINT obituary_content_approved_by_fkey 
  FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL;

-- 5. CASE_NOTES - SET NULL for author (keep note but remove author reference)
ALTER TABLE case_notes DROP CONSTRAINT IF EXISTS case_notes_author_user_id_fkey;
ALTER TABLE case_notes ADD CONSTRAINT case_notes_author_user_id_fkey 
  FOREIGN KEY (author_user_id) REFERENCES users(id) ON DELETE SET NULL;

-- 6. ASSETS - SET NULL for uploader
ALTER TABLE assets DROP CONSTRAINT IF EXISTS assets_uploader_user_id_fkey;
ALTER TABLE assets ADD CONSTRAINT assets_uploader_user_id_fkey 
  FOREIGN KEY (uploader_user_id) REFERENCES users(id) ON DELETE SET NULL;

-- 7. EVENTS - SET NULL for actor_user_id (keep event log but remove user reference)
ALTER TABLE events DROP CONSTRAINT IF EXISTS events_actor_user_id_fkey;
ALTER TABLE events ADD CONSTRAINT events_actor_user_id_fkey 
  FOREIGN KEY (actor_user_id) REFERENCES users(id) ON DELETE SET NULL;

-- 8. NOTIFICATIONS - Keep notification even if user is deleted (no change needed)
-- notifications doesn't have a direct user FK, only case_id

-- 9. EXPORTS - SET NULL for created_by
ALTER TABLE exports DROP CONSTRAINT IF EXISTS exports_created_by_fkey;
ALTER TABLE exports ADD CONSTRAINT exports_created_by_fkey 
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;

-- Summary of changes:
-- - editor_assignments: CASCADE (delete assignments when user deleted)
-- - Everything else: SET NULL (keep records but remove user reference)
-- This allows safe deletion of editor/QC users while preserving audit trail

-- Note: The users.id -> auth.users(id) constraint already has ON DELETE CASCADE
-- from the initial schema, so deleting from auth.users will cascade to public.users

