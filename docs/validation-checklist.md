# Memorio Database Validation Checklist

**Version:** 1.0.0  
**Purpose:** Verify Milestone 1 implementation is production-ready

---

## Pre-Deployment Validation

Run through this checklist before deploying to production.

### ✅ 1. Database Schema Validation

**Verify all tables exist:**

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

**Expected output (9 tables):**
- assets
- cases
- editor_assignments
- events
- exports
- forms
- notifications
- organizations
- users

---

**Verify foreign key relationships:**

```sql
SELECT
  tc.table_name, 
  kcu.column_name, 
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_schema = 'public'
ORDER BY tc.table_name;
```

**Expected:** 15+ foreign key relationships across all tables

---

**Verify indexes exist:**

```sql
SELECT
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

**Expected:** 20+ indexes (including primary keys and custom indexes)

---

### ✅ 2. Row Level Security Validation

**Verify RLS is enabled on all tables:**

```sql
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;
```

**Expected:** All 9 tables have `rowsecurity = true`

---

**Verify RLS policies exist:**

```sql
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

**Expected:** 30-40 policies covering:
- Admin full access policies (9 tables)
- Director org-scoped policies (6 tables)
- Family case-scoped policies (4 tables)
- Editor assignment-scoped policies (3 tables)
- Support read-only policies (9 tables)

---

### ✅ 3. Function & Trigger Validation

**Verify functions exist:**

```sql
SELECT 
  proname AS function_name,
  pg_get_function_identity_arguments(p.oid) AS arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
ORDER BY proname;
```

**Expected functions:**
- `append_form_version_history()`
- `handle_auth_user_login()`
- `log_audit_event()`
- `update_case_on_form_submission()`
- `update_last_login()`
- `update_updated_at_column()`

---

**Verify triggers exist:**

```sql
SELECT 
  event_object_table AS table_name,
  trigger_name,
  event_manipulation AS event,
  action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;
```

**Expected triggers:**
- `update_*_updated_at` on organizations, users, cases, forms
- `audit_*_changes` on organizations, users, cases, forms, editor_assignments
- `maintain_form_version_history` on forms
- `update_case_on_form_submit` on forms

---

### ✅ 4. Seed Data Validation

**Verify test organization exists:**

```sql
SELECT * FROM organizations 
WHERE id = '00000000-0000-0000-0000-000000000001';
```

**Expected:** 1 row (Test Funeral Home)

---

### ✅ 5. Storage Bucket Validation

**Via Supabase Dashboard:**

1. Navigate to Storage → Buckets
2. Verify `case-assets` bucket exists
3. Check settings:
   - Public: No (private)
   - Allowed MIME types: `image/*`, `video/*`
   - File size limit: Configured

**Via CLI:**

```bash
supabase storage list
# Should include 'case-assets'
```

---

### ✅ 6. RLS Policy Testing

#### Test 1: Admin Can Access All Data

```sql
-- Set JWT claims to admin role
SET request.jwt.claims = '{"role": "admin", "sub": "10000000-0000-0000-0000-000000000001"}';

-- Admin should see all organizations
SELECT COUNT(*) FROM organizations;
-- Expected: At least 1 (test org)

-- Admin should see all users
SELECT COUNT(*) FROM users;
-- Expected: 5 (admin, director, family, editor, support)

-- Admin should see all cases
SELECT COUNT(*) FROM cases;
-- Expected: 0 or more

RESET request.jwt.claims;
```

---

#### Test 2: Director Org-Scoped Access

```sql
-- Set JWT claims to director role
SET request.jwt.claims = '{
  "role": "director", 
  "org_id": "00000000-0000-0000-0000-000000000001",
  "sub": "20000000-0000-0000-0000-000000000001"
}';

-- Director should only see their org
SELECT * FROM organizations WHERE id = '00000000-0000-0000-0000-000000000001';
-- Expected: 1 row (their org)

-- Director should NOT see other orgs (if multiple exist)
SELECT * FROM organizations WHERE id != '00000000-0000-0000-0000-000000000001';
-- Expected: 0 rows

-- Director should only see users in their org
SELECT * FROM users WHERE org_id = '00000000-0000-0000-0000-000000000001';
-- Expected: 2+ rows (director, family)

RESET request.jwt.claims;
```

---

#### Test 3: Family Case-Scoped Access

First, create a test case (as admin):

```sql
-- As admin, create test case
SET request.jwt.claims = '{"role": "admin"}';

INSERT INTO cases (id, org_id, deceased_name, created_by, assigned_family_user_id, status)
VALUES (
  'c0000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  'Test Deceased',
  '20000000-0000-0000-0000-000000000001', -- Director
  '30000000-0000-0000-0000-000000000001', -- Family
  'waiting_on_family'
);

RESET request.jwt.claims;
```

Now test family access:

```sql
-- Set JWT claims to family role
SET request.jwt.claims = '{
  "role": "family",
  "sub": "30000000-0000-0000-0000-000000000001"
}';

-- Family should only see their assigned case
SELECT * FROM cases WHERE assigned_family_user_id = '30000000-0000-0000-0000-000000000001';
-- Expected: 1 row (their case)

-- Family should NOT see other cases
SELECT * FROM cases WHERE assigned_family_user_id != '30000000-0000-0000-0000-000000000001';
-- Expected: 0 rows

RESET request.jwt.claims;
```

---

#### Test 4: Editor Assignment-Scoped Access

First, create editor assignment (as admin):

```sql
-- As admin, assign editor to case
SET request.jwt.claims = '{"role": "admin"}';

INSERT INTO editor_assignments (case_id, editor_user_id, assigned_by)
VALUES (
  'c0000000-0000-0000-0000-000000000001',
  '40000000-0000-0000-0000-000000000001', -- Editor
  '20000000-0000-0000-0000-000000000001'  -- Director
);

RESET request.jwt.claims;
```

Now test editor access:

```sql
-- Set JWT claims to editor role
SET request.jwt.claims = '{
  "role": "editor",
  "sub": "40000000-0000-0000-0000-000000000001"
}';

-- Editor should only see assigned cases
SELECT * FROM cases 
WHERE id IN (
  SELECT case_id FROM editor_assignments 
  WHERE editor_user_id = '40000000-0000-0000-0000-000000000001'
  AND unassigned_at IS NULL
);
-- Expected: 1 row (assigned case)

-- Editor should NOT see unassigned cases
SELECT * FROM cases 
WHERE id NOT IN (
  SELECT case_id FROM editor_assignments 
  WHERE editor_user_id = '40000000-0000-0000-0000-000000000001'
);
-- Expected: 0 rows

RESET request.jwt.claims;
```

---

#### Test 5: Cross-Tenant Isolation

Create second organization and user (as admin):

```sql
SET request.jwt.claims = '{"role": "admin"}';

-- Create second org
INSERT INTO organizations (id, name, contact_email)
VALUES (
  '00000000-0000-0000-0000-000000000002',
  'Competitor Funeral Home',
  'competitor@example.com'
);

-- Create director for second org
INSERT INTO users (id, email, role, org_id, status)
VALUES (
  '20000000-0000-0000-0000-000000000002',
  'director2@competitor.com',
  'director',
  '00000000-0000-0000-0000-000000000002',
  'active'
);

RESET request.jwt.claims;
```

Test cross-tenant access blocking:

```sql
-- Login as director from Org 1
SET request.jwt.claims = '{
  "role": "director",
  "org_id": "00000000-0000-0000-0000-000000000001",
  "sub": "20000000-0000-0000-0000-000000000001"
}';

-- Should NOT see Org 2
SELECT * FROM organizations WHERE id = '00000000-0000-0000-0000-000000000002';
-- Expected: 0 rows (blocked by RLS)

-- Should NOT see Org 2's director
SELECT * FROM users WHERE org_id = '00000000-0000-0000-0000-000000000002';
-- Expected: 0 rows (blocked by RLS)

RESET request.jwt.claims;
```

---

### ✅ 7. Trigger Testing

#### Test 1: Auto-Update `updated_at`

```sql
-- Create test org
INSERT INTO organizations (name, contact_email)
VALUES ('Trigger Test Org', 'test@trigger.com')
RETURNING id, created_at, updated_at;

-- Note the id and updated_at timestamp
-- Wait 2 seconds, then update
\! sleep 2

UPDATE organizations 
SET name = 'Trigger Test Org Updated' 
WHERE name = 'Trigger Test Org'
RETURNING id, created_at, updated_at;

-- Verify updated_at changed (should be 2+ seconds after created_at)
```

**Expected:** `updated_at` is automatically updated and newer than `created_at`

---

#### Test 2: Audit Event Creation

```sql
-- Count current events
SELECT COUNT(*) FROM events;
-- Note the count

-- Perform action as director
SET request.jwt.claims = '{
  "role": "director",
  "org_id": "00000000-0000-0000-0000-000000000001",
  "sub": "20000000-0000-0000-0000-000000000001"
}';

-- Create a case (should trigger audit event)
INSERT INTO cases (org_id, deceased_name, created_by)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Audit Test Case',
  '20000000-0000-0000-0000-000000000001'
)
RETURNING id;

RESET request.jwt.claims;

-- Check events table increased by 1
SELECT COUNT(*) FROM events;
-- Expected: Previous count + 1

-- Verify event details
SELECT * FROM events 
WHERE action_type = 'INSERT' 
  AND target_type = 'cases' 
ORDER BY timestamp DESC 
LIMIT 1;

-- Expected: Event with actor_user_id = director's UUID, action_type = 'INSERT'
```

---

#### Test 3: Form Version History

```sql
-- Create test form
INSERT INTO forms (case_id, json_schema_version)
VALUES ('c0000000-0000-0000-0000-000000000001', 'v1')
RETURNING id;
-- Note the form id

-- Submit form (first version)
UPDATE forms 
SET 
  submitted_json = '{"name": "John Doe", "dob": "1950-01-01"}'::jsonb,
  submitted_at = NOW()
WHERE case_id = 'c0000000-0000-0000-0000-000000000001';

-- Check version history
SELECT immutable_version_history FROM forms 
WHERE case_id = 'c0000000-0000-0000-0000-000000000001';
-- Expected: Array with 1 version

-- Submit again (second version)
UPDATE forms 
SET 
  submitted_json = '{"name": "John Doe Updated", "dob": "1950-01-01"}'::jsonb,
  submitted_at = NOW()
WHERE case_id = 'c0000000-0000-0000-0000-000000000001';

-- Check version history
SELECT immutable_version_history FROM forms 
WHERE case_id = 'c0000000-0000-0000-0000-000000000001';
-- Expected: Array with 2 versions
```

---

### ✅ 8. Performance Testing

**Test index performance:**

```sql
-- Enable timing
\timing on

-- Test indexed query (should be fast)
EXPLAIN ANALYZE
SELECT * FROM cases WHERE org_id = '00000000-0000-0000-0000-000000000001';
-- Expected: Uses idx_cases_org_id, execution time < 1ms

-- Test indexed query on events
EXPLAIN ANALYZE
SELECT * FROM events WHERE target_type = 'cases' AND target_id = 'c0000000-0000-0000-0000-000000000001';
-- Expected: Uses idx_events_target, execution time < 5ms

\timing off
```

---

### ✅ 9. Authentication Integration Testing

**Via Supabase JavaScript Client:**

```javascript
const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Test director login
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'director@testfuneralhome.com',
  password: 'TestDirector123!'
});

console.log('Login successful:', data.user);

// Test RLS via client
const { data: cases, error: casesError } = await supabase
  .from('cases')
  .select();

console.log('Cases visible to director:', cases.length);
// Expected: Only cases from their org

// Logout
await supabase.auth.signOut();
```

---

### ✅ 10. Storage Integration Testing

**Test file upload (via Supabase client):**

```javascript
// Login as family user
await supabase.auth.signInWithPassword({
  email: 'family@example.com',
  password: 'TestFamily123!'
});

// Upload test file to their case folder
const file = new File(['test content'], 'test.jpg', { type: 'image/jpeg' });
const { data, error } = await supabase.storage
  .from('case-assets')
  .upload(
    `00000000-0000-0000-0000-000000000001/c0000000-0000-0000-0000-000000000001/test.jpg`,
    file
  );

console.log('Upload result:', data);
// Expected: Success

// Try to upload to another org's folder (should fail)
const { data: data2, error: error2 } = await supabase.storage
  .from('case-assets')
  .upload(
    `00000000-0000-0000-0000-000000000002/some-case/test.jpg`,
    file
  );

console.log('Cross-tenant upload blocked:', error2);
// Expected: Permission denied error
```

---

## Production Readiness Checklist

Before deploying to production:

- [ ] All 9 tables created successfully
- [ ] All foreign keys enforce referential integrity
- [ ] All indexes created and query performance verified
- [ ] RLS enabled on all tables
- [ ] All RLS policies tested and verified
- [ ] Cross-tenant access blocked and tested
- [ ] All database functions created
- [ ] All triggers firing correctly
- [ ] Audit logging working
- [ ] Form version history appending
- [ ] `case-assets` storage bucket created
- [ ] Storage RLS policies configured
- [ ] Test accounts created successfully
- [ ] Admin can access all data
- [ ] Director isolated to their org
- [ ] Family isolated to their case
- [ ] Editor isolated to assigned cases
- [ ] Support has read-only access
- [ ] JWT authentication working
- [ ] Auto-updated `updated_at` timestamps working
- [ ] Performance acceptable (all queries < 100ms)
- [ ] Documentation complete and accurate

---

## Automated Testing (Future)

Create `scripts/test-rls-policies.js` to automate these tests in CI/CD.

---

**End of Validation Checklist**

