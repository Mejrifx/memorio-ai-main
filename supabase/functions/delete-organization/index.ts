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

    // Step 2: Delete all data in correct dependency order
    console.log('Step 2: Deleting all dependent data in correct order...');
    
    // Get list of user IDs for this org (for events deletion)
    const userIds = orgUsers?.map(u => u.id) || [];
    
    // 2a. Delete events first (they reference users via actor_user_id)
    if (userIds.length > 0) {
      const { error: deleteEventsError } = await supabaseAdmin
        .from('events')
        .delete()
        .in('actor_user_id', userIds);

      if (deleteEventsError) {
        console.error(`❌ Failed to delete events: ${deleteEventsError.message}`);
        throw new Error(`Failed to delete events: ${deleteEventsError.message}`);
      }
      console.log(`✅ Deleted events for organization users`);
    }
    
    // 2b. Delete cases (they reference users via created_by, assigned_family_user_id, etc.)
    const { error: deleteCasesError } = await supabaseAdmin
      .from('cases')
      .delete()
      .eq('org_id', orgId);

    if (deleteCasesError) {
      console.error(`❌ Failed to delete cases: ${deleteCasesError.message}`);
      throw new Error(`Failed to delete cases: ${deleteCasesError.message}`);
    }
    console.log(`✅ Deleted cases for organization`);

    // 2c. Now delete from public.users (after all references are removed)
    console.log('Step 2c: Deleting from public.users...');
    const { error: deletePublicUsersError } = await supabaseAdmin
      .from('users')
      .delete()
      .eq('org_id', orgId);

    if (deletePublicUsersError) {
      console.error(`❌ Failed to delete public.users records: ${deletePublicUsersError.message}`);
      throw new Error(`Failed to delete public.users: ${deletePublicUsersError.message}`);
    }
    
    console.log(`✅ Deleted ${orgUsers?.length || 0} record(s) from public.users`);

    // Step 3: NOW delete from auth.users (after public.users is clear)
    console.log('Step 3: Now deleting from auth.users...');
    const deletionResults = [];
    if (orgUsers && orgUsers.length > 0) {
      for (const orgUser of orgUsers) {
        try {
          console.log(`Deleting auth user: ${orgUser.email} (${orgUser.role}) with ID: ${orgUser.id}`);
          
          // First, verify the user exists in auth.users
          const { data: authUserData, error: getUserError } = await supabaseAdmin.auth.admin.getUserById(orgUser.id);
          
          if (getUserError || !authUserData?.user) {
            console.warn(`User ${orgUser.email} not found in auth.users, skipping auth deletion`);
            deletionResults.push({
              id: orgUser.id,
              email: orgUser.email,
              success: false,
              error: 'User not found in auth.users (already deleted or never created)',
            });
            continue;
          }
          
          console.log(`Found auth user ${authUserData.user.email}, proceeding with deletion...`);
          
          // Delete from auth.users using direct SQL (more reliable than Admin API)
          // The service role has full permissions to execute this
          const { data: sqlDeleteData, error: sqlDeleteError } = await supabaseAdmin.rpc('delete_auth_user', {
            user_id: orgUser.id
          });

          console.log(`RPC delete_auth_user response for ${orgUser.email}:`, { data: sqlDeleteData, error: sqlDeleteError });

          if (sqlDeleteError) {
            console.error(`❌ RPC call failed for ${orgUser.email}:`, {
              message: sqlDeleteError.message,
              code: sqlDeleteError.code,
              details: sqlDeleteError.details,
              hint: sqlDeleteError.hint
            });
            
            deletionResults.push({
              id: orgUser.id,
              email: orgUser.email,
              success: false,
              error: `RPC error: ${sqlDeleteError.message}`,
            });
          } else if (sqlDeleteData && sqlDeleteData.success && sqlDeleteData.deleted) {
            // RPC succeeded and user was deleted
            console.log(`✅ Successfully deleted auth user via RPC: ${orgUser.email}`);
            deletionResults.push({
              id: orgUser.id,
              email: orgUser.email,
              success: true,
            });
          } else if (sqlDeleteData && !sqlDeleteData.deleted) {
            // RPC succeeded but user wasn't found (already deleted)
            console.log(`⚠️ User ${orgUser.email} not found in auth.users (already deleted)`);
            deletionResults.push({
              id: orgUser.id,
              email: orgUser.email,
              success: true,
              note: 'User not found (already deleted)',
            });
          } else if (sqlDeleteData && !sqlDeleteData.success) {
            // RPC returned error
            console.error(`❌ RPC function returned error for ${orgUser.email}:`, sqlDeleteData.error);
            deletionResults.push({
              id: orgUser.id,
              email: orgUser.email,
              success: false,
              error: `SQL error: ${sqlDeleteData.error || 'Unknown SQL error'}`,
            });
          } else {
            // Unexpected response
            console.error(`❌ Unexpected RPC response for ${orgUser.email}:`, sqlDeleteData);
            deletionResults.push({
              id: orgUser.id,
              email: orgUser.email,
              success: false,
              error: 'Unexpected RPC response format',
            });
          }
        } catch (e) {
          console.error(`Exception deleting user ${orgUser.email}:`, e);
          deletionResults.push({
            id: orgUser.id,
            email: orgUser.email,
            success: false,
            error: e instanceof Error ? e.message : 'Unknown exception',
          });
        }
      }
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

