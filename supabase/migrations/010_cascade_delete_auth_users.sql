-- Cascade Delete Auth Users When Organization is Deleted
-- Version: 1.0.0
-- Description: Automatically delete Supabase Auth users when their organization is deleted

-- ============================================================================
-- FUNCTION: Delete Auth Users for Organization
-- ============================================================================

CREATE OR REPLACE FUNCTION delete_org_auth_users()
RETURNS TRIGGER AS $$
DECLARE
  user_record RECORD;
BEGIN
  -- Log the organization deletion event
  RAISE NOTICE 'Organization deleted: % - Cleaning up auth users', OLD.name;
  
  -- Loop through all users belonging to this organization
  FOR user_record IN 
    SELECT id, email, role 
    FROM users 
    WHERE org_id = OLD.id
  LOOP
    BEGIN
      -- Delete the auth user (this will cascade delete the users table record)
      -- We need to use the service role to delete auth users
      RAISE NOTICE 'Deleting auth user: % (role: %)', user_record.email, user_record.role;
      
      -- Note: This requires the function to be executed with sufficient privileges
      -- The auth.users table will cascade delete to public.users
      DELETE FROM auth.users WHERE id = user_record.id;
      
      -- Log the deletion
      INSERT INTO events (
        actor_user_id, 
        actor_role, 
        action_type, 
        target_type, 
        target_id,
        payload
      ) VALUES (
        auth.uid(),
        COALESCE(auth.jwt() -> 'app_metadata' ->> 'role', 'system'),
        'CASCADE_DELETE_USER',
        'users',
        user_record.id,
        jsonb_build_object(
          'email', user_record.email,
          'role', user_record.role,
          'reason', 'organization_deleted',
          'org_id', OLD.id,
          'org_name', OLD.name
        )
      );
      
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Failed to delete auth user %: %', user_record.email, SQLERRM;
    END;
  END LOOP;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TRIGGER: Delete Auth Users Before Organization Deletion
-- ============================================================================

-- Drop trigger if it exists
DROP TRIGGER IF EXISTS delete_org_auth_users_trigger ON organizations;

-- Create trigger that fires BEFORE the organization is deleted
-- This ensures users are deleted before the organization record is removed
CREATE TRIGGER delete_org_auth_users_trigger
  BEFORE DELETE ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION delete_org_auth_users();

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Grant necessary permissions for the function to work
GRANT USAGE ON SCHEMA auth TO postgres;
GRANT DELETE ON auth.users TO postgres;

COMMENT ON FUNCTION delete_org_auth_users() IS 
  'Automatically deletes all Supabase Auth users when their organization is deleted. This ensures complete cleanup of user accounts, preventing orphaned auth records and authentication issues.';

COMMENT ON TRIGGER delete_org_auth_users_trigger ON organizations IS
  'Triggers cascade deletion of Auth users before organization deletion';

