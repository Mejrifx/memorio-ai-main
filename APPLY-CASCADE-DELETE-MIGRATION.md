# Apply Cascade Delete Migration

## What This Fixes

**Problem**: When you delete an organization, the database records get deleted but the Supabase Auth users remain. This causes:
- Director accounts can still log in but see no data
- Family accounts can log in but get "no case found" errors
- Orphaned credentials that should be deleted

**Solution**: This migration adds a database trigger that automatically deletes all Auth users when their organization is deleted.

---

## How to Apply the Migration

### Step 1: Go to Supabase Dashboard

1. **Open**: https://supabase.com/dashboard
2. **Select your project**: memorio-ai
3. **Navigate to**: SQL Editor (left sidebar)

### Step 2: Run the Migration

1. **Click**: "+ New Query"
2. **Copy the entire contents** of `supabase/migrations/010_cascade_delete_auth_users.sql`
3. **Paste** into the SQL editor
4. **Click**: "Run" button (or press Ctrl/Cmd + Enter)

### Step 3: Verify Success

You should see a success message:
```
Success. No rows returned
```

This means:
- ✅ Function `delete_org_auth_users()` created
- ✅ Trigger `delete_org_auth_users_trigger` created
- ✅ Permissions granted

---

## What This Migration Does

### 1. **Creates a Function** (`delete_org_auth_users`)
   - Runs automatically when an organization is deleted
   - Loops through all users in that organization
   - Deletes each user from `auth.users` table
   - Logs audit events for each deletion

### 2. **Creates a Trigger** (`delete_org_auth_users_trigger`)
   - Fires BEFORE an organization is deleted
   - Ensures users are deleted before the org record is removed
   - Prevents orphaned auth accounts

### 3. **Cascade Flow**
   ```
   Delete Organization
   ↓
   Trigger Fires → Delete Auth Users
   ↓
   Auth Cascade → Delete Users Table Records
   ↓
   Foreign Key Cascade → Delete Cases
   ↓
   Foreign Key Cascade → Delete Forms
   ↓
   Foreign Key Cascade → Delete Assets
   ↓
   Complete Cleanup ✓
   ```

---

## Testing the Migration

### Test 1: Delete an Organization

1. **Go to Admin Portal**
2. **Find a test organization** (or create a new one)
3. **Click "Delete Organization"**
4. **Confirm deletion**
5. **Expected Result**: Organization and all users completely deleted

### Test 2: Verify Auth Users Deleted

1. **Go to Supabase Dashboard** → Authentication → Users
2. **Search for the deleted organization's users** (by email)
3. **Expected Result**: No users found (they've been deleted)

### Test 3: Try to Log In

1. **Try to log in as a deleted director or family member**
2. **Expected Result**: "Invalid login credentials" error
3. **NOT**: "No cases found" or "Access denied" errors

---

## What Gets Deleted

When you delete an organization, this is the complete cleanup:

### ✅ Authentication Layer
- [ ] All Director auth users
- [ ] All Family auth users  
- [ ] All login credentials wiped

### ✅ Database Layer
- [ ] Organization record
- [ ] All user metadata records
- [ ] All cases for that organization
- [ ] All forms and submissions
- [ ] All uploaded assets
- [ ] All editor assignments
- [ ] All notifications
- [ ] All audit events

---

## Rollback (If Needed)

If you need to remove this migration:

```sql
-- Drop the trigger
DROP TRIGGER IF EXISTS delete_org_auth_users_trigger ON organizations;

-- Drop the function
DROP FUNCTION IF EXISTS delete_org_auth_users();
```

**Note**: This doesn't undo any deletions that already happened. It only prevents future automatic deletions.

---

## Enhanced Admin Portal

The Admin Portal now shows:
- **User count** before deletion
- **Clear warning** about credential deletion
- **Comprehensive list** of what will be deleted
- **Success confirmation** with user count

Example warning:
```
This action will permanently remove:
• Organization details
• 3 user accounts (Directors, Families)
• All authentication credentials
• All associated cases
• All form submissions
• All uploaded assets
• All related data

All users will be immediately logged out and unable to log in.
```

---

## Troubleshooting

### Issue: "Permission denied for table auth.users"

**Cause**: Function doesn't have permission to delete from auth.users

**Fix**: Run this SQL:
```sql
GRANT DELETE ON auth.users TO postgres;
```

### Issue: "Function does not exist"

**Cause**: Migration wasn't applied correctly

**Fix**: Re-run the migration SQL in Supabase Dashboard

### Issue: Users still exist after org deletion

**Cause**: Trigger didn't fire or failed silently

**Fix**: Check logs:
```sql
SELECT * FROM events 
WHERE action_type = 'CASCADE_DELETE_USER' 
ORDER BY timestamp DESC 
LIMIT 10;
```

---

## Security Notes

- **SECURITY DEFINER**: Function runs with elevated privileges to delete auth users
- **Audit Logging**: Every user deletion is logged in the `events` table
- **Error Handling**: Failed deletions are logged as warnings, don't block org deletion
- **Transaction Safety**: BEFORE trigger ensures atomicity

---

## Support

If you encounter any issues:

1. **Check Supabase logs**: Database → Logs
2. **Check audit events**: 
   ```sql
   SELECT * FROM events WHERE action_type = 'CASCADE_DELETE_USER';
   ```
3. **Verify trigger exists**:
   ```sql
   SELECT * FROM pg_trigger WHERE tgname = 'delete_org_auth_users_trigger';
   ```

---

## Summary

✅ **Apply the migration** → Run SQL in Supabase Dashboard
✅ **Test deletion** → Delete a test organization
✅ **Verify cleanup** → Check that auth users are deleted
✅ **Enjoy** → No more orphaned accounts!

