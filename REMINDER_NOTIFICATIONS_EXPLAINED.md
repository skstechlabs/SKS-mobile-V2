# Daily Reminders & Notifications - How It Works

## Overview
The daily reminders feature allows users to receive push notifications at scheduled times to remind them of their spiritual practices (meditation, daily practice, etc.).

## How Notifications Work

### 1. When User Toggles a Reminder ON

**What Happens:**
1. User taps the switch on a reminder card (e.g., "Morning Meditation")
2. App creates/activates the reminder in the database via API
3. Backend stores the reminder with:
   - Title (e.g., "Morning Meditation")
   - Time (e.g., "06:00")
   - Days of week (0-6, where 0=Sunday, 6=Saturday)
   - Active status (true)
   - User ID

**Backend Notification Scheduling:**
The backend needs to schedule push notifications using OneSignal. This happens in the reminders API:

```javascript
// When reminder is created/activated
// Backend should schedule OneSignal notification
await scheduleOneSignalNotification({
  userId: user.id,
  title: 'Morning Meditation',
  message: 'Time for your morning meditation',
  time: '06:00',
  daysOfWeek: [0, 1, 2, 3, 4, 5, 6], // All days
  timezone: user.timezone || 'UTC'
});
```

### 2. Notification Delivery

**OneSignal handles the actual notification delivery:**
- Notifications are sent at the scheduled time
- Works even if app is closed
- Respects user's timezone
- Repeats on selected days of week

**User receives:**
- Push notification on their device
- Notification title: "Morning Meditation"
- Notification body: "Time for your morning meditation"
- Tapping notification opens the app

### 3. When User Toggles a Reminder OFF

**What Happens:**
1. User taps the switch to turn off
2. App deactivates the reminder via API
3. Backend marks reminder as inactive
4. Backend cancels the scheduled OneSignal notification

## Current Implementation Status

### ✅ Implemented (Frontend)
- Beautiful horizontal scrollable reminder cards
- Toggle switches to enable/disable reminders
- Three preset reminders:
  - Morning Meditation (6:00 AM)
  - Evening Meditation (7:00 PM)
  - Daily Practice (12:00 PM)
- API integration to create/update reminders
- Optimistic UI updates
- Error handling and user feedback

### ✅ Implemented (Backend)
- Reminders database table
- API endpoints:
  - `POST /api/reminders` - Create reminder
  - `GET /api/reminders` - Get user's reminders
  - `PUT /api/reminders/:id` - Update reminder
  - `DELETE /api/reminders/:id` - Delete reminder
  - `PATCH /api/reminders/:id/toggle` - Toggle active status
- User authentication and authorization
- Timezone support

### ⚠️ Needs Implementation (Backend)

**OneSignal Notification Scheduling:**

The backend needs to integrate with OneSignal to actually send notifications. Here's what needs to be added:

#### 1. Install OneSignal Node SDK
```bash
npm install onesignal-node
```

#### 2. Add OneSignal Configuration
```javascript
// config/onesignal.js
const OneSignal = require('onesignal-node');

const client = new OneSignal.Client({
  userAuthKey: process.env.ONESIGNAL_USER_AUTH_KEY,
  app: {
    appAuthKey: process.env.ONESIGNAL_REST_API_KEY,
    appId: process.env.ONESIGNAL_APP_ID
  }
});

module.exports = client;
```

#### 3. Schedule Notifications in Reminders API

**In `routes/reminders.js`:**

```javascript
const oneSignalClient = require('../config/onesignal');

// Helper function to schedule notification
async function scheduleReminderNotification(reminder, userId) {
  try {
    // Get user's OneSignal player ID from database
    const [users] = await db.query(
      'SELECT onesignal_player_id FROM users WHERE id = ?',
      [userId]
    );
    
    if (!users[0]?.onesignal_player_id) {
      console.log('User has no OneSignal player ID');
      return;
    }
    
    // Calculate next notification time
    const [hour, minute] = reminder.reminder_time.split(':');
    const now = new Date();
    const notificationTime = new Date();
    notificationTime.setHours(parseInt(hour), parseInt(minute), 0, 0);
    
    // If time has passed today, schedule for tomorrow
    if (notificationTime <= now) {
      notificationTime.setDate(notificationTime.getDate() + 1);
    }
    
    // Create OneSignal notification
    const notification = {
      contents: {
        en: reminder.message || `Time for ${reminder.title.toLowerCase()}`
      },
      headings: {
        en: reminder.title
      },
      include_player_ids: [users[0].onesignal_player_id],
      send_after: notificationTime.toISOString(),
      // For recurring notifications, use delayed_option
      delayed_option: 'timezone',
      delivery_time_of_day: `${hour}:${minute}:00`,
      // Schedule for specific days
      // Note: OneSignal uses different day format, may need conversion
    };
    
    const response = await oneSignalClient.createNotification(notification);
    
    // Store notification ID in database for later cancellation
    await db.query(
      'UPDATE reminders SET onesignal_notification_id = ? WHERE id = ?',
      [response.body.id, reminder.id]
    );
    
    console.log('Scheduled notification:', response.body.id);
  } catch (error) {
    console.error('Error scheduling notification:', error);
  }
}

// Helper function to cancel notification
async function cancelReminderNotification(reminderId) {
  try {
    const [reminders] = await db.query(
      'SELECT onesignal_notification_id FROM reminders WHERE id = ?',
      [reminderId]
    );
    
    if (reminders[0]?.onesignal_notification_id) {
      await oneSignalClient.cancelNotification(
        reminders[0].onesignal_notification_id
      );
      console.log('Cancelled notification:', reminders[0].onesignal_notification_id);
    }
  } catch (error) {
    console.error('Error cancelling notification:', error);
  }
}

// Update POST /api/reminders endpoint
router.post('/', verifyToken, async (req, res) => {
  // ... existing code to create reminder ...
  
  // After creating reminder, schedule notification
  if (isActive) {
    await scheduleReminderNotification(newReminder, userId);
  }
  
  // ... rest of code ...
});

// Update PATCH /api/reminders/:id/toggle endpoint
router.patch('/:id/toggle', verifyToken, async (req, res) => {
  // ... existing code ...
  
  // If activating, schedule notification
  if (newIsActive) {
    await scheduleReminderNotification(reminder, userId);
  } else {
    // If deactivating, cancel notification
    await cancelReminderNotification(id);
  }
  
  // ... rest of code ...
});
```

#### 4. Database Schema Update

Add column to store OneSignal notification ID:

```sql
ALTER TABLE reminders 
ADD COLUMN onesignal_notification_id VARCHAR(255) NULL;
```

## User Experience Flow

### Scenario 1: User Enables Morning Meditation

1. **User Action**: Taps switch on "Morning Meditation" card
2. **UI Update**: Switch turns on immediately (optimistic update)
3. **API Call**: App sends request to create/activate reminder
4. **Backend**: 
   - Creates/activates reminder in database
   - Schedules OneSignal notification for 6:00 AM daily
5. **Confirmation**: User sees success message
6. **Next Day**: User receives push notification at 6:00 AM

### Scenario 2: User Disables Evening Meditation

1. **User Action**: Taps switch on "Evening Meditation" card
2. **UI Update**: Switch turns off immediately
3. **API Call**: App sends request to deactivate reminder
4. **Backend**:
   - Marks reminder as inactive in database
   - Cancels scheduled OneSignal notification
5. **Confirmation**: User sees deactivation message
6. **Result**: No more notifications at 7:00 PM

## Testing Notifications

### Development Testing

1. **Enable a reminder** in the app
2. **Check backend logs** to verify notification was scheduled
3. **Use OneSignal dashboard** to see scheduled notifications
4. **Test immediate notification**:
   ```javascript
   // In backend, send test notification
   const notification = {
     contents: { en: 'Test notification' },
     headings: { en: 'Test' },
     include_player_ids: [playerIdFromDatabase]
   };
   await oneSignalClient.createNotification(notification);
   ```

### Production Testing

1. Enable a reminder for a time 2-3 minutes in the future
2. Wait for notification to arrive
3. Verify notification content and behavior
4. Test disabling and re-enabling

## Important Notes

### Timezone Handling
- Store user's timezone in database
- OneSignal supports timezone-aware scheduling
- Use `delivery_time_of_day` for consistent local time delivery

### Notification Permissions
- User must grant notification permissions in app
- OneSignal handles permission requests
- Check permission status before enabling reminders

### Recurring Notifications
- OneSignal supports recurring notifications
- Use `delayed_option: 'timezone'` for daily repeats
- Specify days of week for weekly patterns

### Error Handling
- Handle cases where user has no OneSignal player ID
- Gracefully handle OneSignal API failures
- Show user-friendly error messages
- Log errors for debugging

## Summary

**Current State:**
- ✅ Beautiful UI with horizontal scrollable cards
- ✅ Toggle switches work
- ✅ Reminders saved to database
- ⚠️ Notifications NOT yet scheduled (needs OneSignal integration)

**To Enable Notifications:**
1. Add OneSignal Node SDK to backend
2. Implement notification scheduling functions
3. Update reminders API to schedule/cancel notifications
4. Add database column for notification IDs
5. Test thoroughly

**User Answer:**
When a user toggles a reminder ON, the app saves it to the database. However, **actual push notifications are not yet implemented**. The backend needs to integrate with OneSignal to schedule and send notifications at the specified times. Once implemented, users will receive push notifications on their devices at the scheduled times (e.g., 6:00 AM for Morning Meditation).
