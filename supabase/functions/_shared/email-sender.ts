// Shared utility to send emails via the send-email Edge Function

const SEND_EMAIL_URL = Deno.env.get('SUPABASE_URL') + '/functions/v1/send-email';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') || '';

export async function sendEmail(to: string, subject: string, html: string): Promise<boolean> {
  try {
    const response = await fetch(SEND_EMAIL_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
      },
      body: JSON.stringify({ to, subject, html }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error('Email send failed:', error);
      return false;
    }

    const result = await response.json();
    console.log('Email sent successfully:', result);
    return true;
  } catch (error) {
    console.error('Error calling send-email function:', error);
    return false;
  }
}
