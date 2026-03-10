// Create Video Upload URL - Cloudflare Stream Direct Creator Upload
// Generates a secure one-time upload URL for editors to upload videos
// directly to Cloudflare Stream without exposing API credentials.
//
// Setup:
//   1. Create a Cloudflare account and enable Stream.
//   2. Get your Account ID from the Cloudflare dashboard.
//   3. Create an API token with "Stream:Edit" permissions.
//   4. Set these secrets in Supabase:
//      supabase secrets set CLOUDFLARE_ACCOUNT_ID=your-account-id
//      supabase secrets set CLOUDFLARE_API_TOKEN=your-api-token
//   5. Deploy this function:  supabase functions deploy create-video-upload-url

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createSupabaseClient, verifyAuth } from '../_shared/supabase-client.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Verify the user is authenticated and is an editor or admin
    const authHeader = req.headers.get('Authorization');
    const { user, error: authError } = await verifyAuth(authHeader);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Check user role
    const supabase = createSupabaseClient(authHeader!);
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single();

    if (userError || !userData || !['editor', 'admin'].includes(userData.role)) {
      return new Response(
        JSON.stringify({ success: false, error: 'Only editors can upload videos' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const body = await req.json();
    const { case_id } = body;

    if (!case_id) {
      return new Response(
        JSON.stringify({ success: false, error: 'case_id is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Read Cloudflare credentials from environment
    const cfAccountId = Deno.env.get('CLOUDFLARE_ACCOUNT_ID');
    const cfApiToken = Deno.env.get('CLOUDFLARE_API_TOKEN');

    if (!cfAccountId || !cfApiToken) {
      console.error('Cloudflare credentials not configured');
      return new Response(
        JSON.stringify({ success: false, error: 'Video service not configured. Please contact an administrator.' }),
        { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Request a Direct Creator Upload URL from Cloudflare Stream
    // This gives us a one-time URL the editor can upload to directly.
    const expiry = new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(); // 2 hours from now
    const cfResponse = await fetch(
      `https://api.cloudflare.com/client/v4/accounts/${cfAccountId}/stream/direct_upload`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${cfApiToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          maxDurationSeconds: 7200,        // Max 2-hour video
          expiry,
          meta: {
            caseId: case_id,
            editorId: user.id,
            editorEmail: user.email,
          },
          requireSignedURLs: false,        // Public URLs for QC access
          allowedOrigins: ['memorio.ai', 'localhost'],
        }),
      }
    );

    if (!cfResponse.ok) {
      const cfError = await cfResponse.text();
      console.error('Cloudflare API error:', cfError);
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to create upload URL' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const cfData = await cfResponse.json();

    if (!cfData.success || !cfData.result) {
      console.error('Unexpected Cloudflare response:', JSON.stringify(cfData));
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to generate upload URL' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const { uploadURL, uid: videoUid } = cfData.result;

    // Derive the player URL from the account ID
    // Cloudflare Stream player embeds: https://customer-{accountHash}.cloudflarestream.com/{uid}/iframe
    // We store a special prefix so QC can detect the provider
    const playerUrl = `cf-stream:${videoUid}`;

    return new Response(
      JSON.stringify({
        success: true,
        uploadURL,        // TUS endpoint editor uploads to
        videoUid,         // Cloudflare Stream video UID
        playerUrl,        // Stored in video_submissions.video_url
        accountId: cfAccountId,  // Needed to construct embed URL
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error in create-video-upload-url:', error);
    return new Response(
      JSON.stringify({ success: false, error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
