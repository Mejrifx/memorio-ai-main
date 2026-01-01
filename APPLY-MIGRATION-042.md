# Migration 042: Enhanced Timeline Events

## Purpose
Improve the admin timeline display to show specific, meaningful event descriptions instead of generic "Case updated" messages.

## Problem
Current timeline shows:
```
27/12/2025, 16:34:51
Case updated
By: authenticated
```

This is not descriptive - we don't know WHAT was updated.

## Solution
This migration:
1. **Enhances the audit logging function** to detect specific changes (status, family assignment, form submission, etc.)
2. **Creates a helper function** `get_event_description()` to generate human-readable descriptions
3. **Creates a view** `timeline_view` that joins events with user details (name, email)
4. **Updates frontend** to display:
   - Specific event descriptions ("Status changed from 'created' to 'submitted'")
   - Actor name/email (not just role)
   - Role badges with icons

## How to Apply

### Option 1: Via Supabase Dashboard (Recommended)

1. Go to https://gkabtvqwwuvigcdubwyv.supabase.co
2. Navigate to **SQL Editor**
3. Click **New Query**
4. Copy and paste the contents of `supabase/migrations/042_enhance_timeline_events.sql`
5. Click **Run**
6. Verify success: Run `SELECT * FROM timeline_view LIMIT 5;`

### Option 2: Via psql (if installed)

```bash
psql "postgresql://postgres.gkabtvqwwuvigcdubwyv:Mejri1990!@aws-0-eu-central-1.pooler.supabase.com:6543/postgres" \
  -f supabase/migrations/042_enhance_timeline_events.sql
```

## What Changes

### Database
- ✅ Function: `log_enhanced_audit_event()` - detects specific changes
- ✅ Function: `get_event_description()` - formats descriptions
- ✅ View: `timeline_view` - includes actor details
- ✅ Triggers updated to use enhanced logging

### Frontend (Already Applied)
- ✅ Timeline now uses `timeline_view` instead of raw `events` table
- ✅ Displays actor name/email instead of just role
- ✅ Shows role badges with emoji icons
- ✅ Formats event descriptions intelligently

## Testing

After applying the migration:

1. Go to Admin Panel → All Cases
2. Click on any case
3. View the Timeline tab
4. You should now see:
   - ✅ "Status changed from 'created' to 'submitted'" (instead of "Case updated")
   - ✅ "By: John Doe 👨‍👩‍👧 Family" (instead of "By: family")
   - ✅ "Intake form submitted by family" (instead of "Case updated")

## Rollback

If you need to rollback this migration:

```sql
-- Restore original audit function
CREATE OR REPLACE FUNCTION log_audit_event()
RETURNS TRIGGER AS $$
-- ... (see migrations/003_functions_triggers.sql)
$$;

-- Drop new view
DROP VIEW IF EXISTS timeline_view;

-- Drop new function
DROP FUNCTION IF EXISTS get_event_description(TEXT, JSONB, TEXT);

-- Restore original triggers
-- (see migrations/003_functions_triggers.sql)
```

## Files Modified

- `supabase/migrations/042_enhance_timeline_events.sql` - New migration file
- `m-admin-3k5a/case-detail.html` - Updated timeline display logic
- `apply-migration-042.sh` - Migration application script
- `APPLY-MIGRATION-042.md` - This documentation

## Expected Results

**Before:**
```
27/12/2025, 16:34:51
Case updated
By: authenticated

27/12/2025, 16:34:48
Case updated
By: authenticated
```

**After:**
```
27/12/2025, 16:34:51
Status changed from "created" to "submitted"
By: Sarah Johnson 👨‍👩‍👧 Family

27/12/2025, 16:34:48
Intake form submitted by family
By: Sarah Johnson 👨‍👩‍👧 Family

27/12/2025, 16:34:16
Editor automatically assigned
By: System ⚙️ System

27/12/2025, 16:34:08
Case created
By: Michael Brown 👔 Director
```

Much clearer! ✨

