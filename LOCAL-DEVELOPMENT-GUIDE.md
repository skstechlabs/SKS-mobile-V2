# Local Development Guide - SKS Mobile App

## Problem: CORS Issues When Testing Locally

When you run the Flutter web app in Chrome and it tries to connect to your local API Gateway (port 6000), you get CORS errors because:
- Flutter web runs on one port (e.g., `http://localhost:8080`)
- API Gateway runs on another port (`http://localhost:6000`)
- **Different ports = Different origins = CORS policy blocks the request**

---

## ✅ SOLUTION 1: Use the Automated Script (RECOMMENDED)

### Steps:
1. **Start your API Gateway** (if not already running):
   ```bash
   cd s:\Backup\api-gateway
   node server.js
   ```
   
   Verify it shows: `🚀 API Gateway running on port 6000`

2. **Run the automated script**:
   ```bash
   cd s:\SKS-mobile-V2
   START-LOCAL-DEV.bat
   ```

3. **What the script does**:
   - Closes all Chrome instances
   - Starts Chrome with CORS disabled (safe for local dev)
   - Starts Flutter web app on port 8080
   - Connects to your local API Gateway on port 6000

4. **Done!** No CORS errors, everything works locally.

---

## ✅ SOLUTION 2: Manual Steps (If Script Doesn't Work)

### Step 1: Start API Gateway
```bash
cd s:\Backup\api-gateway
node server.js
```

### Step 2: Close All Chrome Windows
Close all Chrome browser windows completely.

### Step 3: Start Chrome with CORS Disabled
```bash
"C:\Program Files\Google\Chrome\Application\chrome.exe" --disable-web-security --disable-gpu --user-data-dir="%TEMP%\chrome-dev-session" --disable-features=IsolateOrigins,site-per-process
```

### Step 4: Start Flutter Web App
```bash
cd s:\SKS-mobile-V2
flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://localhost:6000 --dart-define=MSG91_WIDGET_ID=366379717055333935353237 --dart-define=MSG91_AUTH_TOKEN=503409TcpVDVCsWuiQ69c418f1P1 --dart-define=GOOGLE_CLIENT_ID=107751006310624717047-kcqvvvvvvvvvvvvvvvvvvvvvvvvvvvvv.apps.googleusercontent.com --dart-define=ONESIGNAL_APP_ID=b89d199e-15be-4343-9e04-640c43f355e9
```

---

## ✅ SOLUTION 3: Backend Fix (Already Applied)

I've updated the API Gateway CORS configuration to automatically allow all origins in development mode.

**To apply this fix:**
1. Stop your API Gateway (Ctrl+C)
2. Restart it:
   ```bash
   cd s:\Backup\api-gateway
   node server.js
   ```

The updated CORS config now checks `NODE_ENV=development` and allows all origins automatically.

---

## Why CORS Happens

```
┌─────────────────────────────────────────────────────────────┐
│  Flutter Web App                                            │
│  Running on: http://localhost:8080                          │
│                                                             │
│  Tries to call: http://localhost:6000/api/events           │
│                                                             │
│  ❌ Browser blocks this because:                            │
│     - Different ports = Different origins                   │
│     - CORS policy requires server permission                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  API Gateway                                                │
│  Running on: http://localhost:6000                          │
│                                                             │
│  Needs to send CORS headers:                                │
│  - Access-Control-Allow-Origin: *                           │
│  - Access-Control-Allow-Methods: GET, POST, etc.            │
└─────────────────────────────────────────────────────────────┘
```

---

## Testing Checklist

- [ ] API Gateway is running on port 6000
- [ ] You can access `http://localhost:6000/health` in browser
- [ ] Chrome is started with `--disable-web-security` flag
- [ ] Flutter app is running and connecting to `http://localhost:6000`
- [ ] No CORS errors in browser console

---

## Troubleshooting

### "Flutter command not found"
- Add Flutter to your PATH environment variable
- Or use full path: `C:\path\to\flutter\bin\flutter.bat run ...`

### "Chrome not found"
- Update the Chrome path in the script if installed elsewhere
- Common paths:
  - `C:\Program Files\Google\Chrome\Application\chrome.exe`
  - `C:\Program Files (x86)\Google\Chrome\Application\chrome.exe`

### "Still getting CORS errors"
1. Make sure you closed ALL Chrome windows before starting with `--disable-web-security`
2. Check Chrome shows warning: "You are using an unsupported command-line flag"
3. Verify API Gateway is running: `http://localhost:6000/health`
4. Check Flutter is using correct API_BASE_URL in console logs

### "Health endpoint not working"
The health endpoint works fine - it's at `http://localhost:6000/health`
The route is properly configured in server.js: `app.use('/health', healthRoutes)`

---

## Production vs Development

| Environment | API URL | CORS |
|-------------|---------|------|
| **Development (Local)** | `http://localhost:6000` | Disabled in Chrome |
| **Production** | `https://app.sivakundalini.org` | Configured on server |

---

## Quick Reference

**Start Everything:**
```bash
# Terminal 1: API Gateway
cd s:\Backup\api-gateway
node server.js

# Terminal 2: Flutter App (use the script)
cd s:\SKS-mobile-V2
START-LOCAL-DEV.bat
```

**Stop Everything:**
- Press Ctrl+C in both terminals
- Close Chrome
