# 🔔 Notification Testing Guide

## ✅ Implementation Complete

All notification features have been implemented and are ready for testing.

## 📋 What's Been Implemented

### 1. Notification Storage Service
- ✅ Stores notifications locally using SharedPreferences
- ✅ Keeps last 100 notifications
- ✅ Tracks read/unread status
- ✅ Supports mark as read, delete, and clear all
- ✅ Real-time listener updates

### 2. Updated Notifications Page
- ✅ Displays all stored notifications
- ✅ Shows unread count badge in app bar
- ✅ Pull-to-refresh functionality
- ✅ Swipe-to-delete notifications
- ✅ Tap to mark as read
- ✅ "Mark all as read" button
- ✅ "Clear all" option in menu
- ✅ Empty state when no notifications
- ✅ Time formatting (Just now, 5m ago, 2h ago, etc.)
- ✅ Visual distinction for unread notifications

### 3. OneSignal Integration
- ✅ Automatically stores notifications when received
- ✅ Works for both foreground and background notifications
- ✅ Stores notification click events
- ✅ Tracks additional data for deep linking

## 🧪 Testing Steps

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Run the App
```bash
flutter run
```

### Step 3: Complete Permission Flow
1. Open the app
2. Login or skip login
3. You'll be taken to notification permission screen
4. Click "Allow Notifications"
5. Grant system permission when prompted
6. You'll be redirected to home screen

### Step 4: Send Test Notification from OneSignal

#### Option A: OneSignal Dashboard
1. Go to https://app.onesignal.com
2. Select your app: "sks-mobile-notifications"
3. Click "Messages" → "New Push"
4. Fill in:
   - **Title**: "Welcome to SKS"
   - **Message**: "Stay connected with Guruji's teachings"
   - **Audience**: "Send to All Subscribed Users"
5. Click "Send Message"

#### Option B: OneSignal API (Advanced)
```bash
curl --request POST \
  --url https://onesignal.com/api/v1/notifications \
  --header 'Authorization: Basic YOUR_REST_API_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "app_id": "YOUR_ONESIGNAL_APP_ID",
    "included_segments": ["All"],
    "contents": {"en": "Stay connected with Guruji'\''s teachings"},
    "headings": {"en": "Welcome to SKS"}
  }'
```

### Step 5: Verify Notification Received
1. You should see the notification in:
   - System notification tray (Android/iOS)
   - App notification badge (if app is in background)
2. Check console logs for:
   ```
   📬 Notification received in foreground: [notification_id]
   ✅ Notification stored: Welcome to SKS
   ```

### Step 6: Test Notifications Page
1. Tap the bell icon in the app bar
2. You should see:
   - The notification you just received
   - Unread count badge (red number)
   - Blue dot next to unread notifications
   - Light blue background for unread items

### Step 7: Test Interactions

#### Mark as Read
- Tap on any unread notification
- Blue dot should disappear
- Background should turn white
- Unread count should decrease

#### Mark All as Read
- Tap "Mark all read" button in app bar
- All notifications should be marked as read
- Unread count badge should disappear

#### Delete Notification
- Swipe left on any notification
- Red delete background appears
- Swipe fully to delete
- Notification is removed from list

#### Clear All
- Tap the three-dot menu in app bar
- Select "Clear all"
- Confirm in dialog
- All notifications are deleted
- Empty state is shown

## 🎯 Expected Behavior

### When App is in Foreground
- Notification appears in system tray
- Notification is stored automatically
- Bell icon shows unread count
- Console shows: "📬 Notification received in foreground"

### When App is in Background
- Notification appears in system tray
- User taps notification
- App opens
- Notification is stored
- Console shows: "📱 Notification clicked"

### When App is Closed
- Notification appears in system tray
- User taps notification
- App launches
- Notification is stored
- User can see it in notifications page

## 🔍 Troubleshooting

### Notifications Not Appearing in List
1. Check console for storage errors
2. Verify SharedPreferences is working:
   ```dart
   debugPrint('Stored notifications: ${NotificationStorageService().getAll().length}');
   ```
3. Check if OneSignal is initialized:
   ```dart
   debugPrint('OneSignal initialized: ${OneSignalService()._isInitialized}');
   ```

### Unread Count Not Updating
- Pull down to refresh the notifications page
- Check if listener is properly attached
- Verify notification is marked as `isRead: false` when stored

### Swipe to Delete Not Working
- Ensure you're swiping from right to left
- Swipe fully across the screen
- Check console for delete confirmation

### Permission Issues
- Go to device Settings → Apps → SKS → Notifications
- Ensure notifications are enabled
- Try revoking and re-granting permission

## 📊 Testing Checklist

- [ ] Install dependencies (`flutter pub get`)
- [ ] Run app successfully
- [ ] Complete permission flow
- [ ] Send test notification from OneSignal
- [ ] Notification appears in system tray
- [ ] Notification appears in notifications page
- [ ] Unread count badge shows correctly
- [ ] Tap notification marks it as read
- [ ] Swipe to delete works
- [ ] Mark all as read works
- [ ] Clear all works
- [ ] Empty state shows when no notifications
- [ ] Pull to refresh works
- [ ] Time formatting is correct
- [ ] Visual distinction for unread notifications

## 🎨 UI Features

### Unread Notification
- Light blue background
- Blue dot indicator
- Bold title text

### Read Notification
- White background
- No dot indicator
- Normal weight title text

### Time Display
- "Just now" - less than 1 minute
- "5m ago" - less than 1 hour
- "2h ago" - less than 24 hours
- "3d ago" - less than 7 days
- "Jan 15, 2026" - older than 7 days

## 🚀 Production Ready Features

✅ Persistent storage (survives app restart)
✅ Efficient storage (max 100 notifications)
✅ Real-time updates (listener pattern)
✅ Swipe gestures (native feel)
✅ Pull to refresh (standard UX)
✅ Confirmation dialogs (prevent accidents)
✅ Empty states (good UX)
✅ Unread tracking (engagement)
✅ Time formatting (user-friendly)
✅ Deep linking support (future-ready)

## 📱 Next Steps

1. Test on physical device (not just emulator)
2. Test with multiple notifications
3. Test app restart (verify persistence)
4. Test with different notification types
5. Implement deep linking for notification taps
6. Add notification categories/filters (optional)
7. Add notification search (optional)
8. Configure iOS APNs for iOS notifications

## 🔗 Related Documentation

- [ONESIGNAL_IMPLEMENTATION_SUMMARY.md](ONESIGNAL_IMPLEMENTATION_SUMMARY.md)
- [FIREBASE_ONESIGNAL_SETUP_GUIDE.md](FIREBASE_ONESIGNAL_SETUP_GUIDE.md)
- [NOTIFICATION_PERMISSION_TROUBLESHOOTING.md](NOTIFICATION_PERMISSION_TROUBLESHOOTING.md)
- [COMPLETE_IMPLEMENTATION_SUMMARY.md](COMPLETE_IMPLEMENTATION_SUMMARY.md)
