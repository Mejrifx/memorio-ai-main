# Troubleshoot Family Dashboard Issues

## 🐛 **Current Issues**

1. **Obituary shows "No content available"** after family submits form
2. **Photos from other families appearing** in dashboard

---

## 🔍 **Step 1: Check Console Logs**

1. **Open Family Dashboard** with browser DevTools open (Press F12)
2. **Look for these debug sections** in the console:

### **Obituary Debug Output**
```
=== OBITUARY DISPLAY DEBUG ===
currentForm: {...}
submitted_json: {...}
Obituary data keys: [...]
obituary_name: ...
obituary_content: ...
loved_ones_name: ...
=== END OBITUARY DEBUG ===
```

### **Assets Debug Output**
```
=== ASSETS DISPLAY DEBUG ===
currentCase.id: "uuid-here"
currentAssets count: 2
Asset 1: { case_id: "...", uploader_user_id: "...", ... }
Asset 2: { case_id: "...", uploader_user_id: "...", ... }
=== END ASSETS DEBUG ===
```

---

## 🧪 **Step 2: Run Database Queries**

Open `DEBUG-RLS-ASSETS.sql` and run it in **Supabase Dashboard → SQL Editor**.

This will show you:
- Current RLS policies on assets table
- All assets in the database
- Cases and their assigned families

---

## 🎯 **What to Look For**

### **For Obituary Issue:**

**Check if these fields exist in `submitted_json`:**
- ✅ `obituary_name` (set by `publishObituary()`)
- ✅ `obituary_content` (set by `publishObituary()`)
- ✅ `loved_ones_name` (from initial form submission)

**If `obituary_name` and `obituary_content` are missing:**
- Problem: `publishObituary()` function is NOT being called/saving
- This happens if family doesn't click the "Submit" button after viewing the generated obituary

**Possible causes:**
1. Family closes browser before clicking "Submit"
2. N8N webhook fails, so typewriter never shows
3. JavaScript error prevents `publishObituary()` from running

---

### **For Photos Issue:**

**Check the console output:**
- Does `Asset X: case_id` match `currentCase.id`?
- If NO → RLS policy is broken or query is wrong
- If YES → Photos actually belong to this case (might be from previous test)

**Check the SQL query results:**
- Are there multiple cases with photos?
- Do the `case_id` values match across assets?
- Is `assigned_family_user_id` correctly set on cases?

---

## 🔧 **Likely Root Causes & Fixes**

### **Issue 1: Obituary Not Saving**

**Root Cause**: The obituary is only saved when `publishObituary()` is called (when family clicks "Submit" after viewing generated obituary).

**Fix Options:**

**Option A**: Ensure family clicks "Submit" button
- Verify N8N webhook is working
- Check that typewriter effect shows
- Confirm "Submit" button appears

**Option B**: Save obituary earlier in the flow
- Modify `saveFormToDatabase()` to also save obituary content from N8N response
- This requires capturing the N8N response data

---

### **Issue 2: Photos from Other Families**

**Root Cause**: RLS policy not strictly filtering, OR you're looking at photos from a previous test with the same case.

**Fix**: Verify RLS policy is correct

Run this SQL to fix the assets RLS policy:

```sql
-- Drop and recreate with strict filtering
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

---

## 📝 **Action Items**

1. ✅ Run the SQL from RUN-THIS-SQL-NOW.md (fix user app_metadata)
2. ✅ Log out and back in (refresh JWT)
3. ✅ Open Family Dashboard with console open
4. ✅ Share console output (copy/paste the debug sections)
5. ✅ Run DEBUG-RLS-ASSETS.sql and share results
6. ⏳ Based on results, we'll apply the specific fix

---

## 💡 **Quick Test**

To verify the issue:

1. **Create NEW test case**
2. **Invite family member**
3. **Family logs in and submits form**
4. **IMPORTANT**: After obituary appears, click "Submit" button
5. **Then check dashboard**

If you skipped step 4, that's why obituary is blank!

---

## 🚨 **Emergency Fix**

If you need to manually add obituary content:

1. Go to **Supabase Dashboard → Table Editor → forms**
2. Find the form record for your case
3. Edit `submitted_json` column
4. Add these fields:
```json
{
  ...existing fields...,
  "obituary_name": "In Loving Memory of [Name]",
  "obituary_content": "Your obituary text here..."
}
```
5. Save and refresh dashboard

---

## 📊 **Expected vs Actual**

### **Expected Flow:**
1. Family submits form → `saveFormToDatabase()` runs
2. N8N generates obituary → Typewriter shows it
3. Family clicks "Submit" → `publishObituary()` runs
4. Database updated with `obituary_name` + `obituary_content`
5. Dashboard shows obituary ✅

### **What's Happening (Suspected):**
1. Family submits form → ✅
2. N8N generates obituary → ✅ (maybe?)
3. Family clicks "Submit" → ❌ NOT HAPPENING
4. Database missing obituary fields → ❌
5. Dashboard shows "No content available" → ❌

---

Once you share the console output, I'll know exactly what's wrong and can provide the precise fix! 🚀

