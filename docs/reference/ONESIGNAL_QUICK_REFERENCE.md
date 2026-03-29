# OneSignal Quick Reference Card

## 🚀 Quick Start (5 Minutes)

### 1. Get OneSignal App ID
```
1. Go to onesignal.com
2. Create account & app
3. Configure Android (FCM)
4. Copy App ID from Settings > Keys & IDs
```

### 2. Configure App
```json
// .env.json
{
  "ONESIGNAL_APP_ID": "paste_your_app_id_here"
}
```

### 3. Run
```bash
flutter pub get
flutter run --dart-define-from-file=.env.json
```

### 4. Test
```
1. Complete login flow
2. Allow notification permission (MANDATORY)
3. Go to OneSignal Dashboard > Messages > New Push
4. Send to All Subscribers
5. Check your device
```

## 📱 User Flow

```
Login → Profile → Permissions → NOTIFICATION (MUST!) → Home
```

**User CANNOT use app without allowing notifications!**

## 🔧 Common Tasks

### Send Notification to All
```
Dashboard > Messages > New Push
Audience: All Subscribers
Title: "Your Title"
Message: "Your Message"
Send
```

### Send to Specific User
```
Dashboard > Messages > New Push
Audience: Particular Segment
Filter: External User ID = firebase_uid
Send
```

### Send with Deep Link
```
Dashboard > Messages > New Push
Advanced Settings > Additional Data
Key: screen, Value: events
Send
```

### Check User in Dashboard
```
Dashboard > Audience > All Users
Click on user to see:
- Player ID
- External User ID
- Tags
- Subscription status
```

## 💻 Code Snippets

### Initialize (Already Done)
```dart
// In main.dart
await OneSignalService().initialize();
```

### Set User ID (Already Done)
```dart
// After login
await OneSignalService().setExternalUserId(user.uid);
```

### Set Tags
```dart
await OneSignalService().setTags({
  'state': 'Telangana',
  'language': 'English',
});
```

### Check Permission
```dart
final hasPermission = await OneSignalService().hasPermission();
```

### Get Player ID
```dart
final playerId = OneSignalService().playerId;
```

## 📊 Key Metrics

### Good Benchmarks
- Delivery Rate: >95%
- Open Rate: >20%
- Click Rate: >5%

### Check in Dashboard
```
Dashboard > Delivery > Overview
```

## 🎯 Targeting Options

### By User ID
```
External User ID = firebase_uid_123
```

### By Tag
```
Tag "state" = "Telangana"
Tag "auth_provider" = "phone"
```

### By Segment
```
All Subscribers
Active Users
Inactive Users (custom)
```

## ⏰ Scheduling

### One-Time
```
Send After: 2024-03-29 06:00:00 GMT+0530
```

### Recurring
```
Daily at 6:00 AM
Weekly on Sunday
Monthly on 1st
```

## 🔗 Deep Linking

### Navigate to Screen
```json
{
  "data": {
    "screen": "events"
  }
}
```

### Open URL
```json
{
  "data": {
    "url": "https://example.com"
  }
}
```

## 🐛 Quick Troubleshooting

### Not Receiving Notifications?
1. Check App ID is correct
2. Verify permission granted
3. Check internet connection
4. Restart app

### User ID Not Showing?
1. Complete login flow
2. Wait 10 seconds
3. Refresh dashboard

### Tags Not Appearing?
1. Verify setTags() called
2. Wait 15 seconds
3. Refresh dashboard

## 📞 Support Links

- Setup Guide: `ONESIGNAL_SETUP.md`
- Full Documentation: `ONESIGNAL_INTEGRATION_GUIDE.md`
- Examples: `ONESIGNAL_NOTIFICATION_EXAMPLES.md`
- OneSignal Docs: https://documentation.onesignal.com/

## ✅ Pre-Launch Checklist

- [ ] App ID configured
- [ ] Test notification sent
- [ ] Test notification received
- [ ] Click tracking works
- [ ] User ID visible in dashboard
- [ ] Tags visible in dashboard
- [ ] Deep linking works
- [ ] Logout removes user ID

## 🎉 You're Ready!

Your app now has:
- ✅ Mandatory notification permission
- ✅ User tracking
- ✅ Click tracking
- ✅ Deep linking
- ✅ Tag-based targeting
- ✅ Production-ready setup

**Send your first notification now!** 🚀
