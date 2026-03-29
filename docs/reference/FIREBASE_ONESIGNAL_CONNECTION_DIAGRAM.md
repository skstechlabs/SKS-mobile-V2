# Firebase + OneSignal Connection Diagram

## 🔄 How Everything Connects

```
┌─────────────────────────────────────────────────────────────────┐
│                     YOUR FLUTTER APP                            │
│                   (com.spiritual.app)                           │
└────────┬────────────────────────────────────┬───────────────────┘
         │                                    │
         │ Uses                               │ Uses
         │ OneSignal SDK                      │ Firebase Auth
         │                                    │
         ▼                                    ▼
┌─────────────────────┐              ┌─────────────────────┐
│   ONESIGNAL         │              │   FIREBASE          │
│   (Push Service)    │◄─────────────│   (Auth + FCM)      │
│                     │  Server Key  │                     │
│  - Manages users    │              │  - Authenticates    │
│  - Sends push       │              │  - Provides FCM     │
│  - Tracks clicks    │              │  - Delivers push    │
└─────────────────────┘              └─────────────────────┘
         │                                    │
         │ Sends notification                 │ Delivers via FCM
         │ request                            │ (Android) or
         │                                    │ APNs (iOS)
         ▼                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                      USER'S DEVICE                              │
│                   (Android or iOS)                              │
│                                                                 │
│  1. App registers with OneSignal                               │
│  2. OneSignal gets device token from Firebase                  │
│  3. User ID linked to device                                   │
│  4. Notifications delivered via Firebase FCM                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📱 Detailed Flow

### Step 1: App Initialization
```
Flutter App Starts
    │
    ├─► Initialize Firebase
    │   └─► Reads google-services.json (Android)
    │       or GoogleService-Info.plist (iOS)
    │
    └─► Initialize OneSignal
        └─► Uses ONESIGNAL_APP_ID from .env.json
```

### Step 2: User Login
```
User Logs In
    │
    ├─► Firebase Authentication
    │   └─► Returns Firebase UID
    │
    └─► OneSignal.setExternalUserId(Firebase UID)
        └─► Links device to user
```

### Step 3: Notification Permission
```
User Allows Notifications
    │
    ├─► OneSignal requests permission
    │   └─► Gets device token from Firebase FCM
    │
    └─► Device registered with OneSignal
        └─► Ready to receive notifications
```

### Step 4: Sending Notification
```
OneSignal Dashboard
    │
    ├─► Create notification
    │   └─► Select target users
    │
    ├─► OneSignal sends to Firebase FCM
    │   └─► Uses Firebase Server Key
    │
    └─► Firebase FCM delivers to device
        └─► User receives notification
```

---

## 🔑 Key Components

### 1. Firebase Project: `sks-mobile-notifications`
```
Purpose: Provides FCM (Firebase Cloud Messaging)
Contains:
  ├─ Android App (com.spiritual.app)
  │  └─ google-services.json
  │
  └─ iOS App (com.spiritual.app)
     └─ GoogleService-Info.plist
```

### 2. Firebase Server Key
```
Purpose: Allows OneSignal to send via Firebase FCM
Location: Firebase Console > Cloud Messaging > Server key
Used by: OneSignal to authenticate with Firebase
```

### 3. OneSignal App
```
Purpose: Manages push notifications
Contains:
  ├─ App ID (used in Flutter app)
  ├─ Firebase Server Key (for Android)
  └─ APNs Key (for iOS, later)
```

### 4. Flutter App Configuration
```
.env.json
  └─ ONESIGNAL_APP_ID: "xxx-xxx-xxx"

android/app/
  └─ google-services.json

ios/Runner/
  └─ GoogleService-Info.plist
```

---

## 🔄 Data Flow

### Registration Flow
```
1. App starts
   └─► OneSignal SDK initializes

2. User logs in
   └─► Firebase UID obtained
   └─► OneSignal.setExternalUserId(UID)

3. User allows notifications
   └─► OneSignal requests device token
   └─► Firebase FCM provides token
   └─► Token sent to OneSignal servers

4. Device registered
   └─► Player ID created
   └─► Linked to External User ID (Firebase UID)
   └─► Tags added (auth_provider, mobile, etc.)
```

### Notification Flow
```
1. Create notification in OneSignal Dashboard
   └─► Select target: All users / Specific user / By tags

2. OneSignal processes request
   └─► Finds matching devices
   └─► Gets device tokens

3. OneSignal sends to Firebase FCM
   └─► Uses Firebase Server Key for authentication
   └─► Includes device tokens and notification data

4. Firebase FCM delivers
   └─► Android: Via Google Play Services
   └─► iOS: Via Apple Push Notification Service

5. Device receives notification
   └─► App handles notification
   └─► Click tracked by OneSignal
```

---

## 🎯 Why This Architecture?

### OneSignal Benefits
- ✅ Easy to use dashboard
- ✅ Advanced targeting (tags, segments)
- ✅ Analytics and tracking
- ✅ Scheduled notifications
- ✅ A/B testing
- ✅ Multi-platform support

### Firebase Benefits
- ✅ Reliable delivery infrastructure
- ✅ Free for unlimited notifications
- ✅ Works with Google Play Services
- ✅ Integrated with Firebase Auth
- ✅ Automatic token management

### Combined Power
```
OneSignal (Management) + Firebase (Delivery) = Best Solution
    │                          │
    ├─ User targeting          ├─ Reliable delivery
    ├─ Analytics               ├─ Token management
    ├─ Scheduling              ├─ Platform integration
    └─ Easy dashboard          └─ Free infrastructure
```

---

## 📊 Configuration Summary

### What Goes Where

| Component | Location | Purpose |
|-----------|----------|---------|
| Firebase Project | Firebase Console | Provides FCM service |
| google-services.json | android/app/ | Android FCM config |
| GoogleService-Info.plist | ios/Runner/ | iOS FCM config |
| Firebase Server Key | OneSignal Dashboard | Auth for FCM |
| OneSignal App ID | .env.json | Connect app to OneSignal |
| External User ID | Set in code | Link device to user |
| Tags | Set in code | Target specific users |

---

## 🔐 Security Flow

```
1. App authenticates with Firebase
   └─► Gets Firebase ID Token

2. App sends token to your backend
   └─► Backend verifies with Firebase
   └─► Backend saves user data

3. App sets OneSignal External User ID
   └─► Uses Firebase UID (secure)
   └─► No sensitive data in tags

4. Notifications sent via OneSignal
   └─► OneSignal authenticates with Firebase
   └─► Firebase delivers to device
   └─► All communication via HTTPS
```

---

## 🎉 Final Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    COMPLETE SYSTEM                           │
└──────────────────────────────────────────────────────────────┘

    ┌─────────────┐
    │   FLUTTER   │
    │     APP     │
    └──────┬──────┘
           │
    ┌──────┴──────────────────────────────┐
    │                                     │
    ▼                                     ▼
┌─────────┐                         ┌──────────┐
│FIREBASE │                         │ONESIGNAL │
│         │◄────Server Key──────────│          │
│ - Auth  │                         │ - Push   │
│ - FCM   │                         │ - Track  │
└────┬────┘                         └────┬─────┘
     │                                   │
     └───────────┬───────────────────────┘
                 │
                 ▼
         ┌───────────────┐
         │  YOUR BACKEND │
         │   (Optional)  │
         └───────────────┘
                 │
                 ▼
         ┌───────────────┐
         │   DATABASE    │
         │  (User Data)  │
         └───────────────┘
```

---

**This architecture gives you:**
- ✅ Reliable push notifications
- ✅ User tracking and analytics
- ✅ Advanced targeting
- ✅ Easy management
- ✅ Scalable infrastructure
- ✅ Free for unlimited users

**Follow the setup guide to connect everything!** 🚀
