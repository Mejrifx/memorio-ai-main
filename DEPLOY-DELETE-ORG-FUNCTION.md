# Deploy Delete Organization Edge Function

This Edge Function properly deletes an organization and all associated auth users.

## What It Does

1. **Verifies admin permissions** - Only admins can delete organizations
2. **Deletes all auth.users** - Uses Supabase Admin API to completely remove authentication accounts
3. **Deletes public.users records** - Cleans up the users table
4. **Deletes organization** - Removes the organization (cascades to cases, forms, assets, etc.)
5. **Logs audit trail** - Records the deletion in the events table

## Deploy Command

```bash
cd /Users/mejrifx/Downloads/memorio-ai

# Deploy the delete-organization function
supabase functions deploy delete-organization
```

## Environment Variables

The function automatically uses these from your Supabase project:
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Public anon key
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key (has admin permissions)

These are automatically available in Edge Functions, no manual setup needed.

## Testing

After deployment:

1. **Log in as admin** to the Admin Portal
2. **Create a test organization** with 1-2 users
3. **Delete the organization**
4. **Try to log in** with the deleted users' credentials
5. **Verify**: Login should fail with "Invalid login credentials"

## What Gets Deleted

When you delete an organization, the following are **permanently removed**:

✅ **Auth Users** (`auth.users`):
- All director accounts in the organization
- All family accounts in the organization
- Authentication credentials (email/password)
- JWT tokens invalidated

✅ **Public Data** (cascade deleted automatically):
- `public.users` records
- All `cases` in the organization
- All `forms` for those cases
- All `assets` (photos/videos) for those cases
- All `editor_assignments` for those cases
- All `notifications` for those cases
- All `exports` for the organization

✅ **Storage** (manual cleanup recommended):
- Files in `case-assets` bucket under `{org_id}/` folder
- (Currently requires manual deletion via Dashboard)

## Console Logs

You'll see detailed logs:
```
Admin user@example.com is deleting organization abc-123
Found 3 user(s) to delete
Deleting auth user: director@test.com (director)
✅ Successfully deleted auth user: director@test.com
Deleting auth user: family@test.com (family)
✅ Successfully deleted auth user: family@test.com
✅ Organization abc-123 deleted successfully
```

## Troubleshooting

### "Missing authorization header"
- Make sure you're logged in as an admin
- The dashboard passes your session token automatically

### "Unauthorized: Only admins can delete organizations"
- Your account must have `role = 'admin'` in the `users` table
- Run the SQL fix from previous steps if needed

### "Failed to fetch users"
- Check RLS policies on the `users` table
- Ensure the service role key is set correctly

### Users can still log in after deletion
- Check the console logs to see if auth deletion succeeded
- Verify the Edge Function was deployed successfully
- Check for any error messages in the deletion results

## Rollback

If you need to revert to the old method (database trigger only):

1. Comment out the Edge Function call in `dashboard.html`
2. Restore the direct database delete:
```javascript
const { error } = await supabaseClient
  .from('organizations')
  .delete()
  .eq('id', orgId);
```

However, this won't delete auth users properly. The Edge Function is the recommended approach.

## Security Notes

- The Edge Function uses `SUPABASE_SERVICE_ROLE_KEY` which has full admin permissions
- Access is restricted to verified admin users only
- All deletions are logged in the `events` table for audit trail
- Deletion is immediate and **cannot be undone**

## Related Files

- Edge Function: `supabase/functions/delete-organization/index.ts`
- Admin Dashboard: `m-admin-3k5a/dashboard.html`
- Database Trigger (legacy): `supabase/migrations/010_cascade_delete_auth_users.sql`

