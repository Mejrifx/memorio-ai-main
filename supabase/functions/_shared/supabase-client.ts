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

export const generatePassword = (length: number = 12): string => {
  const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
  let password = '';
  
  for (let i = 0; i < length; i++) {
    const randomIndex = Math.floor(Math.random() * charset.length);
    password += charset[randomIndex];
  }
  
  // Ensure it has at least one uppercase, lowercase, number, and special char
  if (!/[A-Z]/.test(password)) password = 'A' + password.slice(1);
  if (!/[a-z]/.test(password)) password = password.slice(0, -1) + 'z';
  if (!/[0-9]/.test(password)) password = password.slice(0, -2) + '1' + password.slice(-1);
  if (!/[!@#$%^&*]/.test(password)) password = password.slice(0, -3) + '!' + password.slice(-2);
  
  return password;
};

