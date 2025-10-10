#!/usr/bin/env node

/**
 * Memorio Test Account Creation Script
 * 
 * Creates test users via Supabase Auth API and inserts metadata into users table
 * Run: node scripts/create-test-accounts.js
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Configuration
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const TEST_ORG_ID = '00000000-0000-0000-0000-000000000001';

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('❌ Missing required environment variables:');
  console.error('   - SUPABASE_URL');
  console.error('   - SUPABASE_SERVICE_ROLE_KEY');
  console.error('\nPlease create a .env file based on .env.example');
  process.exit(1);
}

// Initialize Supabase client with service role (bypasses RLS)
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// Test accounts to create
const testAccounts = [
  {
    id: '10000000-0000-0000-0000-000000000001',
    email: 'admin@memorio.test',
    password: 'TestAdmin123!',
    role: 'admin',
    org_id: null, // Admins are global
    metadata: {
      name: 'Test Admin',
      phone: '+1-555-0001'
    }
  },
  {
    id: '20000000-0000-0000-0000-000000000001',
    email: 'director@testfuneralhome.com',
    password: 'TestDirector123!',
    role: 'director',
    org_id: TEST_ORG_ID,
    metadata: {
      name: 'John Director',
      phone: '+1-555-0002',
      title: 'Funeral Director'
    }
  },
  {
    id: '30000000-0000-0000-0000-000000000001',
    email: 'family@example.com',
    password: 'TestFamily123!',
    role: 'family',
    org_id: TEST_ORG_ID,
    metadata: {
      name: 'Jane Family',
      phone: '+1-555-0003'
    }
  },
  {
    id: '40000000-0000-0000-0000-000000000001',
    email: 'editor@memorio.test',
    password: 'TestEditor123!',
    role: 'editor',
    org_id: null, // Editors can be assigned across orgs
    metadata: {
      name: 'Emily Editor',
      phone: '+1-555-0004',
      specialization: 'Obituary Writing'
    }
  },
  {
    id: '50000000-0000-0000-0000-000000000001',
    email: 'support@memorio.test',
    password: 'TestSupport123!',
    role: 'support',
    org_id: null,
    metadata: {
      name: 'Support Agent',
      phone: '+1-555-0005'
    }
  }
];

async function createTestAccount(account) {
  console.log(`\n📧 Creating ${account.role}: ${account.email}`);

  try {
    // Create auth user
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: account.email,
      password: account.password,
      email_confirm: true, // Auto-confirm for testing
      user_metadata: {
        role: account.role,
        name: account.metadata.name
      }
    });

    if (authError) {
      // Check if user already exists
      if (authError.message.includes('already registered')) {
        console.log(`   ⚠️  User already exists, skipping auth creation`);
        
        // Get existing user ID
        const { data: existingUsers } = await supabase.auth.admin.listUsers();
        const existingUser = existingUsers?.users?.find(u => u.email === account.email);
        
        if (!existingUser) {
          throw new Error('User exists but could not retrieve ID');
        }
        
        // Update metadata record
        await updateUserMetadata(existingUser.id, account);
        return;
      }
      throw authError;
    }

    console.log(`   ✅ Auth user created: ${authData.user.id}`);

    // Insert into users table (metadata)
    await updateUserMetadata(authData.user.id, account);

  } catch (error) {
    console.error(`   ❌ Error creating ${account.email}:`, error.message);
    throw error;
  }
}

async function updateUserMetadata(userId, account) {
  const { data, error } = await supabase
    .from('users')
    .upsert({
      id: userId,
      email: account.email,
      role: account.role,
      org_id: account.org_id,
      status: 'active',
      metadata: account.metadata
    }, {
      onConflict: 'id'
    });

  if (error) {
    console.error(`   ❌ Error inserting user metadata:`, error.message);
    throw error;
  }

  console.log(`   ✅ User metadata saved`);
}

async function createSampleCase() {
  console.log('\n📁 Creating sample case...');

  try {
    const { data, error } = await supabase
      .from('cases')
      .insert({
        id: 'c0000000-0000-0000-0000-000000000001',
        org_id: TEST_ORG_ID,
        deceased_name: 'John Doe',
        created_by: '20000000-0000-0000-0000-000000000001', // Director
        assigned_family_user_id: '30000000-0000-0000-0000-000000000001', // Family
        status: 'waiting_on_family',
        metadata: {
          service_date: '2025-10-15',
          service_location: 'Test Memorial Chapel'
        }
      })
      .select();

    if (error) {
      if (error.message.includes('duplicate key')) {
        console.log('   ⚠️  Sample case already exists, skipping');
        return;
      }
      throw error;
    }

    console.log('   ✅ Sample case created');
  } catch (error) {
    console.error('   ❌ Error creating sample case:', error.message);
  }
}

async function main() {
  console.log('🚀 Memorio Test Account Creation');
  console.log('=================================\n');
  console.log(`Supabase URL: ${SUPABASE_URL}`);
  console.log(`Test Org ID: ${TEST_ORG_ID}`);

  try {
    // Create all test accounts
    for (const account of testAccounts) {
      await createTestAccount(account);
    }

    // Create sample case
    await createSampleCase();

    console.log('\n✨ Test account creation complete!\n');
    console.log('Test Credentials:');
    console.log('─────────────────');
    testAccounts.forEach(account => {
      console.log(`${account.role.toUpperCase().padEnd(10)} ${account.email.padEnd(35)} ${account.password}`);
    });
    console.log('\n⚠️  Remember to change these passwords in production!\n');

  } catch (error) {
    console.error('\n❌ Fatal error:', error.message);
    process.exit(1);
  }
}

main();

