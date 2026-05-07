# ✅ Notification TTL & Links - Fixed

## 🔧 FIXES APPLIED

### 1. Per-Notification TTL Support
- Each notification can have its own TTL (Time To Live)
- TTL is read from OneSignal additional data
- Supports multiple field names: `ttl_days`, `ttl`, or `expiry_days`
- Default: 30 days if not specified
- Auto-cleanup removes expired notifications on app startup and when viewing notifications

### 2. URL Opening Fixed
- Added `<queries>` intent filter in AndroidManifest for Android 11+
- Improved URL parsing (auto-adds https:// if missing)
- Better error handling and logging
- Works with both http:// and https:// URLs

---

## 📱 FRESH APK READY

**Location**: `build/app/outputs/flutter-apk/app-release.apk` (132.2 MB)

**Install now** to test the fixes!

---

## 🎯 HOW TO SEND NOTIFICATIONS WITH CUSTOM TTL

### From OneSignal Dashboard:

**Example 1: Notification expires in 7 days**
```
Title: Limited Time Offer
Message: Register for the event this week!

Additional Data:
{
  "ttl_days": "7",
  "action_url": "https://sivakundalini.org/level5.1/ashramRules",
  "button_text": "Open Link"
}
```

**Example 2: Notification expires in 1 day**
```
Title: Today's Event
Message: Join us today at 6 PM

Additional Data:
{
  "ttl_days": "1",
  "action_url": "https://sivakundalini.org/events/today"
}
```

**Example 3: Notification expires in 90 days**
```
Title: Important Announcement
Message: Long-term information

Additional Data:
{
  "ttl_days": "90"
}
```

**Example 4: No TTL specified (uses default 30 days)**
```
Title: Regular Update
Message: General information

Additional Data:
{
  "action_url": "https://sivakundalini.org"
}
```

---

## 🔗 TESTING YOUR LINK

Your link: `https://sivakundalini.org/level5.1/ashramRules`

### Test Steps:
1. Install fresh APK
2. Send notification from OneSignal with:
   ```json
   {
     "action_url": "https://sivakundalini.org/level5.1/ashramRules",
     "button_text": "Open Link"
   }
   ```
3. Tap notification from system tray
4. App opens to detail screen
5. Tap "Open Link" button
6. Should open in browser

### If Link Still Doesn't Open:
Check app logs for these messages:
```
🔗 Attempting to open URL: https://sivakundalini.org/level5.1/ashramRules
🔗 Parsed URI: https://sivakundalini.org/level5.1/ashramRules
🔗 Can launch URL: true
✅ URL launched: true
```

---

## 📊 TTL BEHAVIOR

### How It Works:
1. Notification received with `ttl_days: 7`
2. Stored with expiry date = receivedAt + 7 days
3. Notification visible in app for 7 days
4. After 7 days, notification is expired
5. Next app startup or notification page visit removes it
6. User never sees expired notifications

### Cleanup Triggers:
- App startup (in main.dart)
- Opening notifications page
- Viewing notification list

### Logs:
```
✅ Notification stored: Event Tomorrow (TTL: 7 days)
🗑️ Removed 3 expired notifications
```

---

## 🎨 NOTIFICATION DETAIL SCREEN FEATURES

### When Notification is Clicked:
1. Opens full detail screen
2. Shows complete message (expandable if >150 chars)
3. Shows received date and expiry date
4. Displays all links as buttons:
   - **Primary action button** (from `action_url` + `button_text`)
   - **Additional links** (from `url` field)
   - **Auto-detected URLs** in message text
5. All links open in external browser
6. Delete button in top right

### Link Button Types:
- **Filled blue button**: Primary action (action_url)
- **Outlined blue button**: Additional link (url)
- **Blue boxes**: URLs found in message text

---

## 🧪 TESTING CHECKLIST

- [ ] Install fresh APK: `build/app/outputs/flutter-apk/app-release.apk`
- [ ] Send notification with `action_url` and `button_text`
- [ ] Tap notification from system tray
- [ ] Verify detail screen opens
- [ ] Tap "Open Link" button
- [ ] Verify browser opens with correct URL
- [ ] Test with different TTL values (1, 7, 30, 90 days)
- [ ] Verify expired notifications are removed

---

## 📝 ONESIGNAL ADDITIONAL DATA FIELDS

### Supported Fields:

**TTL (Time To Live):**
- `ttl_days`: Number of days before auto-delete (e.g., "7", "30", "90")
- `ttl`: Alternative field name
- `expiry_days`: Alternative field name

**Links:**
- `action_url`: Primary link URL
- `button_text`: Text for primary button (default: "Open Link")
- `url`: Additional/secondary link

**Custom Navigation:**
- `screen`: Screen name for in-app navigation
- `open_url_immediately`: Set to "true" to open URL without showing detail screen

### Example Complete Notification:
```json
{
  "ttl_days": "7",
  "action_url": "https://sivakundalini.org/level5.1/ashramRules",
  "button_text": "View Ashram Rules",
  "url": "https://sivakundalini.org/contact",
  "screen": "events"
}
```

---

## 🔍 TROUBLESHOOTING

### Link doesn't open?
1. Check app logs for error messages
2. Verify URL is valid (starts with http:// or https://)
3. Test URL in browser first
4. Check if device has browser app installed

### Notification not auto-deleted?
1. Check TTL is set in additional data
2. Restart app to trigger cleanup
3. Open notifications page to trigger cleanup
4. Check logs: `🗑️ Removed X expired notifications`

### Wrong TTL applied?
1. Verify additional data has `ttl_days` field
2. Check value is a number (as string): "7" not 7
3. Check logs: `✅ Notification stored: Title (TTL: X days)`

---

**Configuration:**
- OneSignal App ID: `b89d199e-15be-4343-9e04-640c43f355e9`
- Default TTL: 30 days
- Supported TTL fields: `ttl_days`, `ttl`, `expiry_days`
- Link fields: `action_url`, `button_text`, `url`
