# 🚨 URGENT: Fix All Director and Family Accounts

## The Problem

You have **TWO issues**:

1. **New accounts are broken** → The fixed `invite-director` function hasn't been deployed
2. **Existing accounts are broken** → They have wrong metadata structure

This is why:
- New director account shows "missing metadata" error
- User count shows 0 even though users exist
- Cases disappear after refresh

---

## 🔧 **Complete Fix (Do These Steps in Order)**

### **Step 1: Fix ALL Existing Accounts** (2 minutes)

This SQL will fix **every** director and family account in your database at once.

1. **Go to Supabase Dashboard** → SQL Editor
2. **Click "+ New Query"**
3. **Copy and paste** the entire contents of:
   `supabase/migrations/011_fix_existing_user_app_metadata.sql`
4. **Click "Run"**
5. **You should see**: `Success. No rows returned`

**What this does:**
- ✅ Fixes ALL director accounts
- ✅ Fixes ALL family accounts
- ✅ Fixes ALL admin accounts
- ✅ Moves role and org_id to app_metadata
- ✅ Logs the fixes in events table

### **Step 2: Deploy Fixed Edge Function** (5 minutes)

Now we need to deploy the corrected invite function so **new** accounts work.

#### **Option A: Using Supabase CLI** (Recommended)

```bash
cd /Users/mejrifx/Downloads/memorio-ai

# Make sure you're linked to your project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy the fixed function
supabase functions deploy invite-director
```

#### **Option B: Manual Deployment** (If CLI doesn't work)

1. **Go to Supabase Dashboard** → Edge Functions
2. **Click "Create a new function"** or find existing `invite-director`
3. **Copy entire contents** of `supabase/functions/invite-director/index.ts`
4. **Paste into the editor**
5. **Click "Deploy"**

### **Step 3: Verify Everything Works** (2 minutes)

#### **Test 1: Existing Accounts**

1. **Log out** from all portals
2. **Log in as your existing director**
3. **Should work now!** Cases should appear
4. **Check console** - should show proper app_metadata

#### **Test 2: New Accounts**

1. **Go to Admin Portal**
2. **Create a NEW director invitation**
3. **Log in with new credentials**
4. **Should work immediately!** No metadata error

---

## 🔍 **Why This Happened**

### **The Metadata Confusion**

Supabase Auth has TWO metadata fields:

| Field | In JWT? | RLS Can See? | Purpose |
|-------|---------|--------------|---------|
| `user_metadata` | ❌ No | ❌ No | Display data (name, phone) |
| `app_metadata` | ✅ Yes | ✅ Yes | Security claims (role, org_id) |

### **The Bug**

**Original code** (WRONG):
```typescript
user_metadata: {
  role: 'director',   // ❌ Not in JWT
  org_id: 'uuid'      // ❌ Not in JWT
}
```

**Fixed code** (CORRECT):
```typescript
app_metadata: {
  role: 'director',   // ✅ In JWT
  org_id: 'uuid'      // ✅ In JWT
}
```

### **The Impact**

- RLS policies check JWT for role/org_id
- JWT didn't have these values
- RLS blocked all queries
- Result: Empty case lists, "no access" errors

---

## 📋 **Verification Queries**

After running the fix, verify it worked:

### **Check App Metadata**

```sql
SELECT 
  u.email,
  u.role,
  u.org_id::text as database_org_id,
  au.raw_app_meta_data->>'role' as jwt_role,
  au.raw_app_meta_data->>'org_id' as jwt_org_id,
  CASE 
    WHEN au.raw_app_meta_data->>'role' = u.role 
    AND au.raw_app_meta_data->>'org_id' = u.org_id::text
    THEN '✅ FIXED'
    ELSE '❌ NEEDS FIX'
  END as status
FROM public.users u
JOIN auth.users au ON au.id = u.id
WHERE u.role IN ('director', 'family')
ORDER BY u.role, u.email;
```

### **Check User Count Per Org**

```sql
SELECT 
  o.name as organization,
  o.id as org_id,
  COUNT(u.id) as user_count,
  STRING_AGG(u.role || ': ' || u.email, ', ') as users
FROM organizations o
LEFT JOIN users u ON u.org_id = o.id
GROUP BY o.id, o.name
ORDER BY o.name;
```

---

## 🎯 **Expected Results**

### **After Step 1 (SQL Migration)**

All existing accounts will have:
```json
{
  "role": "director",
  "org_id": "actual-uuid-here"
}
```

### **After Step 2 (Deploy Function)**

New invitations will automatically create accounts with proper app_metadata.

### **After Step 3 (Verification)**

- ✅ Existing directors can log in
- ✅ Cases appear in "My Cases"
- ✅ New directors work immediately
- ✅ Family accounts work
- ✅ Delete org shows correct user count

---

## 🚨 **Troubleshooting**

### Issue: SQL Migration Fails

**Error**: "permission denied for table auth.users"

**Fix**:
```sql
-- Grant permission
GRANT UPDATE ON auth.users TO postgres;
GRANT SELECT ON auth.users TO postgres;

-- Then re-run the migration
```

### Issue: Function Deployment Fails

**Error**: "Function not found" or "Deployment failed"

**Fix**: Use Manual Deployment (Option B above)

### Issue: Still Shows Metadata Error

**Cause**: JWT not refreshed

**Fix**:
1. **Completely close** the browser tab
2. **Clear browser cache** (Ctrl+Shift+Delete)
3. **Open new tab** and log in again
4. **Or**: Log in from incognito/private window

### Issue: User Count Still Shows 0

**Cause**: May need to refresh the page after fixing metadata

**Fix**: 
1. Hard refresh (Ctrl+Shift+R or Cmd+Shift+R)
2. Re-open the delete dialog
3. Should now show correct count

---

## 📝 **Summary Checklist**

- [ ] **Step 1**: Run SQL migration to fix all existing accounts
- [ ] **Step 2**: Deploy fixed invite-director Edge Function
- [ ] **Step 3**: Test existing director login (should work)
- [ ] **Step 4**: Test new director invitation (should work)
- [ ] **Step 5**: Verify user count shows correctly
- [ ] **Step 6**: Verify cases appear in director portal

---

## 🎉 **After Completing These Steps**

Everything will work:
- ✅ All existing accounts fixed
- ✅ New accounts work correctly
- ✅ Cases visible in director portal
- ✅ Proper user counts
- ✅ Complete organization deletion
- ✅ No more metadata errors

---

## 💡 **Prevention**

**Going forward:**
- New director invitations will work correctly (after Step 2)
- New family invitations already work (we fixed that earlier)
- No manual metadata updates needed
- System fully functional

---

## 🆘 **Still Need Help?**

If anything doesn't work:

1. **Check the events log**:
   ```sql
   SELECT * FROM events 
   WHERE action_type = 'FIX_APP_METADATA' 
   ORDER BY timestamp DESC;
   ```

2. **Verify the fix was applied**:
   ```sql
   SELECT COUNT(*) as fixed_count
   FROM auth.users au
   JOIN public.users u ON u.id = au.id
   WHERE au.raw_app_meta_data->>'role' IS NOT NULL;
   ```

3. **Check specific user**:
   ```sql
   SELECT 
     email,
     raw_app_meta_data,
     raw_user_meta_data
   FROM auth.users
   WHERE email = 'your-director-email@example.com';
   ```

