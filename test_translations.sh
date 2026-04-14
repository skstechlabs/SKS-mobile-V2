#!/bin/bash

echo "🧪 Testing Translation System"
echo "=============================="
echo ""

# Check if translation files exist
echo "📁 Checking translation files..."
if [ -f "assets/translations/en.json" ]; then
    echo "✅ en.json exists"
else
    echo "❌ en.json missing!"
    exit 1
fi

if [ -f "assets/translations/te.json" ]; then
    echo "✅ te.json exists"
else
    echo "❌ te.json missing!"
    exit 1
fi

if [ -f "assets/translations/hi.json" ]; then
    echo "✅ hi.json exists"
else
    echo "❌ hi.json missing!"
    exit 1
fi

echo ""
echo "📝 Validating JSON syntax..."

# Validate JSON files
if python3 -m json.tool assets/translations/en.json > /dev/null 2>&1; then
    echo "✅ en.json is valid JSON"
else
    echo "❌ en.json has JSON syntax errors!"
    exit 1
fi

if python3 -m json.tool assets/translations/te.json > /dev/null 2>&1; then
    echo "✅ te.json is valid JSON"
else
    echo "❌ te.json has JSON syntax errors!"
    exit 1
fi

if python3 -m json.tool assets/translations/hi.json > /dev/null 2>&1; then
    echo "✅ hi.json is valid JSON"
else
    echo "❌ hi.json has JSON syntax errors!"
    exit 1
fi

echo ""
echo "📊 Counting translation keys..."
EN_KEYS=$(python3 -c "import json; print(len(json.load(open('assets/translations/en.json'))))")
TE_KEYS=$(python3 -c "import json; print(len(json.load(open('assets/translations/te.json'))))")
HI_KEYS=$(python3 -c "import json; print(len(json.load(open('assets/translations/hi.json'))))")

echo "English: $EN_KEYS keys"
echo "Telugu: $TE_KEYS keys"
echo "Hindi: $HI_KEYS keys"

if [ "$EN_KEYS" -eq "$TE_KEYS" ] && [ "$EN_KEYS" -eq "$HI_KEYS" ]; then
    echo "✅ All files have same number of keys"
else
    echo "⚠️  Warning: Files have different number of keys"
fi

echo ""
echo "🔍 Checking pubspec.yaml..."
if grep -q "assets/translations/" pubspec.yaml; then
    echo "✅ Translation assets declared in pubspec.yaml"
else
    echo "❌ Translation assets NOT declared in pubspec.yaml!"
    exit 1
fi

echo ""
echo "🧹 Running flutter clean..."
flutter clean > /dev/null 2>&1

echo "📦 Running flutter pub get..."
flutter pub get > /dev/null 2>&1

echo ""
echo "✅ All checks passed!"
echo ""
echo "📱 To test the app:"
echo "1. Clear app data: adb shell pm clear com.spiritual.app"
echo "2. Run app: flutter run"
echo "3. Verify language selection appears"
echo "4. Select a language and verify it works"
echo "5. Go to Profile → Change Language"
echo "6. Select different language and verify instant update"
echo ""
echo "🎉 Translation system is ready!"
