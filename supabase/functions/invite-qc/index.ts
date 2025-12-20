// Invite QC (Quality Control) Edge Function
// Allows Admins to invite GLOBAL QC users (not org-scoped)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createSupabaseClient, verifyAuth, generatePassword } from '../_shared/supabase-client.ts';
import type { ApiResponse, InviteQCRequest } from '../_shared/types.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Verify authentication
    const authHeader = req.headers.get('Authorization');
    const { user, error: authError } = await verifyAuth(authHeader);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Check if user is admin
    const supabase = createSupabaseClient();
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single();

    if (userError || userData?.role !== 'admin') {
      return new Response(
        JSON.stringify({ success: false, error: 'Only admins can invite QC users' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Parse request body
    const body: InviteQCRequest = await req.json();
    const { email, name, phone } = body;

    // Validate required fields (org_id removed - QC is global)
    if (!email || !name) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required fields: email, name' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Generate temporary password
    const tempPassword = generatePassword();

    // Create Supabase Auth user
    const { data: authData, error: createAuthError } = await supabase.auth.admin.createUser({
      email,
      password: tempPassword,
      email_confirm: true,
      app_metadata: {
        role: 'qc'
        // No org_id - QC is global
      },
      user_metadata: {
        name,
        phone
      }
    });

    if (createAuthError) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: `Failed to create auth user: ${createAuthError.message}` 
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Insert user metadata into users table
    const { error: insertError } = await supabase
      .from('users')
      .insert({
        id: authData.user.id,
        email,
        role: 'qc',
        org_id: null, // QC users are global, not org-scoped
        status: 'invited',
        temp_password: tempPassword,
        metadata: { name, phone }
      });

    if (insertError) {
      // Rollback: delete auth user
      await supabase.auth.admin.deleteUser(authData.user.id);
      
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: `Failed to create user metadata: ${insertError.message}` 
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Log audit event
    await supabase
      .from('events')
      .insert({
        actor_user_id: user.id,
        actor_role: 'admin',
        action_type: 'INVITE_QC',
        target_type: 'users',
        target_id: authData.user.id,
        payload: {
          email,
          name,
          note: 'QC user invited - global access to all organizations'
        }
      });

    // Note: Email integration will be added later
    // For now, credentials are returned in the response for the Admin to share manually
    console.log(`Global QC user invited: ${email} / ${tempPassword}`);

    const response: ApiResponse = {
      success: true,
      data: {
        user_id: authData.user.id,
        temp_password: tempPassword,
        email
      },
      message: `QC user invitation sent to ${email} (Global Access)`
    };

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error in invite-qc:', error);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error instanceof Error ? error.message : 'Internal server error' 
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

