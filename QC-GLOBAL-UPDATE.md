# QC Global Access Update

## ✅ Changes Deployed

**Commit:** `66df9ee`  
**Edge Function:** `invite-qc` (deployed successfully)

---

## 🎯 What Changed

QC users are now **GLOBAL** and can review videos from **ALL funeral homes**, not just one organization.

### Before:
- ❌ QC assigned to specific funeral home
- ❌ Could only see cases from their org
- ❌ Admin had to invite separate QC per funeral home

### After:
- ✅ QC has global access (like Admins)
- ✅ Can see cases from ALL organizations
- ✅ One QC team processes all videos

---

## 📋 Steps to Apply

### 1. **Run the Database Migration**

```sql
-- Copy and paste this into Supabase SQL Editor:
-- Location: supabase/migrations/021_make_qc_global.sql
```

Go to: https://supabase.com/dashboard/project/gkabtvqwwuvigcdubwyv/sql/new

Then run the migration file: `/Users/mejrifx/Downloads/memorio-ai/supabase/migrations/021_make_qc_global.sql`

**What it does:**
1. Sets existing QC users' `org_id` to `NULL`
2. Drops old org-scoped RLS policies
3. Creates new global RLS policies for QC
4. Updates case notes and events policies

### 2. **Test the Changes**

#### A. Test in Admin Portal
1. Go to Admin Dashboard → "Invite QC User"
2. Notice: **No funeral home dropdown** ✅
3. Fill in: Email, Name, Phone
4. Click "CREATE GLOBAL QC ACCOUNT"
5. Success box should say: "🌍 This QC user has global access..."

#### B. Test in QC Portal
1. Login as QC user
2. Should see cases from **ALL funeral homes**
3. Can filter by organization
4. Can review any video submission

---

## 🔍 Verification Queries

Run these in Supabase SQL Editor to verify:

```sql
-- 1. Check QC users have NULL org_id
SELECT id, email, role, org_id 
FROM users 
WHERE role = 'qc';
-- Expected: org_id should be NULL

-- 2. Check QC policies exist
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE policyname LIKE '%QC%' 
   OR policyname LIKE '%qc%'
ORDER BY tablename, policyname;
-- Expected: Should see "QC users read all cases", etc.

-- 3. Test QC access (simulate as QC user)
SET request.jwt.claims = '{"role": "qc", "sub": "<any_qc_user_id>"}';
SELECT COUNT(*) FROM cases;
-- Expected: Should see ALL cases, not just one org
```

---

## 🎨 UI Changes

### Admin Portal - Invite QC Tab

**Old UI:**
```
Email: [____________]    Name: [____________]
Funeral Home: [Dropdown]  Phone: [____________]
                   [CREATE QC ACCOUNT]
```

**New UI:**
```
Email: [____________]    Name: [____________]
Phone: [____________]    [🌍 Global Access Info Box]
                   [CREATE GLOBAL QC ACCOUNT]
```

**Success Box:**
```
✅ QC Account Created Successfully!
🌍 This QC user has global access to review videos from all funeral homes.

Email: qc@example.com [Copy]
Password: temp123 [Copy]
Login URL: https://memorio.ai/m-qc-4h7k/login.html [Copy]
```

---

## 🏗️ Architecture Update

### User Role Scoping

| Role | org_id | Access Scope |
|------|--------|-------------|
| **admin** | `NULL` | All organizations |
| **qc** | `NULL` ✅ | All organizations (NEW) |
| **director** | `UUID` | Single organization |
| **editor** | `UUID` | Single organization |
| **family** | `UUID` | Single case (via org) |

---

## 🚨 Important Notes

1. **Existing QC Users**: If you already created QC users with an org_id, the migration will automatically update them to NULL.

2. **RLS Policies**: The migration drops old policies first, then creates new ones. This prevents conflicts.

3. **Edge Function**: Already deployed - no manual deployment needed.

4. **No Data Loss**: This change only affects access permissions, not data.

---

## 🧪 Test Checklist

- [ ] Run migration in Supabase SQL Editor
- [ ] Verify QC users have `org_id = NULL`
- [ ] Verify new RLS policies exist
- [ ] Test creating a new QC account in Admin Portal
- [ ] Test logging in as QC and viewing all cases
- [ ] Test QC can review videos from multiple funeral homes
- [ ] Test QC can see organization name on each case

---

## ❓ Troubleshooting

**Problem:** Migration fails with "policy already exists"  
**Solution:** The migration includes `DROP POLICY IF EXISTS` - should not happen. If it does, run the DROP statements manually first.

**Problem:** QC can't see any cases  
**Solution:** Check JWT in browser console - should have `"role": "qc"` and no `org_id`

**Problem:** Old QC accounts still org-scoped  
**Solution:** Run: `UPDATE users SET org_id = NULL WHERE role = 'qc';`

---

**Ready to apply the migration!** Just run the SQL file in Supabase Dashboard. 🚀

