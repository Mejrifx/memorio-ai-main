# Fix Family Dashboard Issues - Complete Guide

## 🐛 **Issues Fixed**

1. ✅ **"Make Changes" button just refreshes** - Now properly redirects to edit mode
2. ✅ **Initial uploaded photos not showing** - Photos now saved to assets table
3. ✅ **Photo upload fails with RLS error** - Fixed RLS policies for family uploads

---

## ⚡ **STEP 1: Run SQL Migrations** (5 minutes)

Go to **Supabase Dashboard → SQL Editor** and run these 2 SQL scripts:

### **Migration 1: Fix Assets RLS Policy**

This fixes the "new row violates row-level security policy" error when families upload photos.

```sql
-- Fix Assets RLS Policies - Add WITH CHECK Clause
DROP POLICY IF EXISTS "Families manage their case assets" ON assets;

CREATE POLICY "Families manage their case assets"
  ON assets FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = assets.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  )
  WITH CHECK (
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = assets.case_id
      AND cases.assigned_family_user_id = auth.uid()
    )
  );
```

### **Migration 2: Fix Storage Bucket Policies**

This allows families to upload photos to the storage bucket.

```sql
-- Fix Storage Bucket RLS Policies for case-assets
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Families can upload case assets" ON storage.objects;
DROP POLICY IF EXISTS "Families can view case assets" ON storage.objects;
DROP POLICY IF EXISTS "Directors can upload case assets" ON storage.objects;
DROP POLICY IF EXISTS "Directors can view case assets" ON storage.objects;
DROP POLICY IF EXISTS "Admins full access to case assets" ON storage.objects;

-- Admins have full access
CREATE POLICY "Admins full access to case assets"
  ON storage.objects FOR ALL
  TO authenticated
  USING (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'admin'
  )
  WITH CHECK (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'admin'
  );

-- Directors can upload and view assets in their org's cases
CREATE POLICY "Directors can upload case assets"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM public.cases
      WHERE cases.id = (string_to_array(name, '/'))[1]::uuid
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

CREATE POLICY "Directors can view case assets"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'director' AND
    EXISTS (
      SELECT 1 FROM public.cases
      WHERE cases.id = (string_to_array(name, '/'))[1]::uuid
      AND cases.org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
    )
  );

-- Families can upload and view assets for their assigned cases
CREATE POLICY "Families can upload case assets"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM public.cases
      WHERE cases.id = (string_to_array(name, '/'))[1]::uuid
      AND cases.assigned_family_user_id = auth.uid()
    )
  );

CREATE POLICY "Families can view case assets"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'case-assets' AND
    auth.jwt() -> 'app_metadata' ->> 'role' = 'family' AND
    EXISTS (
      SELECT 1 FROM public.cases
      WHERE cases.id = (string_to_array(name, '/'))[1]::uuid
      AND cases.assigned_family_user_id = auth.uid()
    )
  );
```

---

## ⚡ **STEP 2: Deploy Updated Code** (Already done!)

All code changes have been deployed to your GitHub repo. Just pull the latest:

```bash
cd /Users/mejrifx/Downloads/memorio-ai
git pull origin main
```

**If you're using Netlify**, it will auto-deploy from GitHub.

---

## ✅ **What's Fixed**

### **1. "Make Changes" Button Works**
- Clicking "Make Changes" in the Family Dashboard now properly redirects to the form with `?mode=edit` parameter
- Form detects edit mode and allows re-editing instead of redirecting back to dashboard
- Preserves authentication context throughout the flow

### **2. Initial Photos Now Saved to Database**
- When family submits the form, uploaded photos from Uploadcare are automatically saved to the `assets` table
- Photos are linked to the case with proper metadata
- Photos appear in the Family Dashboard's "Photos" section with thumbnails

### **3. Photo Uploads Work in Dashboard**
- Fixed RLS policies allow families to upload additional photos via the dashboard
- Fixed Storage bucket policies allow file uploads
- Both assets table and storage bucket now have proper `WITH CHECK` clauses

### **4. Photo Display Improvements**
- Uploadcare photos show as clickable thumbnails
- Clicking a photo opens the full-size image in a new tab
- Photos from form submission are clearly labeled

---

## 🧪 **How to Test**

1. **Log in as family member** (who hasn't submitted form yet)
2. **Fill out and submit the form** with photos
3. **Check Family Dashboard**:
   - ✅ Obituary content should show
   - ✅ Initial uploaded photos should appear in "Photos" section
4. **Click "Make Changes"**:
   - ✅ Should redirect to form (not dashboard)
   - ✅ Can edit and resubmit
5. **Upload additional photos** via dashboard:
   - ✅ Should upload successfully (no RLS error)
   - ✅ Photos should appear immediately

---

## 🔍 **Verify SQL Applied**

After running the SQL, verify it worked:

```sql
-- Check assets RLS policy
SELECT 
  schemaname,
  tablename,
  policyname,
  with_check IS NOT NULL as has_with_check
FROM pg_policies
WHERE tablename = 'assets'
  AND policyname = 'Families manage their case assets';

-- Should show: has_with_check = true

-- Check storage policies
SELECT 
  policyname,
  cmd
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
ORDER BY policyname;

-- Should show 5 policies (admin, director x2, family x2)
```

---

## 📋 **Files Changed**

1. **`index.html`** - Added `saveUploadedPhotos()` function, edit mode detection
2. **`m-family-7x2p/dashboard.html`** - Fixed "Make Changes" button, improved photo display
3. **`supabase/migrations/012_fix_assets_rls_with_check.sql`** - New migration
4. **`supabase/migrations/013_fix_storage_bucket_policies.sql`** - New migration

---

## 🚀 **Summary**

Run the 2 SQL scripts above, pull latest code, and all issues are fixed! The Family Dashboard will now properly display photos, allow editing, and enable photo uploads without RLS errors.

