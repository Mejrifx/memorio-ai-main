# 🐛 CRITICAL FIX: QC Revision Notes Not Showing in Audit

## Problem Discovered

When QC requests a revision with notes, the `qc_revision` event (which contains the notes) was **NEVER being logged** to the events table!

### Root Cause

**Status Value Mismatch:**

- **Database Column Constraint**: Allows `'revision_requested'` (defined in migration 018)
- **QC Portal Frontend**: Sets `qc_status = 'revision_requested'` ✅ (correct)
- **Database Trigger (Migration 044)**: Checks for `qc_status = 'revision'` ❌ (WRONG!)

Because the trigger was checking for `'revision'` but the actual value is `'revision_requested'`, the condition never matched, so the `qc_revision` event with notes was never inserted into the events table!

## The Fix

Migration `045_fix_qc_revision_trigger.sql` corrects the trigger to check for the right value:

**Before (WRONG):**
```sql
ELSIF NEW.qc_status = 'revision' THEN  -- This never matched!
```

**After (CORRECT):**
```sql
ELSIF NEW.qc_status = 'revision_requested' THEN  -- Now matches!
```

## How to Apply

### Step 1: Apply the Migration

In your Supabase SQL Editor, run:

```sql
-- Copy and paste the entire contents of:
-- supabase/migrations/045_fix_qc_revision_trigger.sql
```

Or use the Supabase CLI:

```bash
cd /Users/mejrifx/Downloads/memorio-ai
supabase db push
```

### Step 2: Verify the Fix

Run this query to confirm the function was updated:

```sql
SELECT routine_name, routine_definition
FROM information_schema.routines
WHERE routine_name = 'log_video_submission_events'
AND routine_definition LIKE '%revision_requested%';
```

**Expected result**: Should return 1 row showing the function contains `'revision_requested'`

### Step 3: Test the Fix

1. Log in as QC user
2. Select a video to review
3. Add notes in the "QC Feedback" box (e.g., "Please fix the audio volume")
4. Click "Request Revision"
5. Log in as Admin
6. View that case's audit trail
7. **You should NOW see:**
   ```
   QC Requested Revision
     QC Notes: Please fix the audio volume
   🔍 [QC User Name]
   ```

## What Was Also Updated

### Frontend (dashboard.html)
- Fixed query to look for `qc_status = 'revision_requested'` instead of `'revision'`
- Added debug logging to help diagnose future issues

## Why This Happened

The original migration (044) was created with the wrong status value. The database schema was already correct (using `'revision_requested'`), but the trigger code used `'revision'` which doesn't exist in the constraint.

This is a typo/oversight that caused the trigger condition to never match, silently failing to log the `qc_revision` events.

## Impact

**Before Fix:**
- ❌ QC revision events never logged
- ❌ QC notes completely lost in audit trail
- ❌ Only generic `status_changed` events visible
- ❌ No way to see what feedback QC gave to editor

**After Fix:**
- ✅ QC revision events properly logged with notes
- ✅ Full audit trail with QC feedback visible
- ✅ Complete accountability and communication history
- ✅ Admins can troubleshoot and review all feedback

## Files Changed

1. `supabase/migrations/045_fix_qc_revision_trigger.sql` - New migration to fix trigger
2. `m-admin-3k5a/dashboard.html` - Fixed query to use correct status value
3. `APPLY-QC-REVISION-FIX.md` - This instructions file

---

**Priority**: 🔴 **CRITICAL** - Apply this immediately to restore audit trail functionality for QC revisions!

