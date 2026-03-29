# Updated User Flow with Skip Login

## 🔄 New User Flow

### Option 1: Full Login Flow
```
Login Screen
    │
    ├─► Phone OTP Login
    │   └─► Backend API Call
    │       └─► Profile Setup
    │           └─► Permissions (Camera/Mic)
    │               └─► Notification Permission (MANDATORY)
    │                   └─► Home Screen
    │
    └─► Google Sign-In
        └─► Backend API Call
            └─► Profile Setup
                └─► Permissions (Camera/Mic)
                    └─► Notification Permission (MANDATORY)
                        └─► Home Screen
```

### Option 2: Skip Login (Guest Mode)
```
Login Screen
    │
    └─► Click "Skip for now"
        └─► Notification Permission (MANDATORY)
            └─► Home Screen (as guest)
```

---

## 🎯 Key Changes

### 1. Skip Button Behavior
**Before:**
```dart
onPressed: () => context.go('/'),  // Went directly to home
```

**After:**
```dart
onPressed: () => context.go('/notification-permission'),  // Must allow notifications first
```

### 2. Notification Permission for Guests
**New Logic:**
- Guest users (who skipped login) can still use the app
- But MUST allow notification permission
- Tagged as 'guest' in OneSignal for targeting
- Can login later to get full features

### 3. Backend API Handling
**Updated:**
- Backend calls wrapped in try-catch
- If user not logged in, backend call fails gracefully
- App continues to work for guest users
- Notifications still work via OneSignal

---

## 📱 User Experience

### For Logged-In Users
```
✅ Full authentication
✅ Profile saved to backend
✅ Permissions saved to backend
✅ OneSignal linked to Firebase UID
✅ Can receive targeted notifications
✅ Full app features
```

### For Guest Users (Skip Login)
```
✅ Can use app immediately
✅ MUST allow notifications
✅ Tagged as 'guest' in OneSignal
✅ Can receive general notifications
✅ Can login later for full features
⚠️ Profile not saved to backend
⚠️ Data not synced across devices
```

---

## 🔔 Notification Targeting

### Send to All Users (Including Guests)
```
OneSignal Dashboard > Messages > New Push
Audience: Send to All Subscribers
```

### Send Only to Logged-In Users
```
OneSignal Dashboard > Messages > New Push
Audience: Send to Particular Segment
Filter: User Tag "user_type" does not equal "guest"
```

### Send Only to Guest Users
```
OneSignal Dashboard > Messages > New Push
Audience: Send to Particular Segment
Filter: User Tag "user_type" = "guest"
```

### Send to Specific User (Logged-In Only)
```
OneSignal Dashboard > Messages > New Push
Audience: Send to Particular Segment
Filter: External User ID = "firebase_uid_xxx"
```

---

## 🔧 Technical Implementation

### Login Screen Changes
```dart
// Skip button now goes to notification permission
TextButton(
  onPressed: () => context.go('/notification-permission'),
  child: Text('Skip for now'),
)
```

### Notification Permission Screen Changes
```dart
Future<void> _requestPermission() async {
  // Request permission
  final granted = await _oneSignal.requestPermission();
  
  if (granted) {
    // Try to save to backend (only if logged in)
    try {
      await _apiService.savePermissions(...);
    } catch (e) {
      // Fail gracefully for guest users
      debugPrint('Backend call failed: $e');
    }
    
    // Tag guest users
    final user = _authState.user;
    if (user == null) {
      await _oneSignal.setTags({
        'user_type': 'guest',
        'permission_granted': 'true',
      });
    }
    
    // Continue to home
    context.go('/');
  }
}
```

---

## 🎨 UI/UX Considerations

### Login Screen
- "Skip for now" button clearly visible
- User understands they can use app without login
- But notifications are still mandatory

### Notification Permission Screen
- Same strict enforcement for all users
- Clear message about connecting with Guruji
- Cannot skip or go back
- Works for both logged-in and guest users

### Home Screen
- Guest users see all content
- Optional: Show "Login for more features" banner
- Optional: Prompt to login for personalized experience

---

## 🔐 Security & Privacy

### Guest Users
- ✅ No personal data collected
- ✅ No backend account created
- ✅ Only OneSignal device token stored
- ✅ Tagged as 'guest' for transparency
- ✅ Can delete app to remove all data

### Logged-In Users
- ✅ Full authentication via Firebase
- ✅ Data saved securely in backend
- ✅ Linked to Firebase UID
- ✅ Can logout to remove data
- ✅ GDPR compliant

---

## 📊 Analytics & Tracking

### OneSignal Dashboard
```
Total Users: 100
├─ Logged-In: 70 (External User ID set)
└─ Guest: 30 (Tagged as 'guest')

All users subscribed to notifications: 100%
```

### Targeting Capabilities
```
✅ Send to all users
✅ Send to logged-in users only
✅ Send to guest users only
✅ Send to specific user (by Firebase UID)
✅ Send by tags (state, auth_provider, etc.)
```

---

## 🚀 Migration Path (Guest → Logged-In)

### When Guest User Logs In Later

1. **User clicks "Login" from home screen**
2. **Complete authentication**
3. **Backend creates account**
4. **OneSignal updates:**
   ```dart
   // Remove guest tag
   await OneSignalService().removeTags(['user_type']);
   
   // Set external user ID
   await OneSignalService().setExternalUserId(user.uid);
   
   // Set user tags
   await OneSignalService().setTags({
     'auth_provider': 'phone',
     'mobile': user.mobile,
   });
   ```
5. **User now has full features**

---

## ✅ Testing Checklist

### Test Guest Flow
- [ ] Click "Skip for now" on login screen
- [ ] Notification permission screen appears
- [ ] MUST allow notification to proceed
- [ ] Home screen opens
- [ ] Can use app features
- [ ] Receive test notification
- [ ] User tagged as 'guest' in OneSignal

### Test Login Flow
- [ ] Complete phone or Google login
- [ ] Backend API call succeeds
- [ ] Profile setup works
- [ ] Permissions screen works
- [ ] Notification permission works
- [ ] Home screen opens
- [ ] User has External User ID in OneSignal
- [ ] User has proper tags

### Test Notifications
- [ ] Send to all users (guests + logged-in)
- [ ] Send to logged-in users only
- [ ] Send to guest users only
- [ ] Send to specific user by UID
- [ ] All notifications received correctly

---

## 🎉 Benefits of This Approach

### For Users
✅ Can try app immediately without signup  
✅ Still get important notifications  
✅ Can login later for full features  
✅ Smooth onboarding experience  

### For You
✅ Lower barrier to entry  
✅ More users try the app  
✅ Can still send notifications to everyone  
✅ Can target different user segments  
✅ Flexible user management  

### For Guruji's Mission
✅ Reach more people quickly  
✅ Share spiritual guidance with everyone  
✅ Build community gradually  
✅ Respect user choice  

---

## 📞 Support

- **Backend Setup**: See `BACKEND_FIREBASE_SETUP.md`
- **OneSignal Guide**: See `ONESIGNAL_INTEGRATION_GUIDE.md`
- **Complete Flow**: See `COMPLETE_IMPLEMENTATION_SUMMARY.md`

---

**Your app now supports both full login and guest mode, with mandatory notifications for all users!** 🚀
