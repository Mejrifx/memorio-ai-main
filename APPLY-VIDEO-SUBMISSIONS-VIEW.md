# Fix QC Reviewer Assignment Display

## Problem
When a QC reviewer starts reviewing a case (clicks "Start Review"), the admin portal still shows "Not assigned" even though the `qc_reviewer_id` is correctly saved in the database.

## Root Cause Analysis

### The Flow Works Correctly:
1. ✅ Editor submits video → creates `video_submissions` record
2. ✅ QC clicks case card → triggers `selectSubmission()`
3. ✅ QC portal runs UPDATE:
   ```javascript
   await supabaseClient
     .from('video_submissions')
     .update({ 
       qc_status: 'in_review',
       qc_reviewer_id: currentUser.id
     })
     .eq('id', submissionId);
   ```
4. ✅ Database saves `qc_reviewer_id` correctly
5. ❌ Admin portal can't display the QC reviewer name

### Why Admin Can't See QC Reviewer:

**The Query Problem:**
```javascript
// Admin dashboard queries video_submissions with FK join:
.from('video_submissions')
.select(`
  case_id,
  qc_status,
  qc_reviewer_id,
  qc_reviewer:qc_reviewer_id (  // ← This is the problem!
    email,
    metadata
  )
`)
```

This foreign key join tries to access the `users` table directly.

**The RLS Restriction:**
After migration 034, the `users` table RLS was simplified:
- ✅ Users can see themselves: `WHERE id = auth.uid()`
- ❌ Admins can't query other users via raw `users` table
- ✅ Admins must use `admin_users_view` instead

**The Conflict:**
- Supabase foreign key joins access the raw table (`users`)
- Admin's RLS policy only allows self-access on raw table
- Admin trying to see QC reviewer (another user) → **RLS BLOCKED**

## The Solution

Create `admin_video_submissions_view` that:
1. Pre-joins `video_submissions` with `users` table
2. Uses `security_barrier = true` to bypass RLS
3. Includes QC reviewer info directly in the result
4. Similar pattern to `admin_cases_view` and `admin_editor_assignments_view`

### Migration Created:
`041_create_admin_video_submissions_view.sql`

### Code Changes:
**Before:**
```javascript
.from('video_submissions')
.select(`
  case_id,
  qc_status,
  qc_reviewer_id,
  qc_reviewer:qc_reviewer_id (email, metadata)  // FK join fails
`)
```

**After:**
```javascript
.from('admin_video_submissions_view')
.select('case_id, qc_status, qc_reviewer_id, qc_reviewer_email, qc_reviewer_metadata')
// Fields already joined, no FK lookup needed!
```

## Apply the Fix

### Step 1: Apply Migration to Supabase

```bash
# Connect to Supabase and run migration 041
supabase db push
```

Or manually via Supabase SQL Editor:
1. Go to: https://supabase.com/dashboard/project/YOUR_PROJECT/sql
2. Copy contents of: `supabase/migrations/041_create_admin_video_submissions_view.sql`
3. Run the SQL

### Step 2: Verify Migration Applied

Run this query in Supabase SQL Editor:
```sql
-- Check view exists
SELECT schemaname, viewname, viewowner 
FROM pg_views 
WHERE viewname = 'admin_video_submissions_view';

-- Test query as admin (should show QC reviewers)
SELECT 
  id,
  case_id, 
  qc_status,
  qc_reviewer_email,
  qc_reviewer_metadata->>'name' as qc_reviewer_name
FROM admin_video_submissions_view
WHERE qc_reviewer_id IS NOT NULL
LIMIT 5;
```

Expected result: You should see QC reviewer names and emails.

### Step 3: Deploy Updated Dashboard

The `m-admin-3k5a/dashboard.html` file has been updated to use the view.

Changes are already committed to git, so just:
```bash
git pull origin main
# Or if you're on Netlify, push will auto-deploy
```

### Step 4: Test the Fix

1. **Create a test case:**
   - Login as Director → Create new case → Assign to family

2. **Submit video:**
   - Login as Editor → Open case → Upload/submit video

3. **Start QC Review:**
   - Login as QC → Open case card → Click "Start Review"

4. **Check Admin Portal:**
   - Login as Admin → Go to "All Cases" → Click on the case
   - **Expected:** Case details modal shows QC Reviewer name (e.g., "Sarah Johnson")
   - **Before fix:** Showed "Not assigned"

## Why This Happened

This is a classic "view-based RLS" pattern issue:

1. We moved from direct table access to view-based access (migration 034)
2. This improved security and avoided recursion issues ✅
3. But forgot to create views for ALL tables that need cross-user lookups ❌
4. `video_submissions` needed a view too because admins need to see QC reviewer info

## Other Tables Using This Pattern

Already fixed with views:
- ✅ `users` → `admin_users_view`
- ✅ `cases` → `admin_cases_view`  
- ✅ `editor_assignments` → `admin_editor_assignments_view`
- ✅ `video_submissions` → `admin_video_submissions_view` (this fix!)

## Verification Checklist

After applying migration 041:

- [ ] Migration applied successfully (no errors)
- [ ] View `admin_video_submissions_view` exists
- [ ] Query returns QC reviewer names for in-review submissions
- [ ] Admin dashboard shows QC reviewer names in case details
- [ ] QC assignment flow still works (QC can start review)
- [ ] No other functionality broken

## Files Changed

1. `supabase/migrations/041_create_admin_video_submissions_view.sql` (NEW)
2. `m-admin-3k5a/dashboard.html` (MODIFIED - loadAllCases function)
3. `APPLY-VIDEO-SUBMISSIONS-VIEW.md` (NEW - this file)

## Expected Result

✅ Admin sees: **QC Reviewer: Sarah Johnson**  
❌ Before: **QC Reviewer: Not assigned**

The QC assignment was always working - we just couldn't display it! 🎯

