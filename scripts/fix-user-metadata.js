#!/usr/bin/env node

/**
 * Fix User Metadata Script
 * 
 * Updates existing test users to have app_metadata with role and org_id
 * This is required for JWT claims and RLS policies to work correctly
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('❌ Missing environment variables');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const testAccounts = [
  {
    email: 'admin@memorio.test',
    role: 'admin',
    org_id: null
  },
  {
    email: 'director@testfuneralhome.com',
    role: 'director',
    org_id: '00000000-0000-0000-0000-000000000001'
  },
  {
    email: 'family@example.com',
    role: 'family',
    org_id: '00000000-0000-0000-0000-000000000001'
  },
  {
    email: 'editor@memorio.test',
    role: 'editor',
    org_id: null
  },
  {
    email: 'support@memorio.test',
    role: 'support',
    org_id: null
  }
];

async function fixUserMetadata() {
  console.log('🔧 Fixing User Metadata\n');
  console.log('=================================\n');

  try {
    // Get all users from Supabase Auth
    const { data: { users }, error: listError } = await supabase.auth.admin.listUsers();

    if (listError) {
      throw new Error(`Failed to list users: ${listError.message}`);
    }

    console.log(`Found ${users.length} users in Supabase Auth\n`);

    // Update each test account
    for (const account of testAccounts) {
      const user = users.find(u => u.email === account.email);

      if (!user) {
        console.log(`⚠️  User not found: ${account.email}`);
        continue;
      }

      console.log(`📧 Updating ${account.email}...`);

      // Update user's app_metadata
      const { data, error } = await supabase.auth.admin.updateUserById(
        user.id,
        {
          app_metadata: {
            role: account.role,
            org_id: account.org_id
          }
        }
      );

      if (error) {
        console.log(`   ❌ Error: ${error.message}`);
      } else {
        console.log(`   ✅ Updated app_metadata: role=${account.role}, org_id=${account.org_id || 'null'}`);
      }
    }

    console.log('\n✨ Metadata fix complete!');
    console.log('\nNext steps:');
    console.log('1. Try logging in again');
    console.log('2. Check that JWT contains role and org_id claims');

  } catch (error) {
    console.error('❌ Fatal error:', error.message);
    process.exit(1);
  }
}

fixUserMetadata();

