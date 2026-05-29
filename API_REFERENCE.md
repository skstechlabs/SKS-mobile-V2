# SKS Mobile Application - Complete API Reference

## Base URL
- **Development**: `http://localhost:3000`
- **Production**: `https://app.sivakundalini.org`

## Authentication
All API requests (except login endpoints) require Firebase ID token in the Authorization header:
```
Authorization: Bearer <firebase_id_token>
```

---

## 1. Authentication APIs

### 1.1 Google Login

**Endpoint**: `POST /api/auth/login/google`

**Request**:
```json
{
  "mobile": "+919876543210",
  "email": "user@gmail.com",
  "name": "John Doe",
  "photo": "https://lh3.googleusercontent.com/..."
}
```

**Response**:
```json
{
  "success": true,
  "user": {
    "uid": "firebase_uid_123",
    "mobile": "+919876543210",
    "email": "user@gmail.com",
    "name": "John Doe",
    "photo": "https://...",
    "is_profile_complete": false,
    "permissions_granted": false,
    "auth_provider": "google",
    "created_at": "2024-01-15T10:00:00Z"
  },
  "is_new_user": true
}
```

### 1.2 Phone OTP Login

**Endpoint**: `POST /api/auth/login/phone`

**Request**:
```json
{
  "access_token": "msg91_access_token_from_widget"
}
```

**Response**:
```json
{
  "success": true,
  "user": {
    "uid": "phone_9876543210",
    "mobile": "+919876543210",
    "is_profile_complete": false,
    "permissions_granted": false,
    "auth_provider": "phone",
    "created_at": "2024-01-15T10:00:00Z"
  },
  "is_new_user": true
}
```

---

## 2. User Profile APIs

### 2.1 Get User Profile

**Endpoint**: `GET /api/user/profile`

**Response**:
```json
{
  "success": true,
  "user": {
    "uid": "firebase_uid_123",
    "mobile": "+919876543210",
    "email": "user@gmail.com",
    "name": "John Doe",
    "photo": "https://...",
    "gender": "Male",
    "date_of_birth": "1990-01-15",
    "age": 34,
    "address": "123 Main St",
    "city": "Bangalore",
    "state": "Karnataka",
    "pincode": "560001",
    "country": "India",
    "profession": "Software Engineer",
    "preferred_language": "en",
    "is_profile_complete": true,
    "permissions_granted": true
  }
}
```

### 2.2 Update User Profile

**Endpoint**: `PUT /api/user/profile`

**Request**:
```json
{
  "name": "John Doe",
  "mobile": "+919876543210",
  "email": "user@gmail.com",
  "gender": "Male",
  "date_of_birth": "1990-01-15",
  "address": "123 Main St",
  "city": "Bangalore",
  "state": "Karnataka",
  "pincode": "560001",
  "profession": "Software Engineer",
  "preferred_language": "en"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "user": { ... }
}
```

### 2.3 Update Permissions

**Endpoint**: `PUT /api/user/permissions`

**Request**:
```json
{
  "permissions_granted": true
}
```

**Response**:
```json
{
  "success": true,
  "message": "Permissions updated successfully"
}
```

---

## 3. Classes / Learning APIs

### 3.1 Get All Classes (Levels)

**Endpoint**: `GET /api/classes`

**Response**:
```json
{
  "success": true,
  "classes": [
    {
      "id": 1,
      "level": "Level 1",
      "title": "Foundation of Meditation",
      "description": "Learn the basics...",
      "duration": "3 days",
      "level_number": 1,
      "total_days": 3,
      "is_active": true,
      "image_url": "https://...",
      "is_unlocked": true
    },
    {
      "id": 2,
      "level": "Level 2",
      "title": "Intermediate Practices",
      "description": "Deepen your practice...",
      "duration": "3 days",
      "level_number": 2,
      "total_days": 3,
      "is_active": true,
      "image_url": "https://...",
      "is_unlocked": false,
      "unlock_requirements": "Complete Level 1"
    }
  ]
}
```

### 3.2 Get Days for a Class

**Endpoint**: `GET /api/classes/:classId/days`

**Response**:
```json
{
  "success": true,
  "days": [
    {
      "id": 1,
      "class_id": 1,
      "day_number": 1,
      "title": "Introduction to Meditation",
      "description": "Learn the fundamentals...",
      "video_duration_seconds": 3600,
      "thumbnail_url": "https://...",
      "is_unlocked": true,
      "is_completed": true,
      "completion_percentage": 100,
      "last_watched_at": "2024-01-14T15:30:00Z"
    },
    {
      "id": 2,
      "class_id": 1,
      "day_number": 2,
      "title": "Breathing Techniques",
      "description": "Master pranayama...",
      "video_duration_seconds": 3600,
      "thumbnail_url": "https://...",
      "is_unlocked": true,
      "is_completed": false,
      "completion_percentage": 45,
      "last_watched_at": "2024-01-15T10:00:00Z"
    },
    {
      "id": 3,
      "class_id": 1,
      "day_number": 3,
      "title": "Chakra Meditation",
      "description": "Activate your chakras...",
      "video_duration_seconds": 3600,
      "thumbnail_url": "https://...",
      "is_unlocked": false,
      "unlock_time": "2024-01-16T10:00:00Z",
      "unlock_message": "Complete Day 2 and wait 24 hours"
    }
  ]
}
```

### 3.3 Start Watching a Day

**Endpoint**: `POST /api/classes/days/:dayId/start`

**Response**:
```json
{
  "success": true,
  "video_url": "https://customer-xxx.cloudflarestream.com/video_id/manifest/video.m3u8?token=...",
  "session_id": "session_123",
  "languages": ["te", "hi", "en"],
  "default_language": "te",
  "video_duration_seconds": 3600,
  "last_position_seconds": 450
}
```

### 3.4 Update Watch Progress

**Endpoint**: `POST /api/classes/days/:dayId/progress`

**Request**:
```json
{
  "session_id": "session_123",
  "current_time_seconds": 930,
  "total_duration_seconds": 3600,
  "completion_percentage": 26
}
```

**Response**:
```json
{
  "success": true,
  "message": "Progress updated"
}
```

### 3.5 Mark Day as Complete

**Endpoint**: `POST /api/classes/days/:dayId/complete`

**Request**:
```json
{
  "session_id": "session_123",
  "watch_time_seconds": 3240,
  "completion_percentage": 90
}
```

**Response**:
```json
{
  "success": true,
  "day_completed": true,
  "next_day_unlocked": false,
  "next_day_unlock_time": "2024-01-16T10:00:00Z",
  "level_completed": false,
  "message": "Day completed! Next day unlocks in 24 hours."
}
```

### 3.6 Get Level Progression

**Endpoint**: `GET /api/level-progression`

**Response**:
```json
{
  "success": true,
  "current_level": 1,
  "unlocked_levels": [1],
  "level_1": {
    "completed_days": 2,
    "total_days": 3,
    "progress_percentage": 66,
    "is_completed": false
  },
  "level_2": {
    "is_locked": true,
    "unlock_requirements": "Complete Level 1",
    "unlock_time": null
  }
}
```

---

## 4. Notification APIs

### 4.1 Get User Notifications

**Endpoint**: `GET /api/notifications`

**Query Parameters**:
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)
- `is_read` (optional): Filter by read status (true/false)

**Response**:
```json
{
  "success": true,
  "notifications": [
    {
      "id": 1,
      "type": "day_unlocked",
      "title": "Day 3 Unlocked!",
      "message": "Chakra Meditation is now available",
      "action_url": "/learnings/class/1/day/3",
      "is_read": false,
      "created_at": "2024-01-16T10:00:00Z"
    },
    {
      "id": 2,
      "type": "event",
      "title": "Event Reminder",
      "message": "Maha Sivaratri celebration tomorrow",
      "action_url": "/events/123",
      "is_read": true,
      "created_at": "2024-01-15T08:00:00Z",
      "read_at": "2024-01-15T09:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "total_pages": 3
  }
}
```

### 4.2 Mark Notification as Read

**Endpoint**: `PUT /api/notifications/:id/read`

**Response**:
```json
{
  "success": true,
  "message": "Notification marked as read"
}
```

### 4.3 Mark All Notifications as Read

**Endpoint**: `PUT /api/notifications/read-all`

**Response**:
```json
{
  "success": true,
  "message": "All notifications marked as read",
  "count": 12
}
```

---

## 5. Reminder APIs

### 5.1 Get User Reminders

**Endpoint**: `GET /api/reminders`

**Response**:
```json
{
  "success": true,
  "reminders": [
    {
      "id": 1,
      "title": "Morning Meditation",
      "message": "Time for your daily practice",
      "reminder_time": "06:00:00",
      "days_of_week": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
      "is_active": true,
      "created_at": "2024-01-10T10:00:00Z"
    },
    {
      "id": 2,
      "title": "Evening Meditation",
      "message": "Wind down with meditation",
      "reminder_time": "18:00:00",
      "days_of_week": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
      "is_active": true,
      "created_at": "2024-01-10T10:05:00Z"
    }
  ]
}
```

### 5.2 Create Reminder

**Endpoint**: `POST /api/reminders`

**Request**:
```json
{
  "title": "Morning Meditation",
  "message": "Time for your daily practice",
  "reminder_time": "06:00:00",
  "days_of_week": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
  "is_active": true
}
```

**Response**:
```json
{
  "success": true,
  "message": "Reminder created successfully",
  "reminder": {
    "id": 3,
    "title": "Morning Meditation",
    "reminder_time": "06:00:00",
    "days_of_week": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
    "is_active": true
  }
}
```

### 5.3 Update Reminder

**Endpoint**: `PUT /api/reminders/:id`

**Request**:
```json
{
  "title": "Morning Meditation (Updated)",
  "reminder_time": "06:30:00",
  "is_active": true
}
```

**Response**:
```json
{
  "success": true,
  "message": "Reminder updated successfully"
}
```

### 5.4 Delete Reminder

**Endpoint**: `DELETE /api/reminders/:id`

**Response**:
```json
{
  "success": true,
  "message": "Reminder deleted successfully"
}
```

### 5.5 Toggle Reminder Active Status

**Endpoint**: `PATCH /api/reminders/:id/toggle`

**Response**:
```json
{
  "success": true,
  "message": "Reminder status updated",
  "is_active": false
}
```

---

## 6. Event APIs

### 6.1 Get All Events

**Endpoint**: `GET /api/events`

**Query Parameters**:
- `page` (optional): Page number
- `limit` (optional): Items per page
- `event_type` (optional): Filter by type (workshop, retreat, ceremony, etc.)
- `is_featured` (optional): Filter featured events

**Response**:
```json
{
  "success": true,
  "events": [
    {
      "id": 1,
      "title": "Maha Sivaratri Celebration",
      "description": "Join us for the grand celebration...",
      "event_type": "celebration",
      "event_date": "2024-03-08",
      "event_time": "18:00:00",
      "location": "Bangalore",
      "venue_details": "Sivoham Ashram, Whitefield",
      "image_url": "https://...",
      "max_participants": 500,
      "registration_fee": 0,
      "is_featured": true,
      "registration_status": "not_registered"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 25,
    "total_pages": 3
  }
}
```

### 6.2 Get Event Details

**Endpoint**: `GET /api/events/:id`

**Response**:
```json
{
  "success": true,
  "event": {
    "id": 1,
    "title": "Maha Sivaratri Celebration",
    "description": "Join us for the grand celebration...",
    "event_type": "celebration",
    "event_date": "2024-03-08",
    "event_time": "18:00:00",
    "end_date": "2024-03-09",
    "location": "Bangalore",
    "venue_details": "Sivoham Ashram, Whitefield",
    "image_url": "https://...",
    "max_participants": 500,
    "current_registrations": 234,
    "registration_fee": 0,
    "is_featured": true,
    "registration_status": "not_registered"
  }
}
```

### 6.3 Register for Event

**Endpoint**: `POST /api/events/:id/register`

**Request**:
```json
{
  "attendees": 2,
  "special_requirements": "Wheelchair access needed"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Successfully registered for event",
  "registration": {
    "id": 123,
    "event_id": 1,
    "user_uid": "firebase_uid_123",
    "attendees": 2,
    "registration_date": "2024-01-15T10:00:00Z",
    "status": "confirmed"
  }
}
```

---

## 7. Meditation APIs

### 7.1 Save Meditation Session

**Endpoint**: `POST /api/meditation/sessions`

**Request**:
```json
{
  "duration_minutes": 15,
  "completed_at": "2024-01-15T06:30:00Z"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Session saved successfully",
  "session": {
    "id": 456,
    "duration_minutes": 15,
    "completed_at": "2024-01-15T06:30:00Z"
  },
  "streak": {
    "current_streak": 7,
    "longest_streak": 15
  }
}
```

### 7.2 Get Meditation Statistics

**Endpoint**: `GET /api/meditation/stats`

**Response**:
```json
{
  "success": true,
  "stats": {
    "total_sessions": 45,
    "total_minutes": 675,
    "current_streak": 7,
    "longest_streak": 15,
    "average_duration": 15,
    "sessions_this_week": 5,
    "sessions_this_month": 22
  }
}
```

### 7.3 Get Meditation History

**Endpoint**: `GET /api/meditation/history`

**Query Parameters**:
- `page` (optional): Page number
- `limit` (optional): Items per page
- `start_date` (optional): Filter from date
- `end_date` (optional): Filter to date

**Response**:
```json
{
  "success": true,
  "sessions": [
    {
      "id": 456,
      "duration_minutes": 15,
      "completed_at": "2024-01-15T06:30:00Z"
    },
    {
      "id": 455,
      "duration_minutes": 20,
      "completed_at": "2024-01-14T06:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45
  }
}
```

---

## 8. Merchandise APIs

### 8.1 Get All Merchandise

**Endpoint**: `GET /api/merchandise`

**Response**:
```json
{
  "success": true,
  "merchandise": [
    {
      "id": "RM",
      "name": "Rudraksha Mala",
      "description": "Traditional sacred Rudraksha mala...",
      "price": 250,
      "category": "Spiritual Items",
      "image_url": "https://...",
      "is_available": true
    },
    {
      "id": "KY",
      "name": "Kalabhairava Yantram",
      "description": "Sacred Kalabhairava Yantram...",
      "price": 500,
      "category": "Spiritual Items",
      "image_url": "https://...",
      "is_available": true
    }
  ]
}
```

### 8.2 Create Purchase

**Endpoint**: `POST /api/purchases`

**Request**:
```json
{
  "items": [
    {
      "merchandise_id": "RM",
      "quantity": 2,
      "price": 250
    },
    {
      "merchandise_id": "KY",
      "quantity": 1,
      "price": 500
    }
  ],
  "total_amount": 1000,
  "shipping_address": {
    "name": "John Doe",
    "address": "123 Main St",
    "city": "Bangalore",
    "state": "Karnataka",
    "pincode": "560001",
    "mobile": "+919876543210"
  }
}
```

**Response**:
```json
{
  "success": true,
  "message": "Purchase created successfully",
  "purchase": {
    "id": 789,
    "order_number": "ORD-2024-0001",
    "total_amount": 1000,
    "status": "pending",
    "created_at": "2024-01-15T10:00:00Z"
  }
}
```

---

## 9. Content APIs

### 9.1 Get Daily Quote

**Endpoint**: `GET /api/quotes/daily`

**Response**:
```json
{
  "success": true,
  "quote": {
    "id": 1,
    "text": "The mind is everything. What you think you become.",
    "author": "Buddha",
    "category": "Wisdom",
    "language": "en"
  }
}
```

### 9.2 Get Wallpapers

**Endpoint**: `GET /api/wallpapers`

**Response**:
```json
{
  "success": true,
  "wallpapers": [
    {
      "id": 1,
      "title": "Meditation Sunrise",
      "image_url": "https://...",
      "thumbnail_url": "https://...",
      "category": "Nature",
      "downloads": 1234
    }
  ]
}
```

### 9.3 Get Gatherings

**Endpoint**: `GET /api/gatherings`

**Response**:
```json
{
  "success": true,
  "gatherings": [
    {
      "id": 1,
      "title": "Annual Retreat 2023",
      "date": "December 2023",
      "description": "A transformative experience...",
      "image_url": "https://...",
      "video_url": "https://...",
      "participants": "500+ devotees"
    }
  ]
}
```

---

## Error Responses

All APIs return errors in the following format:

```json
{
  "success": false,
  "message": "Error description",
  "error_code": "ERROR_CODE"
}
```

### Common Error Codes

- `UNAUTHORIZED` - Invalid or missing authentication token
- `FORBIDDEN` - User does not have permission
- `NOT_FOUND` - Resource not found
- `VALIDATION_ERROR` - Invalid request data
- `SERVER_ERROR` - Internal server error
- `RATE_LIMIT_EXCEEDED` - Too many requests
- `USER_BLOCKED` - User account is blocked
- `DAY_LOCKED` - Day is not yet unlocked
- `LEVEL_LOCKED` - Level is not yet unlocked

---

## Rate Limiting

- **Limit**: 100 requests per 15 minutes per IP address
- **Headers**:
  - `X-RateLimit-Limit`: Maximum requests allowed
  - `X-RateLimit-Remaining`: Remaining requests
  - `X-RateLimit-Reset`: Time when limit resets (Unix timestamp)

---

## Pagination

APIs that return lists support pagination with the following query parameters:

- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)

Response includes pagination metadata:
```json
{
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "total_pages": 5
  }
}
```

---

**Last Updated**: January 2024
**API Version**: 1.0.0
