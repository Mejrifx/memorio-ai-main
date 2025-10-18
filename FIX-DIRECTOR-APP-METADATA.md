# Fix Director App Metadata Issue

## Problem

**Your cases disappeared because the director account is missing `app_metadata` in the JWT.**

The RLS (Row Level Security) policies check for:
- `auth.jwt() -> 'app_metadata' ->> 'role'` = 'director'
- `auth.jwt() -> 'app_metadata' ->> 'org_id'` = your organization ID

But your director account only has this data in `user_metadata`, which is **NOT included in the JWT** by default.

## Solution

You have **2 options**:

### Option 1: Update Existing Director Account (Recommended if you want to keep the same account)

1. **Go to Supabase Dashboard**
2. **Navigate to**: Authentication → Users
3. **Find your director account** (the email you're using to log in)
4. **Click on the user** to open details
5. **Scroll down to "User Metadata"** section
6. **You'll see 2 sections**: 
   - `user_metadata` (has role, name, org_id currently)
   - `app_metadata` (empty or missing)

7. **Click "Edit" on `app_metadata`**
8. **Add this JSON** (replace with your actual org_id):
   ```json
   {
     "role": "director",
     "org_id": "your-actual-org-id-here"
   }
   ```

9. **Save changes**
10. **Log out from Director Portal**
11. **Log back in** - This will refresh the JWT with the new app_metadata
12. **Your cases should now appear!**

### Option 2: Recreate Director Account (Easier but requires new credentials)

1. **Delete the existing director account** from Supabase Dashboard (Authentication → Users)
2. **Go to Admin Portal** and create a new director invitation
3. **The new invite will have the correct `app_metadata` automatically**
4. **Use the new credentials to log in**
5. **Cases will be visible immediately**

---

## How to Find Your Organization ID

1. **Go to Supabase Dashboard**
2. **Navigate to**: Table Editor → organizations
3. **Find your organization** in the list
4. **Copy the `id` column value** (it's a UUID like `123e4567-e89b-12d3-a456-426614174000`)

---

## Verify the Fix

After applying one of the solutions above:

1. **Log in to Director Portal**
2. **Open Browser Console** (F12 or Right Click → Inspect → Console tab)
3. **Go to "My Cases" tab**
4. **Check the console logs** - you should see:
   ```
   Current session: Active
   User ID: [your-user-id]
   User metadata: {...}
   App metadata: { role: "director", org_id: "..." }
   Successfully loaded X cases
   ```

If you see `App metadata: { role: "director", org_id: "..." }` - **it's fixed!**

---

## Why This Happened

The original `invite-director` Edge Function was incorrectly setting the role and org_id in `user_metadata` instead of `app_metadata`. This has now been fixed in the code, but existing director accounts need to be updated manually.

**Going forward**: All new director invitations will automatically have the correct `app_metadata` set.

---

## Need Help?

If you're still having issues:

1. Check the browser console for error messages
2. Verify the organization ID is correct
3. Make sure you logged out and back in after updating app_metadata
4. Try creating a new test director account to verify the fix works for new accounts

