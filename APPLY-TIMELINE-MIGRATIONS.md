# Apply Migrations 042-044: Complete Timeline Enhancement

## Overview
This applies three migrations to fix the admin timeline and show clear, specific event descriptions with full actor details.

## Migrations to Apply

### Migration 042: Enhanced Timeline Events (Already Applied ✅)
- Enhanced audit logging function
- Timeline view with actor details
- Better event descriptions

### Migration 043: Better Form Submission Event Logging (NEW)
- Logs specific `form_submitted` event when family completes intake form
- Includes timestamp in payload

### Migration 044: Video Submission Event Logging (NEW)
- Logs specific events for video submissions: `video_submitted`
- Logs QC review outcomes: `qc_approved`, `qc_revision`, `qc_rejected`
- Includes editor/QC details in payload

## How to Apply

### Via Supabase Dashboard

1. Go to https://supabase.com/dashboard/project/gkabtvqwwuvigcdubwyv/sql
2. Click **SQL Editor** → **New Query**
3. Copy and paste **Migration 043** (form submission events)
4. Click **Run**
5. Repeat for **Migration 044** (video submission events)

### SQL Files

- `supabase/migrations/043_better_form_submission_event.sql`
- `supabase/migrations/044_video_submission_event_logging.sql`

## Expected Timeline Output

After applying all migrations, your timeline will show:

```
🕐 01/01/2026, 18:39:40
   QC approved video - delivered to family by Sarah Chen
   By: Sarah Chen 🔍 QC

🕐 01/01/2026, 18:39:28
   Video submitted to QC by John Smith (Revision #1)
   By: John Smith ✏️ Editor

🕐 01/01/2026, 18:38:15
   Editor automatically assigned: John Smith
   By: Family Member 👨‍👩‍👧 Family

🕐 01/01/2026, 18:38:13
   Intake form completed and submitted by family
   By: Jane Doe 👨‍👩‍👧 Family

🕐 01/01/2026, 18:37:11
   Status changed from "created" to "waiting_on_family"
   By: System ⚙️ System

🕐 01/01/2026, 18:36:57
   Case created for John Doe (deceased)
   By: Michael Brown 👔 Director
```

## What Each Event Shows

| Event Type | What You'll See |
|------------|-----------------|
| **Case Created** | "Case created for [name]" + Director name |
| **Form Submitted** | "Intake form completed and submitted" + Family name |
| **Editor Assigned** | "Editor automatically assigned: [editor name]" + Family who triggered it |
| **Video Submitted** | "Video submitted to QC by [editor]" + Editor name |
| **QC Approved** | "QC approved video - delivered to family by [QC]" + QC name |
| **QC Revision** | "QC requested revision by [QC]" + QC name |
| **Status Changed** | "Status changed from X to Y" + Who changed it |

## Frontend Changes (Already Applied ✅)

The frontend (`m-admin-3k5a/case-detail.html`) has been updated to:

1. **Parse payload data** - Extracts specific details from event payloads
2. **Show actor names** - Displays actual user names/emails, not just roles
3. **Format descriptions** - Converts action types to human-readable text
4. **Add role badges** - Shows emoji icons for each role (👑 Admin, 👔 Director, etc.)

## Testing Checklist

After applying migrations:

- [ ] Go to Admin Panel → All Cases
- [ ] Open any case that has activity
- [ ] Check Timeline tab shows:
  - [ ] "Case created for [name]" with director name
  - [ ] "Intake form completed and submitted" with family name
  - [ ] "Editor automatically assigned: [name]" with editor name
  - [ ] "Video submitted to QC by [name]" with editor name
  - [ ] "QC approved video - delivered to family by [name]" with QC name
  - [ ] Actor names displayed (not just "authenticated" or "System")
  - [ ] Role badges with emojis (👑, 👔, 👨‍👩‍👧, ✏️, 🔍)

## Troubleshooting

### If timeline still shows generic "Status changed"

- **Check payload**: Open browser console, look for `🔍 Formatting event:` logs
- **Verify migrations**: Run `SELECT * FROM events ORDER BY timestamp DESC LIMIT 5;` to check event structure
- **Check actor info**: Verify `admin_users_view` returns user details

### If actor names don't show

- **Check join**: Verify `admin_users_view` exists and has data
- **Check console**: Look for "Could not fetch user details" errors
- **Verify RLS**: Ensure admin role can read from `admin_users_view`

## Rollback

If needed, to rollback these changes:

```sql
-- Remove migration 044 trigger
DROP TRIGGER IF EXISTS video_submission_events ON video_submissions;
DROP FUNCTION IF EXISTS log_video_submission_events();

-- Restore original form submission function (see migration 003)
-- ... (would need to copy from original migration)
```

## Next Steps

Once applied:
1. Test with existing cases
2. Create a new case to verify timeline for new activity
3. Monitor console for any errors
4. Adjust descriptions as needed for your workflow

All frontend changes are already deployed in the latest commit!

