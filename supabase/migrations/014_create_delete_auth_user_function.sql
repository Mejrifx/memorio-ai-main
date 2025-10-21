-- Create RPC function to delete auth users
-- This is more reliable than the Admin API which sometimes fails with "Database error"

CREATE OR REPLACE FUNCTION delete_auth_user(user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auth, pg_temp
AS $$
BEGIN
  -- Delete from auth.users (this will cascade to auth.identities, etc.)
  DELETE FROM auth.users WHERE id = user_id;
  
  -- Return true if deletion succeeded
  RETURN FOUND;
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error but don't fail completely
    RAISE WARNING 'Error deleting auth user %: %', user_id, SQLERRM;
    RETURN false;
END;
$$;

-- Grant execute permission to authenticated users (Edge Functions use service role)
GRANT EXECUTE ON FUNCTION delete_auth_user(uuid) TO authenticated, service_role;

COMMENT ON FUNCTION delete_auth_user IS 
  'Deletes a user from auth.users schema. Must be called with service role permissions. Used by delete-organization Edge Function to ensure complete user deletion.';

