#!/usr/bin/env node

/**
 * Create Sample Case Script
 * 
 * Creates a sample case for testing after accounts are already created
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const TEST_ORG_ID = '00000000-0000-0000-0000-000000000001';

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('❌ Missing environment variables');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function createSampleCase() {
  console.log('📁 Creating sample case...');

  try {
    // Get the actual director user ID from the users table
    const { data: directorUser } = await supabase
      .from('users')
      .select('id')
      .eq('email', 'director@testfuneralhome.com')
      .single();

    const { data: familyUser } = await supabase
      .from('users')
      .select('id')
      .eq('email', 'family@example.com')
      .single();

    if (!directorUser || !familyUser) {
      console.log('❌ Could not find director or family user');
      return;
    }

    const { data, error } = await supabase
      .from('cases')
      .insert({
        id: 'c0000000-0000-0000-0000-000000000001',
        org_id: TEST_ORG_ID,
        deceased_name: 'John Doe',
        created_by: directorUser.id,
        assigned_family_user_id: familyUser.id,
        status: 'waiting_on_family',
        metadata: {
          service_date: '2025-10-15',
          service_location: 'Test Memorial Chapel'
        }
      })
      .select();

    if (error) {
      if (error.message.includes('duplicate key')) {
        console.log('✅ Sample case already exists');
        return;
      }
      throw error;
    }

    console.log('✅ Sample case created successfully');
  } catch (error) {
    console.error('❌ Error creating sample case:', error.message);
  }
}

createSampleCase();
