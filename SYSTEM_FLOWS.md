# SKS Mobile Application - Detailed System Flows

## Table of Contents
1. [Complete User Journey](#complete-user-journey)
2. [Video Learning System](#video-learning-system)
3. [Notification System](#notification-system)
4. [Event Registration Flow](#event-registration-flow)
5. [E-Commerce Flow](#e-commerce-flow)
6. [Meditation Tracking Flow](#meditation-tracking-flow)

---

## 1. Complete User Journey

### First-Time User Complete Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    COMPLETE FIRST-TIME USER JOURNEY                      │
└─────────────────────────────────────────────────────────────────────────┘

START: User opens app for first time
│
├─> STEP 1: Splash Screen (2-3 seconds)
│   ├─ Initialize Firebase
│   ├─ Initialize API Service
│   ├─ Check authentication status
│   └─ Load cached user data (if exists)
│
├─> STEP 2: Language Selection
│   ├─ Display language options:
│   │  • English
│   │  • తెలుగు (Telugu)
│   │  • हिंदी (Hindi)
│   ├─ User selects language
│   ├─ Save preference to SharedPreferences
│   └─ Update app locale
│
├─> STEP 3: Login Screen
│   ├─ Display login options:
│   │  ┌────────────────────────────┐
│   │  │  Sign in with Google       │
│   │  └────────────────────────────┘
│   │  ┌────────────────────────────┐
│   │  │  Sign in with Phone        │
│   │  └────────────────────────────┘
│   │
│   ├─ OPTION A: Google Sign-In
│   │  ├─ User taps "Sign in with Google"
│   │  ├─ Google OAuth dialog appears
│   │  ├─ User selects Google account
│   │  ├─ Firebase authentication
│   │  ├─ Get Firebase ID token
│   │  ├─ POST /api/auth/login/google
│   │  │  Body: {
│   │  │    mobile: "+919876543210",
│   │  │    email: "user@gmail.com",
│   │  │    name: "John Doe",
│   │  │    photo: "https://..."
│   │  │  }
│   │  ├─ Backend verifies token
│   │  ├─ Backend creates/updates user
│   │  └─ Response: {
│   │     success: true,
│   │     user: { uid, email, name, ... },
│   │     is_new_user: true,
│   │     is_profile_complete: false
│   │  }
│   │
│   └─ OPTION B: Phone OTP
│      ├─ User enters phone number
│      ├─ MSG91 widget displays
│      ├─ OTP sent via SMS
│      ├─ User enters OTP
│      ├─ MSG91 verifies OTP
│      ├─ access_token returned
│      ├─ POST /api/auth/login/phone
│      │  Body: { access_token }
│      ├─ Backend verifies with MSG91
│      ├─ Backend creates/updates user
│      └─ Response: {
│         success: true,
│         user: { uid, mobile, ... },
│         is_new_user: true,
│         is_profile_complete: false
│      }
│
├─> STEP 4: Profile Setup (if is_new_user = true)
│   ├─ Display profile form:
│   │  ┌────────────────────────────┐
│   │  │ Full Name: [____________]  │
│   │  │ Mobile: [____________]     │
│   │  │ Email: [____________]      │
│   │  │ Gender: [Male/Female/Other]│
│   │  │ Date of Birth: [__/__/____]│
│   │  │ Address: [____________]    │
│   │  │ City: [____________]       │
│   │  │ State: [____________]      │
│   │  │ Pincode: [______]          │
│   │  │ Profession: [____________] │
│   │  │ How did you know about us? │
│   │  │ [Dropdown]                 │
│   │  │ Referrer Name: [________]  │
│   │  │ Referrer Mobile: [________]│
│   │  └────────────────────────────┘
│   ├─ User fills form
│   ├─ Validate inputs
│   ├─ PUT /api/user/profile
│   │  Body: { name, mobile, email, ... }
│   ├─ Backend updates user
│   │  SET is_profile_complete = 1
│   └─ Response: { success: true, user: {...} }
│
├─> STEP 5: Permissions Screen
│   ├─ Display permission requests:
│   │  ┌────────────────────────────┐
│   │  │ 📷 Camera                  │
│   │  │ For profile photo          │
│   │  │ [Grant Permission]         │
│   │  └────────────────────────────┘
│   │  ┌────────────────────────────┐
│   │  │ 🎤 Microphone              │
│   │  │ For audio features         │
│   │  │ [Grant Permission]         │
│   │  └────────────────────────────┘
│   │  ┌────────────────────────────┐
│   │  │ 🔔 Notifications           │
│   │  │ For reminders & updates    │
│   │  │ [Grant Permission]         │
│   │  └────────────────────────────┘
│   ├─ User grants permissions
│   ├─ PUT /api/user/permissions
│   │  Body: { permissions_granted: true }
│   └─ Backend updates user
│
├─> STEP 6: OneSignal Setup
│   ├─ OneSignal.initialize(appId)
│   ├─ OneSignal.requestPermission()
│   ├─ OneSignal.login(uid)
│   │  (Links device to user UID)
│   └─ Device registered for push notifications
│
├─> STEP 7: Navigate to Home
│   ├─ AuthState.setUser(user)
│   ├─ Save user to SharedPreferences
│   ├─ Navigate to /home
│   └─ Display home dashboard
│
└─> END: User is now logged in and on home screen

HOME SCREEN FEATURES:
┌────────────────────────────────────────────────────────────────┐
│ 🏠 Home                                                        │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│ Welcome, John Doe! 🙏                                          │
│                                                                │
│ ┌──────────────────────────────────────────────────────────┐ │
│ │ Daily Wisdom                                             │ │
│ │ "The mind is everything. What you think you become."    │ │
│ │ - Buddha                                                 │ │
│ └──────────────────────────────────────────────────────────┘ │
│                                                                │
│ Quick Actions:                                                 │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐            │
│ │ 📚      │ │ 🧘      │ │ 📅      │ │ 🔔      │            │
│ │Learnings│ │Meditate │ │ Events  │ │ Notify  │            │
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘            │
│                                                                │
│ Your Progress:                                                 │
│ ┌──────────────────────────────────────────────────────────┐ │
│ │ Level 1: Day 1 ✓ | Day 2 ✓ | Day 3 🔒                   │ │
│ │ [=========>                    ] 66%                     │ │
│ └──────────────────────────────────────────────────────────┘ │
│                                                                │
│ Upcoming Events:                                               │
│ ┌──────────────────────────────────────────────────────────┐ │
│ │ 🎉 Maha Sivaratri Celebration                            │ │
│ │ 📅 March 8, 2024 | 📍 Bangalore                          │ │
│ │ [Register Now]                                           │ │
│ └──────────────────────────────────────────────────────────┘ │
│                                                                │
└────────────────────────────────────────────────────────────────┘

Bottom Navigation:
┌─────────┬─────────┬─────────┬─────────┬─────────┐
│  🏠     │  📚     │  🙏     │  📅     │  👤     │
│  Home   │Learning │ Guruji  │ Events  │ Profile │
└─────────┴─────────┴─────────┴─────────┴─────────┘
```

---

## 2. Video Learning System

### Complete Video Learning Flow with Progressive Unlocking

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    VIDEO LEARNING SYSTEM FLOW                            │
└─────────────────────────────────────────────────────────────────────────┘

USER STARTS: Taps "Learnings" tab
│
├─> SCREEN 1: Levels List
│   ├─ GET /api/classes
│   ├─ Response: [
│   │    { id: 1, level: "Level 1", title: "Foundation", ... },
│   │    { id: 2, level: "Level 2", title: "Intermediate", ... },
│   │    { id: 3, level: "Level 3", title: "Advanced", ... },
│   │    { id: 4, level: "Level 4", title: "Master", ... },
│   │    { id: 5, level: "Level 5", title: "Guru", ... }
│   │  ]
│   ├─ GET /api/level-progression
│   ├─ Response: {
│   │    current_level: 1,
│   │    unlocked_levels: [1],
│   │    level_1_progress: { completed_days: 2, total_days: 3 },
│   │    level_2_locked: true,
│   │    unlock_requirements: "Complete Level 1"
│   │  }
│   └─ Display:
│      ┌────────────────────────────────────────────────────────┐
│      │ 📚 Learnings                                           │
│      ├────────────────────────────────────────────────────────┤
│      │                                                        │
│      │ ┌──────────────────────────────────────────────────┐ │
│      │ │ Level 1: Foundation                    ✓ UNLOCKED│ │
│      │ │ 3 days | Progress: 66% (2/3 days)                │ │
│      │ │ [Continue Learning →]                            │ │
│      │ └──────────────────────────────────────────────────┘ │
│      │                                                        │
│      │ ┌──────────────────────────────────────────────────┐ │
│      │ │ Level 2: Intermediate                  🔒 LOCKED │ │
│      │ │ Complete Level 1 to unlock                       │ │
│      │ └──────────────────────────────────────────────────┘ │
│      │                                                        │
│      │ ┌──────────────────────────────────────────────────┐ │
│      │ │ Level 3: Advanced                      🔒 LOCKED │ │
│      │ │ Complete Level 2 + Pass Test                     │ │
│      │ └──────────────────────────────────────────────────┘ │
│      │                                                        │
│      └────────────────────────────────────────────────────────┘
│
├─> USER ACTION: Taps "Level 1"
│
├─> SCREEN 2: Days List (Level 1)
│   ├─ GET /api/classes/1/days
│   ├─ Response: [
│   │    {
│   │      id: 1,
│   │      day_number: 1,
│   │      title: "Introduction to Meditation",
│   │      is_unlocked: true,
│   │      is_completed: true,
│   │      completion_percentage: 100,
│   │      video_duration_seconds: 3600
│   │    },
│   │    {
│   │      id: 2,
│   │      day_number: 2,
│   │      title: "Breathing Techniques",
│   │      is_unlocked: true,
│   │      is_completed: true,
│   │      completion_percentage: 100,
│   │      video_duration_seconds: 3600
│   │    },
│   │    {
│   │      id: 3,
│   │      day_number: 3,
│   │      title: "Chakra Meditation",
│   │      is_unlocked: false,
│   │      is_completed: false,
│   │      unlock_time: "2024-01-16T10:00:00Z",
│   │      video_duration_seconds: 3600
│   │    }
│   │  ]
│   └─ Display:
│      ┌────────────────────────────────────────────────────────┐
│      │ ← Level 1: Foundation                                  │
│      ├────────────────────────────────────────────────────────┤
│      │                                                        │
│      │ ┌──────────────────────────────────────────────────┐ │
│      │ │ ✓ Day 1: Introduction to Meditation              │ │
│      │ │ 1 hour | Completed 100%                          │ │
│      │ │ [Watch Again]                                    │ │
│      │ └──────────────────────────────────────────────────┘ │
│      │                                                        │
│      │ ┌──────────────────────────────────────────────────┐ │
│      │ │ ✓ Day 2: Breathing Techniques                    │ │
│      │ │ 1 hour | Completed 100%                          │ │
│      │ │ [Watch Again]                                    │ │
│      │ └──────────────────────────────────────────────────┘ │
│      │                                                        │
│      │ ┌──────────────────────────────────────────────────┐ │
│      │ │ 🔒 Day 3: Chakra Meditation                      │ │
│      │ │ Unlocks in: 23h 45m                              │ │
│      │ │ Complete Day 2 and wait 24 hours                │ │
│      │ └──────────────────────────────────────────────────┘ │
│      │                                                        │
│      └────────────────────────────────────────────────────────┘
│
├─> USER ACTION: Taps "Day 1" (to rewatch)
│
├─> SCREEN 3: Video Player
│   ├─ POST /api/classes/days/1/start
│   │  Body: { user_uid: "abc123" }
│   ├─ Response: {
│   │    success: true,
│   │    video_url: "https://customer-xxx.cloudflarestream.com/video_id/manifest/video.m3u8?token=...",
│   │    session_id: "session_123",
│   │    languages: ["te", "hi", "en"],
│   │    default_language: "te"
│   │  }
│   ├─ Initialize video player
│   ├─ Load HLS stream
│   ├─ Display player controls:
│   │  ┌────────────────────────────────────────────────────────┐
│   │  │                                                        │
│   │  │                  [VIDEO PLAYER]                        │
│   │  │                                                        │
│   │  │  ┌──────────────────────────────────────────────┐    │
│   │  │  │                                              │    │
│   │  │  │         Video Content Playing                │    │
│   │  │  │                                              │    │
│   │  │  └──────────────────────────────────────────────┘    │
│   │  │                                                        │
│   │  │  [▶️ Play/Pause] [🔊 Volume] [⚙️ Settings]            │
│   │  │  [=========>                    ] 15:30 / 60:00      │
│   │  │                                                        │
│   │  │  Language: [తెలుగు ▼] [हिंदी] [English]              │
│   │  │  Quality: [Auto ▼] [1080p] [720p] [480p]             │
│   │  │                                                        │
│   │  └────────────────────────────────────────────────────────┘
│   │
│   ├─ PROGRESS TRACKING (every 10 seconds):
│   │  ├─ POST /api/classes/days/1/progress
│   │  │  Body: {
│   │  │    session_id: "session_123",
│   │  │    current_time_seconds: 930,
│   │  │    total_duration_seconds: 3600,
│   │  │    completion_percentage: 26
│   │  │  }
│   │  └─ Backend logs watch event
│   │
│   ├─ USER WATCHES VIDEO (90% completion required)
│   │
│   └─> VIDEO COMPLETION (at 90% watched):
│       ├─ POST /api/classes/days/1/complete
│       │  Body: {
│       │    session_id: "session_123",
│       │    watch_time_seconds: 3240,
│       │    completion_percentage: 90
│       │  }
│       ├─ Backend marks day as complete
│       ├─ Backend checks if next day should unlock
│       ├─ If all days complete → Check if next level unlocks
│       └─ Response: {
│          success: true,
│          day_completed: true,
│          next_day_unlocked: false,
│          next_day_unlock_time: "2024-01-16T10:00:00Z",
│          level_completed: false
│       }
│
├─> NOTIFICATION SYSTEM (24 hours later):
│   ├─ Backend cron job runs
│   ├─ Checks unlock times
│   ├─ Day 3 unlock time reached
│   ├─ POST /api/notifications (internal)
│   │  Body: {
│   │    user_uid: "abc123",
│   │    type: "day_unlocked",
│   │    title: "Day 3 Unlocked!",
│   │    message: "Chakra Meditation is now available",
│   │    action_url: "/learnings/class/1/day/3"
│   │  }
│   ├─ OneSignal push notification sent
│   └─ User receives notification on device
│
├─> USER COMPLETES ALL 3 DAYS OF LEVEL 1
│   ├─ Backend detects level completion
│   ├─ Waits 24 hours
│   ├─ Unlocks Level 2
│   ├─ Sends notification:
│   │  "🎉 Congratulations! Level 2 is now unlocked!"
│   └─ User can now access Level 2
│
└─> SPECIAL CASE: Level 2 → Level 3
    ├─ User completes all 3 days of Level 2
    ├─ Backend shows meditation test requirement
    ├─ User takes meditation test
    ├─ POST /api/level-progression/meditation-test
    │  Body: { answers: [...] }
    ├─ Backend evaluates test
    ├─ If passed:
    │  ├─ Unlock Level 3
    │  └─ Send congratulations notification
    └─ If failed:
       ├─ Show retry message
       └─ Allow retry after 24 hours

UNLOCK LOGIC SUMMARY:
┌────────────────────────────────────────────────────────────────┐
│ Level 1 → Auto-unlocked for all users                         │
│ Level 2 → Complete Level 1 (all 3 days) + wait 24h            │
│ Level 3 → Complete Level 2 + Pass meditation test + wait 24h  │
│ Level 4 → Complete Level 3 + wait 24h                         │
│ Level 5 → Complete Level 4 + wait 24h                         │
│                                                                │
│ Day Unlock → Complete previous day + wait 24h                 │
│ Day Completion → Watch 90% of video                           │
└────────────────────────────────────────────────────────────────┘
```

---

## 3. Notification System

### Complete Notification Flow

