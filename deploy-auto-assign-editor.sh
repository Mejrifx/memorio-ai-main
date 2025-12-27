#!/bin/bash

# Deploy auto-assign-editor Edge Function
# Run this script to deploy the new function

echo "🚀 Deploying auto-assign-editor Edge Function..."
echo ""

# Check if project is linked
if [ ! -d ".supabase" ]; then
    echo "⚠️  Project not linked. Please run:"
    echo "   supabase link --project-ref YOUR_PROJECT_REF"
    echo ""
    exit 1
fi

# Deploy the function
echo "Deploying auto-assign-editor..."
supabase functions deploy auto-assign-editor

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully deployed auto-assign-editor function!"
    echo ""
    echo "📋 Verify deployment:"
    echo "   supabase functions list"
    echo ""
    echo "🧪 Test the function:"
    echo "1. Create 2-3 editor accounts in Admin Portal"
    echo "2. Submit a family form"
    echo "3. Check console for: ✅ Editor auto-assigned: [name]"
    echo "4. Verify case in 'In Progress' in Admin Portal"
    echo ""
    echo "📖 See TESTING-AUTO-ASSIGN-EDITOR.md for full test suite"
else
    echo ""
    echo "❌ Deployment failed."
    echo ""
    echo "Troubleshooting:"
    echo "1. Run: supabase login"
    echo "2. Run: supabase link --project-ref YOUR_PROJECT_REF"
    echo "3. Try deployment again"
    echo ""
    echo "📋 Manual deployment option:"
    echo "1. Go to: https://supabase.com/dashboard/project/YOUR_PROJECT/functions"
    echo "2. Create new function: auto-assign-editor"
    echo "3. Copy from: supabase/functions/auto-assign-editor/index.ts"
    echo "4. Also upload _shared/* files"
fi

