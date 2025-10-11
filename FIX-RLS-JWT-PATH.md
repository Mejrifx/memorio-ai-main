# Fix RLS JWT Path for Organizations

## The Real Problem

The JWT role is stored in `app_metadata.role`, but the RLS policy is checking `auth.jwt() ->> 'role'` (wrong path).

**JWT Structure:**
```json
{
  "app_metadata": {
    "role": "admin",  ← Role is HERE
    "org_id": null
  },
  "role": "authenticated"  ← This is Supabase's auth role, not our custom role
}
```

## The Correct Fix

Run this SQL in **Supabase Dashboard** → **SQL Editor**:

```sql
-- Fix Organizations RLS Policy - Use correct JWT path

-- Drop the existing policy
DROP POLICY IF EXISTS "Admins full access to organizations" ON organizations;

-- Recreate with correct JWT path: app_metadata.role
CREATE POLICY "Admins full access to organizations"
  ON organizations FOR ALL
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin');

-- Also fix the Directors policy
DROP POLICY IF EXISTS "Directors read their organization" ON organizations;

CREATE POLICY "Directors read their organization"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
  );

-- Fix Support policy too
DROP POLICY IF EXISTS "Support read all organizations" ON organizations;

CREATE POLICY "Support read all organizations"
  ON organizations FOR SELECT
  TO authenticated
  USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'support');
```

## After Running

Try creating an organization again - should work now! ✅

---

## Note

This same issue affects ALL RLS policies in the database. We'll need to update all of them to use:
- `auth.jwt() -> 'app_metadata' ->> 'role'` instead of `auth.jwt() ->> 'role'`
- `auth.jwt() -> 'app_metadata' ->> 'org_id'` instead of `auth.jwt() ->> 'org_id'`

But let's test organizations first!

