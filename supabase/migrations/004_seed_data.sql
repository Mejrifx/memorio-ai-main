-- Memorio Seed Data
-- Version: 1.0.0
-- Description: Test data for development and validation

-- ============================================================================
-- SEED: Test Organization
-- ============================================================================
INSERT INTO organizations (id, name, contact_email, contact_phone, region, branding_metadata)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Test Funeral Home',
  'contact@testfuneralhome.com',
  '+1-555-0123',
  'North America',
  '{
    "logo_url": "",
    "primary_color": "#2C3E50",
    "secondary_color": "#8E44AD",
    "website": "https://testfuneralhome.com"
  }'::jsonb
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- SEED: Test Users (Metadata Only)
-- ============================================================================
-- Note: Actual auth.users records must be created via Supabase Auth API
-- These are placeholder UUIDs for testing RLS policies
-- Use the create-test-accounts.js script to create real auth users

-- Placeholder user IDs for documentation:
-- Admin User:    10000000-0000-0000-0000-000000000001
-- Director User: 20000000-0000-0000-0000-000000000001
-- Family User:   30000000-0000-0000-0000-000000000001
-- Editor User:   40000000-0000-0000-0000-000000000001
-- Support User:  50000000-0000-0000-0000-000000000001

-- These will be inserted by create-test-accounts.js after creating auth users

-- ============================================================================
-- SEED: Sample Case (for testing)
-- ============================================================================
-- Commented out until test users are created via script
-- INSERT INTO cases (id, org_id, deceased_name, created_by, assigned_family_user_id, status)
-- VALUES (
--   'c0000000-0000-0000-0000-000000000001',
--   '00000000-0000-0000-0000-000000000001',
--   'John Doe',
--   '20000000-0000-0000-0000-000000000001', -- Director
--   '30000000-0000-0000-0000-000000000001', -- Family
--   'waiting_on_family'
-- );

-- ============================================================================
-- COMPLETION
-- ============================================================================
COMMENT ON SCHEMA public IS 'Memorio seed data v1.0.0 - Test organization created';
