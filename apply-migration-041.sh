#!/bin/bash

# ==============================================================================
# Apply Migration 041: Create admin_video_submissions_view
# ==============================================================================
# This fixes the QC Reviewer display issue in the admin portal
# ==============================================================================

echo "🔧 Applying Migration 041: admin_video_submissions_view"
echo ""
echo "This will create a new view that allows admins to see QC reviewer information"
echo "without being blocked by RLS policies."
echo ""

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found!"
    echo ""
    echo "Please apply this migration manually:"
    echo "1. Go to: https://supabase.com/dashboard/project/YOUR_PROJECT/sql"
    echo "2. Copy the contents of: supabase/migrations/041_create_admin_video_submissions_view.sql"
    echo "3. Paste and run in SQL Editor"
    echo ""
    echo "Or install Supabase CLI: npm install -g supabase"
    exit 1
fi

# Apply migration
echo "📤 Pushing migration to Supabase..."
supabase db push

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Migration applied successfully!"
    echo ""
    echo "🧪 Verify the fix:"
    echo "1. Login as QC → Start reviewing a case"
    echo "2. Login as Admin → Check case details"
    echo "3. Should now see QC Reviewer name (e.g., 'Sarah Johnson')"
    echo ""
    echo "📊 You can also run this query to test:"
    echo ""
    echo "SELECT case_id, qc_status, qc_reviewer_email,"
    echo "       qc_reviewer_metadata->>'name' as qc_name"
    echo "FROM admin_video_submissions_view"
    echo "WHERE qc_reviewer_id IS NOT NULL;"
    echo ""
else
    echo ""
    echo "❌ Migration failed!"
    echo ""
    echo "Please apply manually via Supabase SQL Editor."
    echo "See APPLY-VIDEO-SUBMISSIONS-VIEW.md for detailed instructions."
    exit 1
fi

