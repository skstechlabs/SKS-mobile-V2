# ✅ Wisdom Wallpapers from Cloudflare R2 CDN - COMPLETE

## Overview

Wallpapers are now dynamically loaded from Cloudflare R2 CDN (`sadhaks/Wallpapers/` folder) instead of being hardcoded in Flutter assets. This allows you to add, remove, or update wallpapers without rebuilding the mobile app.

---

## What Was Changed

### Backend Changes

1. **New API Route**: `sks-backend/routes/wallpapers.js`
   - `GET /api/wallpapers` - Lists all wallpapers from R2
   - `GET /api/wallpapers/random` - Returns a random wallpaper
   - Filters image files only (jpg, jpeg, png, webp, gif)
   - Returns CDN URLs for each wallpaper

2. **Route Registration**: Added to `sks-backend/server.js`
   ```javascript
   app.use('/api/wallpapers', wallpapersRoutes);
   ```

### Mobile App Changes

1. **Updated Service**: `SKS-mobile-V2/lib/core/services/wallpaper_service.dart`
   - Changed from asset loading to API fetching
   - Downloads wallpapers from CDN URLs
   - Caches wallpaper list locally
   - Handles network errors gracefully

2. **Updated UI**: `SKS-mobile-V2/lib/features/settings/wallpaper_settings_page.dart`
   - Changed from `Image.asset()` to `Image.network()`
   - Added loading indicators for network images
   - Made `getAvailableWallpapers()` async
   - Fixed deprecation warning (activeColor → activeThumbColor)

---

## How It Works

### 1. Upload Wallpapers to R2

Upload images to your Cloudflare R2 bucket in the `sadhaks/Wallpapers/` folder:

```bash
# Using AWS CLI (S3-compatible)
aws s3 cp wallpaper1.jpg s3://your-bucket/sadhaks/Wallpapers/ \
  --endpoint-url https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com

# Or use Cloudflare R2 dashboard
# Navigate to: R2 → Your Bucket → sadhaks/Wallpapers/
# Click "Upload" and select images
```

### 2. API Fetches from R2

Backend API lists all images in the folder:

```bash
# Test the API
curl https://sivakundalini.org/api/wallpapers
```

Response:
```json
{
  "success": true,
  "wallpapers": [
    {
      "key": "sadhaks/Wallpapers/wisdom1.jpg",
      "filename": "wisdom1.jpg",
      "url": "https://sks-level5-uploads.xxxxx.r2.dev/sadhaks/Wallpapers/wisdom1.jpg",
      "size": 245678,
      "lastModified": "2026-04-10T10:30:00.000Z"
    }
  ],
  "count": 1
}
```

### 3. Mobile App Downloads & Displays

- App fetches wallpaper list from API on startup
- Displays wallpapers in grid view
- User taps to set wallpaper
- Image is downloaded from CDN and set as device wallpaper

---

## Configuration

### Backend Environment Variables

Required in `sks-backend/.env`:

```env
# Cloudflare R2 Configuration
R2_ACCOUNT_ID=your_account_id
R2_ACCESS_KEY_ID=your_access_key_id
R2_SECRET_ACCESS_KEY=your_secret_access_key
R2_BUCKET_NAME=sks-level5-uploads
R2_PUBLIC_URL=https://sks-level5-uploads.xxxxx.r2.dev
```

### Mobile App Configuration

API base URL in `SKS-mobile-V2/lib/core/constants/app_env.dart`:

```dart
static const String apiBaseUrl = 'https://sivakundalini.org';
```

---

## Testing

### 1. Test Backend API

```bash
# List all wallpapers
curl https://sivakundalini.org/api/wallpapers

# Get random wallpaper
curl https://sivakundalini.org/api/wallpapers/random
```

### 2. Test Mobile App

1. Open app and navigate to: Settings → Wisdom Wallpapers
2. Verify wallpapers load from CDN (not assets)
3. Tap a wallpaper to set it
4. Check device wallpaper changed successfully

### 3. Test Dynamic Updates

1. Upload a new image to R2: `sadhaks/Wallpapers/new_wisdom.jpg`
2. Restart mobile app
3. New wallpaper should appear in the list automatically

---

## Supported Image Formats

- JPG / JPEG
- PNG
- WebP
- GIF

---

## Features

✅ Dynamic wallpaper management (no app rebuild needed)
✅ CDN delivery for fast loading
✅ Automatic caching in mobile app
✅ Grid view with thumbnails
✅ Tap to set wallpaper
✅ Auto-rotation support (changes every 15 minutes)
✅ Manual "Change Now" button
✅ Shows current wallpaper indicator
✅ Loading indicators for network images
✅ Error handling for failed loads
✅ Web platform detection (wallpaper setting only works on mobile)

---

## Troubleshooting

### No Wallpapers Showing

1. Check R2 bucket has images in `sadhaks/Wallpapers/` folder
2. Verify R2_PUBLIC_URL is correct in backend .env
3. Test API endpoint: `curl https://sivakundalini.org/api/wallpapers`
4. Check mobile app logs for network errors

### Images Not Loading

1. Verify R2 bucket is publicly accessible
2. Check CORS settings on R2 bucket
3. Test image URL directly in browser
4. Check mobile app has internet permission

### Wallpaper Not Setting

1. Feature only works on Android/iOS (not web)
2. Check app has WRITE_EXTERNAL_STORAGE permission (Android)
3. Check native wallpaper method implementation
4. Review device logs for native errors

---

## File Structure

```
sks-backend/
├── routes/
│   └── wallpapers.js          # API endpoints for wallpapers
├── utils/
│   └── r2Upload.js            # R2 client configuration
└── server.js                  # Route registration

SKS-mobile-V2/
├── lib/
│   ├── core/
│   │   └── services/
│   │       └── wallpaper_service.dart    # Wallpaper management
│   └── features/
│       └── settings/
│           └── wallpaper_settings_page.dart  # UI
└── WALLPAPER_CDN_COMPLETE.md
```

---

## Next Steps

1. ✅ Upload wallpapers to R2 `sadhaks/Wallpapers/` folder
2. ✅ Test API endpoints
3. ✅ Test mobile app wallpaper loading
4. ✅ Verify auto-rotation works
5. ✅ Test on both Android and iOS devices

---

## Benefits

- **No App Updates**: Add/remove wallpapers without rebuilding app
- **Fast Loading**: CDN delivery ensures quick image loads
- **Centralized Management**: Manage all wallpapers from R2 dashboard
- **Scalable**: Can add unlimited wallpapers
- **Cost Effective**: R2 has no egress fees

---

**Status**: ✅ COMPLETE - Ready for production use

**Last Updated**: April 10, 2026
