# OneSignal Push Notifications - Complete Implementation

## 🎯 Overview

OneSignal push notifications are now fully integrated with **MANDATORY** permission enforcement. Users MUST allow notifications to use the app and connect with Guruji.

## ✨ Features

✅ **Mandatory Notification Permission** - App won't open without it  
✅ **User Tracking** - Firebase UID as external user ID  
✅ **Tag-Based Targeting** - Send to specific user groups  
✅ **Click Tracking** - Monitor notification engagement  
✅ **View Tracking** - Track notification impressions  
✅ **Deep Linking** - Navigate to specific screens  
✅ **Rich Notifications** - Images, buttons, actions  
✅ **Scheduled Notifications** - Send at specific times  
✅ **Analytics Dashboard** - Complete metrics and insights  

## 📚 Documentation

| Document | Description |
|----------|-------------|
| **ONESIGNAL_QUICK_REFERENCE.md** | Quick start guide (5 minutes) |
| **ONESIGNAL_SETUP.md** | Detailed setup instructions |
| **ONESIGNAL_INTEGRATION_GUIDE.md** | Complete API reference |
| **ONESIGNAL_NOTIFICATION_EXAMPLES.md** | Examples and templates |
| **ONESIGNAL_IMPLEMENTATION_SUMMARY.md** | What was implemented |

## 🚀 Quick Start

### 1. Setup OneSignal (5 minutes)

```bash
# 1. Create account at onesignal.com
# 2. Create new app
# 3. Configure Android (FCM)
# 4. Copy App ID
```

### 2. Configure App

```json
// .env.json
{
  "ONESIGNAL_APP_ID": "your_app_id_here"
}
```

### 3. Install & Run

```bash
flutter pub get
flutter run --dart-define-from-file=.env.json
```

### 4. Test

1. Complete login flow
2. **MUST** allow notification permission
3. Send test notification from OneSignal Dashboard
4. Verify notification received

## 🔒 Mandatory Permission Flow

```
┌─────────────────────────────────────────────────┐
│  User CANNOT proceed without allowing           │
│  notification permission                        │
│                                                  │
│  "To connect with Guruji you need to           │
│   allow notifications"                          │
└─────────────────────────────────────────────────┘
```

### Why Mandatory?

- Stay connected with Guruji
- Receive spiritual guidance
- Get event reminders
- Daily wisdom messages
- Community updates

## 📱 Sending Notifications

### From Dashboard (Easiest)

```
1. Go to OneSignal Dashboard
2. Messages > New Push
3. Select audience
4. Enter title and message
5. Click Send
```

### Via API

```bash
curl -X POST https://onesignal.com/api/v1/notifications \
  -H "Authorization: Basic YOUR_REST_API_KEY" \
  -d '{
    "app_id": "YOUR_APP_ID",
    "included_segments": ["All"],
    "headings": {"en": "Welcome"},
    "contents": {"en": "Your spiritual journey begins"}
  }'
```

## 🎯 Targeting Options

### Send to All Users
```
Audience: All Subscribers
```

### Send to Specific User
```
Filter: External User ID = firebase_uid_123
```

### Send by Tag
```
Filter: Tag "state" = "Telangana"
```

### Send by Behavior
```
Filter: Last Session > 7 days ago
```

## 📊 Tracking & Analytics

### Automatic Tracking
- ✅ Notification delivered
- ✅ Notification viewed
- ✅ Notification clicked
- ✅ User subscription status
- ✅ Permission changes

### View in Dashboard
```
Dashboard > Delivery > Overview
- Delivery Rate
- Open Rate
- Click Rate
- Conversion Rate
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

## 💡 Use Cases

### 1. Daily Wisdom
```
Schedule: Daily at 6:00 AM
Audience: All Subscribers
Title: "Daily Wisdom 🌅"
Message: "Start your day with Guruji's blessings"
```

### 2. Event Reminders
```
Schedule: 1 day before event
Audience: All Subscribers
Title: "Event Tomorrow! 📅"
Message: "Join us for spiritual gathering"
Deep Link: screen=events
```

### 3. New Content
```
Audience: All Subscribers
Title: "New Learnings Available 📚"
Message: "Explore new spiritual teachings"
Deep Link: screen=learnings
```

### 4. Location-Based
```
Audience: Tag "state" = "Telangana"
Title: "Event in Your Area! 📍"
Message: "Join us in Hyderabad this weekend"
```

## 🛠️ Technical Details

### Files Created
- `lib/core/services/onesignal_service.dart`
- `lib/features/auth/notification_permission_screen.dart`

### Files Modified
- `pubspec.yaml` - Added OneSignal dependency
- `lib/main.dart` - Initialize OneSignal
- `lib/core/router.dart` - Added notification route
- `lib/features/auth/login_screen.dart` - Set user ID
- `lib/features/auth/auth_service.dart` - Remove user ID on logout

### Dependencies
```yaml
onesignal_flutter: ^5.2.5
```

## 🔐 Security & Privacy

- External User ID = Firebase UID (secure)
- Tags don't contain sensitive data
- HTTPS communication
- User can opt out (but app requires it)
- Logout removes user identification

## 📈 Best Practices

### Timing
- Morning: 6-9 AM (motivation)
- Afternoon: 12-2 PM (reminders)
- Evening: 6-8 PM (events)
- Avoid: Late night

### Frequency
- Max 2-3 per day
- Space 4+ hours apart
- Respect user preferences

### Content
- Title: <50 characters
- Message: <150 characters
- Clear call-to-action
- Use emojis sparingly

## 🐛 Troubleshooting

### Not Receiving Notifications?
1. Check App ID is correct
2. Verify permission granted
3. Check internet connection
4. Verify Firebase configuration

### User ID Not Showing?
1. Complete login flow
2. Wait 10 seconds
3. Refresh dashboard

### Tags Not Appearing?
1. Verify setTags() called
2. Wait 15 seconds
3. Refresh dashboard

## ✅ Testing Checklist

- [ ] OneSignal App ID configured
- [ ] App runs without errors
- [ ] Login flow completes
- [ ] Notification permission screen appears
- [ ] Permission MUST be granted
- [ ] User ID visible in dashboard
- [ ] Tags visible in dashboard
- [ ] Test notification received
- [ ] Notification click works
- [ ] Deep linking works
- [ ] Logout removes user ID

## 📞 Support

- **Quick Reference**: `ONESIGNAL_QUICK_REFERENCE.md`
- **Setup Guide**: `ONESIGNAL_SETUP.md`
- **Full Documentation**: `ONESIGNAL_INTEGRATION_GUIDE.md`
- **Examples**: `ONESIGNAL_NOTIFICATION_EXAMPLES.md`
- **OneSignal Docs**: https://documentation.onesignal.com/
- **Support**: https://onesignal.com/support

## 🎉 You're All Set!

Your app now has enterprise-grade push notifications with:
- ✅ Mandatory permission enforcement
- ✅ Complete user tracking
- ✅ Advanced targeting
- ✅ Deep linking
- ✅ Analytics
- ✅ Production-ready

**Start sending notifications to connect with your users!** 🚀

---

**Need help?** Check the documentation files or visit OneSignal support.
