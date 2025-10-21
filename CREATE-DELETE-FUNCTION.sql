-- ============================================================================
-- CREATE AUTH USER DELETION FUNCTION
-- Run this in Supabase SQL Editor to enable proper auth user deletion
-- ============================================================================

-- Drop the function if it exists (to ensure clean creation)
DROP FUNCTION IF EXISTS delete_auth_user(uuid);

-- Create the function with proper permissions
CREATE OR REPLACE FUNCTION delete_auth_user(user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result_json jsonb;
  deleted_count integer;
BEGIN
  -- Delete from auth.users (this will cascade to auth.identities, sessions, etc.)
  DELETE FROM auth.users WHERE id = user_id;
  
  -- Get the number of rows deleted
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  -- Build result JSON
  IF deleted_count > 0 THEN
    result_json := jsonb_build_object(
      'success', true,
      'deleted', true,
      'user_id', user_id,
      'message', 'User deleted successfully'
    );
    RAISE NOTICE 'Successfully deleted auth user: %', user_id;
  ELSE
    result_json := jsonb_build_object(
      'success', true,
      'deleted', false,
      'user_id', user_id,
      'message', 'User not found (may already be deleted)'
    );
    RAISE NOTICE 'User % not found in auth.users', user_id;
  END IF;
  
  RETURN result_json;
  
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error
    RAISE WARNING 'Error deleting auth user %: % (SQLSTATE: %)', user_id, SQLERRM, SQLSTATE;
    
    -- Return error result
    result_json := jsonb_build_object(
      'success', false,
      'deleted', false,
      'user_id', user_id,
      'error', SQLERRM,
      'sqlstate', SQLSTATE
    );
    
    RETURN result_json;
END;
$$;

-- Grant execute permission to authenticated and service_role
GRANT EXECUTE ON FUNCTION delete_auth_user(uuid) TO authenticated, service_role, postgres;

-- Add comment
COMMENT ON FUNCTION delete_auth_user IS 
  'Deletes a user from auth.users schema. Returns JSON with success status and details. Must be called with service role permissions.';

-- Test the function (optional - comment out if you want)
-- SELECT delete_auth_user('00000000-0000-0000-0000-000000000000'::uuid);

-- Verify the function was created
SELECT 
  proname as function_name,
  pg_get_functiondef(oid) as definition
FROM pg_proc
WHERE proname = 'delete_auth_user';

SELECT 'Function delete_auth_user() created successfully!' as status;

