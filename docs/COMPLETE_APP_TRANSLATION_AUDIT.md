# Complete App Translation Audit

## 🎯 GOAL: Translate EVERY piece of text in the entire mobile app

This document lists ALL pages and ALL hardcoded text that needs translation.

---

## ✅ ALREADY TRANSLATED (Dart files updated)

1. **Home Page** - ✅ Complete
2. **Splash Screen** - ✅ Complete  
3. **Language Selection** - ✅ Complete
4. **Profile Screen** - ✅ Complete
5. **Guru Journey Page** - ✅ Complete
6. **Kundalini Science Page** - ✅ Complete
7. **Benefits Page** - ✅ Complete
8. **Chakras Detail Page** - ✅ Complete
9. **Learnings Page** - ✅ Complete
10. **All Songs Page** - ✅ Complete
11. **Guruji Connect Page** - ✅ Complete (just updated)

---

## 🔴 NEEDS TRANSLATION (JSON keys added, Dart files need updating)

### 1. **Meditation Timer Page**
**File**: `lib/features/meditation/meditation_timer_page.dart`
- All timer controls, messages, journal entries

### 2. **Meditation History Page**  
**File**: `lib/features/meditation/meditation_history_page.dart`
- Login prompts, stats, charts, session history

### 3. **Ringtone Settings Page**
**File**: `lib/features/settings/ringtone_settings_page.dart`
- All settings, permissions, messages

### 4. **Wallpaper Settings Page**
**File**: `lib/features/settings/wallpaper_settings_page.dart`
- All settings, rotation options, messages

### 5. **Reminders Screen**
**File**: `lib/features/reminders/reminders_screen.dart`
- List view, delete confirmations, empty states

### 6. **Reminder Form Screen**
**File**: `lib/features/reminders/reminder_form_screen.dart`
- Form fields, validation messages, save buttons

### 7. **Class Days List Screen**
**File**: `lib/features/learnings/class_days_list_screen.dart`
- Enrollment, day cards, unlock messages

---

## 🔴 NEEDS COMPLETE TRANSLATION (No JSON keys yet)

### 8. **Day Video Screen** ⚠️ CRITICAL
**File**: `lib/features/learnings/day_video_screen.dart`

**Hardcoded text**:
- "Security Warning" → needs key
- "Screen recording or screenshot detected." → needs key
- "Recording, downloading, or sharing this content is strictly prohibited and may result in:" → needs key
- "• Immediate account suspension" → needs key
- "• Legal action for copyright violation" → needs key
- "• Loss of access to all courses" → needs key
- "This incident has been logged." → needs key
- "I Understand" → needs key
- "Day Completed!" → needs key
- "Congratulations! You have completed..." → needs key
- "Next day will unlock in 24 hours" → needs key
- "Continue" → already exists
- "Go Back" → needs key
- "Protected Content" → needs key
- "Recording, downloading, or sharing this video is strictly prohibited" → needs key
- "Day X" → dynamic
- "X min" → dynamic
- "Important Notes" → needs key
- "Watch the complete video to mark this day as completed" → needs key
- "Next day will unlock 24 hours after completing this day" → needs key
- "Video seeking is disabled to ensure complete learning" → needs key
- "Your progress is automatically saved" → needs key
- "Screen recording and screenshots are monitored and prohibited" → needs key

### 9. **Events Page** ⚠️ CRITICAL
**File**: `lib/features/events/events_page.dart`

**Hardcoded text**:
- "Upcoming Events" → needs key
- "Join us in spiritual gatherings" → needs key
- "No upcoming events" → needs key
- "Check back later for new events" → needs key
- "Successfully registered for event!" → needs key
- "Failed to register" → needs key
- "Already Registered" → needs key
- "Register Now" → needs key
- "Retry" → already exists

### 10. **Notifications Page** ⚠️ CRITICAL
**File**: `lib/features/notifications/notifications_page.dart`

**Hardcoded text**:
- "Notifications" → already exists
- "Mark all read" → needs key
- "Clear all" → needs key
- "Clear All Notifications" → needs key
- "Are you sure you want to delete all notifications?" → needs key
- "Clear All" → needs key
- "Just now" → already exists
- "Xm ago" / "Xh ago" / "Xd ago" → already exists
- "Stay updated with spiritual content" → needs key
- "Notification deleted" → needs key
- "No Notifications Yet" → needs key
- "You'll receive updates about events, new content, and spiritual reminders here." → needs key
- "Events" → already exists
- "Get notified about upcoming spiritual gatherings" → needs key
- "New Content" → needs key
- "Stay updated with new songs and learnings" → needs key

### 11. **Profile Edit Screen** ⚠️ CRITICAL
**File**: `lib/features/profile/profile_edit_screen.dart`

**Hardcoded text**:
- "Edit Profile" → needs key
- "Save" → already exists
- "Full Name" → needs key
- "Enter your full name" → needs key
- "Phone Number" → needs key
- "Enter your phone number" → needs key
- "Mobile number cannot be changed" → needs key
- "Save Changes" → needs key
- "Profile updated successfully" → needs key
- "Failed to update profile" → needs key
- "Network error. Please try again." → already exists
- "Please enter your name" → needs key
- "Name must be at least 2 characters" → needs key

### 12. **Login Screen** ⚠️ CRITICAL  
**File**: `lib/features/auth/login_screen.dart`

**Already has some translations but needs more**:
- "Continue with Google" → needs key (currently hardcoded)
- Error messages need translation keys

### 13. **Profile Setup Screen**
**File**: `lib/features/auth/profile_setup_screen.dart`
- Needs complete audit

### 14. **Profile Selection Screen**
**File**: `lib/features/profile/profile_selection_screen.dart`
- Needs complete audit

### 15. **Profiles List Screen**
**File**: `lib/features/profile/profiles_list_screen.dart`
- Needs complete audit

### 16. **Audio/Playlist Screen**
**File**: `lib/features/audio/playlist_screen.dart`
- Needs complete audit

### 17. **Notification Detail Screen**
**File**: `lib/features/notifications/notification_detail_screen.dart`
- Needs complete audit

---

## 📊 TRANSLATION PRIORITY

### CRITICAL (User-facing, frequently used):
1. ✅ Day Video Screen - Security warnings, completion messages
2. ✅ Events Page - Event listings, registration
3. ✅ Notifications Page - Notification management
4. ✅ Profile Edit Screen - Profile editing
5. ✅ Login Screen - Authentication flow

### HIGH (Important features):
6. Meditation Timer - Timer controls
7. Meditation History - Progress tracking
8. Reminders - Reminder management
9. Class Days List - Course navigation
10. Ringtone/Wallpaper Settings

### MEDIUM (Secondary features):
11. Profile Setup
12. Profile Selection
13. Profiles List
14. Audio/Playlist
15. Notification Detail

---

## 🎯 ACTION PLAN

### Phase 1: Add Missing Translation Keys (NOW)
Add all missing keys to en.json, te.json, hi.json for:
- Day Video Screen (~20 keys)
- Events Page (~10 keys)
- Notifications Page (~15 keys)
- Profile Edit Screen (~10 keys)
- Login Screen (~5 keys)

### Phase 2: Update Dart Files (NEXT)
Update all Dart files to use `context.tr()` for:
- All 5 critical pages above
- All 5 high priority pages
- All 5 medium priority pages

### Phase 3: Audit Remaining Pages
- Profile Setup Screen
- Profile Selection Screen
- Profiles List Screen
- Audio/Playlist Screen
- Notification Detail Screen

### Phase 4: Test & Verify
- Test language switching on ALL pages
- Verify no hardcoded text remains
- Check for missing translation warnings

---

## 📝 NOTES

- Some pages already have partial translations (Login Screen)
- Need to check for dynamic content (dates, numbers, etc.)
- Need to handle pluralization (1 day vs 2 days)
- Need to handle string interpolation (variables in translations)

---

## ✅ COMPLETION CHECKLIST

- [ ] All translation keys added to JSON files
- [ ] All Dart files updated to use context.tr()
- [ ] No console warnings for missing translations
- [ ] Language switching works on all pages
- [ ] All content (not just headings) is translated
- [ ] Dynamic content is properly formatted
- [ ] Pluralization is handled correctly
- [ ] String interpolation works correctly

