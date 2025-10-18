#!/bin/bash

# Deploy the fixed invite-director Edge Function
# This fixes the app_metadata issue

echo "🚀 Deploying invite-director Edge Function..."
echo ""
echo "⚠️  Make sure you have set your Supabase access token first:"
echo "   supabase link --project-ref YOUR_PROJECT_REF"
echo ""

# Deploy the function
supabase functions deploy invite-director

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully deployed invite-director function!"
    echo ""
    echo "📋 Next steps:"
    echo "1. New director invitations will now work correctly"
    echo "2. Existing directors need their app_metadata updated manually"
    echo "3. See FIX-DIRECTOR-APP-METADATA.md for instructions"
else
    echo ""
    echo "❌ Deployment failed. Please check your Supabase credentials."
    echo ""
    echo "📋 Manual deployment:"
    echo "1. Go to Supabase Dashboard → Edge Functions"
    echo "2. Create new function named 'invite-director'"
    echo "3. Copy contents from supabase/functions/invite-director/index.ts"
    echo "4. Deploy"
fi

