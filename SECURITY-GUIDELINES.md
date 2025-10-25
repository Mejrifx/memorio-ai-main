# Security Guidelines

## ⚠️ CRITICAL SECURITY RULES

### 1. **NEVER COMMIT SENSITIVE DATA**
- ❌ **NEVER** commit service keys, API keys, passwords, or tokens
- ❌ **NEVER** commit `.env` files or configuration files with secrets
- ❌ **NEVER** hardcode secrets in source code

### 2. **SUPABASE KEYS**
- ✅ **ANON KEY**: Safe to commit (public-facing)
- ❌ **SERVICE KEY**: Must be in environment variables only
- ❌ **DATABASE URL**: Must be in environment variables only

### 3. **ENVIRONMENT VARIABLES**
- ✅ Use `Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')` in Edge Functions
- ✅ Use environment variables in deployment platforms
- ❌ Never hardcode in source files

### 4. **GIT SECURITY**
- ✅ Use `.gitignore` to exclude sensitive files
- ✅ Use `git filter-branch` to purge sensitive data if exposed
- ✅ Force push cleaned history: `git push origin --force --all`

### 5. **IF SECRETS ARE EXPOSED**
1. 🔑 **IMMEDIATELY** rotate/disable the exposed key
2. 🧹 **PURGE** git history to remove sensitive data
3. 🔄 **UPDATE** environment variables with new key
4. 📝 **DOCUMENT** the incident and prevention measures

## Current Service Key
- **New Service Key**: `sbp_301626cf29e8479bba414d9969021e57a4589a8d`
- **Status**: Active (rotated after security incident)
- **Location**: Supabase Edge Function environment variables

## Security Incident Log
- **Date**: October 25, 2025
- **Issue**: Service key exposed in `fix-accounts-now.js`
- **Action**: Key rotated, git history purged, environment updated
- **Prevention**: This security guide created
