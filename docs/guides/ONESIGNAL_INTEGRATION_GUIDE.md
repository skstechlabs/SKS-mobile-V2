# OneSignal Push Notifications Integration Guide

## Overview
OneSignal is fully integrated with strict notification permission requirements. Users MUST allow notifications to use the app.

## Features Implemented
✅ OneSignal SDK initialization
✅ Mandatory notification permission screen
✅ User tracking with external user ID (Firebase UID)
✅ User tagging for targeted notifications
✅ Notification click tracking
✅ Notification view tracking (foreground)
✅ Permission state monitoring
✅ Subscription state monitoring
✅ Deep linking support
✅ Logout handling (removes user ID)

## Setup Instructions

### 1. Create OneSignal Account
1. Go to https://onesignal.com/
2. Create a free account
3. Create a new app
4. Get your OneSignal App ID

### 2. Configure Android
1. In OneSignal dashboard, go to Settings > Platforms
2. Click "Google Android (FCM)"
3. Upload your Firebase Server Key or google-services.json
4. Save configuration

### 3. Configure iOS (if needed)
1. In OneSignal dashboard, go to Settings > Platforms
2. Click "Apple iOS (APNs)"
3. Upload your APNs certificate or key
4. Save configuration

### 4. Update Environment Variables
Edit `.env.json`:
```json
{
  "ONESIGNAL_APP_ID": "your_onesignal_app_id_here"
}
```

### 5. Run the App
```bash
flutter pub get
flutter run --dart-define-from-file=.env.json
```

## User Flow

```
Login → Profile Setup → Permissions → NOTIFICATION PERMISSION (MANDATORY) → Home
```

### Notification Permission Screen
- User CANNOT skip this screen
- User CANNOT go back
- Strict message: "To connect with Guruji you need to allow notifications"
- If denied, shows dialog forcing user to allow

## OneSignal Service API

### Initialize
```dart
await OneSignalService().initialize();
```

### Set External User ID (after login)
```dart
await OneSignalService().setExternalUserId(user.uid);
```

### Set User Tags
```dart
await OneSignalService().setTags({
  'auth_provider': 'phone',
  'mobile': '+919876543210',
  'state': 'Telangana',
});
```

### Remove User ID (on logout)
```dart
await OneSignalService().removeExternalUserId();
```

### Check Permission
```dart
final hasPermission = await OneSignalService().hasPermission();
```

### Get Player ID
```dart
final playerId = OneSignalService().playerId;
```

## Sending Notifications from OneSignal Dashboard

### 1. Send to All Users
1. Go to Messages > New Push
2. Select "Send to All Subscribers"
3. Enter title and message
4. Click Send

### 2. Send to Specific User
1. Go to Messages > New Push
2. Select "Send to Particular Segment"
3. Add filter: "External User ID" = "firebase_uid"
4. Enter title and message
5. Click Send

### 3. Send to Users with Tags
1. Go to Messages > New Push
2. Select "Send to Particular Segment"
3. Add filter: "User Tag" = "state" = "Telangana"
4. Enter title and message
5. Click Send

### 4. Send with Deep Link
1. Go to Messages > New Push
2. Enter title and message
3. Click "Advanced Settings"
4. Add "Additional Data":
   - Key: `screen`, Value: `events`
   - Key: `url`, Value: `https://example.com`
5. Click Send

## Notification Types

### 1. Simple Notification
```json
{
  "app_id": "your_app_id",
  "included_segments": ["All"],
  "contents": {"en": "New event tomorrow!"},
  "headings": {"en": "Upcoming Event"}
}
```

### 2. Notification with Deep Link
```json
{
  "app_id": "your_app_id",
  "included_segments": ["All"],
  "contents": {"en": "Check out new learnings"},
  "headings": {"en": "New Content"},
  "data": {
    "screen": "learnings"
  }
}
```

### 3. Notification to Specific User
```json
{
  "app_id": "your_app_id",
  "include_external_user_ids": ["firebase_uid_123"],
  "contents": {"en": "Your profile is complete!"},
  "headings": {"en": "Welcome"}
}
```

### 4. Notification with Image
```json
{
  "app_id": "your_app_id",
  "included_segments": ["All"],
  "contents": {"en": "New wisdom shared"},
  "headings": {"en": "Daily Wisdom"},
  "big_picture": "https://example.com/image.jpg"
}
```

## Tracking & Analytics

### Notification Clicked
Automatically tracked when user taps notification.
View in OneSignal Dashboard > Delivery > Click Rate

### Notification Viewed
Automatically tracked when notification is displayed.
View in OneSignal Dashboard > Delivery > Delivery Rate

### User Subscription Status
View in OneSignal Dashboard > Audience > All Users

### User Tags
View in OneSignal Dashboard > Audience > All Users > Click on user

## Testing

### Test on Android
```bash
flutter run --dart-define-from-file=.env.json
```

### Test on iOS
```bash
flutter run --dart-define-from-file=.env.json -d ios
```

### Send Test Notification
1. Complete login flow
2. Allow notification permission
3. Go to OneSignal Dashboard
4. Messages > New Push
5. Select "Send to Test Users"
6. Enter your device's Player ID
7. Send notification

## Troubleshooting

### Notifications not received
- Check OneSignal App ID is correct
- Verify Firebase configuration
- Check device has internet connection
- Verify notification permission is granted
- Check OneSignal Dashboard > Delivery for errors

### External User ID not set
- Check login flow completes successfully
- Verify `setExternalUserId()` is called after login
- Check OneSignal Dashboard > Audience > User details

### Tags not appearing
- Verify `setTags()` is called after login
- Check OneSignal Dashboard > Audience > User details
- Wait a few seconds for tags to sync

## Best Practices

1. **Always set external user ID** after successful login
2. **Set meaningful tags** for better targeting
3. **Test notifications** before sending to all users
4. **Use deep links** to navigate users to specific screens
5. **Monitor analytics** to improve engagement
6. **Remove user ID** on logout for privacy
7. **Handle notification clicks** to provide good UX

## Security

- External User ID is Firebase UID (secure)
- Tags don't contain sensitive information
- Notifications are sent via OneSignal's secure API
- User can opt out anytime (but app requires it)

## Production Checklist

- [ ] OneSignal App ID configured in `.env.prod.json`
- [ ] Firebase FCM configured in OneSignal
- [ ] APNs configured for iOS (if applicable)
- [ ] Test notifications on real devices
- [ ] Verify click tracking works
- [ ] Verify deep linking works
- [ ] Test logout removes user ID
- [ ] Monitor delivery rates in dashboard
