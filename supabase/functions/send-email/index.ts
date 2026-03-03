// Send Email Edge Function
// Sends emails via Microsoft 365 SMTP using support@memorio.ai

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

    // Get SMTP credentials from environment
    const smtpHost = Deno.env.get('SMTP_HOST') || 'smtp.office365.com';
    const smtpUser = Deno.env.get('SMTP_USER');
    const smtpPass = Deno.env.get('SMTP_PASS');
    const fromEmail = from || Deno.env.get('SMTP_FROM') || 'support@memorio.ai';

    if (!smtpUser || !smtpPass) {
      console.error('SMTP credentials not configured');
      return new Response(
        JSON.stringify({ success: false, error: 'SMTP not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`Sending email to ${to} via ${smtpHost}:587`);

    // Connect to SMTP server on port 587 (plain first, then STARTTLS)
    const conn = await Deno.connect({
      hostname: smtpHost,
      port: 587,
    });

    const encoder = new TextEncoder();
    const decoder = new TextDecoder();
    let currentConn: Deno.Conn | Deno.TlsConn = conn;

    // Helper to read SMTP responses
    async function readResponse(): Promise<string> {
      const buffer = new Uint8Array(4096);
      const n = await currentConn.read(buffer);
      if (!n) throw new Error('Connection closed');
      const response = decoder.decode(buffer.subarray(0, n));
      console.log('SMTP <<', response.trim());
      return response;
    }

    // Helper to send SMTP commands
    async function sendCommand(cmd: string): Promise<string> {
      console.log('SMTP >>', cmd);
      await currentConn.write(encoder.encode(cmd + '\r\n'));
      return await readResponse();
    }

    try {
      // Read welcome banner
      await readResponse();
      
      // Send EHLO to see server capabilities
      await sendCommand(`EHLO ${smtpHost}`);
      
      // Send STARTTLS command
      await sendCommand('STARTTLS');
      
      // Upgrade connection to TLS
      const tlsConn = await Deno.startTls(conn, { hostname: smtpHost });
      currentConn = tlsConn;
      
      // Send EHLO again after TLS
      await sendCommand(`EHLO ${smtpHost}`);
      
      // Authenticate
      await sendCommand('AUTH LOGIN');
      await sendCommand(btoa(smtpUser));
      await sendCommand(btoa(smtpPass));
      
      // Send email
      await sendCommand(`MAIL FROM:<${fromEmail}>`);
      await sendCommand(`RCPT TO:<${to}>`);
      await sendCommand('DATA');
      
      // Send email content
      const boundary = `----=_Part_${Date.now()}`;
      const emailBody = [
        `From: ${fromEmail}`,
        `To: ${to}`,
        `Subject: ${subject}`,
        `MIME-Version: 1.0`,
        `Content-Type: multipart/alternative; boundary="${boundary}"`,
        ``,
        `--${boundary}`,
        `Content-Type: text/html; charset=UTF-8`,
        `Content-Transfer-Encoding: 7bit`,
        ``,
        html,
        ``,
        `--${boundary}--`,
        ``,
        `.`
      ].join('\r\n');
      
      await currentConn.write(encoder.encode(emailBody + '\r\n'));
      await readResponse();
      
      // Close connection
      await sendCommand('QUIT');
      currentConn.close();

      console.log(`✅ Email sent successfully to ${to}`);

      return new Response(
        JSON.stringify({ success: true, message: 'Email sent successfully' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );

    } catch (smtpError) {
      try {
        currentConn.close();
      } catch {}
      throw smtpError;
    }

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
