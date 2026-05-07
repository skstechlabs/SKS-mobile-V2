# User Blocking System Documentation

## Overview
This document describes the comprehensive user blocking system that allows administrators to permanently or temporarily block users from accessing classes. The system includes detailed audit logging, flexible restriction types, and automatic expiry handling.

## Features

### 1. Global User Blocking
- **Permanent Blocks**: Block users indefinitely until manually unblocked
- **Temporary Blocks**: Block users for a specific duration (auto-expires)
- **Audit Trail**: Complete history of all blocking/unblocking actions
- **Reason Tracking**: Mandatory reason for every block/unblock action

### 2. Granular Class Restrictions
- **All Classes**: Block access to all classes
- **Specific Level**: Block access to a specific level (e.g., Level 2)
- **Specific Class**: Block access to a single class
- **Temporary Restrictions**: Set expiry dates for restrictions

### 3. Automatic Expiry
- Temporary blocks automatically expire and unblock users
- System logs auto-unblock actions
- Expired restrictions are automatically deactivated

## Database Schema

### Users Table Additions
```sql
ALTER TABLE users 
ADD COLUMN is_blocked BOOLEAN DEFAULT FALSE,
ADD COLUMN blocked_at DATETIME NULL,
ADD COLUMN blocked_by VARCHAR(128) NULL,
ADD COLUMN block_reason TEXT NULL,
ADD COLUMN block_type ENUM('permanent', 'temporary') DEFAULT 'permanent',
ADD COLUMN block_expires_at DATETIME NULL,
ADD COLUMN unblocked_at DATETIME NULL,
ADD COLUMN unblocked_by VARCHAR(128) NULL,
ADD COLUMN unblock_reason TEXT NULL;
```

### New Tables

#### user_block_history
Tracks all blocking and unblocking actions for audit purposes.

```sql
CREATE TABLE user_block_history (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_uid VARCHAR(128) NOT NULL,
  action ENUM('block', 'unblock') NOT NULL,
  block_type ENUM('permanent', 'temporary') NULL,
  block_expires_at DATETIME NULL,
  reason TEXT NULL,
  performed_by VARCHAR(128) NOT NULL,
  performed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  additional_notes TEXT NULL,
  
  INDEX idx_user_uid (user_uid),
  INDEX idx_performed_at (performed_at),
  FOREIGN KEY (user_uid) REFERENCES users(uid) ON DELETE CASCADE
);
```

#### user_class_restrictions
Allows blocking specific classes or levels for specific users.

```sql
CREATE TABLE user_class_restrictions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_uid VARCHAR(128) NOT NULL,
  restriction_type ENUM('all_classes', 'specific_level', 'specific_class') NOT NULL,
  level_number INT NULL,
  class_id INT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  reason TEXT NULL,
  created_by VARCHAR(128) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  expires_at DATETIME NULL,
  removed_at DATETIME NULL,
  removed_by VARCHAR(128) NULL,
  
  INDEX idx_user_uid (user_uid),
  INDEX idx_restriction_type (restriction_type),
  INDEX idx_is_active (is_active),
  FOREIGN KEY (user_uid) REFERENCES users(uid) ON DELETE CASCADE,
  FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
);
```

## API Endpoints

### Admin Endpoints (Require Admin Privileges)

#### 1. Block User
**POST** `/api/admin/users/:uid/block`

Block a user from accessing classes.

**Request Body:**
```json
{
  "reason": "Violated terms of service by sharing class videos",
  "blockType": "permanent",
  "expiresInDays": null
}
```

For temporary blocks:
```json
{
  "reason": "Suspicious activity detected",
  "blockType": "temporary",
  "expiresInDays": 7
}
```

**Response:**
```json
{
  "success": true,
  "message": "User blocked successfully (permanent)",
  "blockedUser": {
    "uid": "user123",
    "name": "John Doe",
    "mobile": "+919876543210",
    "blockType": "permanent",
    "expiresAt": null,
    "reason": "Violated terms of service by sharing class videos"
  }
}
```

**Validation:**
- Reason must be at least 10 characters
- Block type must be "permanent" or "temporary"
- Temporary blocks require expiresInDays (minimum 1 day)
- User must exist and not already be blocked

#### 2. Unblock User
**POST** `/api/admin/users/:uid/unblock`

Unblock a previously blocked user.

**Request Body:**
```json
{
  "reason": "Appeal approved after review"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User unblocked successfully",
  "unblockedUser": {
    "uid": "user123",
    "name": "John Doe",
    "mobile": "+919876543210",
    "reason": "Appeal approved after review"
  }
}
```

#### 3. Get User Block Status
**GET** `/api/admin/users/:uid/block-status`

Get detailed information about a user's block status, history, and restrictions.

**Response:**
```json
{
  "success": true,
  "user": {
    "uid": "user123",
    "name": "John Doe",
    "mobile": "+919876543210",
    "email": "john@example.com",
    "isBlocked": true,
    "blockInfo": {
      "blockedAt": "2026-04-14T10:30:00.000Z",
      "blockedBy": "admin_uid",
      "reason": "Violated terms of service",
      "type": "permanent",
      "expiresAt": null
    },
    "lastUnblock": null
  },
  "history": [
    {
      "action": "block",
      "blockType": "permanent",
      "expiresAt": null,
      "reason": "Violated terms of service",
      "performedBy": "admin_uid",
      "performedAt": "2026-04-14T10:30:00.000Z",
      "notes": null
    }
  ],
  "restrictions": []
}
```

#### 4. Get All Blocked Users
**GET** `/api/admin/users/blocked`

Get a list of all currently blocked users.

**Response:**
```json
{
  "success": true,
  "count": 2,
  "blockedUsers": [
    {
      "uid": "user123",
      "name": "John Doe",
      "mobile": "+919876543210",
      "email": "john@example.com",
      "blockedAt": "2026-04-14T10:30:00.000Z",
      "blockedBy": "admin_uid",
      "reason": "Violated terms of service",
      "type": "permanent",
      "expiresAt": null
    }
  ]
}
```

#### 5. Add Class Restriction
**POST** `/api/admin/users/:uid/restrict-class`

Add a specific class restriction for a user.

**Request Body:**
```json
{
  "restrictionType": "specific_level",
  "levelNumber": 3,
  "classId": null,
  "reason": "Not ready for Level 3 content",
  "expiresInDays": 30
}
```

**Restriction Types:**
- `all_classes`: Block all classes
- `specific_level`: Block a specific level (requires levelNumber)
- `specific_class`: Block a specific class (requires classId)

**Response:**
```json
{
  "success": true,
  "message": "Class restriction added successfully",
  "restriction": {
    "userUid": "user123",
    "type": "specific_level",
    "levelNumber": 3,
    "classId": null,
    "reason": "Not ready for Level 3 content",
    "expiresAt": "2026-05-14T10:30:00.000Z"
  }
}
```

#### 6. Remove Class Restriction
**DELETE** `/api/admin/users/:uid/restrict-class/:restrictionId`

Remove a specific class restriction.

**Response:**
```json
{
  "success": true,
  "message": "Class restriction removed successfully"
}
```

## Middleware

### checkUserBlocked Middleware
**File**: `sks-backend/middleware/checkUserBlocked.js`

This middleware should be applied to all class-related endpoints to enforce blocking.

**Features:**
- Checks if user is globally blocked
- Auto-expires temporary blocks
- Checks for specific class restrictions
- Returns appropriate error responses

**Usage:**
```javascript
const { checkUserBlocked } = require('../middleware/checkUserBlocked');

router.get('/:classId/days', verifyFirebaseToken, checkUserBlocked, async (req, res) => {
  // Your route handler
});
```

**Error Responses:**

When user is blocked:
```json
{
  "success": false,
  "message": "Your account has been blocked from accessing classes",
  "error_code": "USER_BLOCKED",
  "isBlocked": true,
  "blockInfo": {
    "reason": "Violated terms of service",
    "type": "permanent",
    "expiresAt": null
  }
}
```

When class is restricted:
```json
{
  "success": false,
  "message": "You are restricted from accessing this class",
  "error_code": "CLASS_RESTRICTED",
  "isRestricted": true,
  "restrictionInfo": {
    "type": "specific_level",
    "reason": "Not ready for Level 3 content",
    "expiresAt": "2026-05-14T10:30:00.000Z"
  }
}
```

## Stored Procedures

### check_user_access
Checks if a user has access to a specific class.

```sql
CALL check_user_access('user_uid', 123, @is_blocked, @block_reason);
SELECT @is_blocked, @block_reason;
```

### block_user
Blocks a user with specified parameters.

```sql
CALL block_user(
  'user_uid',
  'admin_uid',
  'Reason for blocking',
  'permanent',
  NULL
);
```

### unblock_user
Unblocks a previously blocked user.

```sql
CALL unblock_user(
  'user_uid',
  'admin_uid',
  'Reason for unblocking'
);
```

## Mobile App Integration

### Handling Blocked Users
**File**: `SKS-mobile-V2/lib/features/learnings/class_days_list_screen.dart`

The mobile app detects blocked/restricted responses and shows appropriate dialogs:

**User Blocked Dialog:**
- Shows block reason
- Displays block type (permanent/temporary)
- Shows expiry date for temporary blocks
- Provides contact support message

**Class Restricted Dialog:**
- Shows restriction reason
- Displays restriction type
- Shows expiry date if applicable
- Provides contact support message

## Admin Requirements

### Setting Up Admin Users
To use the blocking system, users must have admin privileges:

```sql
-- Add is_admin column to users table
ALTER TABLE users ADD COLUMN is_admin BOOLEAN DEFAULT FALSE;

-- Grant admin privileges to a user
UPDATE users SET is_admin = TRUE WHERE uid = 'admin_user_uid';
```

### Admin Middleware
The `requireAdmin` middleware checks if the authenticated user has admin privileges:

```javascript
const requireAdmin = async (req, res, next) => {
  const { uid } = req.user;
  
  const [admins] = await pool.execute(
    'SELECT is_admin FROM users WHERE uid = ? AND is_admin = TRUE',
    [uid]
  );
  
  if (admins.length === 0) {
    return res.status(403).json({
      success: false,
      message: 'Access denied. Admin privileges required.',
      error_code: 'ADMIN_REQUIRED'
    });
  }
  
  next();
};
```

## Usage Examples

### Example 1: Permanently Block User for TOS Violation
```bash
curl -X POST https://api.example.com/api/admin/users/user123/block \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Shared class videos on social media, violating copyright",
    "blockType": "permanent"
  }'
```

### Example 2: Temporarily Block User for 7 Days
```bash
curl -X POST https://api.example.com/api/admin/users/user456/block \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Multiple failed login attempts detected",
    "blockType": "temporary",
    "expiresInDays": 7
  }'
```

### Example 3: Restrict User from Level 3
```bash
curl -X POST https://api.example.com/api/admin/users/user789/restrict-class \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "restrictionType": "specific_level",
    "levelNumber": 3,
    "reason": "Needs to complete meditation test first",
    "expiresInDays": 30
  }'
```

### Example 4: Unblock User After Appeal
```bash
curl -X POST https://api.example.com/api/admin/users/user123/unblock \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Appeal reviewed and approved. User agreed to follow guidelines."
  }'
```

## Security Considerations

1. **Admin Authentication**: All blocking endpoints require admin privileges
2. **Audit Trail**: Every action is logged with timestamp and admin UID
3. **Reason Mandatory**: All blocks/unblocks require a detailed reason
4. **Backend Enforcement**: Blocking is enforced on the backend, cannot be bypassed
5. **Automatic Expiry**: Temporary blocks expire automatically to prevent indefinite locks

## Monitoring and Reporting

### Get Blocking Statistics
```sql
-- Count of currently blocked users
SELECT COUNT(*) as blocked_count 
FROM users 
WHERE is_blocked = TRUE;

-- Blocked users by type
SELECT block_type, COUNT(*) as count 
FROM users 
WHERE is_blocked = TRUE 
GROUP BY block_type;

-- Recent blocking actions
SELECT * FROM user_block_history 
ORDER BY performed_at DESC 
LIMIT 20;

-- Active class restrictions
SELECT restriction_type, COUNT(*) as count 
FROM user_class_restrictions 
WHERE is_active = TRUE 
GROUP BY restriction_type;
```

## Troubleshooting

### Issue: User still has access after blocking
**Solution**: 
- Verify block was applied: `SELECT is_blocked FROM users WHERE uid = 'user_uid'`
- Check if middleware is applied to the endpoint
- Verify user is using correct account

### Issue: Temporary block not expiring
**Solution**:
- Check `block_expires_at` timestamp
- Verify middleware is checking expiry
- Manually trigger expiry check by user accessing any class endpoint

### Issue: Admin cannot block users
**Solution**:
- Verify admin has `is_admin = TRUE` in users table
- Check Firebase token is valid
- Verify admin routes are properly mounted in server.js

## Best Practices

1. **Always Provide Detailed Reasons**: Help users understand why they were blocked
2. **Use Temporary Blocks First**: Give users a chance to correct behavior
3. **Document All Actions**: Use the additional_notes field in history
4. **Review Blocks Regularly**: Check if permanent blocks can be lifted
5. **Communicate with Users**: Inform users about blocks via email/notification
6. **Escalation Path**: Provide clear appeal process for blocked users

## Future Enhancements

1. **Email Notifications**: Automatically notify users when blocked/unblocked
2. **Appeal System**: Allow users to submit appeals through the app
3. **Warning System**: Issue warnings before blocking
4. **Graduated Penalties**: Automatic escalation (warning → temp block → permanent)
5. **Admin Dashboard**: Visual interface for managing blocks
6. **Bulk Operations**: Block/unblock multiple users at once
7. **IP-based Blocking**: Block by IP address in addition to user account

## Summary

The user blocking system provides comprehensive tools for administrators to:
- ✅ Permanently or temporarily block users from all classes
- ✅ Apply granular restrictions to specific levels or classes
- ✅ Track complete audit history of all blocking actions
- ✅ Automatically expire temporary blocks
- ✅ Provide clear feedback to blocked users
- ✅ Maintain security and data integrity

This system ensures that administrators have full control over user access while maintaining transparency and accountability through detailed logging and audit trails.
