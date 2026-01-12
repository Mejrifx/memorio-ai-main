#!/bin/bash

# ============================================================================
# Deploy Server-Side Rate Limiting to Supabase
# ============================================================================
# This script deploys the database migration and Edge Function for
# server-side rate limiting that cannot be bypassed by clients

echo "🚀 Deploying Server-Side Rate Limiting to Supabase..."
echo "========================================================"
echo ""

# Check if SUPABASE_ACCESS_TOKEN is set
if [ -z "$SUPABASE_ACCESS_TOKEN" ]; then
    echo "❌ SUPABASE_ACCESS_TOKEN environment variable is not set"
    echo ""
    echo "Please either:"
    echo "1. Run: export SUPABASE_ACCESS_TOKEN='your-token-here'"
    echo "   Get your token from: https://supabase.com/dashboard/account/tokens"
    echo ""
    echo "2. Or run: npx supabase login"
    echo ""
    echo "3. Or manually apply the migration in Supabase SQL Editor:"
    echo "   - Go to: https://supabase.com/dashboard/project/YOUR_PROJECT/sql"
    echo "   - Copy and paste: supabase/migrations/045_create_login_attempts_table.sql"
    echo ""
    exit 1
fi

echo "Step 1: Applying database migration..."
echo "---------------------------------------"
npx supabase db push

if [ $? -eq 0 ]; then
    echo "✅ Database migration applied successfully"
else
    echo "❌ Database migration failed"
    exit 1
fi

echo ""
echo "Step 2: Deploying Edge Function..."
echo "-----------------------------------"
npx supabase functions deploy rate-limited-login

if [ $? -eq 0 ]; then
    echo "✅ Edge Function deployed successfully"
else
    echo "❌ Edge Function deployment failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Server-Side Rate Limiting Deployed!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. Update login pages to use the Edge Function"
echo "2. Test the rate limiting (try 6 failed logins)"
echo "3. Monitor login_attempts table in Supabase"
echo ""
echo "Edge Function URL:"
echo "https://YOUR_PROJECT.supabase.co/functions/v1/rate-limited-login"
echo ""
