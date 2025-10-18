# Troubleshooting: Cases Disappearing in Director Portal

## The Problem

You're experiencing:
1. ✅ Case created successfully
2. ✅ Family invited and form submitted
3. ✅ Status updates from "waiting_on_family" to "submitted"
4. ❌ Case disappears when you navigate away and come back
5. ❌ Logout/login and hard refresh don't fix it

## Root Cause

**Your director account is missing `app_metadata` in the JWT token.**

The RLS (Row Level Security) policies require:
- `auth.jwt() -> 'app_metadata' ->> 'role'` = 'director'
- `auth.jwt() -> 'app_metadata' ->> 'org_id'` = your organization ID

If these are missing, **ALL database queries return empty results** because RLS blocks access.

---

## Immediate Diagnosis

### Step 1: Open Browser Console

1. **Log in to Director Portal**
2. **Press F12** (or Right Click → Inspect)
3. **Click "Console" tab**
4. **Look for this output:**

```
=== AUTHENTICATION CHECK ===
Session exists: true
User ID: [your-user-id]
User Email: [your-email]
JWT app_metadata: { role: "director", org_id: "[uuid]" }
JWT user_metadata: { name: "...", phone: "..." }
JWT Role from app_metadata: director
JWT Org ID from app_metadata: [uuid]
Database user data: { role: "director", org_id: "[uuid]" }
✅ Authentication successful
Director Org ID: [uuid]
=== END AUTH CHECK ===
```

### Step 2: Check for the Problem

**If you see this:**
```
JWT app_metadata: {}
JWT Role from app_metadata: undefined
JWT Org ID from app_metadata: undefined
❌ CRITICAL: Missing app_metadata in JWT!
```

**Then you have the app_metadata issue!**

---

## The Fix

You have **3 options** to fix this:

### Option 1: Update Your Existing Account (Recommended)

**Step-by-step:**

1. **Go to Supabase Dashboard**: https://supabase.com/dashboard
2. **Navigate to**: Authentication → Users
3. **Find your director email** in the users list
4. **Click on the user** to open their details
5. **Scroll down to the metadata sections**
6. **Look for `app_metadata` section** (it's probably empty or has `{}`)
7. **Click "Edit" next to `app_metadata`**
8. **Add this JSON** (replace with your actual org_id):

```json
{
  "role": "director",
  "org_id": "your-actual-organization-id-here"
}
```

9. **How to get your org_id:**
   - Go to Supabase Dashboard → Table Editor → organizations
   - Find your organization
   - Copy the `id` column value (UUID)

10. **Click "Save"**
11. **IMPORTANT: Log out of Director Portal**
12. **Log back in** (this refreshes the JWT with new metadata)
13. **Check console** - you should now see proper app_metadata
14. **Your cases will reappear!**

---

### Option 2: Recreate Director Account (Fastest)

1. **Go to Supabase Dashboard** → Authentication → Users
2. **Delete your current director account**
3. **Go to Admin Portal**
4. **Create a new director invitation** for the same organization
5. **Use the new credentials** to log in
6. **The new account will have proper app_metadata automatically**

**Note**: This requires the `invite-director` Edge Function to be redeployed with the fix.

---

### Option 3: SQL Update (For Advanced Users)

If you're comfortable with SQL:

```sql
-- Get your user ID first
SELECT id, email FROM auth.users WHERE email = 'your-director-email@example.com';

-- Update app_metadata (replace USER_ID and ORG_ID)
UPDATE auth.users
SET raw_app_meta_data = jsonb_set(
  COALESCE(raw_app_meta_data, '{}'::jsonb),
  '{role}',
  '"director"'::jsonb
)
WHERE id = 'USER_ID';

UPDATE auth.users
SET raw_app_meta_data = jsonb_set(
  raw_app_meta_data,
  '{org_id}',
  '"ORG_ID"'::jsonb
)
WHERE id = 'USER_ID';
```

Then log out and log back in.

---

## Verification Steps

After applying the fix:

### 1. Check Console Logs

Log in and verify you see:
```
✅ Authentication successful
JWT app_metadata: { role: "director", org_id: "[uuid]" }
```

### 2. Test Case Visibility

1. Go to "My Cases" tab
2. Your cases should appear
3. Console should show:
   ```
   Successfully loaded X cases
   ```

### 3. Navigate Away and Back

1. Go to another tab (Create Case, Invite Family)
2. Return to "My Cases"
3. Cases should still be there
4. If they disappear again, app_metadata update didn't work

---

## Why This Happens

### The JWT Structure

Supabase Auth stores user data in two places:

**1. `user_metadata`** (NOT in JWT by default):
```json
{
  "name": "John Director",
  "phone": "555-1234"
}
```
- ❌ Not included in JWT
- ❌ RLS policies can't see this
- ✅ Good for non-sensitive display data

**2. `app_metadata`** (IN JWT):
```json
{
  "role": "director",
  "org_id": "uuid-here"
}
```
- ✅ Included in JWT automatically
- ✅ RLS policies can access this
- ✅ Required for multi-tenant security

### The Bug

The original `invite-director` function set everything in `user_metadata`:
```typescript
// WRONG ❌
user_metadata: {
  role: 'director',    // Not in JWT!
  org_id: 'uuid'       // Not in JWT!
}
```

Should have been:
```typescript
// CORRECT ✅
app_metadata: {
  role: 'director',    // In JWT!
  org_id: 'uuid'       // In JWT!
}
```

### Why Cases Disappear

1. **You log in** → Session created
2. **RLS checks JWT** → No app_metadata → Empty results
3. **Page loads** → Queries return nothing
4. **You see**: "No cases found"

The cases are still in the database! RLS is just blocking you from seeing them because your JWT doesn't prove you have the right role/org.

---

## Preventing This Issue

### For New Accounts

✅ The `invite-director` function has been fixed
✅ New director invitations will have proper `app_metadata`
✅ Redeploy the Edge Function to apply the fix

### For Existing Accounts

⚠️ Must be updated manually (see Option 1 above)
⚠️ Or recreate the account (see Option 2 above)

---

## Still Having Issues?

### 1. Double-Check the Fix

Run this in Supabase SQL Editor:
```sql
SELECT 
  email,
  raw_app_meta_data,
  raw_user_meta_data
FROM auth.users
WHERE email = 'your-director-email@example.com';
```

Verify `raw_app_meta_data` contains:
```json
{"role": "director", "org_id": "your-uuid"}
```

### 2. Force JWT Refresh

```javascript
// Run in browser console while logged in
await supabaseClient.auth.refreshSession();
location.reload();
```

### 3. Check RLS Policies

Verify the policies are active:
```sql
SELECT * FROM pg_policies WHERE tablename = 'cases';
```

### 4. Test RLS Directly

```sql
-- Set JWT manually and test query
SET request.jwt.claims = '{"app_metadata": {"role": "director", "org_id": "YOUR_ORG_ID"}}';
SELECT * FROM cases;
```

---

## Quick Reference

| Symptom | Cause | Fix |
|---------|-------|-----|
| Cases disappear | Missing app_metadata | Update user account |
| "No cases found" | RLS blocking queries | Add role & org_id to JWT |
| Can log in but no data | JWT missing claims | Logout, update metadata, login |
| Works then stops working | JWT not refreshed | Force refresh or recreate account |

---

## Summary

✅ **Diagnosis**: Check browser console for JWT app_metadata
✅ **Fix**: Add role and org_id to app_metadata in Supabase Dashboard
✅ **Verify**: Log out, log in, check console shows proper metadata
✅ **Prevent**: Use updated invite-director function for new accounts

**The cases are NOT deleted - they're just hidden by RLS!**

