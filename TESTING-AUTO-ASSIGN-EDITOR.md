# Auto-Assign Editor Feature - Testing Guide

## Overview
This guide provides step-by-step instructions for testing the auto-assign editor feature with various scenarios.

## Prerequisites
1. Deploy the `auto-assign-editor` Edge Function to Supabase
2. Ensure at least one family account exists with an assigned case
3. Have access to the Admin portal to manage editor accounts

## Deployment Instructions

### 1. Deploy the Edge Function
```bash
# Navigate to the project directory
cd /Users/mejrifx/Downloads/memorio-ai

# Deploy the auto-assign-editor function
supabase functions deploy auto-assign-editor

# Verify deployment
supabase functions list
```

## Test Scenarios

### Test 1: Happy Path - Multiple Editors with Different Loads

**Setup:**
1. Create 3 editor accounts via Admin Portal:
   - Editor A (editorA@test.com)
   - Editor B (editorB@test.com)
   - Editor C (editorC@test.com)

2. Manually assign cases to create different loads:
   - Editor A: 0 cases
   - Editor B: 2 cases (assign manually via Admin portal)
   - Editor C: 1 case (assign manually via Admin portal)

**Test:**
1. Log in as a family user
2. Complete and submit the intake form
3. Check browser console for: `✅ Editor auto-assigned: [name]`

**Expected Result:**
- The case should be assigned to **Editor A** (0 cases)
- Admin portal "All Cases" should show the case in "In Progress"
- Case status should be `in_production`

**Verify:**
```sql
-- Check the assignment in Supabase SQL Editor
SELECT 
  ea.case_id,
  ea.editor_user_id,
  u.email as editor_email,
  c.deceased_name,
  c.status
FROM editor_assignments ea
JOIN users u ON u.id = ea.editor_user_id
JOIN cases c ON c.id = ea.case_id
WHERE ea.unassigned_at IS NULL
ORDER BY ea.assigned_at DESC
LIMIT 5;
```

---

### Test 2: Equal Load - Tiebreaker (Oldest Account)

**Setup:**
1. Create 2 editor accounts on different days (or times):
   - Editor X (created first)
   - Editor Y (created second)

2. Assign 1 case to each editor

**Test:**
1. Submit a new family form

**Expected Result:**
- The case should be assigned to **Editor X** (oldest account)

---

### Test 3: No Editors Available

**Setup:**
1. Delete all editor accounts OR suspend all editors

**Test:**
1. Submit a family form
2. Check browser console for: `⚠️ No editors available - admin notified`

**Expected Result:**
- Case remains in `submitted` status (not `in_production`)
- Admin portal dashboard shows notification alert
- Red badge appears on "All Cases" nav link
- Notification record created in database

**Verify:**
```sql
-- Check notifications table
SELECT * FROM notifications
WHERE event_type = 'no_editors_available'
AND status = 'pending'
ORDER BY created_at DESC;

-- Check the case status
SELECT id, deceased_name, status FROM cases
WHERE status = 'submitted'
ORDER BY created_at DESC
LIMIT 5;
```

---

### Test 4: One Invited Editor (Not Yet Logged In)

**Setup:**
1. Create 1 editor account via Admin Portal
2. Do NOT log in as that editor (status = 'invited')

**Test:**
1. Submit a family form

**Expected Result:**
- Case should be assigned to the invited editor
- Status should be `active` OR `invited` (both are eligible)

---

### Test 5: Case Already Has Editor

**Setup:**
1. Create a case and manually assign an editor via Admin portal
2. Log in as the family user for that case

**Test:**
1. Try to call the auto-assign function (this shouldn't happen in normal flow, but test Edge Function directly)

**Expected Result:**
- Edge Function returns: `"Case already has an editor assigned"`
- No duplicate assignment created

---

### Test 6: Load Balancing with Real-World Scenario

**Setup:**
1. Create 5 editor accounts
2. Assign cases to simulate real workload:
   - Editor 1: 5 cases
   - Editor 2: 3 cases
   - Editor 3: 0 cases
   - Editor 4: 2 cases
   - Editor 5: 1 case

**Test:**
1. Submit 3 family forms in succession

**Expected Results:**
- 1st submission → assigned to Editor 3 (0 cases → 1 case)
- 2nd submission → assigned to Editor 5 (1 case → 2 cases)
- 3rd submission → assigned to Editor 4 (2 cases → 3 cases)

---

### Test 7: RLS Security Verification

**Setup:**
1. Create 2 family users with different cases

**Test A - Valid Request:**
1. Log in as Family User A
2. Submit form for Case A
3. Should succeed

**Test B - Unauthorized Request (Manual API Call):**
1. Get Family User A's auth token
2. Try to call auto-assign for Family User B's case
3. Use browser console:
```javascript
const response = await fetch(
  `${SUPABASE_URL}/functions/v1/auto-assign-editor`,
  {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${session.access_token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ case_id: '<OTHER_FAMILYS_CASE_ID>' })
  }
);
console.log(await response.json());
```

**Expected Result:**
- Request should fail with 403 Forbidden
- Error: "Unauthorized: Case does not belong to you"

---

### Test 8: Concurrent Submissions

**Setup:**
1. Have 2 editors with equal case loads
2. Have 2 family users ready to submit forms

**Test:**
1. Submit both forms at nearly the same time (within 1 second)

**Expected Result:**
- Both submissions should succeed
- Each should get assigned to different editors
- No race condition errors

---

## Monitoring & Debugging

### Check Console Logs
**Family Portal:**
- `🤖 Auto-assigning editor to case...`
- `✅ Editor auto-assigned: [name]` OR
- `⚠️ No editors available - admin notified`

**Supabase Logs:**
```bash
# View Edge Function logs
supabase functions logs auto-assign-editor --tail
```

### Check Database State
```sql
-- View all active assignments with load
SELECT 
  u.email,
  u.status,
  COUNT(ea.id) as active_cases
FROM users u
LEFT JOIN editor_assignments ea 
  ON ea.editor_user_id = u.id 
  AND ea.unassigned_at IS NULL
WHERE u.role = 'editor'
GROUP BY u.id, u.email, u.status
ORDER BY active_cases ASC;

-- View recent audit events
SELECT * FROM events
WHERE action_type IN ('AUTO_ASSIGN_EDITOR', 'NO_EDITORS_AVAILABLE')
ORDER BY timestamp DESC
LIMIT 10;
```

### Check Notifications
```sql
-- View pending notifications for admins
SELECT 
  n.id,
  n.case_id,
  c.deceased_name,
  n.event_type,
  n.recipients,
  n.created_at
FROM notifications n
JOIN cases c ON c.id = n.case_id
WHERE n.event_type = 'no_editors_available'
AND n.status = 'pending'
ORDER BY n.created_at DESC;
```

## Common Issues & Solutions

### Issue 1: "Network Error" or CORS error
**Solution:** Ensure Edge Function is deployed and CORS headers are set correctly

### Issue 2: "Unauthorized" when calling function
**Solution:** Check that family user is logged in and has a valid session

### Issue 3: Editor not being assigned despite being available
**Solution:** 
- Check editor status is 'active' or 'invited'
- Check editor_assignments table for existing assignments
- Review Edge Function logs

### Issue 4: Notification badge not showing
**Solution:**
- Hard refresh admin portal (Cmd/Ctrl + Shift + R)
- Check browser console for errors
- Verify notifications exist in database

### Issue 5: Case stays in "submitted" instead of "in_production"
**Solution:**
- Check if editor was actually assigned
- Review case status update logic in Edge Function
- Check for RLS policy issues on cases table

## Success Criteria

✅ Cases are automatically assigned when family submits form
✅ Editor with fewest cases receives the assignment
✅ When no editors available, admin is notified
✅ Notification badge appears in admin portal
✅ Cases move to "In Progress" column after assignment
✅ Manual assignment still works as backup
✅ No errors in browser console or Edge Function logs
✅ RLS prevents unauthorized assignments

## Performance Benchmarks

- Auto-assignment should complete in < 2 seconds
- Family form submission should not be blocked
- Admin portal loads notifications in < 1 second
- Edge Function handles concurrent requests without errors

