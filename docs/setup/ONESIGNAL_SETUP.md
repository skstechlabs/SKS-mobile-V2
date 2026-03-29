# OneSignal Setup - Step by Step

## Step 1: Create OneSignal Account

1. Visit https://onesignal.com/
2. Click "Get Started Free"
3. Sign up with email or Google
4. Verify your email

## Step 2: Create New App

1. Click "New App/Website"
2. Enter app name: "SKS Spiritual App"
3. Select "Mobile App"
4. Click "Next"

## Step 3: Configure Android Platform

### Option A: Using Firebase (Recommended)

1. In OneSignal dashboard, select "Google Android (FCM)"
2. Click "Configuration"
3. You need Firebase Server Key:
   - Go to Firebase Console
   - Select your project
   - Click Settings (gear icon) > Project Settings
   - Go to "Cloud Messaging" tab
   - Copy "Server Key"
4. Paste Server Key in OneSignal
5. Click "Save"

### Option B: Using google-services.json

1. Upload your `google-services.json` file
2. OneSignal will extract the Server Key automatically
3. Click "Save"

## Step 4: Get OneSignal App ID

1. In OneSignal dashboard, go to Settings > Keys & IDs
2. Copy "OneSignal App ID"
3. It looks like: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

## Step 5: Update Flutter App

1. Open `.env.json`
2. Replace `your_onesignal_app_id_here` with your actual App ID:
```json
{
  "ONESIGNAL_APP_ID": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

3. Save the file

## Step 6: Install Dependencies

```bash
flutter pub get
```

## Step 7: Run the App

```bash
flutter run --dart-define-from-file=.env.json
```

## Step 8: Test Notification

### Complete the Flow
1. Open app
2. Login with phone or Google
3. Complete profile
4. Grant camera/microphone permissions
5. **MUST** allow notification permission
6. App opens to home screen

### Send Test Notification
1. Go to OneSignal Dashboard
2. Click "Messages" > "New Push"
3. Select "Send to All Subscribers"
4. Enter:
   - Title: "Welcome to SKS"
   - Message: "Your spiritual journey begins now"
5. Click "Review"
6. Click "Send Message"
7. Check your device for notification

## Step 9: Verify Integration

### Check User in Dashboard
1. Go to OneSignal Dashboard > Audience > All Users
2. You should see your device listed
3. Click on the user to see:
   - Player ID
   - External User ID (your Firebase UID)
   - Tags (auth_provider, mobile, etc.)
   - Subscription status

### Check Notification Delivery
1. Go to OneSignal Dashboard > Delivery
2. Click on your sent message
3. Verify:
   - Sent: 1
   - Delivered: 1
   - Clicked: (if you clicked it)

## Step 10: Configure iOS (Optional)

If you're building for iOS:

1. In OneSignal dashboard, select "Apple iOS (APNs)"
2. You need APNs certificate or key:
   - Go to Apple Developer Portal
   - Create APNs certificate
   - Download and upload to OneSignal
3. Click "Save"

## Common Issues & Solutions

### Issue: Notifications not received

**Solution:**
- Verify OneSignal App ID is correct
- Check Firebase Server Key is valid
- Ensure notification permission is granted
- Check device has internet connection
- Verify app is in foreground or background (not killed)

### Issue: "Invalid App ID" error

**Solution:**
- Double-check App ID in `.env.json`
- Ensure no extra spaces or quotes
- Restart the app after changing `.env.json`

### Issue: External User ID not showing

**Solution:**
- Complete full login flow
- Check `setExternalUserId()` is called
- Wait a few seconds for sync
- Refresh OneSignal dashboard

### Issue: Tags not appearing

**Solution:**
- Verify `setTags()` is called after login
- Wait 10-15 seconds for sync
- Refresh OneSignal dashboard
- Check network connection

## Production Deployment

### Update Production Config

1. Create `.env.prod.json` if not exists
2. Add production OneSignal App ID:
```json
{
  "ONESIGNAL_APP_ID": "your_production_app_id"
}
```

### Build for Production

```bash
# Android
flutter build apk --dart-define-from-file=.env.prod.json --release

# iOS
flutter build ios --dart-define-from-file=.env.prod.json --release
```

## Next Steps

1. ✅ Test notifications on multiple devices
2. ✅ Set up user segments for targeted messaging
3. ✅ Create notification templates
4. ✅ Schedule recurring notifications
5. ✅ Monitor analytics and engagement
6. ✅ Implement deep linking for specific screens
7. ✅ A/B test notification content

## Support

- OneSignal Documentation: https://documentation.onesignal.com/
- OneSignal Support: https://onesignal.com/support
- Flutter Plugin: https://github.com/OneSignal/OneSignal-Flutter-SDK

## Summary

You now have:
- ✅ OneSignal fully integrated
- ✅ Mandatory notification permission
- ✅ User tracking with Firebase UID
- ✅ User tagging for targeting
- ✅ Click and view tracking
- ✅ Deep linking support
- ✅ Production-ready setup

Your app will NOT open unless user allows notifications!
