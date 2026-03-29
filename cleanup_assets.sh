#!/bin/bash

# ============================================================================
# Asset Cleanup Script - Remove CDN-migrated Images
# ============================================================================
# This script removes all images that have been migrated to CDN
# Only keeps critical assets (logo and audio files)
# ============================================================================

echo "🧹 Starting asset cleanup..."
echo ""

# Navigate to assets directory
cd "$(dirname "$0")/assets/images" || exit 1

echo "📁 Current directory: $(pwd)"
echo ""

# Backup before deletion (optional)
read -p "Create backup before deletion? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📦 Creating backup..."
    cd ..
    tar -czf images_backup_$(date +%Y%m%d_%H%M%S).tar.gz images/
    echo "✅ Backup created: images_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    cd images || exit 1
    echo ""
fi

# List files to be deleted
echo "🗑️  Files to be deleted:"
echo "----------------------------------------"

# Main images (keep only logo)
echo "Main images:"
ls -1 | grep -v "SKS_Logo.png" | grep -E "\.(jpg|jpeg|png|webp)$"

# Subdirectories
echo ""
echo "Subdirectories:"
ls -d */ 2>/dev/null || echo "  (none)"

echo "----------------------------------------"
echo ""

# Confirm deletion
read -p "⚠️  Delete these files? This cannot be undone! (yes/no): " -r
echo
if [[ ! $REPLY == "yes" ]]; then
    echo "❌ Cleanup cancelled"
    exit 0
fi

echo ""
echo "🗑️  Deleting files..."

# Delete main images (except logo)
find . -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) ! -name "SKS_Logo.png" -delete
echo "✅ Deleted main images"

# Delete subdirectories
rm -rf chakras/ 2>/dev/null && echo "✅ Deleted chakras/"
rm -rf daily_wisdom_images/ 2>/dev/null && echo "✅ Deleted daily_wisdom_images/"
rm -rf recentGatherings/ 2>/dev/null && echo "✅ Deleted recentGatherings/"

echo ""
echo "📊 Remaining files:"
echo "----------------------------------------"
ls -lh
echo "----------------------------------------"

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Update pubspec.yaml to remove deleted asset paths"
echo "2. Run: flutter clean"
echo "3. Run: flutter pub get"
echo "4. Test the app to ensure all images load from CDN"
echo "5. Build release APK and verify size reduction"
echo ""
