

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

---

**Total Setup Time: ~10 minutes**

*You now have a production-ready, secure, multi-tenant backend for Memorio!*

