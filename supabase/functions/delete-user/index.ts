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

    // Verify the caller is an admin or director
    const callerRole = caller.app_metadata?.role;
    const callerOrgId = caller.app_metadata?.org_id;
    console.log('Caller role:', callerRole, 'User:', caller.email, 'Org:', callerOrgId);
    
    if (callerRole !== 'admin' && callerRole !== 'director') {
      throw new Error('Only admins and directors can delete users');
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

    // Directors can only delete family users in their own organization
    if (callerRole === 'director') {
      if (userData.role !== 'family') {
        throw new Error('Directors can only delete family users');
      }
      if (userData.org_id !== callerOrgId) {
        throw new Error('Directors can only delete family users in their own organization');
      }
    }

    // Log the deletion event BEFORE deleting (so we still have the user_id reference)
    const { error: eventError } = await supabaseAdmin
      .from('events')
      .insert({
        actor_user_id: caller.id,
        actor_role: callerRole,
        action_type: 'user_deleted',
        target_type: 'user',
        target_id: user_id,
        payload: {
          deleted_user_email: userData.email,
          deleted_user_role: userData.role,
          deleted_user_org_id: userData.org_id,
          reason: reason || 'No reason provided',
          deleted_by: caller.email
        },
      });

    if (eventError) {
      console.error('Failed to log deletion event:', eventError);
      // Continue with deletion even if logging fails
    }

    // STEP 1: Delete from public.users first (triggers FK cascades/set nulls we configured)
    console.log('Deleting from public.users table...');
    const { error: publicDeleteError } = await supabaseAdmin
      .from('users')
      .delete()
      .eq('id', user_id);

    if (publicDeleteError) {
      console.error('Public delete error:', JSON.stringify(publicDeleteError, null, 2));
      throw new Error(`Failed to delete from public.users: ${publicDeleteError.message || JSON.stringify(publicDeleteError)}`);
    }

    console.log('Successfully deleted from public.users');

    // STEP 2: Delete from auth.users (clean up authentication)
    console.log('Deleting from auth.users...');
    const { error: authDeleteError } = await supabaseAdmin.auth.admin.deleteUser(user_id);

    if (authDeleteError) {
      console.error('Auth delete error:', JSON.stringify(authDeleteError, null, 2));
      // This might fail if CASCADE already deleted, which is okay
      console.log('Auth delete failed (might be already deleted by CASCADE), continuing...');
    } else {
      console.log('Successfully deleted from auth.users');
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

