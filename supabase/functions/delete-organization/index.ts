import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

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
    // Get the authorization header
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Missing authorization header');
    }

    // Create Supabase client with service role key (has full admin access)
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

    // Extract JWT token from Authorization header
    const token = authHeader.replace('Bearer ', '');
    
    // Verify the JWT and get user from service role client
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token);
    if (userError || !user) {
      console.error('User verification error:', userError);
      throw new Error('Unauthorized: Invalid user token');
    }

    console.log(`User verified: ${user.email} (${user.id})`);

    // Check user role from public.users table
    const { data: userData, error: roleError } = await supabaseAdmin
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single();

    if (roleError) {
      console.error('Role check error:', roleError);
      throw new Error('Unauthorized: Could not verify user role');
    }

    if (!userData || userData.role !== 'admin') {
      console.error(`User ${user.email} has role: ${userData?.role}, not admin`);
      throw new Error('Unauthorized: Only admins can delete organizations');
    }

    console.log(`Admin verified: ${user.email} (role: ${userData.role})`);

    // Get organization ID from request
    const { orgId } = await req.json();
    if (!orgId) {
      throw new Error('Missing orgId parameter');
    }

    console.log(`Admin ${user.email} is deleting organization ${orgId}`);

    // Step 1: Get all users in this organization
    const { data: orgUsers, error: usersError } = await supabaseAdmin
      .from('users')
      .select('id, email, role')
      .eq('org_id', orgId);

    if (usersError) {
      throw new Error(`Failed to fetch users: ${usersError.message}`);
    }

    console.log(`Found ${orgUsers?.length || 0} user(s) to delete`);

    // Step 2: Delete all auth.users for this organization
    const deletionResults = [];
    if (orgUsers && orgUsers.length > 0) {
      for (const orgUser of orgUsers) {
        try {
          console.log(`Deleting auth user: ${orgUser.email} (${orgUser.role})`);
          
          // Delete from auth.users using admin API
          const { error: deleteAuthError } = await supabaseAdmin.auth.admin.deleteUser(
            orgUser.id
          );

          if (deleteAuthError) {
            console.error(`Failed to delete auth user ${orgUser.email}:`, deleteAuthError);
            deletionResults.push({
              id: orgUser.id,
              email: orgUser.email,
              success: false,
              error: deleteAuthError.message,
            });
          } else {
            console.log(`✅ Successfully deleted auth user: ${orgUser.email}`);
            deletionResults.push({
              id: orgUser.id,
              email: orgUser.email,
              success: true,
            });
          }
        } catch (e) {
          console.error(`Exception deleting user ${orgUser.email}:`, e);
          deletionResults.push({
            id: orgUser.id,
            email: orgUser.email,
            success: false,
            error: e.message,
          });
        }
      }
    }

    // Step 3: Delete from public.users table (if any remain)
    const { error: deletePublicUsersError } = await supabaseAdmin
      .from('users')
      .delete()
      .eq('org_id', orgId);

    if (deletePublicUsersError) {
      console.warn(`Warning: Could not delete public.users records: ${deletePublicUsersError.message}`);
    }

    // Step 4: Get organization details for logging
    const { data: orgData } = await supabaseAdmin
      .from('organizations')
      .select('name')
      .eq('id', orgId)
      .single();

    // Step 5: Delete the organization (this will cascade to cases, forms, assets, etc.)
    const { error: deleteOrgError } = await supabaseAdmin
      .from('organizations')
      .delete()
      .eq('id', orgId);

    if (deleteOrgError) {
      throw new Error(`Failed to delete organization: ${deleteOrgError.message}`);
    }

    console.log(`✅ Organization ${orgId} deleted successfully`);

    // Step 6: Log the deletion event
    try {
      await supabaseAdmin.from('events').insert({
        actor_user_id: user.id,
        actor_role: 'admin',
        action_type: 'DELETE_ORGANIZATION',
        target_type: 'organizations',
        target_id: orgId,
        payload: {
          org_name: orgData?.name,
          deleted_users_count: orgUsers?.length || 0,
          deleted_users: deletionResults,
          timestamp: new Date().toISOString(),
        },
      });
    } catch (e) {
      console.warn('Could not log audit event:', e);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Organization deleted successfully`,
        org_id: orgId,
        org_name: orgData?.name,
        deleted_users_count: orgUsers?.length || 0,
        deletion_results: deletionResults,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );

  } catch (error) {
    console.error('Error in delete-organization function:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
});

