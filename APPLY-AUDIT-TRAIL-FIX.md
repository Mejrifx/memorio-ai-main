# 🚨 URGENT: Fix Audit Trail RLS Policy

## Issue
When reassigning an editor, you see this error in the console:
```
POST https://gkabtvqwwuvigcdubwyv.supabase.co/rest/v1/events 403 (Forbidden)
⚠️ Error logging to audit trail: 
{code: '42501', message: 'new row violates row-level security policy for table "events"'}
```

**Cause:** The `events` table has RLS policies that only allow SELECT (read), not INSERT (write).

## Solution
Run the SQL fix in your Supabase dashboard:

### Steps:

1. **Go to Supabase Dashboard**
   - https://supabase.com/dashboard/project/gkabtvqwwuvigcdubwyv

2. **Open SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "New query"

3. **Copy & Paste the SQL**
   - Open the file: `FIX-AUDIT-TRAIL-RLS.sql`
   - Copy ALL contents
   - Paste into the SQL Editor

4. **Run the Query**
   - Click "Run" or press Ctrl+Enter (Cmd+Enter on Mac)
   - Should see: "Success. No rows returned"

5. **Verify**
   - Scroll down in the results
   - Should see 5 new INSERT policies listed

## What This Fixes

Adds INSERT policies for:
- ✅ **Admins** - Can insert any event (full access)
- ✅ **Directors** - Can insert events for their org's cases
- ✅ **Editors** - Can insert events for their assigned cases
- ✅ **QC** - Can insert events for cases they review
- ✅ **Family** - Can insert events for their case

## Test After Applying

1. Go to Admin Portal → All Cases
2. Open any case
3. Click "Reassign Editor"
4. Select a different editor
5. Click "Reassign Editor" button
6. **Should see:** Success modal (centered, green)
7. **Console should show:** ✅ Audit trail updated successfully
8. **Audit tab should show:** New "editor_reassigned" event

## Changes Made

### UI Improvements ✅
- ✅ Success message now shows as centered modal (not toast in corner)
- ✅ Modal has detailed message and OK button
- ✅ Errors still show as toast (quick, non-blocking)

### Database Fix 🔧
- Created: `supabase/migrations/044_fix_events_insert_policy.sql`
- Created: `FIX-AUDIT-TRAIL-RLS.sql` (for manual application)
- Adds INSERT policies to events table for all roles

---

**After applying this fix, audit trail logging will work for:**
- Editor reassignments
- QC reviews  
- Status changes
- All other system events
