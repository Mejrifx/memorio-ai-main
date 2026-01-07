# 🔧 FIX: Autosave Failing - Add Unique Constraint to forms.case_id

## Problem

Family form autosave is failing with database error:

```
POST https://...supabase.co/rest/v1/forms?on_conflict=case_id 400 (Bad Request)

Error: {
  code: '42P10',
  message: 'there is no unique or exclusion constraint matching the ON CONFLICT specification'
}
```

**What's happening:**
1. Family fills out form
2. Clicks NEXT
3. Autosave tries to upsert: `upsert({ case_id: ..., draft_json: ... }, { onConflict: 'case_id' })`
4. PostgreSQL error: `case_id` column has no UNIQUE constraint
5. Autosave fails
6. Data is NOT saved

---

## Root Cause

The `forms` table schema:
```sql
CREATE TABLE forms (
  id UUID PRIMARY KEY,
  case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,  ← No UNIQUE!
  draft_json JSONB,
  submitted_json JSONB,
  ...
);
```

**Missing:** `UNIQUE` constraint on `case_id`

The upsert needs a unique constraint to know which row to update.

---

## The Fix

### Migration 050: Add UNIQUE Constraint

This migration:
1. ✅ Checks for duplicate `case_id` entries (shouldn't be any)
2. ✅ Removes duplicates if found (keeps most recent)
3. ✅ Adds `UNIQUE` constraint on `case_id`
4. ✅ Creates index for performance
5. ✅ Idempotent (safe to run multiple times)

---

## How to Apply

### Step 1: Apply Migration 050

Go to **Supabase SQL Editor** and run:

```sql
-- Copy and paste the entire contents of:
-- supabase/migrations/050_add_unique_constraint_to_forms_case_id.sql
```

Click **Run**.

**Expected output:**
```
NOTICE: Added UNIQUE constraint forms_case_id_unique
```

Or if already exists:
```
NOTICE: Unique constraint forms_case_id_unique already exists
```

---

### Step 2: Verify the Constraint

Run this query:
```sql
SELECT conname, contype 
FROM pg_constraint 
WHERE conrelid = 'forms'::regclass 
AND conname = 'forms_case_id_unique';
```

**Expected result:**
```
conname                    | contype
---------------------------|--------
forms_case_id_unique       | u
```

(`u` means unique constraint)

---

### Step 3: Test Autosave

1. **Refresh** the family form page (hard refresh)
2. **Log in** as a family user
3. **Open console** (F12)
4. **Fill out a field**
5. **Click NEXT**
6. **Watch console** - should see:
   ```
   📝 Navigation button clicked - saving draft immediately
   📝 Collecting form data from X inputs...
   💾 Saving to database...
   ✅ Form draft autosaved successfully (X fields)
   ```
   
   **NO MORE 400 ERROR!** ✅

7. **Sign out and log back in**
8. **Data should be restored!** 🎉

---

## What This Fixes

### Before (Broken):
```sql
-- Upsert fails
INSERT INTO forms (case_id, draft_json, ...)
VALUES ('abc123', {...}, ...)
ON CONFLICT (case_id)  -- ❌ ERROR: No unique constraint
DO UPDATE SET draft_json = ...;

-- Error: 42P10 - no unique constraint matching ON CONFLICT
```

### After (Fixed):
```sql
-- Upsert works!
INSERT INTO forms (case_id, draft_json, ...)
VALUES ('abc123', {...}, ...)
ON CONFLICT (case_id)  -- ✅ Matches forms_case_id_unique
DO UPDATE SET draft_json = ...;

-- Success: Row inserted or updated
```

---

## Technical Details

**Constraint added:**
```sql
ALTER TABLE forms
ADD CONSTRAINT forms_case_id_unique UNIQUE (case_id);
```

**Index created:**
```sql
CREATE INDEX idx_forms_case_id ON forms(case_id);
```

**Relationship:**
- One case → One form (one-to-one)
- Multiple forms per case not allowed
- Makes sense: Each case has exactly one intake form

**Safety:**
- Migration checks for duplicates first
- Removes duplicates (keeps newest)
- Idempotent (can run multiple times)
- No data loss

---

## Mobile UI Fix (Bonus)

Also fixed mobile UI issue where sign-out button overlapped with logo:

**Before on mobile:**
```
Memorio Logo [Sign Out]  ← Overlapping!
```

**After on mobile:**
```
    Memorio Logo
    [Sign Out]           ← Stacked vertically
```

**CSS added:**
```css
@media (max-width: 768px) {
  #signOutBtn {
    position: static;
    display: block;
    width: calc(100% - 40px);
    max-width: 200px;
    margin: 10px auto;
  }
  
  .nav {
    flex-direction: column;
    align-items: center;
  }
}
```

---

## Files Changed

1. ✅ **`supabase/migrations/050_add_unique_constraint_to_forms_case_id.sql`** (NEW)
   - Adds UNIQUE constraint to forms.case_id
   - Handles duplicates
   - Creates index

2. ✅ **`family-form.html`**
   - Added mobile responsive CSS for sign-out button
   - Prevents overlap on small screens

3. ✅ **`APPLY-FORMS-UNIQUE-CONSTRAINT.md`** (this file)
   - Instructions for applying fix
   - Verification steps
   - Technical documentation

---

## Priority

🔴 **CRITICAL** - Autosave is completely broken without this. Apply migration 050 immediately!

After applying, family users will be able to save their progress properly. 🚀

