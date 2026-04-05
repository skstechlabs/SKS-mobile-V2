#!/bin/bash

# Run Flutter Web in Development Mode (localhost backend)
# This connects to local backend at http://localhost:3012

echo "🌐 Starting Flutter Web - Development Mode"
echo "Backend: http://localhost:3012"
echo ""

flutter run -d chrome --dart-define-from-file=.env.json
