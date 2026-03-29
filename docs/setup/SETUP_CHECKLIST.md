# Setup Checklist - Quick Reference

## 🎯 Complete This Checklist in Order

### Phase 1: Firebase Setup (10 minutes)

- [ ] **1.1** Go to https://console.firebase.google.com/
- [ ] **1.2** Create project: `sks-mobile-notifications`
- [ ] **1.3** Disable Google Analytics (optional)
- [ ] **1.4** Click "Add app" → Select Android
- [ ] **1.5** Package name: `com.spiritual.app`
- [ ] **1.6** Download `google-services.json`
- [ ] **1.7** Click "Add app" → Select iOS
- [ ] **1.8** Bundle ID: `com.spiritual.app`
- [ ] **1.9** Download `GoogleService-Info.plist`
- [ ] **1.10** Go to Settings → Cloud Messaging
- [ ] **1.11** Enable Cloud Messaging API (V1)
- [ ] **1.12** Copy Firebase Server Key (Legacy)

### Phase 2: Flutter Project Configuration (5 minutes)

- [ ] **2.1** Copy `google-services.json` to `android/app/`
- [ ] **2.2** Edit `android/build.gradle` - Add google-services classpath
- [ ] **2.3** Edit `android/app/build.gradle` - Add google-services plugin
- [ ] **2.4** Copy `GoogleService-Info.plist` to `ios/Runner/`
- [ ] **2.5** Open `ios/Runner.xcworkspace` in Xcode
- [ ] **2.6** Add `GoogleService-Info.plist` to Xcode project

### Phase 3: OneSignal Configuration (5 minutes)

- [ ] **3.1** Go to https://onesignal.com/
- [ ] **3.2** Select your app (or create new)
- [ ] **3.3** Go to Settings → Platforms
- [ ] **3.4** Click "Google Android (FCM)"
- [ ] **3.5** Paste Firebase Server Key
- [ ] **3.6** Click "Save & Continue"
- [ ] **3.7** Go to Settings → Keys & IDs
- [ ] **3.8** Copy OneSignal App ID
- [ ] **3.9** Update `.env.json` with App ID

### Phase 4: Testing (5 minutes)

- [ ] **4.1** Run: `flutter clean`
- [ ] **4.2** Run: `flutter pub get`
- [ ] **4.3** Run: `flutter run --dart-define-from-file=.env.json`
- [ ] **4.4** Complete login flow
- [ ] **4.5** Allow notification permission
- [ ] **4.6** Check OneSignal Dashboard → Audience
- [ ] **4.7** Verify user appears with External User ID
- [ ] **4.8** Send test notification from OneSignal
- [ ] **4.9** Receive notification on device
- [ ] **4.10** Tap notification to open app

---

## ✅ Quick Verification

### Files in Place?
```bash
# Check Android
ls android/app/google-services.json

# Check iOS
ls ios/Runner/GoogleService-Info.plist

# Check .env.json
cat .env.json | grep ONESIGNAL_APP_ID
```

### Configuration Correct?

**android/build.gradle** should have:
```gradle
classpath 'com.google.gms:google-services:4.4.0'
```

**android/app/build.gradle** should have at bottom:
```gradle
apply plugin: 'com.google.gms.google-services'
```

**.env.json** should have:
```json
{
  "ONESIGNAL_APP_ID": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

---

## 🎯 Success Criteria

✅ App runs without errors  
✅ Login flow completes  
✅ Notification permission granted  
✅ User appears in OneSignal dashboard  
✅ External User ID is set  
✅ Tags are visible  
✅ Test notification received  
✅ Notification click opens app  

---

## 🚨 Common Mistakes to Avoid

❌ Placing `google-services.json` in wrong folder  
✅ Must be in `android/app/` not `android/`

❌ Forgetting to add GoogleService-Info.plist to Xcode  
✅ Must add via Xcode, not just copy file

❌ Using wrong package name  
✅ Must be exactly: `com.spiritual.app`

❌ Not enabling Cloud Messaging API  
✅ Must enable in Google Cloud Console

❌ Copying wrong key from Firebase  
✅ Use "Server key" from "Cloud Messaging API (Legacy)"

❌ Not updating .env.json  
✅ Must paste actual OneSignal App ID

---

## 📞 Need Help?

See detailed guide: `FIREBASE_ONESIGNAL_SETUP_GUIDE.md`

---

**Print this checklist and check off items as you complete them!** ✓
