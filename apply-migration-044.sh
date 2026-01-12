#!/bin/bash

# Apply migration 044 - Fix events table INSERT policies
# This fixes the RLS issue preventing admins from logging audit events

echo "🔧 Applying migration 044: Fix events INSERT policies..."
echo ""
echo "This will add INSERT policies for:"
echo "  - Admins (full access)"
echo "  - Directors (their org's cases)"
echo "  - Editors (their assigned cases)"
echo "  - QC (cases they review)"
echo "  - Family (their assigned case)"
echo ""

supabase db push

echo ""
echo "✅ Migration 044 applied!"
echo ""
echo "🧪 Testing audit trail insertion..."
echo "Please reassign an editor and check if the event appears in the audit trail."
