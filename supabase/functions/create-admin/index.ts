import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );

    const { email, password } = await req.json();

    // Default values
    const adminEmail = email || 'admin@memorio.test';
    const adminPassword = password || 'MemorioAdmin2024!';

    console.log(`Creating admin account: ${adminEmail}`);

    // Step 1: Delete the wrong family user ID if it exists
    const wrongUserId = '2540eb1b-21ec-49f0-955f-488732a92c90';
    
    // Delete events for wrong user
    await supabaseAdmin.from('events').delete().eq('actor_user_id', wrongUserId);
    
    // Delete from public.users
    await supabaseAdmin.from('users').delete().eq('id', wrongUserId);
    
    // Delete from auth.users
    try {
      await supabaseAdmin.auth.admin.deleteUser(wrongUserId);
    } catch (e) {
      console.log('Wrong user already deleted from auth');
    }

    console.log('✅ Cleaned up wrong user ID');

    // Step 2: Check if admin already exists
    const { data: existingUser } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('email', adminEmail)
      .eq('role', 'admin')
      .single();

    if (existingUser) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'Admin already exists',
          admin: {
            id: existingUser.id,
            email: existingUser.email,
            note: 'Use the existing password or reset it via Supabase Dashboard'
          }
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      );
    }

    // Step 3: Create auth user
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: adminEmail,
      password: adminPassword,
      email_confirm: true,
      app_metadata: {
        role: 'admin'
      },
      user_metadata: {
        name: 'Admin User'
      }
    });

    if (authError || !authData?.user) {
      throw new Error(`Failed to create auth user: ${authError?.message}`);
    }

    console.log(`✅ Auth user created: ${authData.user.id}`);

    // Step 4: Create public.users record
    const { error: insertError } = await supabaseAdmin
      .from('users')
      .insert({
        id: authData.user.id,
        email: adminEmail,
        role: 'admin',
        org_id: null,
        status: 'active',
        metadata: { name: 'Admin User' }
      });

    if (insertError) {
      // Rollback: delete auth user
      await supabaseAdmin.auth.admin.deleteUser(authData.user.id);
      throw new Error(`Failed to create user record: ${insertError.message}`);
    }

    console.log('✅ Admin account created successfully');

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Admin account created successfully',
        admin: {
          id: authData.user.id,
          email: adminEmail,
          password: adminPassword,
          note: 'Save these credentials securely!'
        }
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    );

  } catch (error) {
    console.error('Error creating admin:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    );
  }
});

