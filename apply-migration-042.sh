#!/bin/bash

# ============================================================================
# Apply Migration 042: Enhanced Timeline Events
# ============================================================================

set -e

echo "============================================================"
echo "Applying Migration 042: Enhanced Timeline Events"
echo "============================================================"
echo ""

# Load environment variables
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

SUPABASE_DB_URL="postgresql://postgres.gkabtvqwwuvigcdubwyv:Mejri1990!@aws-0-eu-central-1.pooler.supabase.com:6543/postgres"

echo "📋 Migration Details:"
echo "   - Creates enhanced audit logging function"
echo "   - Detects specific changes (status, assignments, etc.)"
echo "   - Creates timeline_view with actor details"
echo "   - Replaces generic 'Case updated' with specific descriptions"
echo ""

read -p "Ready to apply? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "❌ Migration cancelled"
  exit 1
fi

echo ""
echo "🚀 Applying migration..."
echo ""

psql "$SUPABASE_DB_URL" -f supabase/migrations/042_enhance_timeline_events.sql

echo ""
echo "✅ Migration 042 applied successfully!"
echo ""
echo "📊 Testing timeline view..."
echo ""

# Test the timeline view
psql "$SUPABASE_DB_URL" -c "
SELECT 
  timestamp,
  description,
  actor_name,
  actor_email,
  actor_role
FROM timeline_view
ORDER BY timestamp DESC
LIMIT 10;
"

echo ""
echo "============================================================"
echo "✅ Migration 042 Complete!"
echo "============================================================"
echo ""
echo "What changed:"
echo "  ✅ Enhanced audit logging function installed"
echo "  ✅ Timeline view created with actor details"
echo "  ✅ Better event descriptions (status changes, assignments, etc.)"
echo ""
echo "Next steps:"
echo "  1. Test the timeline in admin panel"
echo "  2. Verify events show detailed descriptions"
echo "  3. Check that actor names/emails are displayed"
echo ""

