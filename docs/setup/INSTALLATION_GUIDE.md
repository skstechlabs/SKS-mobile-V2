# Complete Installation Guide

## Prerequisites

- Flutter SDK installed
- Android Studio or VS Code
- Firebase project configured
- OneSignal account (free)

## Step 1: Install Dependencies

```bash
flutter pub get
```

This will install:
- `onesignal_flutter: ^5.2.5` - Push notifications
- `dio: ^5.4.0` - API calls
- `firebase_auth: ^5.3.1` - Authentication
- All other dependencies

## Step 2: Configure OneSignal

### 2.1 Create OneSignal Account
1. Go to https://onesignal.com/
2. Sign up for free account
3. Verify your email

### 2.2 Create New App
1. Click "New App/Website"
2. Name: "SKS Spiritual App"
3. Select "Mobile App"
4. Click "Next"

### 2.3 Configure Android
1. Select "Google Android (FCM)"
2. You need Firebase Server Key:
   - Go to Firebase Console
   - Select your project
   - Settings > Project Settings
   - Cloud Messaging tab
   - Copy "Server Key"
3. Paste in OneSignal
4. Click "Save & Continue"

### 2.4 Get App ID
1. Go to Settings > Keys & IDs
2. Copy "OneSignal App ID"
3. Format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

## Step 3: Configure Environment

### 3.1 Update .env.json
```json
{
  "MSG91_WIDGET_ID": "your_msg91_widget_id",
  "MSG91_AUTH_TOKEN": "your_msg91_auth_token",
  "API_BASE_URL": "http://localhost:3009",
  "FIREBASE_API_KEY": "your_firebase_api_key",
  "FIREBASE_AUTH_DOMAIN": "your-project.firebaseapp.com",
  "FIREBASE_PROJECT_ID": "your-project-id",
  "FIREBASE_STORAGE_BUCKET": "your-project.firebasestorage.app",
  "FIREBASE_MESSAGING_SENDER_ID": "your_sender_id",
  "FIREBASE_WEB_APP_ID": "your_web_app_id",
  "GOOGLE_CLIENT_ID": "your_google_client_id",
  "ONESIGNAL_APP_ID": "paste_your_onesignal_app_id_here"
}
```

### 3.2 Update .env.prod.json (for production)
```json
{
  "API_BASE_URL": "https://your-production-api.com",
  "ONESIGNAL_APP_ID": "your_production_onesignal_app_id"
}
```

## Step 4: Run the App

### Development
```bash
flutter run --dart-define-from-file=.env.json
```

### Production
```bash
flutter run --dart-define-from-file=.env.prod.json --release
```

## Step 5: Test the Integration

### 5.1 Complete User Flow
1. Open app
2. Click "Send OTP" or "Continue with Google"
3. Complete authentication
4. Fill profile information
5. Grant camera/microphone permissions
6. **MUST** allow notification permission
7. App opens to home screen

### 5.2 Verify in OneSignal Dashboard
1. Go to OneSignal Dashboard
2. Audience > All Users
3. You should see your device
4. Click on user to verify:
   - Player ID exists
   - External User ID = Firebase UID
   - Tags are set (auth_provider, mobile, etc.)
   - Subscription status = Subscribed

### 5.3 Send Test Notification
1. Messages > New Push
2. Audience: Send to All Subscribers
3. Title: "Test Notification"
4. Message: "Testing OneSignal integration"
5. Click "Send Message"
6. Check your device for notification

### 5.4 Test Notification Click
1. Tap the notification
2. App should open
3. Check console logs for click event

## Step 6: Backend Setup (Optional)

If you have a backend server:

### 6.1 Start Backend
```bash
cd backend
npm install
npm start
```

### 6.2 Verify API Endpoints
- POST /api/auth/login
- POST /api/user/profile
- POST /api/user/permissions

## Step 7: Build for Release

### Android APK
```bash
flutter build apk --dart-define-from-file=.env.prod.json --release
```

### Android App Bundle
```bash
flutter build appbundle --dart-define-from-file=.env.prod.json --release
```

### iOS
```bash
flutter build ios --dart-define-from-file=.env.prod.json --release
```

## Verification Checklist

- [ ] Dependencies installed (`flutter pub get`)
- [ ] OneSignal App ID configured in `.env.json`
- [ ] Firebase configured
- [ ] App runs without errors
- [ ] Login flow works
- [ ] Profile setup works
- [ ] Notification permission screen appears
- [ ] Permission MUST be granted to proceed
- [ ] User appears in OneSignal dashboard
- [ ] External User ID is set
- [ ] Tags are visible
- [ ] Test notification received
- [ ] Notification click works
- [ ] Backend API calls work (if applicable)

## Troubleshooting

### Issue: "ONESIGNAL_APP_ID not found"
**Solution:**
```bash
# Make sure you're running with --dart-define-from-file
flutter run --dart-define-from-file=.env.json
```

### Issue: Notifications not received
**Solution:**
1. Check App ID is correct
2. Verify Firebase Server Key in OneSignal
3. Ensure notification permission granted
4. Check device has internet
5. Restart app

### Issue: User ID not in dashboard
**Solution:**
1. Complete full login flow
2. Wait 10-15 seconds
3. Refresh OneSignal dashboard
4. Check console logs for errors

### Issue: Build errors
**Solution:**
```bash
flutter clean
flutter pub get
flutter run --dart-define-from-file=.env.json
```

### Issue: Firebase authentication fails
**Solution:**
1. Verify Firebase configuration
2. Check google-services.json (Android)
3. Check GoogleService-Info.plist (iOS)
4. Enable authentication methods in Firebase Console

## Next Steps

1. **Read Documentation**
   - `ONESIGNAL_README.md` - Overview
   - `ONESIGNAL_QUICK_REFERENCE.md` - Quick reference
   - `ONESIGNAL_SETUP.md` - Detailed setup
   - `ONESIGNAL_INTEGRATION_GUIDE.md` - Complete guide

2. **Send Your First Campaign**
   - Go to OneSignal Dashboard
   - Messages > New Push
   - Create your first notification

3. **Set Up Automation**
   - Daily wisdom at 6 AM
   - Event reminders
   - Welcome series
   - Re-engagement campaigns

4. **Monitor Analytics**
   - Delivery rates
   - Open rates
   - Click rates
   - User engagement

## Support

- **Documentation**: See all `ONESIGNAL_*.md` files
- **OneSignal Docs**: https://documentation.onesignal.com/
- **Flutter SDK**: https://documentation.onesignal.com/docs/flutter-sdk-setup
- **Support**: https://onesignal.com/support

## Success!

You now have a fully functional app with:
- ✅ Firebase authentication
- ✅ Backend API integration
- ✅ OneSignal push notifications
- ✅ Mandatory notification permission
- ✅ User tracking and analytics
- ✅ Production-ready setup

**Start connecting with your users through push notifications!** 🚀
