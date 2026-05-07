# Reminders Feature - Complete Implementation

## Overview
The reminders feature allows users to set daily meditation reminders with customizable times and days of the week. Users receive local push notifications at scheduled times.

## Backend Implementation

### Database Table
**Table:** `reminders`
```sql
CREATE TABLE reminders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_uid VARCHAR(128) NOT NULL,
  title VARCHAR(200) NOT NULL,
  message TEXT,
  reminder_time VARCHAR(5) NOT NULL,
  days_of_week JSON NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_uid) REFERENCES users(uid) ON DELETE CASCADE,
  INDEX idx_user_uid (user_uid),
  INDEX idx_is_active (is_active)
)
```

### API Endpoints
All endpoints require authentication (Firebase token in Authorization header).

#### 1. GET /api/reminders
Get all reminders for the authenticated user.

**Response:**
```json
{
  "success": true,
  "reminders": [
    {
      "id": 1,
      "title": "Morning Meditation",
      "message": "Time for your daily practice",
      "reminderTime": "06:00",
      "daysOfWeek": [1, 2, 3, 4, 5],
      "isActive": true,
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

#### 2. POST /api/reminders
Create a new reminder.

**Request Body:**
```json
{
  "title": "Morning Meditation",
  "message": "Time for your daily practice",
  "reminder_time": "06:00",
  "days_of_week": [1, 2, 3, 4, 5]
}
```

**Validation:**
- `title`: Required, non-empty string
- `reminder_time`: Required, HH:MM format (00:00 to 23:59)
- `days_of_week`: Required, array of integers 0-6 (0=Sunday, 6=Saturday)
- `message`: Optional string

**Error Codes:**
- `INVALID_TITLE`: Title is missing or empty
- `INVALID_TIME`: Time format is invalid
- `INVALID_DAYS`: Days array is invalid or empty

#### 3. PUT /api/reminders/:id
Update an existing reminder.

**Request Body:** (all fields optional)
```json
{
  "title": "Evening Meditation",
  "message": "Updated message",
  "reminder_time": "18:00",
  "days_of_week": [0, 1, 2, 3, 4, 5, 6],
  "is_active": true
}
```

**Error Codes:**
- `REMINDER_NOT_FOUND`: Reminder doesn't exist or doesn't belong to user
- `INVALID_TITLE`: Title is empty
- `INVALID_TIME`: Time format is invalid
- `INVALID_DAYS`: Days array is invalid
- `NO_UPDATES`: No fields provided to update

#### 4. DELETE /api/reminders/:id
Delete a reminder.

**Error Codes:**
- `REMINDER_NOT_FOUND`: Reminder doesn't exist or doesn't belong to user

#### 5. PATCH /api/reminders/:id/toggle
Toggle reminder active status (enable/disable).

**Response:**
```json
{
  "success": true,
  "message": "Reminder enabled successfully",
  "isActive": true
}
```

## Mobile App Implementation

### Files Created
1. **lib/features/reminders/reminders_screen.dart**
   - Main reminders list screen
   - Shows all user reminders with active/inactive status
   - Toggle switch to enable/disable reminders
   - Edit and delete options via popup menu
   - Pull-to-refresh support
   - Empty state with helpful message

2. **lib/features/reminders/reminder_form_screen.dart**
   - Add/Edit reminder form
   - Title and message input fields
   - Time picker for selecting reminder time
   - Day selector chips (Sun-Sat)
   - Form validation
   - Handles both create and update operations

3. **lib/core/services/reminder_notification_service.dart**
   - Local notification scheduling service
   - Uses flutter_local_notifications package
   - Schedules recurring notifications based on days of week
   - Handles notification permissions
   - Cancels notifications when reminders are disabled/deleted

### Dependencies Added
```yaml
# Local Notifications
flutter_local_notifications: ^17.0.0
timezone: ^0.9.2
```

### API Service Methods
Added to `lib/core/services/api_service.dart`:
- `getReminders()` - Fetch all reminders
- `createReminder()` - Create new reminder
- `updateReminder()` - Update existing reminder
- `deleteReminder()` - Delete reminder
- `toggleReminder()` - Toggle active status

### Routes Added
```dart
GoRoute(
  path: '/reminders',
  builder: (context, state) => const RemindersScreen(),
  routes: [
    GoRoute(
      path: 'add',
      builder: (context, state) => const ReminderFormScreen(),
    ),
    GoRoute(
      path: 'edit/:reminderId',
      builder: (context, state) {
        final reminderId = int.parse(state.pathParameters['reminderId']!);
        return ReminderFormScreen(reminderId: reminderId);
      },
    ),
  ],
),
```

### UI Access
Added alarm icon button to app bar in `main_scaffold.dart`:
- Icon: `Icons.alarm`
- Location: App bar, left of profile icon
- Action: Navigates to `/reminders`

## Features

### User Features
1. **Create Reminders**
   - Set custom title (e.g., "Morning Meditation")
   - Optional message for notification body
   - Choose specific time (24-hour format)
   - Select days of week (multiple selection)

2. **Manage Reminders**
   - View all reminders in a list
   - Toggle reminders on/off with switch
   - Edit reminder details
   - Delete reminders with confirmation

3. **Local Notifications**
   - Scheduled notifications at specified times
   - Recurring based on selected days
   - Works even when app is closed
   - Notification permissions requested on first use

### Security
- All API endpoints require Firebase authentication
- Users can only access their own reminders
- Foreign key constraint ensures data integrity

### UX Enhancements
- Auth guard protects reminders screen (login required)
- Pull-to-refresh to sync reminders
- Empty state with helpful message
- Loading states during API calls
- Success/error feedback via SnackBars
- Confirmation dialog before deletion

## Testing Checklist

### Backend Testing
- [ ] Create reminder with valid data
- [ ] Create reminder with invalid title (should fail)
- [ ] Create reminder with invalid time format (should fail)
- [ ] Create reminder with empty days array (should fail)
- [ ] Get all reminders for authenticated user
- [ ] Update reminder title
- [ ] Update reminder time and days
- [ ] Toggle reminder active status
- [ ] Delete reminder
- [ ] Try to access another user's reminder (should fail)

### Mobile App Testing
- [ ] Navigate to reminders screen from app bar
- [ ] View empty state when no reminders
- [ ] Create new reminder
- [ ] Edit existing reminder
- [ ] Toggle reminder on/off
- [ ] Delete reminder with confirmation
- [ ] Pull to refresh reminders list
- [ ] Verify notifications appear at scheduled time
- [ ] Verify notifications work when app is closed
- [ ] Test notification permissions flow
- [ ] Test with multiple reminders
- [ ] Test with all days selected
- [ ] Test with single day selected

## Future Enhancements
1. **Notification Customization**
   - Custom notification sounds
   - Vibration patterns
   - Notification priority levels

2. **Advanced Scheduling**
   - One-time reminders (specific date)
   - Interval-based reminders (every X hours)
   - Smart scheduling based on user activity

3. **Analytics**
   - Track reminder completion
   - Streak tracking
   - Usage statistics

4. **Reminder Templates**
   - Pre-configured meditation reminders
   - Quick setup for common schedules

5. **Snooze Feature**
   - Snooze notifications for X minutes
   - Configurable snooze duration

## Notes
- Notifications use exact timing with `AndroidScheduleMode.exactAllowWhileIdle`
- Timezone handling uses device local timezone
- Each reminder can have up to 7 scheduled notifications (one per day)
- Notification IDs are calculated as: `reminderId * 10 + dayOfWeek`
- When reminder is toggled off, all scheduled notifications are cancelled
- When reminder is deleted, all scheduled notifications are cancelled
- Reminders are automatically rescheduled when app loads the reminders list
