// Generate Obituary Edge Function
// Replaces the n8n memorio-intake webhook (memorioo.app.n8n.cloud).
//
// Differences from the n8n flow it replaces:
// - Authenticated: only the family user assigned to the case can generate.
// - Generates natively in English OR Spanish (replaces the MyMemory translation hack).
// - Voice is derived from the family's own answers (register selection + their wording).
// - Writes the result to obituary_content server-side and returns { name, content } -
//   the exact shape family-form.html's extractContent() already parses.
//
// Required secrets (supabase secrets set):
//   ANTHROPIC_API_KEY
// Deploy: supabase functions deploy generate-obituary
// Then in family-form.html set OBITUARY_ENDPOINT to
//   https://<project-ref>.supabase.co/functions/v1/generate-obituary
// and send the user's JWT in the Authorization header (see the marked block in the form).

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createSupabaseClient, verifyAuth } from '../_shared/supabase-client.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

// Build the voice/register hints from the intake answers themselves.
function voiceHints(p: Record<string, string>): string {
  const hints: string[] = [];
  if (p.military_service && p.military_service !== 'N/A' && p.military_service.trim()) {
    hints.push('The deceased served in the military; carry quiet pride and service language where fitting.');
  }
  if (p.loved_ones_spiritual_beliefs && p.loved_ones_spiritual_beliefs !== 'N/A' && p.loved_ones_spiritual_beliefs.trim()) {
    hints.push('Faith mattered to this person; let the spiritual language the family used shape the register, without inventing doctrine.');
  }
  const anecdotes = [p.loved_ones_description, p.loved_ones_hobbies, p.final_details].filter(Boolean).join(' ');
  if (/laugh|joke|humor|funny|witty/i.test(anecdotes)) {
    hints.push('The family remembers humor; let warmth and lightness surface once or twice, gently.');
  }
  return hints.length ? hints.join('\n') : 'Default register: warm, dignified, plain language.';
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const authHeader = req.headers.get('Authorization');
    const { user, error: authError } = await verifyAuth(authHeader);
    if (authError || !user) return json(401, { success: false, error: 'Unauthorized' });

    const payload = (await req.json()) as Record<string, string>;

    const supabase = createSupabaseClient();

    // The family user's case (same ownership check pattern as auto-assign-editor)
    const { data: caseData, error: caseError } = await supabase
      .from('cases')
      .select('id, deceased_name, assigned_family_user_id, metadata')
      .eq('assigned_family_user_id', user.id)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (caseError || !caseData) return json(404, { success: false, error: 'No case found for this user' });

    const language = payload.language === 'es' ? 'es' : 'en';
    const fullName = [payload.loved_ones_name, payload.loved_ones_middle_name, payload.loved_ones_last_name]
      .filter((v) => v && v !== 'N/A')
      .join(' ') || caseData.deceased_name;

    const fields: [string, string][] = [
      ['Full name', fullName],
      ['Salutation', payload.loved_ones_salutation],
      ['Nickname', payload.loved_ones_nickname],
      ['Maiden name', payload.loved_ones_maiden_name],
      ['Suffix', payload.loved_ones_suffix],
      ['Gender', payload.loved_ones_gender],
      ['Date of birth', payload.date_of_birth],
      ['Place of birth', [payload.city_of_birth, payload.state_of_birth, payload.country_of_birth].filter((v) => v && v !== 'N/A').join(', ')],
      ['Date of passing', payload.date_of_passing],
      ['Place of passing', [payload.city_of_passing, payload.state_of_passing, payload.country_of_passing].filter((v) => v && v !== 'N/A').join(', ')],
      ['Family members', payload.family_members],
      ['About them', payload.loved_ones_description],
      ['Achievements', payload.loved_ones_achievements],
      ['Hobbies and passions', payload.loved_ones_hobbies],
      ['Career', payload.loved_ones_career],
      ['Spiritual beliefs', payload.loved_ones_spiritual_beliefs],
      ['Military service', payload.military_service],
      ['Additional details from the family', payload.final_details],
      ['A quote the family chose', payload.tribute_quote],
    ];
    const factSheet = fields
      .filter(([, v]) => v && v.trim() && v !== 'N/A')
      .map(([k, v]) => `${k}: ${v}`)
      .join('\n');

    const system = language === 'es'
      ? 'Escribes obituarios con dignidad y calidez para familias en duelo. Escribes EXCLUSIVAMENTE con los hechos proporcionados; nunca inventas datos, fechas, nombres ni creencias. Usas un espanol natural y respetuoso (registro de Estados Unidos). Devuelves solo el texto del obituario, en parrafos separados por lineas en blanco, sin titulos ni comentarios.'
      : 'You write obituaries with dignity and warmth for grieving families. You write ONLY from the facts provided; you never invent details, dates, names, or beliefs. Return only the obituary text, in paragraphs separated by blank lines, with no headings or commentary.';

    const userPrompt = `${language === 'es' ? 'Escribe un obituario' : 'Write an obituary'} (350-500 ${language === 'es' ? 'palabras' : 'words'}) ${language === 'es' ? 'para' : 'for'} ${fullName}.

${language === 'es' ? 'Hechos proporcionados por la familia' : 'Facts provided by the family'}:
${factSheet}

${language === 'es' ? 'Registro y voz' : 'Register and voice'}:
${voiceHints(payload)}

${language === 'es'
  ? 'Usa las palabras y expresiones de la familia cuando sea natural. Si un dato no aparece arriba, no lo menciones.'
  : "Echo the family's own words and phrasings where natural. If a fact is not listed above, do not mention it."}`;

    const anthropicKey = Deno.env.get('ANTHROPIC_API_KEY');
    if (!anthropicKey) return json(500, { success: false, error: 'Generation service not configured' });

    const resp = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': anthropicKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-5',
        max_tokens: 1500,
        system,
        messages: [{ role: 'user', content: userPrompt }],
      }),
    });

    if (!resp.ok) {
      const detail = await resp.text();
      console.error('Anthropic API error:', resp.status, detail.slice(0, 300));
      return json(502, { success: false, error: 'Obituary generation failed, please try again' });
    }

    const result = await resp.json();
    const content = (result?.content?.[0]?.text || '').trim();
    if (!content) return json(502, { success: false, error: 'Empty generation, please try again' });

    // Persist server-side (upsert keyed on case_id; schema from migration 018:
    // content_html + content_plain are NOT NULL)
    const contentHtml = content
      .split(/\n\n+/)
      .map((p) => `<p>${p.replace(/\n/g, '<br>')}</p>`)
      .join('\n');
    const { error: saveError } = await supabase
      .from('obituary_content')
      .upsert(
        {
          case_id: caseData.id,
          content_html: contentHtml,
          content_plain: content,
          generated_at: new Date().toISOString(),
          generated_by: 'AI',
        },
        { onConflict: 'case_id' },
      );
    if (saveError) console.error('obituary_content save failed (returning content anyway):', saveError.message);

    await supabase.from('events').insert({
      actor_user_id: user.id,
      actor_role: 'family',
      action_type: 'OBITUARY_GENERATED',
      target_type: 'cases',
      target_id: caseData.id,
      payload: { language, model: 'claude-sonnet-5' },
    });

    return json(200, { name: fullName, content });
  } catch (error) {
    console.error('Error in generate-obituary:', error);
    return json(500, { success: false, error: 'Internal server error' });
  }
});
