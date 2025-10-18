-- Fix Existing User App Metadata
-- Version: 1.0.0
-- Description: Update all existing director and family accounts to have proper app_metadata

-- This migration fixes accounts created before the invite functions were corrected
-- It moves role and org_id from user_metadata to app_metadata where they belong

-- ============================================================================
-- FIX DIRECTOR ACCOUNTS
-- ============================================================================

-- Update all directors to have role and org_id in app_metadata
UPDATE auth.users
SET raw_app_meta_data = jsonb_build_object(
  'role', 'director',
  'org_id', (
    SELECT org_id::text 
    FROM public.users 
    WHERE id = auth.users.id
  )
)
WHERE id IN (
  SELECT id 
  FROM public.users 
  WHERE role = 'director'
    AND org_id IS NOT NULL
);

-- Log the fix
INSERT INTO public.events (
  actor_role,
  action_type,
  target_type,
  payload
)
SELECT 
  'system',
  'FIX_APP_METADATA',
  'users',
  jsonb_build_object(
    'fixed_count', COUNT(*),
    'role', 'director',
    'migration', '011_fix_existing_user_app_metadata'
  )
FROM public.users
WHERE role = 'director' AND org_id IS NOT NULL;

-- ============================================================================
-- FIX FAMILY ACCOUNTS
-- ============================================================================

-- Update all family members to have role and org_id in app_metadata
UPDATE auth.users
SET raw_app_meta_data = jsonb_build_object(
  'role', 'family',
  'org_id', (
    SELECT org_id::text 
    FROM public.users 
    WHERE id = auth.users.id
  )
)
WHERE id IN (
  SELECT id 
  FROM public.users 
  WHERE role = 'family'
    AND org_id IS NOT NULL
);

-- Log the fix
INSERT INTO public.events (
  actor_role,
  action_type,
  target_type,
  payload
)
SELECT 
  'system',
  'FIX_APP_METADATA',
  'users',
  jsonb_build_object(
    'fixed_count', COUNT(*),
    'role', 'family',
    'migration', '011_fix_existing_user_app_metadata'
  )
FROM public.users
WHERE role = 'family' AND org_id IS NOT NULL;

-- ============================================================================
-- FIX ADMIN ACCOUNTS (if any exist with missing app_metadata)
-- ============================================================================

-- Update all admins to have role in app_metadata
UPDATE auth.users
SET raw_app_meta_data = jsonb_build_object(
  'role', 'admin'
)
WHERE id IN (
  SELECT id 
  FROM public.users 
  WHERE role = 'admin'
);

-- Log the fix
INSERT INTO public.events (
  actor_role,
  action_type,
  target_type,
  payload
)
SELECT 
  'system',
  'FIX_APP_METADATA',
  'users',
  jsonb_build_object(
    'fixed_count', COUNT(*),
    'role', 'admin',
    'migration', '011_fix_existing_user_app_metadata'
  )
FROM public.users
WHERE role = 'admin';

-- ============================================================================
-- VERIFICATION QUERY (Optional - run this after migration)
-- ============================================================================

-- Check that all users now have proper app_metadata
-- Run this manually to verify:
/*
SELECT 
  u.email,
  u.role,
  u.org_id,
  au.raw_app_meta_data
FROM public.users u
JOIN auth.users au ON au.id = u.id
ORDER BY u.role, u.email;
*/

COMMENT ON TABLE public.users IS 
  'Users table - app_metadata fixed via migration 011 on ' || NOW()::text;

