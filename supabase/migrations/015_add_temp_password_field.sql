-- Add temporary password field to users table
-- This stores the password generated during invitation for admin reference

ALTER TABLE users 
ADD COLUMN temp_password TEXT;

-- Add comment explaining the field
COMMENT ON COLUMN users.temp_password IS 'Temporary password generated during invitation. Used for admin reference and can be cleared after first login.';

-- Update existing users to have NULL temp_password (they were created before this field)
UPDATE users SET temp_password = NULL WHERE temp_password IS NULL;
