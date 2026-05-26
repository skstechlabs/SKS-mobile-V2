# How to Filter Logcat for API Calls in Android Studio

## Method 1: Use Logcat Filter (Easiest)

### Step 1: Open Logcat
1. In Android Studio, click **"Logcat"** tab at the bottom
2. You'll see lots of scrolling logs

### Step 2: Create a Filter
1. Look for the **filter dropdown** (says "Show only selected application" or "No Filters")
2. Click the **dropdown** next to it
3. Click **"Edit Filter Configuration"** (or the **+** icon)

### Step 3: Configure Filter for API Calls
Create a new filter with these settings:

**Filter Name:** `API Calls`

**Log Tag:** Leave empty

**Log Message:** `http` (or `https`)

**Package Name:** `com.spiritual.app` (your app package)

**Log Level:** `Debug` or `Verbose`

Click **OK**

### Step 4: Apply Filter
1. Select **"API Calls"** from the filter dropdown
2. Now you'll only see logs containing "http" or "https"

---

## Method 2: Use Search Box (Quick)

### In Logcat:
1. Look for the **search box** at the top of Logcat panel
2. Type one of these search terms:
   - `http://` - Shows all HTTP requests
   - `https://` - Shows all HTTPS requests
   - `app.sivakundalini.org` - Shows only your API calls
   - `api/auth` - Shows authentication API calls
   - `POST` or `GET` - Shows specific HTTP methods

### Example Searches:
```
app.sivakundalini.org          # All API calls to your server
POST /api/auth                 # Google login requests
GET /health                    # Health check requests
401                            # Unauthorized responses
200                            # Successful responses
```

---

## Method 3: Use Regex Filter (Advanced)

### Create Advanced Filter:
1. Click **"Edit Filter Configuration"**
2. Enable **"Regex"** checkbox
3. Use this pattern in **Log Message**:

```regex
(http|https|POST|GET|PUT|DELETE|api/)
```

This will show:
- All HTTP/HTTPS requests
- All API endpoints
- All HTTP methods

---

## Method 4: Filter by Log Level

### In Logcat:
1. Click the **Log Level dropdown** (shows "Verbose" by default)
2. Select **"Debug"** or **"Info"**
3. This reduces noise from verbose logs

---

## Best Practice: Create Multiple Filters

### Filter 1: All API Calls
- **Name:** `API Calls`
- **Message:** `http`
- **Level:** `Debug`

### Filter 2: Errors Only
- **Name:** `API Errors`
- **Message:** `error|exception|failed`
- **Level:** `Error`

### Filter 3: Google Login
- **Name:** `Google Login`
- **Message:** `google|auth/login`
- **Level:** `Debug`

### Filter 4: Network Responses
- **Name:** `API Responses`
- **Message:** `200|201|400|401|404|500`
- **Level:** `Info`

---

## Quick Keyboard Shortcuts

- **Ctrl/Cmd + F** - Open search in Logcat
- **Ctrl/Cmd + K** - Clear Logcat
- **Pause** button - Pause log scrolling (top right of Logcat)
- **Scroll Lock** - Keep view at bottom while logs scroll

---

## Visual Guide

```
┌─────────────────────────────────────────────────────────┐
│ Logcat                                    [Pause] [Clear]│
├─────────────────────────────────────────────────────────┤
│ [Show only selected app ▼] [API Calls ▼] [Debug ▼]     │
│ [🔍 Search: app.sivakundalini.org          ]            │
├─────────────────────────────────────────────────────────┤
│ 2026-05-26 10:30:15.123 D/HTTP: POST https://app...    │
│ 2026-05-26 10:30:15.456 D/HTTP: Response: 200 OK       │
│ 2026-05-26 10:30:16.789 D/HTTP: GET https://app...     │
└─────────────────────────────────────────────────────────┘
```

---

## What to Look For in API Calls

### Successful Request:
```
D/HTTP: --> POST https://app.sivakundalini.org/api/auth/login/google
D/HTTP: Content-Type: application/json
D/HTTP: {"idToken":"eyJhbGc..."}
D/HTTP: --> END POST
D/HTTP: <-- 200 OK https://app.sivakundalini.org/api/auth/login/google
D/HTTP: {"success":true,"user":{...}}
```

### Failed Request:
```
D/HTTP: --> POST https://app.sivakundalini.org/api/auth/login/google
D/HTTP: <-- 401 Unauthorized
D/HTTP: {"success":false,"message":"Invalid token"}
```

### Network Error:
```
E/HTTP: java.net.ConnectException: Failed to connect to app.sivakundalini.org
E/HTTP: Caused by: java.net.SocketTimeoutException: timeout
```

---

## Pro Tips

### 1. Pause Logs While Reading
- Click the **Pause** button (⏸️) in Logcat toolbar
- Read the logs without them scrolling
- Click **Resume** when done

### 2. Clear Old Logs
- Click **Clear** button (🗑️) before testing
- Start fresh for each test
- Easier to find your specific API calls

### 3. Use Multiple Filters
- Switch between filters quickly
- Keep different filters for different scenarios
- Save time debugging

### 4. Copy Logs
- Right-click on a log line
- Select **"Copy"**
- Paste into text editor for analysis

### 5. Export Logs
- Right-click in Logcat
- Select **"Save As"**
- Save logs to file for later review

---

## Common API Call Patterns to Search

```
# Google Login
google|auth/login/google

# All POST requests
POST /api

# All responses
<-- 200|<-- 401|<-- 404|<-- 500

# Errors
error|exception|failed|timeout

# Your domain
app.sivakundalini.org

# JSON responses
{"success"|{"error"

# Headers
Authorization:|Content-Type:
```

---

## Recommended Setup

### For Testing Google Login:

1. **Clear Logcat** (click 🗑️)
2. **Create filter:**
   - Name: `Google Login`
   - Message: `auth/login/google|google|POST /api/auth`
3. **Apply filter**
4. **Test login in app**
5. **Watch Logcat** for:
   ```
   POST https://app.sivakundalini.org/api/auth/login/google
   <-- 200 OK (success) or <-- 401 (error)
   ```

---

## Troubleshooting

### Issue: No logs showing
**Solution:**
- Make sure app is selected in device dropdown
- Check if "Show only selected application" is enabled
- Try removing all filters temporarily

### Issue: Too many logs
**Solution:**
- Use more specific search terms
- Increase log level to "Info" or "Warn"
- Create a custom filter with regex

### Issue: Can't find API calls
**Solution:**
- Search for: `app.sivakundalini.org`
- Or search for: `http`
- Or search for: `POST` or `GET`

---

## Summary

**Quickest Method:**
1. Open Logcat
2. Type in search box: `app.sivakundalini.org`
3. Press Enter
4. See only your API calls! ✅

**Best Method:**
1. Create filter named "API Calls"
2. Set message to: `http`
3. Apply filter
4. Clean, filtered view of all API calls! ✅

---

## Example: Watching Google Login

1. **Clear Logcat** (🗑️)
2. **Search:** `auth/login/google`
3. **Tap "Sign in with Google"** in app
4. **Watch Logcat:**
   ```
   D/HTTP: POST https://app.sivakundalini.org/api/auth/login/google
   D/HTTP: {"idToken":"eyJhbGc..."}
   D/HTTP: <-- 200 OK
   D/HTTP: {"success":true,"token":"...","user":{...}}
   ```
5. **Success!** ✅

Now you can easily track all API calls! 🎯
