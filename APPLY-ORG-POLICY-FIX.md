# Fix Organization INSERT Policy

## The Problem
The RLS policy on the `organizations` table doesn't allow admins to INSERT new organizations. The policy needs both `USING` (for SELECT/UPDATE/DELETE) and `WITH CHECK` (for INSERT/UPDATE).

## The Fix

Run this SQL in **Supabase Dashboard** → **SQL Editor**:

```sql
-- Fix Organizations INSERT Policy

-- Drop the existing policy
DROP POLICY IF EXISTS "Admins full access to organizations" ON organizations;

-- Recreate with explicit WITH CHECK for INSERT operations
CREATE POLICY "Admins full access to organizations"
  ON organizations FOR ALL
  TO authenticated
  USING (auth.jwt() ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');
```

## After Running

1. Go back to Admin Portal
2. Try creating an organization again
3. Should work now! ✅

---

**Quick Steps:**
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Paste the SQL above
4. Click "Run"
5. Should see "Success. No rows returned"
6. Test creating an org in Admin Portal

