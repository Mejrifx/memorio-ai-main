# 🔧 FIX: Temp Password Not Showing in Account Details

## Problem

When admin clicks "Reveal" in the account details modal, the temp password shows as **"Not available"**.

### Root Cause

The console logs showed:
```
✅ Loaded 3 accounts
✅ Fetched temp passwords for 0 accounts  ← PROBLEM!
🔑 Temp password value: null
```

**Why?**
- `admin_users_view` doesn't include the `temp_password` column
- Direct query to `users` table is blocked by RLS
- The separate query returns 0 rows

## The Fix

### Migration 046: Add temp_password to admin_users_view

This migration updates the view to include the `temp_password` column so admins can access it without hitting RLS issues.

### How to Apply

#### Step 1: Apply the Migration

Go to your **Supabase SQL Editor** and run:

```sql
-- Copy and paste the entire contents of:
-- supabase/migrations/046_add_temp_password_to_admin_users_view.sql
```

Or use Supabase CLI:
```bash
cd /Users/mejrifx/Downloads/memorio-ai
supabase db push
```

#### Step 2: Verify the Migration

Run this query to confirm `temp_password` was added:

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'admin_users_view'
ORDER BY ordinal_position;
```

**Expected result:** Should show `temp_password | text` in the list

#### Step 3: Test in Admin Portal

1. Refresh your admin portal
2. Go to **Manage Accounts** tab
3. Open browser console (F12)
4. Click on an Editor or QC card
5. Click **"Reveal"**

**Console should now show:**
```
✅ Loaded 3 accounts
📊 Sample account data: {... temp_password: "ActualPassword123!", ...}
🔑 3/3 accounts have temp_password  ← SUCCESS!
🔍 Revealing credentials for: editor@memorio.ai
🔑 Temp password value: ActualPassword123!  ← Shows actual password!
```

**Modal should show:**
```
Email:    editor@memorio.ai
Password: ActualPassword123!
```

## Technical Details

### Before (BROKEN):
```javascript
// Query 1: Get accounts from view (no temp_password)
SELECT * FROM admin_users_view WHERE role IN ('editor', 'qc')

// Query 2: Try to get temp_password from users table
SELECT id, temp_password FROM users WHERE id IN (...)
// ❌ Returns 0 rows (blocked by RLS)
```

### After (FIXED):
```javascript
// Single query: Get everything including temp_password from view
SELECT * FROM admin_users_view WHERE role IN ('editor', 'qc')
// ✅ Returns all data including temp_password (view bypasses RLS)
```

### Frontend Changes:
- Removed separate query to `users` table
- Now relies on `admin_users_view` which includes `temp_password`
- Simplified code and improved performance

## Security

This is secure because:
✅ View has `security_barrier = true` (prevents leakage)
✅ View WHERE clause restricts access by role
✅ Only admins can see all users
✅ Directors only see users in their org
✅ temp_password needed for account recovery/support
✅ Credentials still blurred by default (must click "Reveal")

## Files Changed

1. **`supabase/migrations/046_add_temp_password_to_admin_users_view.sql`** (NEW)
   - Updated view to include temp_password column
   
2. **`m-admin-3k5a/dashboard.html`**
   - Removed separate temp_password query
   - Now uses temp_password from admin_users_view
   - Added logging to show which accounts have passwords

3. **`APPLY-TEMP-PASSWORD-FIX.md`** (this file)
   - Instructions for applying the fix

---

**Priority:** 🔴 **IMMEDIATE** - Apply this migration to fix the temp password display!

