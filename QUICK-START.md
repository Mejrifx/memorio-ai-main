# Memorio Quick Start Guide

**Get your Memorio backend up and running in 10 minutes.**

---

## Prerequisites Checklist

- [ ] Supabase account (sign up at https://supabase.com)
- [ ] Node.js 18+ installed
- [ ] Git installed

---

## Step 1: Create Supabase Project (2 min)

1. Go to https://app.supabase.com
2. Click **"New Project"**
3. Fill in:
   - **Name:** `memorio-production`
   - **Database Password:** Generate and save securely
   - **Region:** Choose closest to your users
4. Wait ~2 minutes for provisioning

---

## Step 2: Get Your Credentials (1 min)

1. Go to **Project Settings** → **API**
2. Copy these 3 values:
   - **Project URL**
   - **anon/public key**
   - **service_role key** (click "Reveal")

---

## Step 3: Configure Environment (1 min)

```bash
# In your project root
cp .env.example .env

# Edit .env and paste your credentials:
# SUPABASE_URL=https://xxxxx.supabase.co
# SUPABASE_ANON_KEY=eyJ...
# SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

**Important:** Never commit `.env` to Git (already in `.gitignore`).

---

## Step 4: Install Supabase CLI (1 min)

```bash
npm install -g supabase
supabase login
```

Follow the browser prompt to authenticate.

---

## Step 5: Link Project & Deploy Schema (2 min)

```bash
# Initialize Supabase in your project
supabase init

# Link to your remote project
supabase link --project-ref your-project-ref
# (Find project-ref in Supabase dashboard URL)

# Push all database migrations
supabase db push
```

**Expected output:**
```
✔ Finished supabase db push on branch main
```

---

## Step 6: Configure Storage Bucket (2 min)

### Via Supabase Dashboard:

1. Go to **Storage** → **Create Bucket**
2. Settings:
   - **Name:** `case-assets`
   - **Public:** No (private)
   - **File size limit:** 50 MB
3. Click **"Create"**

### Set Bucket Policies:

Go to **Storage** → `case-assets` → **Policies** → **"New Policy"**

**Quick Policy (Admin access):**
```sql
CREATE POLICY "Admins full access"
ON storage.objects FOR ALL
USING (
  bucket_id = 'case-assets' AND
  auth.jwt() ->> 'role' = 'admin'
);
```

*(For complete policies, see `docs/supabase-setup-guide.md`)*

---

## Step 7: Create Test Accounts (2 min)

```bash
# Install dependencies
cd scripts
npm install

# Run test account creation
node create-test-accounts.js
```

**Expected output:**
```
✨ Test account creation complete!

Test Credentials:
─────────────────
ADMIN      admin@memorio.test               TestAdmin123!
DIRECTOR   director@testfuneralhome.com     TestDirector123!
FAMILY     family@example.com               TestFamily123!
EDITOR     editor@memorio.test              TestEditor123!
SUPPORT    support@memorio.test             TestSupport123!
```

---

## Step 8: Verify Setup (1 min)

```bash
# Check tables exist
supabase db pull

# Should show:
# - organizations
# - users
# - cases
# - forms
# - assets
# - editor_assignments
# - events
# - notifications
# - exports
```

---

## Step 9: Test Authentication (1 min)

### Via Supabase Dashboard:

1. Go to **Authentication** → **Users**
2. You should see 5 test users
3. Click on `director@testfuneralhome.com` → **"Send Magic Link"**
4. Check that email is sent

---

## Step 10: Configure CORS (1 min)

1. Go to **Settings** → **API**
2. Scroll to **"CORS Allowed Origins"**
3. Add:
   ```
   https://memorio.ai
   http://localhost:8000
   ```
4. Click **"Save"**

---

## ✅ You're Done!

Your Memorio backend is now live and ready.

### What's Running:

✅ **Database:** 9 tables with RLS policies  
✅ **Authentication:** Supabase Auth with 5 test users  
✅ **Storage:** `case-assets` bucket for photos/videos  
✅ **Security:** Multi-tenant RLS enforced at database level  
✅ **Audit:** Automatic event logging on all changes  

---

## Next Steps

### Test the Frontend:

```bash
# Start local server
python3 -m http.server 8000

# Visit http://localhost:8000
# Fill out the form and verify N8N integration still works
```

### Explore the Database:

1. Go to **Supabase Dashboard** → **Table Editor**
2. Browse the 9 tables
3. Try inserting/updating data as different roles

### Read the Docs:

- **Schema Reference:** `docs/database-schema.md`
- **Security Guide:** `docs/security-policies.md`
- **Complete Setup:** `docs/supabase-setup-guide.md`
- **Validation Tests:** `docs/validation-checklist.md`

---

## Troubleshooting

### Error: "relation does not exist"
**Fix:** Run `supabase db push` again

### Error: "permission denied"
**Fix:** Check RLS policies in `docs/security-policies.md`

### Error: JWT expired
**Fix:** Refresh token via `supabase.auth.refreshSession()`

### Storage upload fails
**Fix:** Verify bucket policies in Dashboard → Storage → `case-assets` → Policies

---

## Production Checklist

Before going live:

- [ ] Change all test account passwords
- [ ] Delete test organization
- [ ] Enable database backups (auto in Pro plan)
- [ ] Configure custom SMTP (Settings → Auth → SMTP)
- [ ] Enable MFA for Director+ roles
- [ ] Review storage bucket size limits
- [ ] Test RLS with production scenarios
- [ ] Set up monitoring/alerting

---

## Need Help?

- **Documentation:** Check `docs/` folder
- **Supabase Docs:** https://supabase.com/docs
- **Validation Tests:** `docs/validation-checklist.md`

---

**Total Setup Time: ~10 minutes**

*You now have a production-ready, secure, multi-tenant backend for Memorio!*

