#!/bin/bash

# ============================================================================
# Deploy invite-family edge function with temp password fix
# ============================================================================
# This script deploys the updated invite-family function that now properly
# stores the temp_password in the user's metadata.
# ============================================================================

echo "🚀 Deploying invite-family edge function..."
echo ""
echo "⚠️  IMPORTANT: You must be logged in to Supabase CLI first!"
echo "   If not logged in, run: supabase login"
echo ""

# Deploy the function
npx supabase functions deploy invite-family --project-ref gkabtvqwwuvigcdubwyv

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ invite-family function deployed successfully!"
    echo ""
    echo "📋 NEXT STEPS:"
    echo "   1. Test by inviting a new family member from director portal"
    echo "   2. Open the case details modal"
    echo "   3. Click 'Reveal' on the credentials section"
    echo "   4. Verify the temp password is now displayed"
    echo ""
    echo "⚠️  NOTE: Existing family members invited BEFORE this fix"
    echo "   will still show 'Not available' until they are re-invited."
    echo ""
else
    echo ""
    echo "❌ Deployment failed!"
    echo ""
    echo "💡 TROUBLESHOOTING:"
    echo "   - Make sure you're logged in: supabase login"
    echo "   - Check your internet connection"
    echo "   - Verify project reference is correct: gkabtvqwwuvigcdubwyv"
    echo ""
fi
