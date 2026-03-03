// Send Email Edge Function
// Sends emails using Resend API (fallback to SMTP if configured)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface EmailRequest {
  to: string;
  subject: string;
  html: string;
  from?: string;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { to, subject, html, from } = await req.json() as EmailRequest;

    if (!to || !subject || !html) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required fields: to, subject, html' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const fromEmail = from || Deno.env.get('SMTP_FROM') || 'Memorio <support@memorio.ai>';
    
    // Check if Resend API key is configured (preferred method)
    const resendApiKey = Deno.env.get('RESEND_API_KEY');
    
    if (resendApiKey) {
      console.log(`Sending email to ${to} via Resend API`);
      
      // Send via Resend API
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${resendApiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: fromEmail,
          to: [to],
          subject: subject,
          html: html,
        }),
      });

      if (!response.ok) {
        const error = await response.text();
        console.error('Resend API error:', error);
        throw new Error(`Resend API failed: ${error}`);
      }

      const result = await response.json();
      console.log(`✅ Email sent successfully via Resend to ${to}`, result);

      return new Response(
        JSON.stringify({ success: true, message: 'Email sent successfully', id: result.id }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    // Fallback to direct SMTP if Resend not configured
    console.warn('Resend API not configured, emails will not be sent');
    console.warn('Please set RESEND_API_KEY environment variable');
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: 'Email service not configured. Please contact administrator.' 
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error sending email:', error);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error instanceof Error ? error.message : 'Failed to send email' 
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
