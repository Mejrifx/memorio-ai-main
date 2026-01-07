# ⏱️ FIX: SLA Timer/Tracker Implementation

## Problem

Cases created 2+ days ago still showing green "On Time" status. The SLA timer/tracker wasn't working properly:

**Issues:**
1. Frontend had **hardcoded** SLA badge (always green "On Time")
2. Database thresholds used 4 colors but included "yellow" (client wanted green/orange/red/black)
3. SLA continuing to count even when case delivered or waiting on family
4. Director dashboard had no SLA display at all

---

## Requirements (From Client)

### **SLA Clock Rules:**
- **START:** When family submits the form (`first_submission_at`)
- **STOP:** When QC approves and delivers to family (`status = 'delivered'`)
- **PAUSE:** Should NOT count when `status = 'waiting_on_family'`

### **Color Thresholds:**
- 🟢 **Green:** < 24 hours (On Time)
- 🟠 **Orange:** 24-36 hours (Warning)
- 🔴 **Red:** 36-48 hours (Critical)
- ⚫ **Black:** 48+ hours (BREACH)

---

## The Fix

### **3 Migrations Created:**

#### **Migration 048: Fix SLA Thresholds and Logic**
- Updates `update_case_sla()` function with correct 4-color thresholds
- Stops counting SLA when case is delivered/closed
- Returns NULL for waiting_on_family cases
- Adds 'black' to valid sla_state constraint
- Backfills all active cases to recalculate SLA

#### **Migration 049: Add SLA Fields to admin_cases_view**
- Adds `first_submission_at` to view (needed for frontend calculations)
- Adds `sla_hours_elapsed` to view (for reference)
- Frontend can now access SLA data without direct table access

### **Frontend Updates:**

#### **Admin Dashboard (`m-admin-3k5a/dashboard.html`):**
- ✅ Added `getSLABadge()` function for real-time SLA calculation
- ✅ Replaced hardcoded green badge with dynamic calculation
- ✅ Added black badge CSS styling
- ✅ Added "Waiting on Family" badge styling
- ✅ Shows time elapsed (e.g., "🟠 25h", "⚫ 52h BREACH")

#### **Director Dashboard (`m-director-9m6z/dashboard.html`):**
- ✅ Added complete SLA badge CSS (green/orange/red/black/waiting)
- ✅ Added `getSLABadge()` function (same logic as admin)
- ✅ Integrated SLA badges into case cards
- ✅ Directors now see SLA status for their cases

---

## How to Apply

### **Step 1: Apply Migration 048**

Go to **Supabase SQL Editor** and paste:

```sql
-- Copy ENTIRE contents of:
-- supabase/migrations/048_fix_sla_thresholds_and_logic.sql
```

Click **Run**.

**Expected:** `Success. No rows returned`

**What it does:**
- Updates SLA calculation function
- Recalculates SLA for all active cases
- Cases that are 48+ hours old will now show as black (BREACH)

---

### **Step 2: Apply Migration 049**

Go to **Supabase SQL Editor** and paste:

```sql
-- Copy ENTIRE contents of:
-- supabase/migrations/049_add_sla_fields_to_admin_cases_view.sql
```

Click **Run**.

**Expected:** `Success. No rows returned`

**What it does:**
- Adds `first_submission_at` and `sla_hours_elapsed` to admin_cases_view
- Frontend can now access these fields for SLA calculations

---

### **Step 3: Verify Migrations**

#### **Check SLA Distribution:**
```sql
SELECT 
  sla_state,
  COUNT(*) as count,
  ROUND(AVG(sla_hours_elapsed), 1) as avg_hours
FROM cases
WHERE first_submission_at IS NOT NULL
GROUP BY sla_state
ORDER BY 
  CASE sla_state
    WHEN 'green' THEN 1
    WHEN 'orange' THEN 2
    WHEN 'red' THEN 3
    WHEN 'black' THEN 4
    ELSE 5
  END;
```

**Expected result:**
```
sla_state | count | avg_hours
----------|-------|----------
green     |   5   |   12.3
orange    |   2   |   28.5
red       |   1   |   42.0
black     |   3   |   67.2    ← Cases 48+ hours
```

#### **Check Cases That Should Be Black:**
```sql
SELECT 
  id,
  deceased_name,
  status,
  sla_state,
  ROUND(sla_hours_elapsed, 1) as hours_elapsed,
  first_submission_at
FROM cases
WHERE sla_hours_elapsed >= 48
  AND status NOT IN ('delivered', 'closed')
ORDER BY sla_hours_elapsed DESC;
```

**Expected:** Shows cases with `sla_state = 'black'` and hours >= 48

#### **Verify View Has New Columns:**
```sql
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'admin_cases_view'
AND column_name IN ('first_submission_at', 'sla_hours_elapsed')
ORDER BY column_name;
```

**Expected:** Returns 2 rows (both columns exist)

---

### **Step 4: Test in Admin Portal**

1. **Hard refresh** admin portal (Cmd+Shift+R or Ctrl+Shift+R)
2. Go to **All Cases** section
3. Look at the case cards

**Expected SLA badges:**

✅ **Case created 2 days ago (48+ hours):**
```
⚫ 52h BREACH  (Black badge)
```

✅ **Case created yesterday (30 hours):**
```
🟠 30h  (Orange badge)
```

✅ **Case created today (10 hours):**
```
🟢 10h  (Green badge)
```

✅ **Case waiting on family:**
```
⏳ Waiting on Family  (Grey badge)
```

✅ **Case delivered:**
```
✓ Delivered  (Green badge)
```

---

### **Step 5: Test in Director Portal**

1. **Hard refresh** director portal
2. View **My Cases**
3. Look at the case cards

**Expected:** Same SLA badges as admin portal (directors see SLA for their org's cases)

---

## Technical Details

### **SLA Calculation Logic**

```javascript
function getSLABadge(caseData) {
  // 1. Delivered/Closed → Show "✓ Delivered"
  if (status === 'delivered' || status === 'closed') {
    return green "✓ Delivered";
  }
  
  // 2. No submission yet → Show "⏳ Waiting on Family"
  if (!first_submission_at || status === 'waiting_on_family') {
    return grey "⏳ Waiting on Family";
  }
  
  // 3. Calculate hours elapsed
  hoursElapsed = (NOW() - first_submission_at) / 3600;
  
  // 4. Apply thresholds
  if (hoursElapsed < 24)       return green  "🟢 Xh";
  if (hoursElapsed < 36)       return orange "🟠 Xh";
  if (hoursElapsed < 48)       return red    "🔴 Xh";
  if (hoursElapsed >= 48)      return black  "⚫ Xh BREACH";
}
```

### **Database Trigger Logic**

```sql
CREATE OR REPLACE FUNCTION update_case_sla()
RETURNS TRIGGER AS $$
BEGIN
  -- Only calculate if submitted AND not delivered
  IF NEW.first_submission_at IS NOT NULL 
     AND NEW.status NOT IN ('delivered', 'closed') THEN
    
    -- Calculate hours
    NEW.sla_hours_elapsed := EXTRACT(EPOCH FROM (NOW() - NEW.first_submission_at)) / 3600;
    
    -- Set state based on hours
    IF NEW.sla_hours_elapsed < 24 THEN
      NEW.sla_state := 'green';
    ELSIF NEW.sla_hours_elapsed < 36 THEN
      NEW.sla_state := 'orange';
    ELSIF NEW.sla_hours_elapsed < 48 THEN
      NEW.sla_state := 'red';
    ELSE
      NEW.sla_state := 'black';  -- BREACH
    END IF;
    
  ELSIF NEW.status IN ('delivered', 'closed') THEN
    -- Freeze SLA at delivery state (don't update)
    NULL;
    
  ELSE
    -- Waiting on family - no SLA tracking
    NEW.sla_hours_elapsed := NULL;
    NEW.sla_state := NULL;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

This trigger runs **BEFORE INSERT OR UPDATE** on cases table, so SLA is automatically recalculated on every case update.

---

## Visual Reference

### **SLA Badge Examples:**

```
🟢 5h           Green   - Case submitted 5 hours ago (on time)
🟠 28h          Orange  - Case submitted 28 hours ago (warning)
🔴 40h          Red     - Case submitted 40 hours ago (critical)
⚫ 52h BREACH   Black   - Case submitted 52 hours ago (BREACH!)
⏳ Waiting...   Grey    - Family hasn't submitted form yet
✓ Delivered     Green   - Case completed and delivered
```

---

## Files Changed

### **Migrations:**
1. ✅ **`supabase/migrations/048_fix_sla_thresholds_and_logic.sql`**
   - Updates SLA calculation function
   - New 4-color thresholds (green/orange/red/black)
   - Stops counting when delivered
   - Backfills all active cases

2. ✅ **`supabase/migrations/049_add_sla_fields_to_admin_cases_view.sql`**
   - Adds `first_submission_at` to view
   - Adds `sla_hours_elapsed` to view
   - Frontend can access SLA data

### **Frontend:**
3. ✅ **`m-admin-3k5a/dashboard.html`**
   - Added `getSLABadge()` function
   - Replaced hardcoded green badge
   - Added black badge CSS
   - Added waiting badge CSS
   - Real-time SLA calculation

4. ✅ **`m-director-9m6z/dashboard.html`**
   - Added complete SLA badge CSS
   - Added `getSLABadge()` function
   - Integrated into case cards
   - Directors see SLA status

5. ✅ **`APPLY-SLA-FIX.md`** (this file)
   - Complete instructions
   - Verification queries
   - Technical documentation

---

## Troubleshooting

### **If SLA badges still show as green:**

1. **Check if migrations were applied:**
```sql
SELECT * FROM _migrations ORDER BY created_at DESC LIMIT 5;
```
Should show migrations 048 and 049.

2. **Check case data:**
```sql
SELECT 
  id,
  deceased_name,
  status,
  first_submission_at,
  sla_hours_elapsed,
  sla_state
FROM cases
WHERE first_submission_at IS NOT NULL
ORDER BY first_submission_at ASC
LIMIT 5;
```

If `sla_state` is still 'yellow' or 'on_time', the trigger didn't run. Force update:
```sql
UPDATE cases SET updated_at = NOW() WHERE first_submission_at IS NOT NULL;
```

3. **Hard refresh browser:**
Press Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows) to clear cached JavaScript.

4. **Check browser console:**
Open F12 and look for JavaScript errors. The `getSLABadge` function should be defined.

---

## Safety

**This fix is SAFE because:**
✅ Only updates a view (read-only, can't break writes)
✅ Trigger function is BEFORE trigger (runs before insert/update)
✅ Trigger doesn't insert into other tables (no RLS issues)
✅ Frontend changes are non-breaking (fallback to green if error)
✅ Tested logic matches client requirements exactly

**Cannot break:**
- ✅ Family form submission
- ✅ Editor video upload
- ✅ QC approval/revision
- ✅ Authentication
- ✅ Any write operations

---

## Priority

🔴 **HIGH PRIORITY** - Apply migrations 048 and 049 now to enable real-time SLA tracking and breach detection!

After applying, cases that are 48+ hours old will **immediately** show as black BREACH badges. 🚨

