#!/bin/bash
# Usage:
#   ./run.sh              → dev (uses .env.json)
#   ./run.sh prod         → prod (uses .env.prod.json)
#   ./run.sh build        → build APK with dev env
#   ./run.sh build prod   → build APK with prod env

ENV_FILE=".env.json"
if [[ "$1" == "prod" || "$2" == "prod" ]]; then
  ENV_FILE=".env.prod.json"
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ $ENV_FILE not found. Copy .env.example.json → $ENV_FILE and fill in values."
  exit 1
fi

echo "📦 Loading env from $ENV_FILE"

# Read values from JSON using python (available on macOS by default)
read_env() {
  python3 -c "import json,sys; d=json.load(open('$ENV_FILE')); print(d.get('$1',''))"
}

FIREBASE_API_KEY=$(read_env FIREBASE_API_KEY)
FIREBASE_AUTH_DOMAIN=$(read_env FIREBASE_AUTH_DOMAIN)
FIREBASE_PROJECT_ID=$(read_env FIREBASE_PROJECT_ID)
FIREBASE_STORAGE_BUCKET=$(read_env FIREBASE_STORAGE_BUCKET)
FIREBASE_MESSAGING_SENDER_ID=$(read_env FIREBASE_MESSAGING_SENDER_ID)
FIREBASE_WEB_APP_ID=$(read_env FIREBASE_WEB_APP_ID)
GOOGLE_CLIENT_ID=$(read_env GOOGLE_CLIENT_ID)

INDEX_HTML="web/index.html"
BACKUP_HTML="web/index.html.bak"

# Backup original index.html
cp "$INDEX_HTML" "$BACKUP_HTML"

# Inject values into placeholders
sed -i '' \
  -e "s|%%FIREBASE_API_KEY%%|$FIREBASE_API_KEY|g" \
  -e "s|%%FIREBASE_AUTH_DOMAIN%%|$FIREBASE_AUTH_DOMAIN|g" \
  -e "s|%%FIREBASE_PROJECT_ID%%|$FIREBASE_PROJECT_ID|g" \
  -e "s|%%FIREBASE_STORAGE_BUCKET%%|$FIREBASE_STORAGE_BUCKET|g" \
  -e "s|%%FIREBASE_MESSAGING_SENDER_ID%%|$FIREBASE_MESSAGING_SENDER_ID|g" \
  -e "s|%%FIREBASE_WEB_APP_ID%%|$FIREBASE_WEB_APP_ID|g" \
  -e "s|%%GOOGLE_CLIENT_ID%%|$GOOGLE_CLIENT_ID|g" \
  "$INDEX_HTML"

echo "✅ Firebase config injected into index.html"

# Build dart-define args from all keys in env file
DART_DEFINES=$(python3 -c "
import json
d = json.load(open('$ENV_FILE'))
print(' '.join(f'--dart-define={k}={v}' for k,v in d.items()))
")

# Run or build
if [[ "$1" == "build" ]]; then
  echo "🔨 Building APK..."
  flutter build apk $DART_DEFINES
else
  echo "🚀 Running on Chrome..."
  flutter run -d chrome --web-port 8083 --web-hostname 0.0.0.0 $DART_DEFINES
fi

# Restore index.html with placeholders (keep repo clean)
cp "$BACKUP_HTML" "$INDEX_HTML"
rm "$BACKUP_HTML"
echo "🔁 index.html restored to placeholders"
