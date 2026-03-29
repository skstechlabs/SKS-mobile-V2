# OneSignal Notification Examples

## Sending from Dashboard (Easy Way)

### 1. Welcome Notification
**When:** After user completes registration
**How:**
1. Messages > New Push
2. Audience: Send to Particular Segment
3. Filter: External User ID = `user_firebase_uid`
4. Title: "Welcome to SKS! 🙏"
5. Message: "Your spiritual journey with Guruji begins now"
6. Send

### 2. Daily Wisdom
**When:** Every morning at 6 AM
**How:**
1. Messages > New Push
2. Audience: Send to All Subscribers
3. Title: "Daily Wisdom 🌅"
4. Message: "Start your day with Guruji's blessings"
5. Schedule: Daily at 6:00 AM
6. Send

### 3. Event Reminder
**When:** 1 day before event
**How:**
1. Messages > New Push
2. Audience: Send to All Subscribers
3. Title: "Event Tomorrow! 📅"
4. Message: "Join us for spiritual gathering at 5 PM"
5. Additional Data:
   - screen: events
6. Schedule: 1 day before event
7. Send

### 4. New Content Available
**When:** New learning content added
**How:**
1. Messages > New Push
2. Audience: Send to All Subscribers
3. Title: "New Learnings Available 📚"
4. Message: "Explore new spiritual teachings"
5. Additional Data:
   - screen: learnings
6. Send

### 5. Location-Based Notification
**When:** Event in specific state
**How:**
1. Messages > New Push
2. Audience: Send to Particular Segment
3. Filter: User Tag "state" = "Telangana"
4. Title: "Event in Your Area! 📍"
5. Message: "Join us in Hyderabad this weekend"
6. Send

## Sending via API (Advanced)

### Setup
```bash
# Get your REST API Key from OneSignal Dashboard
# Settings > Keys & IDs > REST API Key
```

### 1. Send to All Users
```bash
curl -X POST https://onesignal.com/api/v1/notifications \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YOUR_REST_API_KEY" \
  -d '{
    "app_id": "YOUR_APP_ID",
    "included_segments": ["All"],
    "headings": {"en": "Welcome to SKS"},
    "contents": {"en": "Your spiritual journey begins"}
  }'
```

### 2. Send to Specific User
```bash
curl -X POST https://onesignal.com/api/v1/notifications \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YOUR_REST_API_KEY" \
  -d '{
    "app_id": "YOUR_APP_ID",
    "include_external_user_ids": ["firebase_uid_123"],
    "headings": {"en": "Profile Complete"},
    "contents": {"en": "Welcome! Your profile is ready"}
  }'
```

### 3. Send with Image
```bash
curl -X POST https://onesignal.com/api/v1/notifications \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YOUR_REST_API_KEY" \
  -d '{
    "app_id": "YOUR_APP_ID",
    "included_segments": ["All"],
    "headings": {"en": "Daily Wisdom"},
    "contents": {"en": "Today'\''s message from Guruji"},
    "big_picture": "https://example.com/wisdom.jpg",
    "ios_attachments": {"id": "https://example.com/wisdom.jpg"}
  }'
```

### 4. Send with Deep Link
```bash
curl -X POST https://onesignal.com/api/v1/notifications \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YOUR_REST_API_KEY" \
  -d '{
    "app_id": "YOUR_APP_ID",
    "included_segments": ["All"],
    "headings": {"en": "New Event"},
    "contents": {"en": "Check out upcoming events"},
    "data": {
      "screen": "events",
      "event_id": "123"
    }
  }'
```

### 5. Send to Users with Tags
```bash
curl -X POST https://onesignal.com/api/v1/notifications \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YOUR_REST_API_KEY" \
  -d '{
    "app_id": "YOUR_APP_ID",
    "filters": [
      {"field": "tag", "key": "state", "relation": "=", "value": "Telangana"}
    ],
    "headings": {"en": "Local Event"},
    "contents": {"en": "Event in your state this weekend"}
  }'
```

### 6. Scheduled Notification
```bash
curl -X POST https://onesignal.com/api/v1/notifications \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YOUR_REST_API_KEY" \
  -d '{
    "app_id": "YOUR_APP_ID",
    "included_segments": ["All"],
    "headings": {"en": "Morning Wisdom"},
    "contents": {"en": "Start your day with blessings"},
    "send_after": "2024-03-29 06:00:00 GMT+0530"
  }'
```

### 7. Notification with Action Buttons
```bash
curl -X POST https://onesignal.com/api/v1/notifications \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YOUR_REST_API_KEY" \
  -d '{
    "app_id": "YOUR_APP_ID",
    "included_segments": ["All"],
    "headings": {"en": "Event Invitation"},
    "contents": {"en": "Will you attend tomorrow'\''s event?"},
    "buttons": [
      {"id": "yes", "text": "Yes, I'\''ll attend"},
      {"id": "no", "text": "Maybe next time"}
    ],
    "data": {
      "screen": "events"
    }
  }'
```

## Notification Templates

### Template 1: Daily Motivation
```json
{
  "title": "Daily Motivation 🌟",
  "message": "{{wisdom_quote}}",
  "schedule": "Daily at 6:00 AM",
  "audience": "All Subscribers"
}
```

### Template 2: Event Reminder
```json
{
  "title": "Event Reminder 📅",
  "message": "{{event_name}} starts in {{time_remaining}}",
  "schedule": "1 hour before event",
  "audience": "Users who registered",
  "deep_link": "events/{{event_id}}"
}
```

### Template 3: New Content
```json
{
  "title": "New {{content_type}} Available 📚",
  "message": "{{content_title}} - {{content_description}}",
  "audience": "All Subscribers",
  "deep_link": "{{content_type}}/{{content_id}}"
}
```

### Template 4: Engagement
```json
{
  "title": "We Miss You! 💙",
  "message": "It's been {{days}} days since your last visit",
  "audience": "Inactive users (7+ days)",
  "deep_link": "home"
}
```

## Automation Ideas

### 1. Welcome Series
- Day 0: Welcome message
- Day 1: Explore features
- Day 3: Join community
- Day 7: Share feedback

### 2. Event Reminders
- 7 days before: Save the date
- 1 day before: Event tomorrow
- 1 hour before: Event starting soon
- After event: Thank you message

### 3. Engagement Boosters
- Daily wisdom at 6 AM
- Weekly summary on Sunday
- Monthly highlights
- Birthday wishes

### 4. Re-engagement
- 3 days inactive: "We miss you"
- 7 days inactive: "New content available"
- 14 days inactive: "Special offer"
- 30 days inactive: "Come back"

## Best Practices

1. **Timing**
   - Morning: 6-9 AM (motivation, wisdom)
   - Afternoon: 12-2 PM (reminders)
   - Evening: 6-8 PM (events, updates)
   - Avoid: Late night (10 PM - 6 AM)

2. **Frequency**
   - Max 2-3 notifications per day
   - Space them 4+ hours apart
   - Respect user preferences

3. **Content**
   - Keep title under 50 characters
   - Keep message under 150 characters
   - Use emojis sparingly (1-2 max)
   - Clear call-to-action

4. **Targeting**
   - Use tags for personalization
   - Segment by behavior
   - Test different audiences
   - A/B test content

5. **Tracking**
   - Monitor open rates
   - Track click-through rates
   - Analyze conversion
   - Optimize based on data

## Testing Checklist

- [ ] Send test to your device
- [ ] Verify notification appears
- [ ] Click notification
- [ ] Verify deep link works
- [ ] Check tracking in dashboard
- [ ] Test on Android
- [ ] Test on iOS
- [ ] Test with app in foreground
- [ ] Test with app in background
- [ ] Test with app closed

## Monitoring

### Key Metrics
- **Delivery Rate**: Should be >95%
- **Open Rate**: Target >20%
- **Click Rate**: Target >5%
- **Conversion Rate**: Track based on goal

### Dashboard Views
1. Delivery > Overview: See all metrics
2. Delivery > Individual Message: Detailed stats
3. Audience > All Users: User engagement
4. Audience > Segments: Group performance

## Support Resources

- OneSignal Docs: https://documentation.onesignal.com/
- API Reference: https://documentation.onesignal.com/reference
- Flutter SDK: https://documentation.onesignal.com/docs/flutter-sdk-setup
- Community: https://onesignal.com/community
