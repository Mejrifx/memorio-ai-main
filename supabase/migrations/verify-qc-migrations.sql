-- ============================================================================
-- MEMORIO QC SYSTEM - MIGRATION VERIFICATION SCRIPT
-- ============================================================================
-- Run this after migrations 018 and 019 to verify everything is correct
-- ============================================================================

-- Test 1: Verify QC role was added to users table
SELECT 
  'users_role_check' as test_name,
  CASE 
    WHEN check_clause LIKE '%qc%' THEN '✅ PASS - QC role added'
    ELSE '❌ FAIL - QC role not found'
  END as result,
  check_clause as constraint_definition
FROM information_schema.check_constraints 
WHERE constraint_name = 'users_role_check';

-- Test 2: Verify revision_requested status was added to cases table
SELECT 
  'cases_status_check' as test_name,
  CASE 
    WHEN check_clause LIKE '%revision_requested%' THEN '✅ PASS - revision_requested status added'
    ELSE '❌ FAIL - revision_requested status not found'
  END as result,
  check_clause as constraint_definition
FROM information_schema.check_constraints 
WHERE constraint_name = 'cases_status_check';

-- Test 3: Verify video_submissions table exists
SELECT 
  'video_submissions_table' as test_name,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ PASS - video_submissions table created (' || COUNT(*) || ' columns)'
    ELSE '❌ FAIL - video_submissions table not found'
  END as result
FROM information_schema.columns 
WHERE table_name = 'video_submissions';

-- Test 4: Verify obituary_content table exists
SELECT 
  'obituary_content_table' as test_name,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ PASS - obituary_content table created (' || COUNT(*) || ' columns)'
    ELSE '❌ FAIL - obituary_content table not found'
  END as result
FROM information_schema.columns 
WHERE table_name = 'obituary_content';

-- Test 5: Verify RLS is enabled on new tables
SELECT 
  'rls_enabled' as test_name,
  tablename,
  CASE 
    WHEN rowsecurity = true THEN '✅ PASS - RLS enabled'
    ELSE '❌ FAIL - RLS not enabled'
  END as result
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('video_submissions', 'obituary_content')
ORDER BY tablename;

-- Test 6: Count RLS policies on new tables
SELECT 
  'rls_policies_count' as test_name,
  tablename,
  COUNT(*) as policy_count,
  CASE 
    WHEN COUNT(*) >= 3 THEN '✅ PASS - Multiple policies created'
    WHEN COUNT(*) > 0 THEN '⚠️  WARNING - Only ' || COUNT(*) || ' policy/policies'
    ELSE '❌ FAIL - No policies found'
  END as result
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename IN ('video_submissions', 'obituary_content')
GROUP BY tablename
ORDER BY tablename;

-- Test 7: Verify indexes were created
SELECT 
  'indexes' as test_name,
  tablename,
  indexname,
  '✅ Index created' as result
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('video_submissions', 'obituary_content')
ORDER BY tablename, indexname;

-- Test 8: Verify foreign key constraints
SELECT 
  'foreign_keys' as test_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  '✅ Foreign key valid' as result
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name IN ('video_submissions', 'obituary_content')
ORDER BY tc.table_name, kcu.column_name;

-- Test 9: Verify QC policies on existing tables
SELECT 
  'qc_policies_on_existing_tables' as test_name,
  tablename,
  policyname,
  '✅ QC policy created' as result
FROM pg_policies
WHERE schemaname = 'public'
  AND policyname LIKE '%QC%' OR policyname LIKE '%qc%'
ORDER BY tablename, policyname;

-- Test 10: Show all video_submissions columns (detailed view)
SELECT 
  ordinal_position as "#",
  column_name,
  data_type,
  CASE 
    WHEN is_nullable = 'NO' THEN 'NOT NULL'
    ELSE 'NULL'
  END as nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'video_submissions'
ORDER BY ordinal_position;

-- Test 11: Show all obituary_content columns (detailed view)
SELECT 
  ordinal_position as "#",
  column_name,
  data_type,
  CASE 
    WHEN is_nullable = 'NO' THEN 'NOT NULL'
    ELSE 'NULL'
  END as nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'obituary_content'
ORDER BY ordinal_position;

-- ============================================================================
-- SUMMARY
-- ============================================================================
SELECT 
  '🎉 VERIFICATION COMPLETE' as status,
  'If all tests show ✅ PASS, migrations were successful!' as message;

-- ============================================================================
-- NEXT STEPS
-- ============================================================================
-- 1. All tests passed? Great! Proceed with building the QC Portal UI
-- 2. Any failures? Send the error details to troubleshoot
-- 3. Ready to create the invite-qc Edge Function
-- ============================================================================

