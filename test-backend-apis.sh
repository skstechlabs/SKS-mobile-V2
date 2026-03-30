#!/bin/bash

echo "========================================="
echo "  Backend API Connectivity Test"
echo "========================================="
echo ""

BASE_URL="https://sivakundalini.org"

echo "Testing backend at: $BASE_URL"
echo ""

# Test 1: Health Check
echo "1. Testing Health Endpoint..."
echo "   GET $BASE_URL/api/health"
HEALTH=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/health" 2>&1)
HTTP_CODE=$(echo "$HEALTH" | tail -n1)
RESPONSE=$(echo "$HEALTH" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ Health check passed"
    echo "   Response: $RESPONSE"
else
    echo "   ❌ Health check failed (HTTP $HTTP_CODE)"
    echo "   Response: $RESPONSE"
fi
echo ""

# Test 2: Gatherings (Public endpoint)
echo "2. Testing Gatherings Endpoint..."
echo "   GET $BASE_URL/api/gatherings"
GATHERINGS=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/gatherings" 2>&1)
HTTP_CODE=$(echo "$GATHERINGS" | tail -n1)
RESPONSE=$(echo "$GATHERINGS" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ Gatherings endpoint working"
    # Count gatherings
    COUNT=$(echo "$RESPONSE" | grep -o '"id"' | wc -l)
    echo "   Found $COUNT gatherings"
else
    echo "   ❌ Gatherings endpoint failed (HTTP $HTTP_CODE)"
    echo "   Response: $RESPONSE"
fi
echo ""

# Test 3: Events (Public endpoint)
echo "3. Testing Events Endpoint..."
echo "   GET $BASE_URL/api/events"
EVENTS=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/events" 2>&1)
HTTP_CODE=$(echo "$EVENTS" | tail -n1)
RESPONSE=$(echo "$EVENTS" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ Events endpoint working"
    # Count events
    COUNT=$(echo "$RESPONSE" | grep -o '"id"' | wc -l)
    echo "   Found $COUNT events"
else
    echo "   ❌ Events endpoint failed (HTTP $HTTP_CODE)"
    echo "   Response: $RESPONSE"
fi
echo ""

# Test 4: Classes (Public endpoint)
echo "4. Testing Classes Endpoint..."
echo "   GET $BASE_URL/api/classes"
CLASSES=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/classes" 2>&1)
HTTP_CODE=$(echo "$CLASSES" | tail -n1)
RESPONSE=$(echo "$CLASSES" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ Classes endpoint working"
    # Count classes
    COUNT=$(echo "$RESPONSE" | grep -o '"id"' | wc -l)
    echo "   Found $COUNT classes"
else
    echo "   ❌ Classes endpoint failed (HTTP $HTTP_CODE)"
    echo "   Response: $RESPONSE"
fi
echo ""

# Test 5: Check CORS headers
echo "5. Testing CORS Headers..."
echo "   Checking if mobile app can access API"
CORS=$(curl -s -I -H "Origin: http://localhost" "$BASE_URL/api/gatherings" 2>&1)

if echo "$CORS" | grep -q "Access-Control-Allow-Origin"; then
    echo "   ✅ CORS headers present"
    echo "$CORS" | grep "Access-Control"
else
    echo "   ⚠️  CORS headers not found (may cause issues)"
fi
echo ""

# Test 6: SSL Certificate
echo "6. Testing SSL Certificate..."
SSL=$(echo | openssl s_client -connect sivakundalini.org:443 2>&1 | grep "Verify return code")
if echo "$SSL" | grep -q "0 (ok)"; then
    echo "   ✅ SSL certificate valid"
else
    echo "   ⚠️  SSL certificate issue: $SSL"
fi
echo ""

# Summary
echo "========================================="
echo "  Test Summary"
echo "========================================="
echo ""

# Count passed tests
PASSED=0
if [ "$HTTP_CODE" = "200" ]; then ((PASSED++)); fi

echo "Backend URL: $BASE_URL"
echo ""

if [ $PASSED -ge 3 ]; then
    echo "✅ Backend is WORKING"
    echo ""
    echo "If mobile app still shows continuous loader:"
    echo "1. Rebuild APK with: ./rebuild-production.sh"
    echo "2. Ensure you use: --dart-define-from-file=.env.prod.json"
    echo "3. Check logs: adb logcat | grep API_BASE_URL"
else
    echo "❌ Backend has ISSUES"
    echo ""
    echo "Possible causes:"
    echo "1. Backend server is down"
    echo "2. Network connectivity issues"
    echo "3. Firewall blocking requests"
    echo "4. SSL certificate problems"
    echo ""
    echo "Check backend logs:"
    echo "  pm2 logs sks-backend"
fi

echo ""
echo "========================================="
