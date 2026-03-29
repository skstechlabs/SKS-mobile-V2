# Notification Permission Troubleshooting Guide

## 🐛 Common Issues & Solutions

### Issue 1: "Failed to request notification permission"

#### Possible Causes:
1. OneSignal App ID not configured
2. OneSignal not initialized properly
3. Internet connection issues
4. Google Play Services not installed (Android)
5. Firebase configuration missing

#### Solutions:

**Step 1: Verify OneSignal App ID**
```bash
# Check .env.json
cat .env.json | grep ONESIGNAL_APP_ID

# Should show:
# "ONESIGNAL_APP_ID": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# If empty or "your_onesignal_app_id_here", update it!
```

**Step 2: Check Console Logs**
```bash
# Run app with verbose logging
flutter run --dart-define-from-file=.env.json

# Look for these messages:
# ✅ OneSignal initialized successfully with App ID: xxx
# 🔔 Requesting notification permission...
# ✅ Notification permission granted
```

**Step 3: Verify Firebase Configuration**
```bash
# Check files exist
ls android/app/google-services.json
ls ios/Runner/GoogleService-Info.plist

# If missing, download from Firebase Console
```

**Step 4: Check Internet Connection**
- Make sure device has active internet
- Try on WiFi and mobile data
- Check firewall settings

**Step 5: Verify Google Play Services (Android)**
```bash
# On Android device:
# Settings > Apps > Google Play Services
# Make sure it's enabled and updated
```

---

### Issue 2: Permission Dialog Not Appearing

#### Cause:
Permission already denied or granted

#### Solution:

**Reset App Permissions:**

**Android:**
```
1. Settings > Apps > SKS
2. Permissions > Notifications
3. Toggle OFF then ON
4. Or: Clear app data and reinstall
```

**iOS:**
```
1. Settings > SKS
2. Notifications
3. Toggle OFF then ON
4. Or: Delete app and reinstall
```

---

### Issue 3: User Not Appearing in OneSignal Dashboard

#### Possible Causes:
1. Permission not granted
2. Internet connection issues
3. OneSignal App ID mismatch
4. Firebase Server Key not configured

#### Solutions:

**Step 1: Verify Permission Granted**
```dart
// Check in app logs:
// ✅ Notification permission granted
// ✅ Opted in to push notifications
```

**Step 2: Check OneSignal Configuration**
```
OneSignal Dashboard > Settings > Platforms
- Google Android (FCM): Should show "Configured"
- Firebase Server Key: Should be set
```

**Step 3: Wait and Refresh**
```
1. Wait 10-15 seconds after granting permission
2. Refresh OneSignal Dashboard
3. Go to Audience > All Users
4. User should appear
```

**Step 4: Check Player ID**
```dart
// In app logs, look for:
// 📊 Push subscription state changed
//    - ID: abc123...
//    - Token: def456...
//    - Opted In: true
```

---

### Issue 4: Notifications Not Received

#### After Permission Granted

**Step 1: Verify Subscription**
```
OneSignal Dashboard > Audience > All Users
Click on your user:
- Subscription: Should say "Subscribed"
- Last Active: Should be recent
```

**Step 2: Send Test Notification**
```
OneSignal Dashboard > Messages > New Push
Audience: Send to All Subscribers
Title: Test
Message: Testing notifications
Send
```

**Step 3: Check Device**
```
- Notification should appear in 5-10 seconds
- Check notification tray
- Try with app in foreground, background, and closed
```

**Step 4: Check Logs**
```dart
// Look for:
// 📬 Notification received in foreground
// 📱 Notification clicked
```

---

### Issue 5: Layout/Responsive Issues

#### Symptoms:
- Content cut off
- Buttons not visible
- Scrolling issues

#### Solution:
Already fixed in latest code with:
- `LayoutBuilder` for responsive layout
- `SingleChildScrollView` for scrolling
- `ConstrainedBox` for proper sizing
- `IntrinsicHeight` for flexible height

---

## 🧪 Testing Checklist

### Before Testing
- [ ] OneSignal App ID configured in .env.json
- [ ] Firebase google-services.json in place
- [ ] Firebase Server Key added to OneSignal
- [ ] Internet connection active
- [ ] Google Play Services installed (Android)

### During Testing
- [ ] App runs without errors
- [ ] OneSignal initialization message appears
- [ ] Notification permission screen displays correctly
- [ ] Click "Allow Notifications" button
- [ ] System permission dialog appears
- [ ] Grant permission
- [ ] Success message or navigation to home
- [ ] Check console logs for success messages

### After Testing
- [ ] User appears in OneSignal Dashboard
- [ ] Subscription status is "Subscribed"
- [ ] Send test notification
- [ ] Notification received on device
- [ ] Click notification opens app
- [ ] Check analytics in OneSignal

---

## 📊 Debug Logs to Check

### Successful Flow:
```
✅ OneSignal initialized successfully with App ID: xxx
🔔 Requesting notification permission...
🔔 Permission granted: true
✅ Notification permission granted
✅ Opted in to push notifications
💾 Saving permissions to backend...
✅ Permissions saved to backend
🏠 Navigating to home screen
📊 Push subscription state changed
   - ID: abc123...
   - Token: def456...
   - Opted In: true
```

### Failed Flow:
```
❌ OneSignal initialization failed: ...
❌ Error requesting notification permission: ...
❌ Permission granted: false
⚠️ Failed to save permissions to backend: ...
```

---

## 🔧 Quick Fixes

### Fix 1: Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter run --dart-define-from-file=.env.json
```

### Fix 2: Reset App Data
```bash
# Android
adb shell pm clear com.spiritual.app

# Then reinstall
flutter run --dart-define-from-file=.env.json
```

### Fix 3: Verify Configuration
```bash
# Check OneSignal App ID
grep ONESIGNAL_APP_ID .env.json

# Check Firebase files
ls -la android/app/google-services.json
ls -la ios/Runner/GoogleService-Info.plist
```

### Fix 4: Check OneSignal Dashboard
```
1. Settings > Platforms > Google Android (FCM)
2. Should show "Configured" with green checkmark
3. If not, re-add Firebase Server Key
```

---

## 🎯 Verification Steps

### Step 1: Check Initialization
```dart
// Should see in logs:
✅ OneSignal initialized successfully with App ID: xxx
```

### Step 2: Check Permission Request
```dart
// Should see in logs:
🔔 Requesting notification permission...
🔔 Permission granted: true
```

### Step 3: Check Subscription
```dart
// Should see in logs:
📊 Push subscription state changed
   - Opted In: true
```

### Step 4: Check OneSignal Dashboard
```
Audience > All Users > Should see 1 user
Click on user:
- Player ID: ✓
- Subscription: Subscribed ✓
- Last Active: Just now ✓
```

### Step 5: Test Notification
```
Messages > New Push > Send to All
Wait 5-10 seconds
Check device notification tray ✓
```

---

## 📞 Still Having Issues?

### Collect Debug Information:

1. **App Logs**
   ```bash
   flutter run --dart-define-from-file=.env.json > app_logs.txt 2>&1
   ```

2. **Configuration**
   ```bash
   # Check .env.json (remove sensitive data)
   cat .env.json
   
   # Check OneSignal App ID
   grep ONESIGNAL_APP_ID .env.json
   ```

3. **OneSignal Dashboard**
   - Screenshot of Settings > Platforms
   - Screenshot of Audience > All Users
   - Screenshot of any error messages

4. **Device Information**
   - Android version or iOS version
   - Device model
   - Google Play Services version (Android)

---

## ✅ Success Criteria

You know it's working when:
- ✅ No errors in console logs
- ✅ Permission dialog appears
- ✅ User grants permission
- ✅ App navigates to home screen
- ✅ User appears in OneSignal Dashboard
- ✅ Subscription status is "Subscribed"
- ✅ Test notification is received
- ✅ Clicking notification opens app

---

## 🎉 Common Success Patterns

### Pattern 1: First Time Setup
```
1. Configure OneSignal App ID
2. Run app
3. Grant permission
4. Receive notifications ✓
```

### Pattern 2: After Reset
```
1. Clear app data
2. Reinstall app
3. Grant permission again
4. Receive notifications ✓
```

### Pattern 3: Multiple Devices
```
1. Install on device 1 → Works ✓
2. Install on device 2 → Works ✓
3. Send to all → Both receive ✓
```

---

**Follow this guide to troubleshoot any notification permission issues!** 🚀
