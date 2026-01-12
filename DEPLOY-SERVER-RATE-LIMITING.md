# Deploy Server-Side Rate Limiting

## Overview

This guide walks you through deploying **server-side rate limiting** that cannot be bypassed by clients. This significantly enhances security compared to client-side rate limiting.

## What's Included

1. **Database Table**: `login_attempts` - Tracks all login attempts (success/failure) with IP and user agent
2. **Database Functions**: Rate limit checking, attempt recording, and automatic cleanup
3. **Edge Function**: `rate-limited-login` - Handles authentication with server-side rate limiting
4. **Updated Login Pages**: All portals now use the Edge Function instead of direct auth

## Deployment Steps

### Option 1: Using Supabase CLI (Recommended)

```bash
# 1. Login to Supabase CLI (if not already logged in)
npx supabase login

# 2. Apply the database migration
npx supabase db push

# 3. Deploy the Edge Function
npx supabase functions deploy rate-limited-login

# Done!
```

### Option 2: Manual Deployment via Supabase Dashboard

If the CLI doesn't work, you can deploy manually:

#### Step 1: Apply Database Migration

1. Go to your Supabase project: https://supabase.com/dashboard
2. Navigate to **SQL Editor**
3. Click **New Query**
4. Copy the entire contents of: `supabase/migrations/045_create_login_attempts_table.sql`
5. Paste into the SQL Editor
6. Click **Run** (or press Cmd/Ctrl + Enter)
7. Verify success: You should see "Success. No rows returned"

#### Step 2: Deploy Edge Function

1. In your Supabase project, go to **Edge Functions**
2. Click **Deploy Function**
3. Function name: `rate-limited-login`
4. Copy the contents of: `supabase/functions/rate-limited-login/index.ts`
5. Paste into the function editor
6. Click **Deploy**
7. Note the Function URL (you'll need this)

## Verification

### Verify Database Migration

Run this SQL in your Supabase SQL Editor:

```sql
-- Check if table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_name = 'login_attempts'
);

-- Check if functions exist
SELECT proname FROM pg_proc 
WHERE proname IN (
  'check_rate_limit', 
  'record_login_attempt', 
  'clear_login_attempts',
  'cleanup_old_login_attempts'
);
```

You should see:
- `EXISTS` = true
- 4 function names listed

### Verify Edge Function

Test the function with curl:

```bash
curl -i --location --request POST \
  'https://YOUR_PROJECT_REF.supabase.co/functions/v1/rate-limited-login' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"email":"test@example.com","password":"wrongpassword","expectedRole":"admin"}'
```

You should get a 401 response with an error message.

## Rate Limiting Settings

Current configuration (can be adjusted in the Edge Function):

- **Max Attempts**: 5 failures
- **Time Window**: 15 minutes
- **Lockout Duration**: 15 minutes from first failed attempt
- **Auto-Cleanup**: Login attempts older than 7 days are automatically deleted

### How It Works

1. User attempts to login
2. Edge Function checks `login_attempts` table
3. If < 5 failures in last 15 minutes → Allow attempt
4. If ≥ 5 failures in last 15 minutes → Return 429 (Rate Limited)
5. On success → Clear all failed attempts for that email
6. On failure → Record attempt with IP and user agent

### Progressive Lockout Example

```
Attempt 1 (wrong password) → "Invalid credentials. 4 attempts remaining"
Attempt 2 (wrong password) → "Invalid credentials. 3 attempts remaining"
Attempt 3 (wrong password) → "Invalid credentials. 2 attempts remaining"
Attempt 4 (wrong password) → "Invalid credentials. 1 attempts remaining"
Attempt 5 (wrong password) → "Invalid credentials. 0 attempts remaining"
Attempt 6 → "Too many failed attempts. Account locked for 15 minutes."
```

## Monitoring

### View Login Attempts

```sql
-- Recent failed attempts
SELECT 
  email,
  ip_address,
  user_agent,
  created_at
FROM login_attempts
WHERE attempt_type = 'failure'
ORDER BY created_at DESC
LIMIT 20;

-- Currently locked accounts
SELECT 
  email,
  COUNT(*) as failed_attempts,
  MIN(created_at) as first_attempt,
  MAX(created_at) as last_attempt
FROM login_attempts
WHERE attempt_type = 'failure'
  AND created_at > NOW() - INTERVAL '15 minutes'
GROUP BY email
HAVING COUNT(*) >= 5
ORDER BY failed_attempts DESC;

-- Successful logins today
SELECT 
  email,
  ip_address,
  created_at
FROM login_attempts
WHERE attempt_type = 'success'
  AND created_at > CURRENT_DATE
ORDER BY created_at DESC;
```

## Security Benefits

### Server-Side (Cannot Be Bypassed)

✅ **Rate limiting enforced at database level**
- Cannot be bypassed by clearing localStorage
- Cannot be bypassed by using different browsers
- Cannot be bypassed by using incognito mode

✅ **IP and user agent tracking**
- Identify suspicious patterns
- Detect distributed attacks
- Forensic analysis capabilities

✅ **Centralized monitoring**
- All attempts logged in database
- Easy to query and analyze
- Audit trail for security incidents

✅ **Automatic cleanup**
- Old records automatically deleted
- No storage bloat
- Maintains performance

### What This Prevents

❌ **Brute Force Attacks**: Limits attempts to 5 per 15 minutes
❌ **Credential Stuffing**: Each email independently rate limited
❌ **Account Enumeration**: Failed attempts counted regardless of email validity
❌ **Distributed Attacks**: Per-email limiting works even from multiple IPs

## Troubleshooting

### Migration Fails

```
Error: relation "login_attempts" already exists
```

**Solution**: Table already created. This is fine, skip migration.

### Edge Function Fails to Deploy

```
Error: Function already exists
```

**Solution**: Update the existing function instead:
```bash
npx supabase functions deploy rate-limited-login --no-verify-jwt
```

### Rate Limit Not Working

1. Check if Edge Function is deployed:
   - Go to Supabase Dashboard → Edge Functions
   - Verify `rate-limited-login` is listed and "Active"

2. Check if login pages are using the Edge Function:
   - Open browser DevTools → Network tab
   - Login attempt should call `/functions/v1/rate-limited-login`
   - NOT `auth.signInWithPassword`

3. Check database:
   ```sql
   SELECT * FROM login_attempts ORDER BY created_at DESC LIMIT 10;
   ```
   - Should see records being created

### Unlock a Locked Account Manually

```sql
-- Clear failed attempts for a specific email
SELECT clear_login_attempts('user@example.com');

-- Or delete all their failed attempts
DELETE FROM login_attempts 
WHERE email = 'user@example.com' 
AND attempt_type = 'failure';
```

## Next Steps

After deployment:

1. ✅ Test rate limiting with intentional failed logins
2. ✅ Monitor `login_attempts` table for activity
3. ✅ Set up alerts for suspicious patterns (optional)
4. ✅ Document new login flow in your runbooks

## Support

If you encounter issues:

1. Check Supabase logs: Dashboard → Logs → Edge Functions
2. Check database logs: Dashboard → Logs → Database
3. Test the migration SQL manually in SQL Editor
4. Verify environment variables are set in Edge Function

---

**Status**: Ready to deploy
**Estimated Time**: 5-10 minutes
**Impact**: All login pages will use server-side rate limiting
