# Apply All RLS Policy Fixes

## What This Does

This migration updates **ALL** RLS policies across **9 tables** to use the correct JWT path:
- ✅ Organizations
- ✅ Users
- ✅ Cases
- ✅ Forms
- ✅ Assets
- ✅ Editor Assignments
- ✅ Events
- ✅ Notifications
- ✅ Exports

## How to Apply

### Method 1: Copy & Paste (Easiest)

1. Go to **Supabase Dashboard** → **SQL Editor**
2. Open the file `supabase/migrations/008_fix_all_rls_policies.sql`
3. **Copy ALL the SQL** (it's a big file, ~400 lines)
4. **Paste** into the SQL Editor
5. Click **Run**
6. Wait ~10 seconds for it to complete

### Method 2: Command Line (If you prefer)

```bash
cd /Users/mejrifx/Downloads/memorio-ai
supabase db push --linked
```

(This will prompt you to confirm - just type 'y' and press Enter)

## What Gets Fixed

Before:
```sql
auth.jwt() ->> 'role' = 'admin'  ❌ WRONG (checks root level)
```

After:
```sql
auth.jwt() -> 'app_metadata' ->> 'role' = 'admin'  ✅ CORRECT
```

## After Running

Test in the Admin Portal:
1. ✅ Create Organization - should work
2. ✅ View Organizations list - should show all orgs
3. ✅ Invite Director - should work

## Total Changes

- **9 tables** updated
- **35+ policies** fixed
- All role checks now use `app_metadata.role`
- All org_id checks now use `app_metadata.org_id`

---

**Once you run this, ALL your RLS policies will be fixed!** 🎉

