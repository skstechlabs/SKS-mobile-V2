# Testing Locally Against Production Server - CORS Fix

## 🎯 Your Scenario

You want to:
- Run Flutter app locally on Chrome (`http://localhost:xxxxx`)
- Connect to production server (`http://app.sivakundalini.org`)
- But getting CORS errors because production doesn't allow localhost origins

## ❌ The Problem

```
Browser (localhost:50000) → Production Server (app.sivakundalini.org)
                          ← CORS Error: Origin not allowed
```

The production server at `app.sivakundalini.org` needs to allow `localhost` origins for development testing.

---

## ✅ Solution 1: Configure Production Server CORS (Recommended)

### If You Have Access to Production Server

The production server needs to allow localhost origins in its CORS configuration.

**For API Gateway on Production:**

Update the `.env` file on production server:

```env
# Add localhost origins for development testing
CORS_ORIGINS=http://localhost:3000,http://localhost:8080,http://localhost:50000,http://localhost:50001,http://localhost:50002,http://localhost:50003,http://localhost:50004,http://localhost:50005,http://127.0.0.1:3000,http://127.0.0.1:8080,http://app.sivakundalini.org,https://app.sivakundalini.org
```

Or simply allow all origins (development only):

```env
CORS_ORIGINS=*
```

**Then restart the production API Gateway:**

```bash
# On production server
cd /path/to/api-gateway
pm2 restart api-gateway
# or
npm restart
```

### Verify Production CORS

Test if production allows localhost:

```powershell
# Test CORS from localhost
curl -H "Origin: http://localhost:50000" `
     -H "Access-Control-Request-Method: GET" `
     -H "Access-Control-Request-Headers: Content-Type,Authorization" `
     -X OPTIONS `
     http://app.sivakundalini.org/api/events -v
```

Should return:
```
Access-Control-Allow-Origin: http://localhost:50000
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS
```

---

## ✅ Solution 2: Use CORS Browser Extension (Quick Fix)

### For Chrome - Install CORS Extension

**Option A: CORS Unblock Extension**

1. Open Chrome Web Store
2. Search for "CORS Unblock" or "Allow CORS"
3. Install extension
4. Click extension icon → Enable
5. Refresh your Flutter app

**Option B: Moesif Origin & CORS Changer**

1. Install from: https://chrome.google.com/webstore/detail/moesif-origin-cors-change/digfbfaphojjndkpccljibejjbppifbc
2. Click extension icon
3. Enable "Activate CORS"
4. Refresh your Flutter app

**Option C: Allow CORS: Access-Control-Allow-Origin**

1. Install from Chrome Web Store
2. Click extension icon to enable
3. Refresh your Flutter app

### ⚠️ Important Notes

- **Only use CORS extensions for development testing**
- **Never use in production**
- **Disable after testing**
- Extensions bypass browser security - use with caution

---

## ✅ Solution 3: Run Chrome with CORS Disabled (Development Only)

### Windows

Close all Chrome instances, then run:

```powershell
# Create a shortcut or run directly
"C:\Program Files\Google\Chrome\Application\chrome.exe" --disable-web-security --user-data-dir="C:\chrome-dev-session" --disable-site-isolation-trials
```

Then run your Flutter app:

```powershell
cd s:\SKS-mobile-V2
flutter run -d chrome --dart-define=API_BASE_URL=http://app.sivakundalini.org --dart-define=MSG91_WIDGET_ID=366379717055333935353237 --dart-define=MSG91_AUTH_TOKEN=503409TcpVDVCsWuiQ69c418f1P1 --dart-define=GOOGLE_CLIENT_ID=107751006310624717047-kcqvvvvvvvvvvvvvvvvvvvvvvvvvvvvv.apps.googleusercontent.com --dart-define=ONESIGNAL_APP_ID=b89d199e-15be-4343-9e04-640c43f355e9
```

### ⚠️ Security Warning

This disables web security in Chrome. **Only use for development testing!**

---

## ✅ Solution 4: Use a Proxy Server

### Setup Local Proxy

Create a simple proxy that adds CORS headers:

**File: `cors-proxy.js`**

```javascript
const express = require('express');
const cors = require('cors');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();

// Enable CORS for all origins
app.use(cors({
  origin: '*',
  credentials: true
}));

// Proxy all requests to production
app.use('/', createProxyMiddleware({
  target: 'http://app.sivakundalini.org',
  changeOrigin: true,
  onProxyRes: function (proxyRes, req, res) {
    proxyRes.headers['Access-Control-Allow-Origin'] = '*';
    proxyRes.headers['Access-Control-Allow-Methods'] = 'GET,POST,PUT,DELETE,PATCH,OPTIONS';
    proxyRes.headers['Access-Control-Allow-Headers'] = 'Content-Type,Authorization';
  }
}));

app.listen(3000, () => {
  console.log('CORS Proxy running on http://localhost:3000');
  console.log('Proxying to: http://app.sivakundalini.org');
});
```

**Install dependencies:**

```powershell
npm install express cors http-proxy-middleware
```

**Run proxy:**

```powershell
node cors-proxy.js
```

**Update Flutter app to use proxy:**

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000 ...
```

---

## 🎯 Recommended Approach

### For Your Scenario

Since you want to test locally against production:

**Best Option: Solution 2 (CORS Extension)**

1. Install "Allow CORS" Chrome extension
2. Enable it
3. Run your Flutter app with production URL:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://app.sivakundalini.org --dart-define=MSG91_WIDGET_ID=366379717055333935353237 --dart-define=MSG91_AUTH_TOKEN=503409TcpVDVCsWuiQ69c418f1P1 --dart-define=GOOGLE_CLIENT_ID=107751006310624717047-kcqvvvvvvvvvvvvvvvvvvvvvvvvvvvvv.apps.googleusercontent.com --dart-define=ONESIGNAL_APP_ID=b89d199e-15be-4343-9e04-640c43f355e9
```

4. Test your app
5. Disable extension when done

---

## 🔍 Verify CORS is Working

### Check Response Headers

Open Chrome DevTools → Network tab → Select any API request → Headers:

**Should see:**
```
Access-Control-Allow-Origin: http://localhost:50000
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

### Check Console

**Should NOT see:**
```
❌ Access-Control-Allow-Origin error
❌ CORS policy blocked
❌ XMLHttpRequest onError
```

---

## 📝 Quick Command Reference

### Run Flutter with Production URL

```powershell
cd s:\SKS-mobile-V2

flutter run -d chrome `
    --dart-define=API_BASE_URL=http://app.sivakundalini.org `
    --dart-define=MSG91_WIDGET_ID=366379717055333935353237 `
    --dart-define=MSG91_AUTH_TOKEN=503409TcpVDVCsWuiQ69c418f1P1 `
    --dart-define=GOOGLE_CLIENT_ID=107751006310624717047-kcqvvvvvvvvvvvvvvvvvvvvvvvvvvvvv.apps.googleusercontent.com `
    --dart-define=ONESIGNAL_APP_ID=b89d199e-15be-4343-9e04-640c43f355e9
```

### Test Production CORS

```powershell
curl -H "Origin: http://localhost:50000" `
     -X OPTIONS `
     http://app.sivakundalini.org/api/events -v
```

---

## 🎯 Summary

| Solution | Pros | Cons | Recommended |
|----------|------|------|-------------|
| Configure Production CORS | Permanent fix, secure | Requires server access | ✅ Best |
| CORS Extension | Quick, easy | Browser-specific, not secure | ✅ Good for testing |
| Chrome --disable-web-security | Works immediately | Very insecure | ⚠️ Use with caution |
| Local Proxy | Full control | Extra setup | ✅ Good alternative |

---

## 🔒 Security Reminders

1. **Never deploy with CORS: * in production**
2. **Disable CORS extensions after testing**
3. **Don't use --disable-web-security for regular browsing**
4. **Configure production CORS properly with specific origins**

---

## ✨ Expected Result

After applying one of the solutions:

1. ✅ Flutter app runs on `localhost:50000` (or similar)
2. ✅ Connects to `http://app.sivakundalini.org`
3. ✅ No CORS errors
4. ✅ All API calls work
5. ✅ Data loads successfully

---

**Last Updated**: January 2024
