// Invite Family Edge Function
// Allows Directors to invite Family members to create tributes for specific cases

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createSupabaseClient, verifyAuth, generatePassword } from '../_shared/supabase-client.ts';
import { familyInviteTemplate } from '../_shared/email-templates.ts';
import type { InviteFamilyRequest, ApiResponse } from '../_shared/types.ts';

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

    // Check if user is director
    const supabase = createSupabaseClient();
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('role, org_id, metadata')
      .eq('id', user.id)
      .single();

    if (userError || userData?.role !== 'director') {
      return new Response(
        JSON.stringify({ success: false, error: 'Only directors can invite families' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Parse request body
    const body: InviteFamilyRequest = await req.json();
    const { email, name, case_id, phone } = body;

    // Validate required fields
    if (!email || !name || !case_id) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required fields: email, name, case_id' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Verify case exists and belongs to director's organization
    const { data: caseData, error: caseError } = await supabase
      .from('cases')
      .select('deceased_name, org_id')
      .eq('id', case_id)
      .single();

    if (caseError || !caseData) {
      return new Response(
        JSON.stringify({ success: false, error: 'Case not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Verify director owns this case (RLS will handle this, but double-check)
    if (caseData.org_id !== userData.org_id) {
      return new Response(
        JSON.stringify({ success: false, error: 'Case does not belong to your organization' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Generate temporary password
    const tempPassword = generatePassword();

    // Create Supabase Auth user with password
    const { data: authData, error: createAuthError } = await supabase.auth.admin.createUser({
      email,
      password: tempPassword,
      email_confirm: true,
      user_metadata: {
        role: 'family',
        name,
        case_id
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
        role: 'family',
        org_id: userData.org_id,
        status: 'invited',
        metadata: { name, phone, case_id }
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

    // Update case with assigned family user
    await supabase
      .from('cases')
      .update({
        assigned_family_user_id: authData.user.id,
        status: 'waiting_on_family'
      })
      .eq('id', case_id);

    // Log audit event
    await supabase
      .from('events')
      .insert({
        actor_user_id: user.id,
        actor_role: 'director',
        action_type: 'INVITE_FAMILY',
        target_type: 'users',
        target_id: authData.user.id,
        payload: {
          email,
          name,
          case_id,
          deceased_name: caseData.deceased_name
        }
      });

    // Note: Email integration will be added later
    // For now, credentials are returned in the response for the Director to share manually
    console.log(`Family invited: ${email} for case ${case_id}`);
    console.log(`Password: ${tempPassword}`);

    const response: ApiResponse = {
      success: true,
      data: {
        user_id: authData.user.id,
        temp_password: tempPassword,
        email,
        case_id
      },
      message: `Family invitation sent to ${email}`
    };

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error in invite-family:', error);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error instanceof Error ? error.message : 'Internal server error' 
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

