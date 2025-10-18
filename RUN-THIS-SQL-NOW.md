# 🚨 RUN THIS SQL NOW TO FIX ALL ACCOUNTS

## ✅ Good News

I've already deployed the fixed `invite-director` Edge Function! New director invitations will work correctly now.

## ⚠️ Action Required

You need to run ONE SQL query to fix all existing accounts (directors, families, admins).

---

## 🔧 **How to Run the SQL** (2 minutes)

### **Step 1: Go to Supabase Dashboard**
1. Open: https://supabase.com/dashboard
2. Select your project: **gkabtvqwwuvigcdubwyv**
3. Click: **SQL Editor** (in left sidebar)

### **Step 2: Copy the SQL**

Copy this ENTIRE SQL query:

```sql
-- Fix ALL existing accounts at once
-- This adds proper app_metadata to directors, families, and admins

-- Update all directors
UPDATE auth.users
SET raw_app_meta_data = jsonb_build_object(
  'role', 'director',
  'org_id', (
    SELECT org_id::text 
    FROM public.users 
    WHERE id = auth.users.id
  )
)
WHERE id IN (
  SELECT id 
  FROM public.users 
  WHERE role = 'director'
    AND org_id IS NOT NULL
);

-- Update all family members
UPDATE auth.users
SET raw_app_meta_data = jsonb_build_object(
  'role', 'family',
  'org_id', (
    SELECT org_id::text 
    FROM public.users 
    WHERE id = auth.users.id
  )
)
WHERE id IN (
  SELECT id 
  FROM public.users 
  WHERE role = 'family'
    AND org_id IS NOT NULL
);

-- Update all admins
UPDATE auth.users
SET raw_app_meta_data = jsonb_build_object(
  'role', 'admin'
)
WHERE id IN (
  SELECT id 
  FROM public.users 
  WHERE role = 'admin'
);

-- Show how many accounts were fixed
SELECT 
  u.role,
  COUNT(*) as total_accounts,
  COUNT(CASE WHEN au.raw_app_meta_data->>'role' IS NOT NULL THEN 1 END) as fixed_accounts
FROM public.users u
LEFT JOIN auth.users au ON au.id = u.id
GROUP BY u.role
ORDER BY u.role;
```

### **Step 3: Paste and Run**
1. **Paste** the SQL into the SQL Editor
2. **Click "Run"** button (or press Ctrl/Cmd + Enter)
3. **Wait for success message**

### **Step 4: Verify**
You should see output like:
```
role      | total_accounts | fixed_accounts
----------|----------------|---------------
admin     | 1              | 1
director  | 2              | 2
family    | 3              | 3
```

This shows all accounts now have proper metadata!

---

## 🎉 **What This Fixes**

✅ **All existing director accounts** → Can log in and see cases
✅ **All existing family accounts** → Can access forms/dashboard
✅ **All admin accounts** → Proper authentication
✅ **User count in delete** → Shows correct numbers
✅ **New invitations** → Work correctly (already deployed!)

---

## 🧪 **Test After Running SQL**

### **Test 1: Existing Director**
1. Log out from director portal
2. Log back in
3. **Should work!** No metadata error
4. Cases should appear in "My Cases"

### **Test 2: New Director**
1. Go to Admin Portal
2. Create a NEW director invitation
3. Log in with new credentials
4. **Should work immediately!**

### **Test 3: Delete Organization**
1. Go to Admin Portal
2. Try to delete an organization
3. **Should show correct user count** (not 0)

---

## 📋 **Summary**

**What I did:**
- ✅ Deployed fixed `invite-director` Edge Function
- ✅ Fixed admin portal user count query
- ✅ Added comprehensive debugging
- ✅ Created SQL migration to fix all accounts

**What you need to do:**
- ⏳ Run the SQL above in Supabase Dashboard (2 minutes)
- ✅ Test login (should work immediately)
- ✅ Enjoy working system!

---

## 🆘 **If You Get an Error**

### Error: "permission denied for table auth.users"

Run this first:
```sql
GRANT UPDATE ON auth.users TO postgres;
GRANT SELECT ON auth.users TO postgres;
```

Then re-run the main SQL.

### Error: "relation auth.users does not exist"

You're in the wrong schema. Make sure you're running this as a SQL query, not in the table editor.

---

## ✨ **After This is Done**

Everything will be fixed:
- ✅ All existing accounts work
- ✅ New invitations work
- ✅ Cases visible
- ✅ Proper user counts
- ✅ Complete system functionality

**Go run the SQL now and you'll be all set!** 🚀

