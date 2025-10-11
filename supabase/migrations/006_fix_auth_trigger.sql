-- Fix Auth Login Trigger
-- Version: 1.0.0
-- Description: Fixes the "database error granting user" issue during login

-- The issue: The update_last_login trigger tries to update users table during login,
-- but RLS policies block it because JWT doesn't have role yet during auth process.

-- Solution: Drop the problematic trigger temporarily
-- We can re-add it later with a better implementation or update via API after login

-- Drop the existing trigger
DROP TRIGGER IF EXISTS update_last_login_on_auth ON auth.users;

-- Drop the function if it exists
DROP FUNCTION IF EXISTS handle_auth_user_login();

-- Alternative solution: Update the function to use SECURITY DEFINER properly
-- and ensure it bypasses RLS during the auth process

CREATE OR REPLACE FUNCTION handle_auth_user_login()
RETURNS TRIGGER AS $$
BEGIN
  -- Use SECURITY DEFINER to bypass RLS during login
  -- This is safe because it only updates the user's own last_login_at
  UPDATE public.users
  SET last_login_at = NOW()
  WHERE id = NEW.id;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- If update fails, don't break the login process
    -- Just log the error and continue
    RAISE WARNING 'Failed to update last_login_at for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger with error handling
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE schemaname = 'auth' AND tablename = 'users'
  ) THEN
    CREATE TRIGGER update_last_login_on_auth
      AFTER UPDATE ON auth.users
      FOR EACH ROW
      WHEN (OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at)
      EXECUTE FUNCTION handle_auth_user_login();
  END IF;
END $$;

COMMENT ON FUNCTION handle_auth_user_login IS 'Updates last_login_at with error handling to prevent login failures';

