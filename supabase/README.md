# Supabase Migrations

This directory contains all database migrations for the Memorio platform.

## Migration Files

1. **001_initial_schema.sql** - Core database tables, relationships, and indexes
2. **002_rls_policies.sql** - Row Level Security policies for multi-tenant access control
3. **003_functions_triggers.sql** - Database functions and automated triggers
4. **004_seed_data.sql** - Test organization and sample data

## Applying Migrations

### Method 1: Supabase CLI (Recommended)

```bash
# Initialize Supabase
supabase init

# Link to your project
supabase link --project-ref your-project-ref

# Push all migrations
supabase db push
```

### Method 2: Manual via SQL Editor

1. Go to Supabase Dashboard → SQL Editor
2. Run each migration file in order (001, 002, 003, 004)
3. Verify success with `SELECT * FROM organizations;`

## Creating New Migrations

```bash
# Create new migration file
supabase migration new add_new_feature

# Edit the generated file in supabase/migrations/
# Then push to remote
supabase db push
```

## Rolling Back

```bash
# Reset local database to specific migration
supabase db reset --version 20231010_003_functions_triggers
```

## Important Notes

- **Never edit existing migration files** after they've been applied to production
- Always create new migrations for schema changes
- Test migrations in development before applying to production
- Migrations are run in alphabetical/numerical order
- Keep migrations idempotent when possible (use `IF NOT EXISTS`)

## Verification

After applying migrations, verify:

```sql
-- Check all tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- Check policies exist
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';
```

Expected output:
- 9 tables (organizations, users, cases, forms, assets, editor_assignments, events, notifications, exports)
- All tables have `rowsecurity = true`
- 30+ RLS policies across all tables

