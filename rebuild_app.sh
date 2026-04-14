#!/bin/bash

# SKS Mobile App Rebuild Script
# Use this after making changes to pubspec.yaml or assets

echo "🧹 Cleaning Flutter build cache..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo ""
echo "✅ Rebuild preparation complete!"
echo ""
echo "Now run one of these commands to start the app:"
echo ""
echo "  For Android:     flutter run -d android"
echo "  For iOS:         flutter run -d ios"
echo "  For Web:         flutter run -d chrome"
echo "  For macOS:       flutter run -d macos"
echo ""
echo "Note: Hot reload will NOT work for asset changes."
echo "      You must do a full rebuild (which this script prepares)."
echo ""
