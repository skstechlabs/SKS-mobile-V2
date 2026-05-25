#!/bin/bash

# Run Flutter Web in Production Mode (production backend)
# This connects to production backend at https://app.sivakundalini.org

echo "🌐 Starting Flutter Web - Production Mode"
echo "Backend: https://app.sivakundalini.org"
echo ""

flutter run -d chrome --dart-define-from-file=.env.prod.json
