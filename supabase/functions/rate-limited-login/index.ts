// ============================================================================
// Supabase Edge Function: Rate-Limited Login
// ============================================================================
// Handles authentication with server-side rate limiting that cannot be bypassed
// 
// Features:
// - Server-side rate limiting (5 attempts per 15 minutes)
// - Progressive lockout (increases with repeated failures)
// - IP and user agent tracking
// - Automatic cleanup of failed attempts on success
// - Role-based access validation
//
// Usage:
// POST /functions/v1/rate-limited-login
// Body: { email, password, expectedRole }

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface LoginRequest {
  email: string
  password: string
  expectedRole: 'family' | 'director' | 'editor' | 'qc' | 'admin'
}

interface RateLimitCheck {
  is_locked: boolean
  attempt_count: number
  max_attempts: number
  minutes_remaining: number
  window_minutes: number
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase clients
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!

    // Service role client for rate limiting checks
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)
    // Anon client for auth operations
    const supabase = createClient(supabaseUrl, supabaseAnonKey)

    // Parse request body
    const { email, password, expectedRole }: LoginRequest = await req.json()

    // Validate input
    if (!email || !password || !expectedRole) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: email, password, expectedRole' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get client IP and user agent for tracking
    const clientIp = req.headers.get('x-forwarded-for') || req.headers.get('x-real-ip') || 'unknown'
    const userAgent = req.headers.get('user-agent') || 'unknown'

    console.log(`[Rate-Limited Login] Attempt for ${email} from IP: ${clientIp}`)

    // Check rate limit
    const { data: rateLimitData, error: rateLimitError } = await supabaseAdmin
      .rpc('check_rate_limit', {
        p_email: email.toLowerCase(),
        p_window_minutes: 15,
        p_max_attempts: 5
      })

    if (rateLimitError) {
      console.error('[Rate Limit Check Error]', rateLimitError)
      return new Response(
        JSON.stringify({ error: 'Rate limit check failed' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const rateLimit = rateLimitData as RateLimitCheck

    // If rate limited, return error
    if (rateLimit.is_locked) {
      console.log(`[Rate Limited] ${email} - ${rateLimit.attempt_count}/${rateLimit.max_attempts} attempts, ${rateLimit.minutes_remaining} minutes remaining`)
      
      return new Response(
        JSON.stringify({
          error: 'rate_limited',
          message: `Too many failed login attempts. Please try again in ${rateLimit.minutes_remaining} minute${rateLimit.minutes_remaining !== 1 ? 's' : ''}.`,
          attempts: rateLimit.attempt_count,
          max_attempts: rateLimit.max_attempts,
          minutes_remaining: rateLimit.minutes_remaining,
          locked_until: new Date(Date.now() + rateLimit.minutes_remaining * 60000).toISOString()
        }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Attempt authentication
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: email,
      password: password
    })

    // If authentication failed
    if (authError || !authData.user) {
      console.log(`[Auth Failed] ${email} - ${authError?.message}`)
      
      // Record failed attempt
      await supabaseAdmin.rpc('record_login_attempt', {
        p_email: email.toLowerCase(),
        p_ip_address: clientIp,
        p_user_agent: userAgent,
        p_attempt_type: 'failure'
      })

      // Check if this failure caused a lockout
      const { data: newRateLimit } = await supabaseAdmin.rpc('check_rate_limit', {
        p_email: email.toLowerCase(),
        p_window_minutes: 15,
        p_max_attempts: 5
      })

      const updatedLimit = newRateLimit as RateLimitCheck

      if (updatedLimit.is_locked) {
        return new Response(
          JSON.stringify({
            error: 'rate_limited',
            message: `Invalid credentials. Too many failed attempts. Account locked for ${updatedLimit.minutes_remaining} minute${updatedLimit.minutes_remaining !== 1 ? 's' : ''}.`,
            attempts: updatedLimit.attempt_count,
            max_attempts: updatedLimit.max_attempts,
            minutes_remaining: updatedLimit.minutes_remaining
          }),
          { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      return new Response(
        JSON.stringify({
          error: 'invalid_credentials',
          message: authError?.message || 'Invalid email or password',
          attempts_remaining: updatedLimit.max_attempts - updatedLimit.attempt_count
        }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Authentication succeeded - verify role
    const userRole = authData.user.app_metadata?.role

    if (userRole !== expectedRole) {
      console.log(`[Role Mismatch] ${email} - Expected: ${expectedRole}, Got: ${userRole}`)
      
      // Sign out the user
      await supabase.auth.signOut()

      // Record as failed attempt (wrong portal)
      await supabaseAdmin.rpc('record_login_attempt', {
        p_email: email.toLowerCase(),
        p_ip_address: clientIp,
        p_user_agent: userAgent,
        p_attempt_type: 'failure'
      })

      return new Response(
        JSON.stringify({
          error: 'access_denied',
          message: `Access denied: This portal is only for ${expectedRole} users.`
        }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // SUCCESS! Clear failed attempts
    await supabaseAdmin.rpc('clear_login_attempts', {
      p_email: email.toLowerCase()
    })

    // Record successful login
    await supabaseAdmin.rpc('record_login_attempt', {
      p_email: email.toLowerCase(),
      p_ip_address: clientIp,
      p_user_agent: userAgent,
      p_attempt_type: 'success'
    })

    // Update last login timestamp
    await supabaseAdmin
      .from('users')
      .update({ last_login_at: new Date().toISOString() })
      .eq('id', authData.user.id)

    // Update status to active if first login
    const { data: userData } = await supabaseAdmin
      .from('users')
      .select('status')
      .eq('id', authData.user.id)
      .single()

    if (userData?.status === 'invited') {
      await supabaseAdmin
        .from('users')
        .update({ status: 'active' })
        .eq('id', authData.user.id)
    }

    console.log(`[Login Success] ${email} - Role: ${userRole}`)

    // Return success with session
    return new Response(
      JSON.stringify({
        success: true,
        session: authData.session,
        user: authData.user
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[Unexpected Error]', error)
    return new Response(
      JSON.stringify({
        error: 'internal_error',
        message: error.message || 'An unexpected error occurred'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
