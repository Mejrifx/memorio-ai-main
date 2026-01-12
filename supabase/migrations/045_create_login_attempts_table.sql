-- ============================================================================
-- Migration 045: Server-Side Rate Limiting Infrastructure
-- ============================================================================
-- Creates table and policies for tracking login attempts and preventing
-- brute force attacks at the database level

-- Create login_attempts table
CREATE TABLE IF NOT EXISTS login_attempts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  attempt_type TEXT NOT NULL CHECK (attempt_type IN ('success', 'failure')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_login_attempts_email ON login_attempts(email);
CREATE INDEX IF NOT EXISTS idx_login_attempts_created_at ON login_attempts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_login_attempts_email_created ON login_attempts(email, created_at DESC);

-- Enable RLS
ALTER TABLE login_attempts ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Only service role can access (for Edge Functions)
-- Users should not be able to read or write directly
CREATE POLICY "Service role full access to login_attempts"
  ON login_attempts FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Function to check if user is rate limited
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_email TEXT,
  p_window_minutes INT DEFAULT 15,
  p_max_attempts INT DEFAULT 5
) RETURNS JSONB AS $$
DECLARE
  v_attempt_count INT;
  v_oldest_attempt TIMESTAMPTZ;
  v_is_locked BOOLEAN;
  v_minutes_remaining INT;
BEGIN
  -- Count failed attempts within the time window
  SELECT COUNT(*), MIN(created_at)
  INTO v_attempt_count, v_oldest_attempt
  FROM login_attempts
  WHERE email = p_email
    AND attempt_type = 'failure'
    AND created_at > NOW() - (p_window_minutes || ' minutes')::INTERVAL;
  
  -- Check if user is locked
  v_is_locked := v_attempt_count >= p_max_attempts;
  
  -- Calculate remaining lockout time
  IF v_is_locked THEN
    v_minutes_remaining := CEIL(
      EXTRACT(EPOCH FROM (
        v_oldest_attempt + (p_window_minutes || ' minutes')::INTERVAL - NOW()
      )) / 60
    );
  ELSE
    v_minutes_remaining := 0;
  END IF;
  
  RETURN jsonb_build_object(
    'is_locked', v_is_locked,
    'attempt_count', v_attempt_count,
    'max_attempts', p_max_attempts,
    'minutes_remaining', GREATEST(v_minutes_remaining, 0),
    'window_minutes', p_window_minutes
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to record login attempt
CREATE OR REPLACE FUNCTION record_login_attempt(
  p_email TEXT,
  p_ip_address TEXT DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL,
  p_attempt_type TEXT DEFAULT 'failure'
) RETURNS UUID AS $$
DECLARE
  v_attempt_id UUID;
BEGIN
  INSERT INTO login_attempts (email, ip_address, user_agent, attempt_type)
  VALUES (p_email, p_ip_address, p_user_agent, p_attempt_type)
  RETURNING id INTO v_attempt_id;
  
  RETURN v_attempt_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to clear login attempts for an email (on successful login)
CREATE OR REPLACE FUNCTION clear_login_attempts(p_email TEXT) RETURNS VOID AS $$
BEGIN
  DELETE FROM login_attempts
  WHERE email = p_email
    AND attempt_type = 'failure';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Auto-cleanup old login attempts (older than 7 days)
CREATE OR REPLACE FUNCTION cleanup_old_login_attempts() RETURNS VOID AS $$
BEGIN
  DELETE FROM login_attempts
  WHERE created_at < NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a scheduled job to run cleanup daily (requires pg_cron extension)
-- This is optional and will only work if pg_cron is enabled
-- If pg_cron is not available, this will fail silently
DO $$
BEGIN
  -- Check if pg_cron extension exists
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    -- Schedule daily cleanup at 3 AM
    PERFORM cron.schedule(
      'cleanup-old-login-attempts',
      '0 3 * * *',
      'SELECT cleanup_old_login_attempts();'
    );
  END IF;
END $$;

-- Grant execute permissions to service role
GRANT EXECUTE ON FUNCTION check_rate_limit(TEXT, INT, INT) TO service_role;
GRANT EXECUTE ON FUNCTION record_login_attempt(TEXT, TEXT, TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION clear_login_attempts(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_old_login_attempts() TO service_role;

-- Add comment for documentation
COMMENT ON TABLE login_attempts IS 'Tracks login attempts for server-side rate limiting. Only accessible by service role via Edge Functions.';
COMMENT ON FUNCTION check_rate_limit(TEXT, INT, INT) IS 'Checks if an email is rate limited. Returns JSON with lock status and remaining time.';
COMMENT ON FUNCTION record_login_attempt(TEXT, TEXT, TEXT, TEXT) IS 'Records a login attempt (success or failure) with optional IP and user agent.';
COMMENT ON FUNCTION clear_login_attempts(TEXT) IS 'Clears all failed login attempts for an email (called on successful login).';
