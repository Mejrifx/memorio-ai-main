# Memorio Supabase Setup Guide

**Version:** 1.0.0  
**Last Updated:** October 10, 2025

## Prerequisites

- Supabase account (https://supabase.com)
- Supabase CLI installed (`npm install -g supabase`)
- Node.js 18+ and npm
- PostgreSQL client (optional, for manual testing)

---

## Step 1: Create Supabase Project

### Option A: Via Supabase Dashboard

1. Go to https://app.supabase.com
2. Click "New Project"
3. Fill in details:
   - **Name**: `memorio-production` (or `memorio-dev`)
   - **Database Password**: Generate strong password (save securely!)
   - **Region**: Choose closest to your users
   - **Pricing Plan**: Pro (recommended for production)
4. Wait 2-3 minutes for provisioning

### Option B: Via Supabase CLI

```bash
supabase login
supabase projects create memorio-production --region us-east-1
```

---

## Step 2: Configure Environment Variables

1. Get your project credentials from Supabase Dashboard:
   - Go to Project Settings → API
   - Copy `Project URL` and `anon` key

2. Create `.env` file in project root:

```bash
cp .env.example .env
```

3. Fill in `.env` with your credentials:

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
DATABASE_URL=postgresql://postgres:[password]@db.xxxxx.supabase.co:5432/postgres
```

**Security**: Never commit `.env` to Git. It's already in `.gitignore`.

---

## Step 3: Run Database Migrations

### Option A: Via Supabase CLI (Recommended)

```bash
# Initialize Supabase locally
supabase init

# Link to your remote project
supabase link --project-ref xxxxx

# Push migrations to remote database
supabase db push
```

### Option B: Via SQL Editor in Dashboard

1. Go to Supabase Dashboard → SQL Editor
2. Open `supabase/migrations/001_initial_schema.sql`
3. Copy contents and paste into SQL Editor
4. Click "Run"
5. Repeat for `002_rls_policies.sql`, `003_functions_triggers.sql`, `004_seed_data.sql`

---

## Step 4: Configure Storage Bucket

### Create `case-assets` Bucket

1. Go to Supabase Dashboard → Storage
2. Click "Create Bucket"
3. Settings:
   - **Name**: `case-assets`
   - **Public**: No (private)
   - **Allowed MIME types**: `image/*`, `video/*`
   - **Max file size**: 50 MB (adjust as needed)
4. Click "Create"

### Set Bucket RLS Policies

Go to Storage → `case-assets` → Policies → "New Policy":

**Policy 1: Families can upload to their case folder**
```sql
CREATE POLICY "Families can upload to their case"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'case-assets' AND
  auth.jwt() ->> 'role' = 'family' AND
  (storage.foldername(name))[1] IN (
    SELECT org_id::text FROM cases 
    WHERE assigned_family_user_id = auth.uid()
  ) AND
  (storage.foldername(name))[2] IN (
    SELECT id::text FROM cases 
    WHERE assigned_family_user_id = auth.uid()
  )
);
```

**Policy 2: Directors can access all files in their org**
```sql
CREATE POLICY "Directors access org files"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'case-assets' AND
  auth.jwt() ->> 'role' = 'director' AND
  (storage.foldername(name))[1] = (auth.jwt() ->> 'org_id')
);
```

**Policy 3: Admins have full access**
```sql
CREATE POLICY "Admins full access to storage"
ON storage.objects FOR ALL
USING (
  bucket_id = 'case-assets' AND
  auth.jwt() ->> 'role' = 'admin'
);
```

---

## Step 5: Configure CORS for memorio.ai

1. Go to Supabase Dashboard → Settings → API
2. Scroll to "CORS Allowed Origins"
3. Add:
   ```
   https://memorio.ai
   https://www.memorio.ai
   http://localhost:8000 (for local development)
   ```
4. Click "Save"

---

## Step 6: Enable Realtime (Optional)

If you want real-time case status updates:

1. Go to Database → Replication
2. Enable replication for tables:
   - `cases`
   - `notifications`
   - `forms` (for live form autosave)
3. Click "Save"

---

## Step 7: Configure Auth Settings

### Email Templates

1. Go to Authentication → Email Templates
2. Customize:
   - **Invite User**: Director invites Family
   - **Confirm Signup**: Family account activation
   - **Reset Password**: Password recovery

**Example Invite Template**:
```html
<h2>You've been invited to Memorio</h2>
<p>{{ .SiteName }} has invited you to collaborate on a tribute.</p>
<p><a href="{{ .ConfirmationURL }}">Accept Invitation</a></p>
```

### Auth Providers

1. Go to Authentication → Providers
2. **Email**: Enabled (default)
3. **Magic Link**: Enabled (recommended for families)
4. **Google/Social**: Disable (invitation-only system)

### Security Settings

1. Go to Authentication → Settings
2. Configure:
   - **Site URL**: `https://memorio.ai`
   - **Redirect URLs**: Add `https://memorio.ai/auth/callback`
   - **JWT Expiry**: 3600 seconds (1 hour)
   - **Refresh Token Expiry**: 2592000 seconds (30 days)
   - **Require Email Confirmation**: Yes
   - **Enable MFA**: Yes (for Director+ roles)

---

## Step 8: Create Test Accounts

### Install Script Dependencies

```bash
cd scripts
npm install
cd ..
```

### Run Test Account Creation

```bash
node scripts/create-test-accounts.js
```

**Expected Output**:
```
🚀 Memorio Test Account Creation
=================================

Supabase URL: https://xxxxx.supabase.co
Test Org ID: 00000000-0000-0000-0000-000000000001

📧 Creating admin: admin@memorio.test
   ✅ Auth user created: 10000000-0000-0000-0000-000000000001
   ✅ User metadata saved

📧 Creating director: director@testfuneralhome.com
   ✅ Auth user created: 20000000-0000-0000-0000-000000000001
   ✅ User metadata saved

...

✨ Test account creation complete!

Test Credentials:
─────────────────
ADMIN      admin@memorio.test               TestAdmin123!
DIRECTOR   director@testfuneralhome.com     TestDirector123!
FAMILY     family@example.com               TestFamily123!
EDITOR     editor@memorio.test              TestEditor123!
SUPPORT    support@memorio.test             TestSupport123!

⚠️  Remember to change these passwords in production!
```

---

## Step 9: Verify Setup

### Test 1: Check Tables Exist

```bash
supabase db pull
# Should list all 9 tables
```

### Test 2: Verify RLS Policies

```sql
-- Run in SQL Editor
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';

-- Should return ~30-40 policies
```

### Test 3: Test Auth Login

```javascript
// In browser console or Node.js
const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const { data, error } = await supabase.auth.signInWithPassword({
  email: 'director@testfuneralhome.com',
  password: 'TestDirector123!'
});

console.log(data.user); // Should show user object
```

### Test 4: Verify RLS Works

```javascript
// Still logged in as director
const { data: cases } = await supabase
  .from('cases')
  .select();

console.log(cases); 
// Should only show cases for org 00000000-0000-0000-0000-000000000001
```

---

## Step 10: Production Checklist

Before going live:

- [ ] Change all test account passwords
- [ ] Delete test organization and cases
- [ ] Enable database backups (automatic in Supabase Pro)
- [ ] Set up monitoring/alerting (Supabase Dashboard)
- [ ] Configure custom SMTP for emails (Settings → Auth → SMTP)
- [ ] Enable MFA for all Director+ accounts
- [ ] Review and adjust storage bucket size limits
- [ ] Test RLS policies with real user scenarios
- [ ] Document emergency access procedures
- [ ] Set up database read replicas (if needed)

---

## Troubleshooting

### Error: "relation does not exist"

**Cause**: Migrations not applied  
**Fix**: Run `supabase db push` again

### Error: "permission denied for table X"

**Cause**: RLS blocking query  
**Fix**: Check user's JWT claims match RLS policy requirements

### Error: "JWT expired"

**Cause**: Token expired after 1 hour  
**Fix**: Refresh token via `supabase.auth.refreshSession()`

### Error: "new row violates row-level security policy"

**Cause**: Trying to insert data that violates RLS policy  
**Fix**: Use service role key for system operations, or adjust RLS policy

### Storage Upload Fails

**Cause**: Bucket RLS policy too restrictive  
**Fix**: Review storage policies in Dashboard → Storage → `case-assets` → Policies

---

## Useful Commands

```bash
# View current migrations
supabase migration list

# Create new migration
supabase migration new my_new_migration

# Reset local database (destructive!)
supabase db reset

# View database logs
supabase db logs

# Generate TypeScript types from database schema
supabase gen types typescript --local > types/supabase.ts
```

---

## Next Steps

After setup is complete:

1. **Milestone 2**: Build authentication flows and invite system
2. **Milestone 3**: Create Case Management APIs
3. **Milestone 4**: Build Admin Portal UI
4. **Milestone 5**: Build Director Portal UI
5. **Milestone 6**: Build Editor Portal UI

---

**End of Setup Guide**

