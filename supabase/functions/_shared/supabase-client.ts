// Shared Supabase client for Edge Functions

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

export const createSupabaseClient = (authHeader?: string) => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  // Use service role key for server-side operations
  return createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    },
    global: {
      headers: authHeader ? { Authorization: authHeader } : {}
    }
  });
};

export const verifyAuth = async (authHeader: string | null) => {
  if (!authHeader) {
    return { error: 'Missing authorization header', user: null };
  }

  const supabase = createSupabaseClient(authHeader);
  
  const { data: { user }, error } = await supabase.auth.getUser();
  
  if (error || !user) {
    return { error: 'Unauthorized', user: null };
  }

  return { user, error: null };
};

export const generatePassword = (length: number = 14): string => {
  // Cryptographically secure generation (previously Math.random, which is predictable)
  const lower = 'abcdefghijkmnopqrstuvwxyz';
  const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const digits = '23456789';
  const special = '!@#$%^&*';
  const all = lower + upper + digits + special;

  const pick = (charset: string, n: number): string => {
    const out: string[] = [];
    const buf = new Uint32Array(n);
    crypto.getRandomValues(buf);
    for (let i = 0; i < n; i++) out.push(charset[buf[i] % charset.length]);
    return out.join('');
  };

  // Guarantee one of each class, fill the rest from the full set, then shuffle securely
  const base = pick(lower, 1) + pick(upper, 1) + pick(digits, 1) + pick(special, 1) + pick(all, Math.max(length - 4, 0));
  const arr = base.split('');
  const rnd = new Uint32Array(arr.length);
  crypto.getRandomValues(rnd);
  for (let i = arr.length - 1; i > 0; i--) {
    const j = rnd[i] % (i + 1);
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr.join('');
};
