# Quick Start: User Blocking System

## Installation Steps

### 1. Run Database Migration
```bash
cd sks-backend
mysql -u your_username -p your_database < migrations/add_user_blocking_system.sql
```

Or using the migration runner:
```bash
node run-migration.js migrations/add_user_blocking_system.sql
```

### 2. Verify Migration
```sql
-- Check if tables were created
SHOW TABLES LIKE '%block%';
SHOW TABLES LIKE '%restriction%';

-- Check if columns were added to users table
DESCRIBE users;
```

### 3. Create Admin User
```sql
-- Add is_admin column if not exists
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- Grant admin privileges to your user
UPDATE users SET is_admin = TRUE WHERE uid = 'YOUR_ADMIN_UID';

-- Verify
SELECT uid, name, mobile, is_admin FROM users WHERE is_admin = TRUE;
```

### 4. Restart Server
The routes are already added to `server.js`, just restart:
```bash
# If using PM2
pm2 restart sks-api

# If running directly
npm start
```

## Quick Test

### Test 1: Block a User (Permanent)
```bash
curl -X POST http://localhost:3012/api/admin/users/TEST_USER_UID/block \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Testing permanent block functionality",
    "blockType": "permanent"
  }'
```

### Test 2: Check Block Status
```bash
curl -X GET http://localhost:3012/api/admin/users/TEST_USER_UID/block-status \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

### Test 3: Try to Access Classes (Should Fail)
```bash
curl -X GET http://localhost:3012/api/classes/1/days \
  -H "Authorization: Bearer BLOCKED_USER_TOKEN"
```

Expected response:
```json
{
  "success": false,
  "message": "Your account has been blocked from accessing classes",
  "error_code": "USER_BLOCKED",
  "isBlocked": true,
  "blockInfo": {
    "reason": "Testing permanent block functionality",
    "type": "permanent",
    "expiresAt": null
  }
}
```

### Test 4: Unblock User
```bash
curl -X POST http://localhost:3012/api/admin/users/TEST_USER_UID/unblock \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Test completed successfully"
  }'
```

### Test 5: Temporary Block (7 Days)
```bash
curl -X POST http://localhost:3012/api/admin/users/TEST_USER_UID/block \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Testing temporary block functionality",
    "blockType": "temporary",
    "expiresInDays": 7
  }'
```

## Common Use Cases

### Use Case 1: User Shared Class Videos
```bash
curl -X POST http://localhost:3012/api/admin/users/VIOLATOR_UID/block \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Shared copyrighted class videos on social media, violating terms of service",
    "blockType": "permanent"
  }'
```

### Use Case 2: Suspicious Activity (Temporary)
```bash
curl -X POST http://localhost:3012/api/admin/users/SUSPICIOUS_UID/block \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Multiple failed login attempts from different locations",
    "blockType": "temporary",
    "expiresInDays": 3
  }'
```

### Use Case 3: Restrict Specific Level
```bash
curl -X POST http://localhost:3012/api/admin/users/USER_UID/restrict-class \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "restrictionType": "specific_level",
    "levelNumber": 3,
    "reason": "User needs to complete meditation test before accessing Level 3",
    "expiresInDays": 30
  }'
```

### Use Case 4: Get All Blocked Users
```bash
curl -X GET http://localhost:3012/api/admin/users/blocked \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

## Mobile App Testing

1. **Login as blocked user** in the mobile app
2. **Navigate to Classes** tab
3. **Try to open any class**
4. **Expected**: Dialog appears saying "Account Blocked" with reason
5. **Verify**: User cannot access any class content

## Monitoring Queries

### Check Currently Blocked Users
```sql
SELECT uid, name, mobile, blocked_at, block_reason, block_type, block_expires_at
FROM users
WHERE is_blocked = TRUE
ORDER BY blocked_at DESC;
```

### Check Block History
```sql
SELECT 
  ubh.user_uid,
  u.name,
  u.mobile,
  ubh.action,
  ubh.block_type,
  ubh.reason,
  ubh.performed_at,
  ubh.performed_by
FROM user_block_history ubh
JOIN users u ON ubh.user_uid = u.uid
ORDER BY ubh.performed_at DESC
LIMIT 20;
```

### Check Active Restrictions
```sql
SELECT 
  ucr.user_uid,
  u.name,
  ucr.restriction_type,
  ucr.level_number,
  ucr.class_id,
  ucr.reason,
  ucr.expires_at
FROM user_class_restrictions ucr
JOIN users u ON ucr.user_uid = u.uid
WHERE ucr.is_active = TRUE
ORDER BY ucr.created_at DESC;
```

## Troubleshooting

### Problem: "Admin privileges required" error
**Solution:**
```sql
-- Check if user is admin
SELECT uid, name, is_admin FROM users WHERE uid = 'YOUR_UID';

-- If not admin, grant privileges
UPDATE users SET is_admin = TRUE WHERE uid = 'YOUR_UID';
```

### Problem: Middleware not blocking users
**Solution:**
1. Check if middleware is imported in routes file
2. Verify middleware is applied to the route
3. Restart the server
4. Check server logs for errors

### Problem: Temporary block not expiring
**Solution:**
- The block expires automatically when user tries to access classes
- Or manually unblock: `CALL unblock_user('user_uid', 'system', 'Expired');`

## API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/admin/users/:uid/block` | Block a user |
| POST | `/api/admin/users/:uid/unblock` | Unblock a user |
| GET | `/api/admin/users/:uid/block-status` | Get user's block status |
| GET | `/api/admin/users/blocked` | Get all blocked users |
| POST | `/api/admin/users/:uid/restrict-class` | Add class restriction |
| DELETE | `/api/admin/users/:uid/restrict-class/:id` | Remove restriction |

## Next Steps

1. ✅ Test all endpoints with Postman or curl
2. ✅ Test mobile app with blocked user
3. ✅ Set up monitoring queries
4. ✅ Create admin dashboard (optional)
5. ✅ Set up email notifications (optional)
6. ✅ Document your blocking policies
7. ✅ Train support team on unblocking process

## Support

For issues or questions:
1. Check server logs: `pm2 logs sks-api`
2. Check database: Run monitoring queries above
3. Review documentation: `USER_BLOCKING_SYSTEM_DOCUMENTATION.md`
4. Test with curl commands above

## Security Reminders

- ⚠️ Only grant admin privileges to trusted users
- ⚠️ Always provide detailed reasons for blocks
- ⚠️ Review blocked users regularly
- ⚠️ Keep audit logs for compliance
- ⚠️ Use temporary blocks when appropriate
- ⚠️ Provide clear appeal process for users
