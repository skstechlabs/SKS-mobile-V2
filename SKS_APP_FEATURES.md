# SKS Mobile App — Feature Inventory & Roadmap

**App:** Siva Kundalini Sadhana (SKS)  
**Platform:** Flutter (Android / iOS / Web)  
**Purpose:** Guide seekers on the path to Kundalini awakening through structured learning, daily practice, and community connection.

---

## Part 1 — What the App Already Has

### 🔐 Authentication & Onboarding
- Google Sign-In (Firebase)
- Phone / OTP login (code present, currently disabled)
- 7-slide onboarding (mission, Gurudev's story, Kundalini science, courses, meditation, bhajans, community)
- Language selection at first run (English / Telugu)
- Profile setup with personal info, location, profession, referral source
- Multi-profile support
- Account blocking by admin (graceful blocked-screen with reason)

---

### 📚 Kundalini Sadhana Courses
- **4 graded online levels** — Level 1 (Brahmarandhra Opening) → Level 2 (Sushumna Nadi) → Level 3 (Chakra Activation) → Level 4 (Kundalini Activation)
- Video lessons per day, watched in sequence
- 24-hour unlock timer between days (prevents rushing)
- Progress tracking per level, per day
- Meditation Test required to unlock Level 3 (conducted offline, admin-notified)
- Level 5 (residential with Gurudev) — unlocked after completing all online levels
- Screen recording detection and prohibition
- **Residential courses** — described separately, available after online completion

---

### 🧘 Meditation
- **Free-form Timer** — count-up (open-ended) or countdown (preset duration)
- **Duration presets** — 5, 10, 15, 20, 30, 45 min, 1 hour
- **Custom duration picker** — hours + minutes
- **Start/End sounds** — fetched from API per language (English/Hindi/Telugu/Kannada), downloaded to disk, pre-buffered for instant playback
- **Breathing animation** — pulsing Guruji image during active session
- **Journal entry** — optional notes after each session (up to 500 chars)
- **Auto-save** for logged-in users; login prompt for guests
- **Session history** with filtering (year, month), pagination (10 per page, infinite scroll)
- **Statistics** — current streak, longest streak, days meditated, total time, sessions count
- **Charts** — Last 7 Days bar chart, Monthly Hours bar chart
- **Yearly & Monthly breakdown** in Stats tab
- **Leaderboard** — All Time / This Week / This Month / Yearly / Most Sessions / Most Days tabs
- **Rank badge** — Gold / Silver / Bronze for top 3
- **Meditation Journey page** — 3 tabs (Journey, Leaderboard, Stats)
- Pauses global audio (bhajans) when meditation starts
- Global audio resumes after session (if it was playing)

---

### 🎵 Audio & Music
- **Sivoham Chanting / Meditation Music** — full audio player with play/pause/next/previous
- **Bhajans** — devotional songs with artwork, duration, language
- **All Songs page** — full library
- **Now Playing screen** — mini-player + full-screen player
- **Background audio** — continues when app is minimized
- **Audio caching** — files downloaded once, played from disk
- **Sivoham Ringtone** — set as phone ringtone / notification / alarm sound (Android)
- Language-aware meditation sounds (start bell / end bell in user's language)

---

### 📅 Events & Gatherings
- **Upcoming Programs** — event cards with title, date, location, thumbnail
- **Event registration** — one-tap register with confirmation
- **Recent Gatherings** — photo gallery of past satsangs
- **Maha Sivaratri** — dedicated event flow (registration, travel details, seat registration)
- **Spot registrations** — real-time seat availability
- **Event attendance tracking** (admin-side)

---

### 🙏 Kalpataru
- Full educational content: what Kalpataru is, how it works
- 3-body healing explanation (Sthula / Sukshma / Karana Sharira)
- Step-by-step technique overview
- Benefits list (Healing, Clarity, Relations, Peace, Abundance, Spiritual Growth)
- "Begin Your Transformation" call-to-action

---

### 🌀 Spiritual Knowledge Base
- **Guru Journey** — Gurudev's life story in 5 slides with quotes and statistics (Asia Book of Records)
- **Kundalini Science** — Deep explanation of Kundalini, nadis, chakra system, safe awakening
- **7 Chakras** — Full detail page for each chakra (location, color, element, mantra, deity, archetype, description, opening age, physical experiences)
- **Benefits of Sadhana** — 6 key benefits with icons and descriptions
- **Vision & Mission** — Organization's vision, mission, values

---

### 🔔 Reminders & Notifications
- **Daily reminders** — Morning Meditation, Evening Meditation, Daily Practice (custom time)
- **Preset quick-set** — one-tap morning/evening reminders from home screen
- **Custom reminders** — title, message, time, repeat days
- **Push notifications** via OneSignal — events, new content, admin messages
- **Notification inbox** — list view with mark-as-read, delete, clear all
- **Notification detail** — full message view

---

### 🖼️ Personalization
- **Guruji Wallpapers** — grid of images, one-tap set as device wallpaper
- **Auto-rotate wallpapers** — changes every 15 minutes (Android background service)
- **Language selector** — switch between English and Telugu at any time
- **Profile editing** — name, photo, city, state, pincode, age, profession

---

### 📊 Profile & Progress
- **User profile** — photo, name, location, stats
- **Sadhana Streak** display on profile
- **Total Meditation Time** display on profile
- **Meditation Journey** shortcut from profile
- **Edit Profile** with photo upload (Cloudflare R2)

---

### 🛠️ Technical Infrastructure
- **API Gateway** — nginx → Node.js gateway (port 3000) → microservices
- **sks-meditation-service** — dedicated meditation analytics service (port 3015, 4-worker cluster)
- **sks-mobile-backend-service** — main app data (events, users, gatherings, classes, etc.)
- **sks-notification-service** — push notifications via OneSignal
- **sks-classes-service** — video courses and level progression
- **sks-google-login-service** / **sks-otp-login-service** — authentication
- **sivoham_meditation DB** — dedicated MSSQL database for meditation analytics (pre-aggregated summary tables: daily/weekly/monthly/yearly/lifetime)
- **Cloudflare R2** — CDN for images, audio files, wallpapers
- **Firebase** — Authentication (Google login), push token management
- **Redis** — session caching, rate limiting
- **PM2** — process management with cluster mode
- Offline-aware (connectivity check before API calls, graceful degradation)
- Image caching (365-day stale policy, 500-image limit)
- Localization (English + Telugu, JSON-based, backend-synced)

---

## Part 2 — Features That Would Genuinely Serve Sadhaks

Prioritized by impact on daily spiritual practice.

---

### 🔴 Priority 1 — Core Practice Tools (Highest Impact)

#### 1. Daily Sadhana Tracker
A simple daily checklist tailored to each sadhak's current level:
- Did I do my Level practice today? ✓
- Did I meditate? ✓
- Did I do japa (Sivoham chanting)? ✓
- Did I read/listen to Gurudev's teaching? ✓

Each item has its own streak. A weekly heatmap (like GitHub contributions) shows consistency over time. Sadhaks are specifically instructed to practice daily — this makes that tangible and rewarding.

**Why:** The most common reason sadhaks slow down is inconsistency. Visibility creates accountability.

---

#### 2. Level-Specific Guided Practice Timer
Instead of a generic timer, a "Start Level 1 Practice" button that:
- Knows the correct duration for that level (admin-configured per level)
- Plays the correct start/end meditation sound
- Marks the session as "Level Practice" (distinct from free meditation)
- Counts toward both the meditation streak and the level-specific practice streak

**Why:** Sadhaks often ask "how long should I practice for Level 2?" — this removes the guesswork.

---

#### 3. Spiritual Diary / Experience Journal
A private, date-stamped personal journal where sadhaks record:
- Experiences during meditation (sensations, visions, movements)
- Dreams that feel spiritually significant
- Kalpataru manifestations and healing observations
- Gratitude entries
- Questions to ask Gurudev

Stored encrypted on the server (per user). Searchable by date. Optional export as PDF.

**Why:** Kundalini experiences are often vivid and unusual. Sadhaks need a sacred private space to record them. Reading their own journal over months shows them their own transformation.

---

#### 4. Japa / Mala Counter
A digital japa mala for mantra counting:
- Counter with haptic feedback on each tap
- Preset counts: 108, 1008, custom
- Mala visualization (beads lighting up)
- Tracks total mantra count over lifetime
- Supports multiple mantras (Sivoham, Om Namah Shivaya, user-defined)
- Works fully offline

**Why:** Japa is a daily practice for many sadhaks. A physical mala isn't always at hand. This serves a real daily-use need.

---

### 🟡 Priority 2 — Deepening Practice

#### 5. Kalpataru Practice Companion
The app explains Kalpataru thoroughly but has no guided practice flow. Add:
- Step-by-step interactive session (set intention → relax → connect → offer → release)
- Guided audio narration option
- Timer for the practice
- Post-session journal entry (what did I intend? what did I notice?)
- Log of past Kalpataru sessions and their outcomes over time

**Why:** People read about Kalpataru but don't know how to actually "do" it. A guided companion removes that barrier.

---

#### 6. Sadhana FAQ / Guidance
A searchable knowledge base of practical guidance:
- "What do I do if I feel heat/cold during meditation?"
- "Is it normal to shake during practice?"
- "How many times a day should I practice?"
- "What does tingling in the spine mean?"
- "Can I do Kalpataru and Kundalini Sadhana together?"

Organized by category (Physical Sensations, Frequency, Diet, Experiences, Levels). Admin-managed via dashboard. Content in English + Telugu.

**Why:** Sadhaks frequently have these questions. Currently there's no in-app answer — they have to contact support or wait for a gathering.

---

#### 7. Spiritual Calendar (Auspicious Days)
A monthly calendar view showing:
- Ekadashi dates
- Shivaratri (monthly + Maha Shivaratri)
- Guru Pournima
- Gurudev's birthday and significant dates
- Special sadhana days (admin-marked)
- User's own reminder days

Tapping a day shows why it's auspicious and what additional practice is recommended.

**Why:** Sadhaks plan their practice intensity around auspicious days. This information is scattered — having it in the app creates a natural practice rhythm.

---

#### 8. Offline Content Download
Allow sadhaks to download:
- Level 1 and Level 2 video lessons
- All bhajans and meditation sounds
- Spiritual knowledge base (Chakras, Kundalini Science, Guru Journey)
- Daily quotes cache

**Why:** Many sadhaks practice in areas with poor internet (ashrams, travel, rural areas). Spiritual practice should never depend on a data connection.

---

### 🟢 Priority 3 — Community & Connection

#### 9. Gurudev's Daily Message / Satsang Feed
A simple read-only feed:
- Short text message or quote from Gurudev — posted once daily by admin
- Optional: short audio clip (1–3 minutes)
- Optional: photo from recent gatherings or events
- No comments, no likes — keeps the space clean and sacred
- Push notification when new message is posted (opt-in)

**Why:** Between events and gatherings, sadhaks feel disconnected from Gurudev. A daily message maintains that living connection. This is one of the most requested features in spiritual apps.

---

#### 10. Verified Experience Sharing (Read-Only)
A curated section where sadhaks can:
- Submit their meditation/Kalpataru/healing experience (text, 500 chars max)
- Admin reviews and publishes selected experiences
- Others can read but not comment — purely inspirational

**Why:** Real experiences from real sadhaks are deeply validating and motivating. "I also felt that tingling — I'm on the right path" is something sadhaks constantly seek.

---

#### 11. Sadhana Partner / Small Accountability Groups
Opt-in pairing with 2–4 other sadhaks at the same level:
- Each day, each member marks their practice done (simple ✓)
- Group sees the streak heatmap of each member (no details, just ✓/✗)
- Optional: one shared goal per week set by the group
- Admin can create verified "Sadhana Circles" for dedicated practitioners

**Why:** Social accountability is one of the strongest drivers of habit formation. Even seeing that your sadhana partner practiced today creates gentle peer encouragement.

---

### ⚪ Priority 4 — Wellbeing & Milestones

#### 12. Progress Milestones & Certificates
Automatic recognition for:
- Completing Level 1 / 2 / 3 / 4 (shareable digital certificate)
- 7-day / 21-day / 30-day / 100-day meditation streaks
- 100 / 500 / 1000 total meditation sessions
- 1 lakh (100,000) Sivoham japa count
- First Kalpataru session

Each milestone shows a badge on the profile and can be shared (WhatsApp, etc.).

**Why:** Sadhaks invest deeply in their practice. Acknowledging milestones honors that investment and creates natural sharing that also serves as organic word-of-mouth.

---

#### 13. Personal Wellbeing Tracker
A simple weekly self-assessment (takes 30 seconds):
- Energy level this week (1–5)
- Sleep quality (1–5)
- Mental clarity (1–5)
- Emotional stability (1–5)
- Overall peace (1–5)

Over 3–6 months this becomes a personal chart showing how Sadhana is transforming their life. Completely private. No comparison with others.

**Why:** Sadhaks sometimes doubt whether their practice is working. This gives them objective evidence of their own transformation over time.

---

#### 14. Granular Notification Preferences
Let sadhaks choose exactly what they want:
- [ ] Gurudev's daily message
- [ ] New event announcements
- [ ] New course content
- [ ] My sadhana partner's streak reminder
- [ ] Auspicious day reminders
- [ ] Weekly progress summary

**Why:** Currently notifications appear to be binary. Granular control respects sadhaks' time and prevents notification fatigue.

---

## Summary Table

| Feature | Priority | Works Offline | Requires Backend | Effort |
|---|---|---|---|---|
| Daily Sadhana Tracker | 🔴 High | ✓ (sync when online) | Minor | Medium |
| Level-Specific Guided Timer | 🔴 High | ✓ | Minor | Low |
| Spiritual Diary / Journal | 🔴 High | ✓ | Medium | Medium |
| Japa / Mala Counter | 🔴 High | ✓ | Minor | Low |
| Kalpataru Practice Companion | 🟡 Medium | Partial | Medium | Medium |
| Sadhana FAQ / Guidance | 🟡 Medium | ✓ (cached) | Low | Medium |
| Spiritual Calendar | 🟡 Medium | ✓ (cached) | Low | Low |
| Offline Content Download | 🟡 Medium | ✓ | Medium | High |
| Gurudev's Daily Message | 🟢 Community | No | Low | Low |
| Verified Experience Sharing | 🟢 Community | No | Medium | Medium |
| Sadhana Partner Groups | 🟢 Community | No | High | High |
| Progress Milestones & Certificates | ⚪ Milestone | No | Medium | Medium |
| Personal Wellbeing Tracker | ⚪ Wellbeing | ✓ | Low | Low |
| Granular Notification Preferences | ⚪ Settings | No | Low | Low |

---

*Document generated: July 15, 2026*  
*Based on full codebase analysis of SKS-mobile-V2 Flutter app and backend microservices.*
