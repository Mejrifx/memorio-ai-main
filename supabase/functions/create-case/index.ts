// Create Case Edge Function
// Allows Directors to create new cases for deceased individuals

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createSupabaseClient, verifyAuth } from '../_shared/supabase-client.ts';
import type { CreateCaseRequest, ApiResponse } from '../_shared/types.ts';

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
      .select('role, org_id')
      .eq('id', user.id)
      .single();

    if (userError || userData?.role !== 'director') {
      return new Response(
        JSON.stringify({ success: false, error: 'Only directors can create cases' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Parse request body
    const body: CreateCaseRequest = await req.json();
    const { 
      deceased_name, 
      gender,
      date_of_birth,
      date_of_death,
      city_of_birth,
      city_of_death,
      service_date,
      service_location, 
      metadata 
    } = body;

    // Validate required fields
    const requiredFields = {
      deceased_name,
      gender,
      date_of_birth,
      date_of_death,
      city_of_birth,
      city_of_death,
      service_date
    };

    const missingFields = Object.entries(requiredFields)
      .filter(([key, value]) => !value)
      .map(([key]) => key);

    if (missingFields.length > 0) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: `Missing required fields: ${missingFields.join(', ')}` 
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Create case with all decedent information in metadata
    const { data: caseData, error: caseError } = await supabase
      .from('cases')
      .insert({
        org_id: userData.org_id,
        deceased_name,
        created_by: user.id,
        status: 'created',
        metadata: {
          // Core decedent information (required)
          gender,
          date_of_birth,
          date_of_death,
          city_of_birth,
          city_of_death,
          service_date,
          service_location,
          // Additional metadata
          ...metadata,
          // Flag that core info was provided by director
          director_provided_core_info: true
        }
      })
      .select()
      .single();

    if (caseError) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: `Failed to create case: ${caseError.message}` 
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Create empty form record for this case
    const { error: formError } = await supabase
      .from('forms')
      .insert({
        case_id: caseData.id,
        json_schema_version: 'v1'
      });

    if (formError) {
      console.error('Failed to create form record:', formError);
      // Don't fail the request, just log the error
    }

    // Log audit event
    await supabase
      .from('events')
      .insert({
        actor_user_id: user.id,
        actor_role: 'director',
        action_type: 'CREATE_CASE',
        target_type: 'cases',
        target_id: caseData.id,
        payload: {
          deceased_name,
          gender,
          date_of_birth,
          date_of_death,
          city_of_birth,
          city_of_death,
          service_date,
          service_location
        }
      });

    const response: ApiResponse = {
      success: true,
      data: {
        case_id: caseData.id,
        deceased_name: caseData.deceased_name,
        status: caseData.status,
        created_at: caseData.created_at
      },
      message: `Case created successfully for ${deceased_name}`
    };

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error in create-case:', error);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error instanceof Error ? error.message : 'Internal server error' 
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

