# 📊 FIX: Organization Analytics Showing Zero/Mock Data

## Problem

When viewing an organization's details in the admin portal, the case analytics are not working:

**Current behavior:**
- Active Cases: **0** (should show real count)
- Cases in Last 30 Days: **0** (should show real count)
- On-Time Cases: **0** (should show real count)
- Breach Cases: **0** (should show real count)
- SLA Performance: **100%** (should show real percentage)

**Looks like mock/dummy data even when the org has cases!**

---

## Root Cause

### The `case_analytics` View is Missing Required Fields

The view currently only includes:
- ✅ `total_cases`
- ✅ `completed_cases`
- ✅ `active_cases`
- ✅ `avg_completion_hours`

But the frontend expects:
- ✅ `active_cases` (exists)
- ❌ `cases_last_30_days` (MISSING)
- ❌ `on_time_cases` (MISSING)
- ❌ `breach_cases` (MISSING)
- ❌ `sla_percentage` (MISSING)

### What Happens:
1. Frontend queries `case_analytics` view for org_id
2. Query succeeds but missing fields return as `undefined`
3. Frontend tries to access `analyticsData.cases_last_30_days` → `undefined`
4. Falls back to `|| 0` → Shows **0**
5. Same for all other missing fields
6. Result: Everything shows 0 except SLA which defaults to 100%

---

## The Fix

### Migration 047: Recreate case_analytics with ALL fields

This migration recreates the view with comprehensive analytics including:
- Total cases
- Completed cases  
- Active cases (current statuses)
- Cases created in last 30 days
- On-time cases (SLA green/yellow)
- Breach cases (SLA orange/red)
- SLA performance percentage
- Average completion hours

---

## How to Apply

### Step 1: Apply Migration 047

Go to your **Supabase SQL Editor** and run:

```sql
-- Copy and paste the ENTIRE contents of:
-- supabase/migrations/047_fix_case_analytics_view.sql
```

Click **Run**.

**Expected output:** `Success. No rows returned`

---

### Step 2: Verify View Structure

Run this query to confirm all columns exist:

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'case_analytics'
ORDER BY ordinal_position;
```

**Expected columns:**
```
column_name          | data_type
---------------------|----------
org_id               | uuid
total_cases          | bigint
completed_cases      | bigint
active_cases         | bigint
cases_last_30_days   | bigint        ← Should be here now!
on_time_cases        | bigint        ← Should be here now!
breach_cases         | bigint        ← Should be here now!
sla_percentage       | numeric       ← Should be here now!
avg_completion_hours | numeric
```

---

### Step 3: Test Data Retrieval

Run this query to see actual analytics data:

```sql
SELECT 
  org_id,
  total_cases,
  active_cases,
  cases_last_30_days,
  on_time_cases,
  breach_cases,
  sla_percentage
FROM case_analytics;
```

**Expected result:** Should show **real data** for orgs with cases, not zeros!

Example output:
```
org_id                | total | active | last_30 | on_time | breach | sla_%
----------------------|-------|--------|---------|---------|--------|------
abc123...             |   15  |    8   |   12    |    6    |   2    | 75.0
def456...             |    5  |    2   |    4    |    2    |   0    | 100.0
```

---

### Step 4: Test in Admin Portal

1. **Refresh your admin portal** (hard refresh: Cmd+Shift+R or Ctrl+Shift+R)
2. Open **browser console** (F12)
3. Go to **Manage Organizations** tab
4. Click on an **organization card** that has cases

**Console should show:**
```
📊 Loading analytics for org: abc123-def456-...
📊 Analytics query result: {
  analytics: {
    org_id: "abc123...",
    total_cases: 15,
    active_cases: 8,
    cases_last_30_days: 12,  ← Should have real data!
    on_time_cases: 6,        ← Should have real data!
    breach_cases: 2,         ← Should have real data!
    sla_percentage: 75.0     ← Should have real data!
  },
  analyticsError: null
}
✅ Analytics loaded successfully: {...}
```

**Organization modal should display:**
```
Case Analytics
--------------
Active Cases:          8
Cases (Last 30 Days):  12
On-Time Cases:         6
Breach Cases:          2
SLA Performance:       75.0%  (color: yellow/red depending on value)
```

---

### Step 5: Test Organizations Without Cases

Click on an org that **has NO cases yet**.

**Console should show:**
```
📊 Loading analytics for org: xyz789...
📊 Analytics query result: {
  analytics: null,
  analyticsError: { code: 'PGRST116', ... }
}
⚠️ Analytics error (using defaults): {...}
ℹ️ No cases found for this organization yet
```

**Organization modal should display:**
```
Case Analytics
--------------
Active Cases:          0
Cases (Last 30 Days):  0
On-Time Cases:         0
Breach Cases:          0
SLA Performance:       100%  (green - no cases to breach)
```

This is **correct behavior** for orgs with no cases!

---

## Technical Details

### SLA State Values

The `cases` table uses these `sla_state` values:

**On-Time (Good):**
- `'green'` - Under 24 hours
- `'yellow'` - 24-36 hours (warning)
- `'on_time'` - Generic on-time state

**Breach (Bad):**
- `'orange'` - 36-48 hours (breach warning)
- `'red'` - 48+ hours (critical breach)
- `'warning'` - Generic warning state
- `'breach'` - Generic breach state

**No SLA Yet:**
- `NULL` - Family hasn't submitted form yet

### Analytics Calculation Logic

```sql
-- Active Cases: Any case not delivered/closed
active_cases = COUNT(*) WHERE status IN (
  'created', 'waiting_on_family', 'intake_in_progress', 
  'submitted', 'in_production', 'awaiting_review'
)

-- Cases Last 30 Days: Created within 30 days
cases_last_30_days = COUNT(*) WHERE created_at >= NOW() - INTERVAL '30 days'

-- On-Time Cases: Good SLA + Active
on_time_cases = COUNT(*) WHERE 
  sla_state IN ('green', 'yellow', 'on_time')
  AND status NOT IN ('delivered', 'closed')

-- Breach Cases: Bad SLA + Active
breach_cases = COUNT(*) WHERE 
  sla_state IN ('orange', 'red', 'warning', 'breach')
  AND status NOT IN ('delivered', 'closed')

-- SLA Performance: Percentage of on-time cases
sla_percentage = (on_time_cases / (on_time_cases + breach_cases)) * 100
-- Returns 100% if no active cases (no cases to breach)
```

### Frontend Changes

Added comprehensive logging to `openOrgModal()`:
- Logs the org_id being queried
- Logs the full analytics query result
- Distinguishes between "no cases" (PGRST116) vs actual errors
- Shows what data was loaded or what defaults were used

---

## Troubleshooting

### If Analytics Still Show Zero:

**1. Check if org actually has cases:**
```sql
SELECT COUNT(*) 
FROM cases 
WHERE org_id = '<org-id>';
```

If result is 0, then zero analytics is correct!

**2. Check view permissions:**
```sql
SELECT has_table_privilege('authenticated', 'case_analytics', 'SELECT');
```

Should return `true`.

**3. Check your role:**
```sql
SELECT public.get_my_role();
```

Should return `'admin'` when logged in as admin.

**4. Test view directly:**
```sql
SELECT * FROM case_analytics WHERE org_id = '<org-id>';
```

Should return a row with real data if org has cases.

**5. Check browser console:**
Look for the `📊 Analytics query result` log and share the output.

---

## Files Changed

1. ✅ **`supabase/migrations/047_fix_case_analytics_view.sql`** (NEW)
   - Recreates `case_analytics` view with all required fields
   - Adds comprehensive SLA calculations
   - Includes detailed comments and verification queries

2. ✅ **`m-admin-3k5a/dashboard.html`**
   - Added debug logging to `openOrgModal()` function
   - Better error handling for analytics query
   - Distinguishes "no cases" from actual errors

3. ✅ **`APPLY-ANALYTICS-FIX.md`** (this file)
   - Complete instructions for applying the fix
   - Verification steps
   - Troubleshooting guide

---

## Priority

🔴 **HIGH PRIORITY** - This affects the ability to monitor organization performance and SLA compliance in the admin portal.

Apply migration 047 now to see real analytics data! 📊

