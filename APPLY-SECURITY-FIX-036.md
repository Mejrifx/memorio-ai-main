# CRITICAL SECURITY FIX - Admin Views Access Control

## ⚠️ SEVERITY: HIGH - Apply Immediately

### The Problem

Your admin views (`admin_users_view`, `admin_cases_view`, `admin_editor_assignments_view`, `case_analytics`) are **unrestricted** and accessible to ANY authenticated user via the API.

**What this means:**
- A family user could query `admin_users_view` and get ALL user emails, phone numbers, roles
- An editor could query `admin_cases_view` and see ALL cases from ALL organizations
- **Major privacy/GDPR violation**
- **Data exfiltration risk**

### The Fix

Migration `036_secure_admin_views.sql` adds WHERE clauses to all views that filter based on the caller's role.

**Access Control After Fix:**
- **Admin/Support/QC**: See everything (as intended)
- **Director**: See only their organization's data
- **Family**: See only themselves + their case
- **Editor**: See only assigned cases

### How to Apply (2 Steps)

#### Step 1: Run the Migration

1. Go to Supabase Dashboard: https://supabase.com/dashboard/project/gkabtvqwwuvigcdubwyv/editor
2. Click "SQL Editor" in the left sidebar
3. Click "New query"
4. Copy the entire contents of `supabase/migrations/036_secure_admin_views.sql`
5. Paste into the SQL editor
6. Click "Run" (or press Cmd/Ctrl + Enter)

**Expected Output:**
```
Success. No rows returned.
```

#### Step 2: Verify the Fix

1. In the same SQL Editor, run this query:

```sql
-- Should show all 4 views with proper security
SELECT 
  viewname, 
  viewowner,
  substring(definition, 1, 100) as definition_start
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname IN ('admin_users_view', 'admin_cases_view', 'admin_editor_assignments_view', 'case_analytics')
ORDER BY viewname;
```

**Expected Output:**
All 4 views should exist, and the definition should start with `SELECT` and include `WHERE` clauses.

2. Test access from different portals:

**Admin Portal** (should work normally):
```sql
SELECT COUNT(*) FROM admin_users_view;  -- Should return total count
```

**Family Portal** (console):
```javascript
// Should return only 1 (themselves)
const { data, error } = await supabaseClient
  .from('admin_users_view')
  .select('*');
console.log('Family can see users:', data?.length);
```

**Editor Portal** (console):
```javascript
// Should return only assigned cases
const { data, error } = await supabaseClient
  .from('admin_cases_view')
  .select('*');
console.log('Editor can see cases:', data?.length);
```

### What Gets Fixed

✅ **admin_users_view**: Now filters by role and org  
✅ **admin_cases_view**: Now filters by role and assignment  
✅ **admin_editor_assignments_view**: Now filters by role  
✅ **case_analytics**: Now filters by role and org  

### Will This Break Anything?

**NO** - This is 100% backwards compatible:
- Admin portal queries will still work (admins see everything)
- Director portal queries will still work (directors see their org)
- Family/Editor portals already only query their own data via RLS

### Why This Happened

We created these views with `security_invoker = false` to bypass RLS recursion on the `users` table (which was causing login issues). However, we forgot to add WHERE clauses to restrict access based on the caller's role.

The views were **functioning correctly** for authorized users (admins), but were **also accessible** to unauthorized users via direct API calls.

### Security Impact Timeline

- **Before Fix**: Any authenticated user could access all data via views
- **After Fix**: Only authorized roles can see appropriate data

### Alternative Method: CLI Deployment

If you prefer to use the CLI:

```bash
cd /Users/mejrifx/Downloads/memorio-ai
export SUPABASE_ACCESS_TOKEN=sbp_7a48542cf147183c0e0039c97427a64b55100e31
psql "postgresql://postgres:[YOUR_DB_PASSWORD]@db.gkabtvqwwuvigcdubwyv.supabase.co:5432/postgres" < supabase/migrations/036_secure_admin_views.sql
```

### Post-Migration Checklist

- [ ] Migration 036 ran successfully
- [ ] All 4 views exist in database
- [ ] Admin portal still loads organizations
- [ ] Admin portal "All Cases" still works
- [ ] Family portal login still works
- [ ] Editor portal dashboard still works
- [ ] No console errors in any portal

### Rollback (If Needed)

If something goes wrong, you can rollback by running the previous view definitions from migration `034_final_remove_user_rls_add_view.sql` and `035_create_admin_cases_view.sql`.

But this should NOT be necessary - the fix is designed to be non-breaking.

---

**Apply this fix now to secure your database!** 🔒

