#!/usr/bin/env node

// Fix all director and family accounts by updating app_metadata
// This script connects to Supabase and runs the SQL migration

const https = require('https');

const SUPABASE_URL = 'https://gkabtvqwwuvigcdubwyv.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdrYWJ0dnF3d3V2aWdjZHVid3l2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTkwMTkyNSwiZXhwIjoyMDc1NDc3OTI1fQ.rp5WHQrcLIExJpJJSYbVnwUvfM7vBp_ElBdhJwR9rEQ';

async function fixAccounts() {
  console.log('🔧 Starting account metadata fix...\n');
  
  // SQL to fix all accounts
  const sql = `
-- Update all directors
UPDATE auth.users
SET raw_app_meta_data = jsonb_build_object(
  'role', 'director',
  'org_id', (
    SELECT org_id::text 
    FROM public.users 
    WHERE id = auth.users.id
  )
)
WHERE id IN (
  SELECT id 
  FROM public.users 
  WHERE role = 'director'
    AND org_id IS NOT NULL
);

-- Update all family members
UPDATE auth.users
SET raw_app_meta_data = jsonb_build_object(
  'role', 'family',
  'org_id', (
    SELECT org_id::text 
    FROM public.users 
    WHERE id = auth.users.id
  )
)
WHERE id IN (
  SELECT id 
  FROM public.users 
  WHERE role = 'family'
    AND org_id IS NOT NULL
);

-- Update all admins
UPDATE auth.users
SET raw_app_meta_data = jsonb_build_object(
  'role', 'admin'
)
WHERE id IN (
  SELECT id 
  FROM public.users 
  WHERE role = 'admin'
);

-- Return counts
SELECT 
  'directors' as role,
  COUNT(*) as fixed_count
FROM public.users
WHERE role = 'director'
UNION ALL
SELECT 
  'family' as role,
  COUNT(*) as fixed_count
FROM public.users
WHERE role = 'family'
UNION ALL
SELECT 
  'admin' as role,
  COUNT(*) as fixed_count
FROM public.users
WHERE role = 'admin';
`;

  const postData = JSON.stringify({ query: sql });

  const options = {
    hostname: 'gkabtvqwwuvigcdubwyv.supabase.co',
    port: 443,
    path: '/rest/v1/rpc/exec_sql',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SERVICE_ROLE_KEY,
      'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
      'Prefer': 'params=single-object'
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        if (res.statusCode === 200 || res.statusCode === 201) {
          console.log('✅ Successfully fixed all accounts!\n');
          console.log('Response:', data);
          resolve(data);
        } else {
          console.error('❌ Error:', res.statusCode, data);
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    
    req.on('error', (error) => {
      console.error('❌ Request error:', error);
      reject(error);
    });
    
    req.write(postData);
    req.end();
  });
}

// Run the fix
fixAccounts()
  .then(() => {
    console.log('\n🎉 All accounts have been fixed!');
    console.log('\n📋 Next steps:');
    console.log('1. Log out from all portals');
    console.log('2. Log back in');
    console.log('3. Your cases should now appear!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Failed to fix accounts:', error.message);
    console.log('\n📋 Please run the SQL migration manually in Supabase Dashboard');
    process.exit(1);
  });

