-- Debug Assets RLS Policies
-- Run this in Supabase Dashboard → SQL Editor to see current policies

SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual as using_expression,
  with_check as with_check_expression
FROM pg_policies
WHERE tablename = 'assets'
ORDER BY policyname;

-- Also check what's actually in the assets table
SELECT 
  id,
  case_id,
  uploader_user_id,
  file_key,
  mime_type,
  metadata->>'source' as source,
  uploaded_at
FROM assets
ORDER BY uploaded_at DESC
LIMIT 10;

-- Check cases and their assigned families
SELECT 
  c.id as case_id,
  c.deceased_name,
  c.assigned_family_user_id,
  u.email as family_email,
  u.role as family_role
FROM cases c
LEFT JOIN users u ON u.id = c.assigned_family_user_id
ORDER BY c.created_at DESC
LIMIT 5;

