import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface DeleteUserRequest {
  user_id: string;
  reason?: string;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Get auth header and extract JWT token
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Missing authorization header');
    }

    // Extract JWT token (format: "Bearer TOKEN")
    const jwt = authHeader.replace('Bearer ', '');

    // Create Supabase client with service role for admin operations
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

    // Verify the caller is authenticated using service role
    const { data: { user: caller }, error: authError } = await supabaseAdmin.auth.getUser(jwt);
    if (authError || !caller) {
      console.error('Auth error:', authError);
      throw new Error('Unauthorized: ' + (authError?.message || 'Invalid token'));
    }

    // Verify the caller is an admin
    const callerRole = caller.app_metadata?.role;
    console.log('Caller role:', callerRole, 'User:', caller.email);
    
    if (callerRole !== 'admin') {
      throw new Error('Only admins can delete users');
    }

    // Parse request body
    const requestData: DeleteUserRequest = await req.json();
    const { user_id, reason } = requestData;

    if (!user_id) {
      throw new Error('user_id is required');
    }

    // Get user info before deletion (for logging)
    const { data: userData, error: userFetchError } = await supabaseAdmin
      .from('users')
      .select('email, role, org_id')
      .eq('id', user_id)
      .single();

    if (userFetchError) {
      throw new Error(`User not found: ${userFetchError.message}`);
    }

    // Don't allow deleting admin users (safety measure)
    if (userData.role === 'admin') {
      throw new Error('Cannot delete admin users');
    }

    // Log the deletion event BEFORE deleting (so we still have the user_id reference)
    const { error: eventError } = await supabaseAdmin
      .from('events')
      .insert({
        actor_user_id: caller.id,
        actor_role: 'admin',
        action_type: 'user_deleted',
        target_type: 'user',
        target_id: user_id,
        payload: {
          deleted_user_email: userData.email,
          deleted_user_role: userData.role,
          deleted_user_org_id: userData.org_id,
          reason: reason || 'No reason provided',
        },
      });

    if (eventError) {
      console.error('Failed to log deletion event:', eventError);
      // Continue with deletion even if logging fails
    }

    // Delete the user from Supabase Auth (this will CASCADE to public.users due to FK)
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(user_id);

    if (deleteError) {
      console.error('Delete error details:', JSON.stringify(deleteError, null, 2));
      throw new Error(`Failed to delete user: ${deleteError.message || JSON.stringify(deleteError)}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `User ${userData.email} (${userData.role}) deleted successfully`,
        deleted_user: {
          id: user_id,
          email: userData.email,
          role: userData.role,
        },
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    console.error('Error in delete-user function:', error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : 'Unknown error occurred',
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
});

