#!/bin/bash

# Run Flutter Web in Production Mode (production backend)
# This connects to production backend at https://sivakundalini.org

echo "🌐 Starting Flutter Web - Production Mode"
echo "Backend: https://sivakundalini.org"
echo ""

flutter run -d chrome --dart-define-from-file=.env.prod.json
