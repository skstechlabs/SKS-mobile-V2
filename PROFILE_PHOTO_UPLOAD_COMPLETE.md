# Profile Photo Upload to CDN - COMPLETE ✅

## Overview
Profile photos are now uploaded to Cloudflare R2 CDN in the `mobile/profiles/` folder with automatic old photo deletion.

## Implementation Details

### Backend

#### 1. R2 Upload Utility (`sks-backend/utils/r2Upload.js`)
- S3-compatible client for Cloudflare R2
- Upload buffer directly to R2
- Generate unique filenames
- Delete old files
- Pre-signed URL generation

#### 2. User Routes (`sks-backend/routes/user.js`)
**POST /api/user/upload-profile-photo**
- Accepts multipart/form-data with 'photo' field
- Max file size: 5MB
- Accepts only image files
- Uploads to `mobile/profiles/` folder
- Generates unique filename: `{userId}_{timestamp}.{ext}`
- Deletes old photo automatically
- Updates user.photo in database
- Returns public CDN URL

**DELETE /api/user/profile-photo**
- Deletes photo from R2
- Removes photo URL from database
- Returns success confirmation

### Frontend

#### 1. API Service (`lib/core/services/api_service.dart`)
**uploadProfilePhoto(File imageFile)**
- Reads file as bytes
- Creates FormData with MultipartFile
- Sends to backend endpoint
- Returns photo URL

**deleteProfilePhoto()**
- Calls delete endpoint
- Returns success status

#### 2. Enhanced Profile Setup Screen
- Image picker integration
- Preview before upload
- Upload during profile submission
- Graceful error handling
- Continues without photo if upload fails

## File Storage Structure

### Cloudflare R2 Bucket
```
sks-level5-uploads/
└── mobile/
    └── profiles/
        ├── user123_1712745600000.jpg
        ├── user456_1712745700000.png
        └── user789_1712745800000.jpg
```

### Filename Format
```
{userId}_{timestamp}.{extension}
```

Example: `abc123def456_1712745600000.jpg`

## API Endpoints

### Upload Profile Photo
```http
POST /api/user/upload-profile-photo
Authorization: Bearer {firebase_token}
Content-Type: multipart/form-data

Body:
- photo: (file) Image file
```

**Response:**
```json
{
  "success": true,
  "photoUrl": "https://sks-level5-uploads.xxxxx.r2.dev/mobile/profiles/user123_1712745600000.jpg",
  "message": "Profile photo uploaded successfully"
}
```

### Delete Profile Photo
```http
DELETE /api/user/profile-photo
Authorization: Bearer {firebase_token}
```

**Response:**
```json
{
  "success": true,
  "message": "Profile photo deleted successfully"
}
```

## Environment Variables Required

Add to `.env` file:
```env
# Cloudflare R2 Configuration
R2_ACCOUNT_ID=your_cloudflare_account_id
R2_ACCESS_KEY_ID=your_r2_access_key_id
R2_SECRET_ACCESS_KEY=your_r2_secret_access_key
R2_BUCKET_NAME=sks-level5-uploads
R2_PUBLIC_URL=https://sks-level5-uploads.xxxxx.r2.dev
```

## NPM Packages Required

Add to `package.json`:
```json
{
  "dependencies": {
    "@aws-sdk/client-s3": "^3.0.0",
    "@aws-sdk/s3-request-presigner": "^3.0.0",
    "multer": "^1.4.5-lts.1"
  }
}
```

Install:
```bash
cd sks-backend
npm install @aws-sdk/client-s3 @aws-sdk/s3-request-presigner multer
```

## Flutter Packages Required

Already included in project:
- `dio` - HTTP client
- `image_picker` - Image selection
- `http_parser` - Media type handling

## Usage Flow

### 1. User Selects Photo
```dart
// Tap on profile photo circle
GestureDetector(
  onTap: _pickProfileImage,
  child: Stack(
    children: [
      Container(
        // Profile photo or placeholder
      ),
      Positioned(
        // Camera icon overlay
      ),
    ],
  ),
)
```

### 2. Photo Preview
```dart
// Show selected image
Container(
  decoration: BoxDecoration(
    image: _profileImage != null
        ? DecorationImage(
            image: FileImage(_profileImage!),
            fit: BoxFit.cover,
          )
        : null,
  ),
)
```

### 3. Upload on Submit
```dart
// Upload photo first
String? photoUrl;
if (_profileImage != null) {
  final uploadResult = await _apiService.uploadProfilePhoto(_profileImage!);
  if (uploadResult['success'] == true) {
    photoUrl = uploadResult['photoUrl'];
  }
}

// Then save profile with photo URL
await _apiService.post('/api/user/profile', {
  'name': name,
  'photo': photoUrl,
  // ... other fields
});
```

## Features

### ✅ Automatic Old Photo Deletion
When user uploads a new photo, the old one is automatically deleted from R2.

### ✅ Unique Filenames
Each photo gets a unique filename with user ID and timestamp to prevent conflicts.

### ✅ File Size Limit
Maximum 5MB per image to prevent abuse and save storage.

### ✅ Image Type Validation
Only image files (image/*) are accepted.

### ✅ Error Handling
- Graceful failure if upload fails
- Profile submission continues without photo
- User can retry later

### ✅ CDN Delivery
Photos served via Cloudflare R2 CDN for fast global access.

## Testing

### Test Upload
```bash
# Using curl
curl -X POST "http://localhost:4000/api/user/upload-profile-photo" \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  -F "photo=@/path/to/image.jpg"
```

### Test Delete
```bash
curl -X DELETE "http://localhost:4000/api/user/profile-photo" \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN"
```

### Test in App
1. Login to app
2. Go to profile setup
3. Tap on profile photo circle
4. Select image from gallery
5. See preview
6. Submit form
7. Check database for photo URL
8. Verify image accessible via CDN URL

## Database Schema

The `photo` field in `users` table stores the full CDN URL:

```sql
ALTER TABLE users 
ADD COLUMN photo VARCHAR(500) NULL 
COMMENT 'Profile photo CDN URL';
```

Example value:
```
https://sks-level5-uploads.xxxxx.r2.dev/mobile/profiles/user123_1712745600000.jpg
```

## Security

### ✅ Authentication Required
All upload/delete endpoints require Firebase authentication.

### ✅ User Isolation
Users can only upload/delete their own photos.

### ✅ File Type Validation
Only image files accepted (MIME type check).

### ✅ File Size Limit
5MB maximum to prevent abuse.

### ✅ Unique Filenames
Prevents overwriting other users' photos.

## Troubleshooting

### Upload Fails
1. Check R2 credentials in `.env`
2. Verify bucket name is correct
3. Check R2 access key permissions
4. Verify file size < 5MB
5. Ensure file is an image

### Photo Not Displaying
1. Check CDN URL in database
2. Verify R2 bucket is public
3. Check CORS settings on R2
4. Verify file exists in R2

### Old Photo Not Deleted
1. Check backend logs for errors
2. Verify delete permissions on R2
3. Check if old photo URL format is correct

## Performance

- **Upload Time**: ~2-5 seconds for typical photo
- **CDN Delivery**: < 100ms globally
- **Storage Cost**: ~$0.015/GB/month on R2
- **Bandwidth**: Free egress on R2

## Future Enhancements

1. **Image Compression**
   - Compress before upload
   - Multiple sizes (thumbnail, medium, full)

2. **Image Cropping**
   - Allow user to crop before upload
   - Enforce square aspect ratio

3. **Progress Indicator**
   - Show upload progress
   - Cancel upload option

4. **Multiple Photos**
   - Photo gallery
   - Cover photo + profile photo

5. **Image Filters**
   - Apply filters before upload
   - Adjust brightness/contrast

## Status

✅ **COMPLETE** - Profile photos are now stored in CDN under `mobile/profiles/` folder!

---

**Created**: April 10, 2026
**Backend**: `sks-backend/utils/r2Upload.js`, `sks-backend/routes/user.js`
**Frontend**: `lib/core/services/api_service.dart`, `lib/features/auth/enhanced_profile_setup_screen.dart`
**Storage**: Cloudflare R2 - `mobile/profiles/` folder
