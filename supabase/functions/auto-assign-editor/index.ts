// Auto-Assign Editor Edge Function
// Automatically assigns an editor to a case when family submits form
// Uses load balancing to assign to editor with fewest active cases

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createSupabaseClient, verifyAuth } from '../_shared/supabase-client.ts';
import type { ApiResponse } from '../_shared/types.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface AutoAssignEditorRequest {
  case_id: string;
}

interface AutoAssignEditorResponse extends ApiResponse {
  assigned: boolean;
  editor_id?: string;
  editor_name?: string;
  message?: string;
}

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

    // Parse request body
    const body: AutoAssignEditorRequest = await req.json();
    const { case_id } = body;

    // Validate required fields
    if (!case_id) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required field: case_id' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createSupabaseClient();

    // Verify the case exists and belongs to the requesting family user
    const { data: caseData, error: caseError } = await supabase
      .from('cases')
      .select('id, deceased_name, assigned_family_user_id, status, org_id')
      .eq('id', case_id)
      .single();

    if (caseError || !caseData) {
      return new Response(
        JSON.stringify({ success: false, error: 'Case not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Verify the case belongs to the requesting family user
    if (caseData.assigned_family_user_id !== user.id) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized: Case does not belong to you' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Check if case already has an active editor assignment
    const { data: existingAssignment } = await supabase
      .from('editor_assignments')
      .select('id, editor_user_id')
      .eq('case_id', case_id)
      .is('unassigned_at', null)
      .single();

    if (existingAssignment) {
      console.log(`Case ${case_id} already has an editor assigned`);
      return new Response(
        JSON.stringify({ 
          success: true, 
          assigned: true, 
          editor_id: existingAssignment.editor_user_id,
          message: 'Case already has an editor assigned'
        } as AutoAssignEditorResponse),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Find the editor with the fewest active cases using load balancing query
    const { data: eligibleEditors, error: editorQueryError } = await supabase.rpc(
      'get_editor_with_least_cases'
    );

    // If RPC doesn't exist, fall back to manual query
    let selectedEditor = null;
    
    if (editorQueryError) {
      console.log('RPC not available, using manual query');
      
      // Manual load balancing query
      const { data: editors, error: manualQueryError } = await supabase
        .from('users')
        .select(`
          id,
          email,
          metadata,
          created_at
        `)
        .eq('role', 'editor')
        .in('status', ['active', 'invited'])
        .order('created_at', { ascending: true });

      if (manualQueryError) {
        throw new Error(`Failed to query editors: ${manualQueryError.message}`);
      }

      if (!editors || editors.length === 0) {
        // No editors available - create admin notification
        await createAdminNotification(supabase, case_id, caseData.deceased_name);
        
        return new Response(
          JSON.stringify({ 
            success: true, 
            assigned: false, 
            message: 'No editors available - admin notified'
          } as AutoAssignEditorResponse),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Count active assignments for each editor
      const editorsWithCounts = await Promise.all(
        editors.map(async (editor) => {
          const { count, error: countError } = await supabase
            .from('editor_assignments')
            .select('id', { count: 'exact', head: true })
            .eq('editor_user_id', editor.id)
            .is('unassigned_at', null);

          return {
            ...editor,
            active_case_count: countError ? 999999 : (count || 0)
          };
        })
      );

      // Sort by case count (ascending), then by created_at (oldest first)
      editorsWithCounts.sort((a, b) => {
        if (a.active_case_count !== b.active_case_count) {
          return a.active_case_count - b.active_case_count;
        }
        return new Date(a.created_at).getTime() - new Date(b.created_at).getTime();
      });

      selectedEditor = editorsWithCounts[0];
      console.log(`Selected editor: ${selectedEditor.email} with ${selectedEditor.active_case_count} active cases`);
    } else {
      selectedEditor = eligibleEditors;
    }

    if (!selectedEditor) {
      // No editors available - create admin notification
      await createAdminNotification(supabase, case_id, caseData.deceased_name);
      
      return new Response(
        JSON.stringify({ 
          success: true, 
          assigned: false, 
          message: 'No editors available - admin notified'
        } as AutoAssignEditorResponse),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Assign the selected editor to the case
    const { error: assignError } = await supabase
      .from('editor_assignments')
      .insert({
        case_id: case_id,
        editor_user_id: selectedEditor.id,
        assigned_by: user.id, // Family user who submitted
        assigned_at: new Date().toISOString()
      });

    if (assignError) {
      throw new Error(`Failed to assign editor: ${assignError.message}`);
    }

    // Update case status to 'in_production'
    const { error: statusError } = await supabase
      .from('cases')
      .update({ 
        status: 'in_production',
        updated_at: new Date().toISOString()
      })
      .eq('id', case_id);

    if (statusError) {
      console.warn('⚠️ Failed to update case status:', statusError);
      // Don't throw - assignment was successful
    }

    // Log audit event
    await supabase
      .from('events')
      .insert({
        actor_user_id: user.id,
        actor_role: 'family',
        action_type: 'AUTO_ASSIGN_EDITOR',
        target_type: 'case',
        target_id: case_id,
        payload: {
          editor_id: selectedEditor.id,
          editor_email: selectedEditor.email,
          deceased_name: caseData.deceased_name,
          active_case_count: selectedEditor.active_case_count || 0
        }
      });

    const editorName = selectedEditor.metadata?.name || selectedEditor.email;

    const response: AutoAssignEditorResponse = {
      success: true,
      assigned: true,
      editor_id: selectedEditor.id,
      editor_name: editorName,
      message: `Editor ${editorName} assigned successfully`
    };

    console.log(`✅ Auto-assigned editor ${editorName} to case ${case_id}`);

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error in auto-assign-editor:', error);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error instanceof Error ? error.message : 'Internal server error' 
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

// Helper function to create admin notification when no editors available
async function createAdminNotification(supabase: any, caseId: string, deceasedName: string) {
  try {
    // Get all admin users
    const { data: admins, error: adminError } = await supabase
      .from('users')
      .select('email')
      .eq('role', 'admin')
      .eq('status', 'active');

    if (adminError || !admins || admins.length === 0) {
      console.warn('⚠️ No admin users found for notification');
      return;
    }

    const adminEmails = admins.map((admin: any) => admin.email);

    // Create notification record
    await supabase
      .from('notifications')
      .insert({
        case_id: caseId,
        event_type: 'no_editors_available',
        recipients: adminEmails,
        status: 'pending',
        created_at: new Date().toISOString()
      });

    // Log audit event
    await supabase
      .from('events')
      .insert({
        actor_user_id: null,
        actor_role: 'system',
        action_type: 'NO_EDITORS_AVAILABLE',
        target_type: 'case',
        target_id: caseId,
        payload: {
          deceased_name: deceasedName,
          admin_emails: adminEmails
        }
      });

    console.log(`📧 Admin notification created for case ${caseId} - no editors available`);
  } catch (error) {
    console.error('Error creating admin notification:', error);
    // Don't throw - this is a non-critical operation
  }
}

