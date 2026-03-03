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
    const smtpPort = parseInt(Deno.env.get('SMTP_PORT') || '587');
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

    console.log(`Sending email to ${to} via ${smtpHost}:${smtpPort}`);

    // Create email in RFC 5322 format
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
      `Content-Transfer-Encoding: quoted-printable`,
      ``,
      html.replace(/\r?\n/g, '\r\n'),
      ``,
      `--${boundary}--`
    ].join('\r\n');

    // Connect to SMTP server using raw TCP
    const conn = await Deno.connect({
      hostname: smtpHost,
      port: smtpPort,
    });

    // Upgrade to TLS
    const tlsConn = await Deno.startTls(conn, { hostname: smtpHost });
    
    const encoder = new TextEncoder();
    const decoder = new TextDecoder();

    // Helper to read SMTP responses
    async function readResponse(): Promise<string> {
      const buffer = new Uint8Array(4096);
      const n = await tlsConn.read(buffer);
      if (!n) throw new Error('Connection closed');
      return decoder.decode(buffer.subarray(0, n));
    }

    // Helper to send SMTP commands
    async function sendCommand(cmd: string): Promise<string> {
      await tlsConn.write(encoder.encode(cmd + '\r\n'));
      return await readResponse();
    }

    try {
      // SMTP conversation
      await readResponse(); // Read banner
      await sendCommand(`EHLO ${smtpHost}`);
      await sendCommand(`AUTH LOGIN`);
      await sendCommand(btoa(smtpUser));
      await sendCommand(btoa(smtpPass));
      await sendCommand(`MAIL FROM:<${fromEmail}>`);
      await sendCommand(`RCPT TO:<${to}>`);
      await sendCommand('DATA');
      await tlsConn.write(encoder.encode(emailBody + '\r\n.\r\n'));
      await readResponse();
      await sendCommand('QUIT');
      
      tlsConn.close();

      console.log(`✅ Email sent successfully to ${to}`);

      return new Response(
        JSON.stringify({ success: true, message: 'Email sent successfully' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );

    } catch (smtpError) {
      tlsConn.close();
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
