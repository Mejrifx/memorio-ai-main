#!/usr/bin/env node

/**
 * Test Login Script
 * 
 * Tests the login process and displays JWT token contents
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error('❌ Missing environment variables');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function testLogin() {
  console.log('🔐 Testing Login\n');
  console.log('=================================\n');

  try {
    // Try to sign in as admin
    const { data, error } = await supabase.auth.signInWithPassword({
      email: 'admin@memorio.test',
      password: 'TestAdmin123!'
    });

    if (error) {
      console.error('❌ Login failed:', error.message);
      console.error('Error details:', JSON.stringify(error, null, 2));
      return;
    }

    console.log('✅ Login successful!\n');
    console.log('User ID:', data.user.id);
    console.log('Email:', data.user.email);
    console.log('\n📋 User Metadata:', JSON.stringify(data.user.user_metadata, null, 2));
    console.log('\n📋 App Metadata:', JSON.stringify(data.user.app_metadata, null, 2));
    
    // Decode JWT to see what's inside
    const jwt = data.session.access_token;
    const parts = jwt.split('.');
    const payload = JSON.parse(Buffer.from(parts[1], 'base64').toString());
    
    console.log('\n🔑 JWT Claims:', JSON.stringify(payload, null, 2));
    
    // Check if role is in JWT
    if (payload.role) {
      console.log('\n✅ Role found in JWT:', payload.role);
    } else if (payload.app_metadata?.role) {
      console.log('\n✅ Role found in app_metadata:', payload.app_metadata.role);
    } else {
      console.log('\n❌ Role NOT found in JWT!');
      console.log('This is the problem - RLS policies need role in JWT claims');
    }

    // Try to read from users table
    console.log('\n🔍 Testing database access...');
    const { data: userData, error: dbError } = await supabase
      .from('users')
      .select('*')
      .eq('id', data.user.id)
      .single();

    if (dbError) {
      console.log('❌ Database query failed:', dbError.message);
    } else {
      console.log('✅ Database query successful');
      console.log('User role in database:', userData.role);
    }

  } catch (error) {
    console.error('❌ Unexpected error:', error.message);
  }
}

testLogin();

