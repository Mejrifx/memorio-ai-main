# Setup Storage Bucket Policies - Supabase Dashboard

## ⚠️ **Why Not SQL?**

Storage policies on `storage.objects` require `supabase_storage_admin` role permissions, which SQL Editor doesn't have by default. The easiest way is to set these policies via the **Supabase Dashboard**.

---

## 🎯 **Step-by-Step Guide** (5 minutes)

### **Step 1: Open Storage in Supabase Dashboard**

1. Go to https://supabase.com/dashboard
2. Select your Memorio project
3. Click **Storage** in the left sidebar
4. Click on the **case-assets** bucket

---

### **Step 2: Enable RLS on the Bucket**

1. Look for **"RLS Enabled"** toggle at the top
2. If it's OFF, turn it **ON**
3. You'll see a warning that files will be restricted - that's what we want!

---

### **Step 3: Add Storage Policies**

Click **"New Policy"** and add these **5 policies** one by one:

---

#### **Policy 1: Admins Full Access**

- **Name**: `Admins full access to case assets`
- **Allowed operations**: Check ALL (SELECT, INSERT, UPDATE, DELETE)
- **Target roles**: `authenticated`
- **Policy definition**:

```sql
(bucket_id = 'case-assets'::text) 
AND 
((auth.jwt() -> 'app_metadata'::text) ->> 'role'::text) = 'admin'::text
```

- **With check**: Same as above (copy/paste)

---

#### **Policy 2: Directors Can Upload**

- **Name**: `Directors can upload case assets`
- **Allowed operations**: Check only **INSERT**
- **Target roles**: `authenticated`
- **WITH CHECK expression**:

```sql
(bucket_id = 'case-assets'::text) 
AND 
((auth.jwt() -> 'app_metadata'::text) ->> 'role'::text) = 'director'::text
AND
EXISTS (
  SELECT 1 FROM public.cases
  WHERE cases.id = ((string_to_array(storage.objects.name, '/'::text))[1])::uuid
  AND cases.org_id = (((auth.jwt() -> 'app_metadata'::text) ->> 'org_id'::text))::uuid
)
```

---

#### **Policy 3: Directors Can View**

- **Name**: `Directors can view case assets`
- **Allowed operations**: Check only **SELECT**
- **Target roles**: `authenticated`
- **USING expression**:

```sql
(bucket_id = 'case-assets'::text) 
AND 
((auth.jwt() -> 'app_metadata'::text) ->> 'role'::text) = 'director'::text
AND
EXISTS (
  SELECT 1 FROM public.cases
  WHERE cases.id = ((string_to_array(storage.objects.name, '/'::text))[1])::uuid
  AND cases.org_id = (((auth.jwt() -> 'app_metadata'::text) ->> 'org_id'::text))::uuid
)
```

---

#### **Policy 4: Families Can Upload**

- **Name**: `Families can upload case assets`
- **Allowed operations**: Check only **INSERT**
- **Target roles**: `authenticated`
- **WITH CHECK expression**:

```sql
(bucket_id = 'case-assets'::text) 
AND 
((auth.jwt() -> 'app_metadata'::text) ->> 'role'::text) = 'family'::text
AND
EXISTS (
  SELECT 1 FROM public.cases
  WHERE cases.id = ((string_to_array(storage.objects.name, '/'::text))[1])::uuid
  AND cases.assigned_family_user_id = auth.uid()
)
```

---

#### **Policy 5: Families Can View**

- **Name**: `Families can view case assets`
- **Allowed operations**: Check only **SELECT**
- **Target roles**: `authenticated`
- **USING expression**:

```sql
(bucket_id = 'case-assets'::text) 
AND 
((auth.jwt() -> 'app_metadata'::text) ->> 'role'::text) = 'family'::text
AND
EXISTS (
  SELECT 1 FROM public.cases
  WHERE cases.id = ((string_to_array(storage.objects.name, '/'::text))[1])::uuid
  AND cases.assigned_family_user_id = auth.uid()
)
```

---

## ✅ **Verify Policies**

After adding all 5 policies, you should see them listed in the Storage → case-assets → Policies section:

1. ✅ Admins full access to case assets (ALL)
2. ✅ Directors can upload case assets (INSERT)
3. ✅ Directors can view case assets (SELECT)
4. ✅ Families can upload case assets (INSERT)
5. ✅ Families can view case assets (SELECT)

---

## 🧪 **Test It**

1. **As Family Member**:
   - Log in to Family Dashboard
   - Try uploading a photo
   - ✅ Should work without RLS error

2. **As Director**:
   - Log in to Director Portal
   - Try viewing case details
   - ✅ Should see any assets

---

## 📝 **Summary**

- ✅ Migration 012 (assets table RLS) → Run via SQL Editor ✓
- ✅ Migration 013 (storage bucket policies) → Set via Dashboard UI (this guide)

Both are needed for photo uploads to work!

---

## 🆘 **Troubleshooting**

**Error: "bucket_id does not exist"**
- Make sure you created the `case-assets` bucket first
- Go to Storage → Create Bucket → Name: `case-assets` → Public: OFF

**Error: "new row violates row-level security policy"**
- Make sure you ran Migration 012 first (assets table RLS)
- Make sure family has `app_metadata.role = 'family'` in their JWT
- Check console logs for JWT contents

**Policies not saving**
- Try refreshing the page
- Make sure you're on the correct project
- Check for any SQL syntax errors (missing parentheses, etc.)

