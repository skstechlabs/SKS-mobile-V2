# 🔔 Notification Features - Complete Implementation

## ✅ NEW FEATURES ADDED

### 1. Auto-Delete Expired Notifications (TTL)
- **Default TTL**: 30 days
- Notifications automatically removed after expiry
- Cleanup happens on app startup
- Expired notifications filtered from all views

### 2. Notification Detail Screen
- Click any notification to see full details
- Expandable message body (for long messages)
- Shows received date and expiry date
- Delete button in app bar

### 3. Link Detection & Buttons
- **Automatic URL detection** in message body
- **Custom action buttons** from OneSignal data
- **Multiple link support**:
  - Primary action button (from `action_url` + `button_text`)
  - Additional links (from `url` field)
  - URLs found in message text
- All links open in external browser

### 4. Deep Linking
- Clicking notification from system tray opens detail screen
- Automatic navigation to notification detail
- Mark as read automatically when opened

---

## 📱 HOW IT WORKS

### When User Clicks Notification in System Tray:
1. App opens (or comes to foreground)
2. Automatically navigates to notification detail screen
3. Shows full message with expand/collapse
4. Displays all links as clickable buttons
5. Marks notification as read

### When User Clicks Notification in App:
1. Opens notification detail screen
2. Same features as above

### Auto-Cleanup:
- Every time app starts, expired notifications are removed
- Default: notifications deleted after 30 days
- Can be customized per notification via `ttlDays` field

---

## 🎯 SENDING NOTIFICATIONS WITH LINKS

### From OneSignal Dashboard:

**Basic Notification:**
```
Title: New Event Tomorrow
Message: Join us for meditation session at 6 PM
```

**Notification with Action Button:**
```
Title: New Video Available
Message: Watch Guruji's latest teaching

Additional Data:
{
  "action_url": "https://youtube.com/watch?v=xyz",
  "button_text": "Watch Now"
}
```

**Notification with Multiple Links:**
```
Title: Event Registration Open
Message: Register now for the upcoming retreat

Additional Data:
{
  "action_url": "https://example.com/register",
  "button_text": "Register Now",
  "url": "https://example.com/event-details"
}
```

**Notification with URL in Body:**
```
Title: Check This Out
Message: Visit our website https://example.com for more info
```
The URL will be automatically detected and shown as a clickable link.

---

## 🔧 ONESIGNAL DASHBOARD SETUP

### To Send Notification with Links:

1. Go to: https://dashboard.onesignal.com/apps/b89d199e-15be-4343-9e04-640c43f355e9/messages/new
2. Write your message
3. Click "Additional Data" section
4. Add key-value pairs:
   - Key: `action_url`, Value: `https://your-link.com`
   - Key: `button_text`, Value: `Open Link` (or any text)
5. Send notification

### Example Additional Data:
```json
{
  "action_url": "https://sivakundalini.org/events",
  "button_text": "View Event Details",
  "screen": "events"
}
```

---

## 📋 NOTIFICATION BEHAVIOR

### In Notification List:
- Shows title, preview (2 lines), and time
- Unread notifications have blue dot and highlighted background
- Swipe left to delete
- Tap to open detail screen

### In Detail Screen:
- Full title and message
- Expand/collapse for long messages (>150 chars)
- All links shown as buttons:
  - Primary action button (blue, filled)
  - Additional links (blue, outlined)
  - URLs in text (blue boxes with underline)
- Shows received date and expiry date
- Delete button in top right

### Auto-Cleanup:
- Runs on app startup
- Removes notifications older than 30 days
- Expired notifications don't appear in list
- Logs cleanup activity: `🗑️ Removed X expired notifications`

---

## 🧪 TESTING

### Test 1: Basic Notification
1. Send notification from OneSignal Dashboard
2. Tap notification from system tray
3. Should open app and show detail screen
4. Verify full message is displayed

### Test 2: Notification with Link
1. Send notification with `action_url` and `button_text` in Additional Data
2. Open notification
3. Should see action button
4. Tap button - should open URL in browser

### Test 3: Multiple Links
1. Send notification with both `action_url` and `url` in Additional Data
2. Open notification
3. Should see two buttons
4. Both should work

### Test 4: URL in Message Body
1. Send notification with URL in the message text
2. Open notification
3. URL should be detected and shown as clickable link

### Test 5: TTL Cleanup
1. Wait 30 days (or modify TTL for testing)
2. Restart app
3. Old notifications should be auto-deleted

---

## 🎨 UI FEATURES

- Clean, modern design
- Smooth animations
- Unread badge on notification icon
- Swipe to delete
- Pull to refresh
- Empty state with helpful message
- Expandable long messages
- Color-coded link buttons
- Timestamp formatting (Just now, 5m ago, 2h ago, etc.)

---

## 📦 FRESH APK READY

**Location**: `build/app/outputs/flutter-apk/app-release.apk` (132.2 MB)

**Install Instructions:**
1. Uninstall old app from device
2. Transfer and install new APK
3. Grant permissions
4. Send test notification from OneSignal
5. Tap notification - should open detail screen
6. Test all link buttons

---

## 🔍 WHAT TO CHECK

### In OneSignal Dashboard:
- Device appears in Audience → Subscriptions
- Shows Subscription ID, device model, last active
- Tags visible: auth_provider, has_camera, has_microphone

### In App:
- Notifications appear in notification tab
- Tap notification opens detail screen
- Links are clickable
- Swipe to delete works
- Unread count badge shows correctly

### In System Tray:
- Tap notification opens app
- Navigates to detail screen automatically
- Message fully displayed with all links

---

**Configuration:**
- OneSignal App ID: `b89d199e-15be-4343-9e04-640c43f355e9`
- Firebase Project: `sks-login-mobile`
- Package Name: `com.spiritual.app`
- TTL: 30 days (auto-cleanup)
