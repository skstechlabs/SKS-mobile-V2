# Wallpaper Setup Guide

## Issue Fixed
The app was showing "No wallpapers available" because it was looking in the wrong R2 bucket path.

## Changes Made

### Backend Changes (`sks-backend/routes/wallpapers.js`)
Changed the R2 bucket prefix from `sadhaks/Wallpapers/` to `Wallpapers/`

**Before:**
```javascript
Prefix: 'sadhaks/Wallpapers/'
```

**After:**
```javascript
Prefix: 'Wallpapers/'
```

## R2 Bucket Structure

Your wallpapers should be organized as follows:

```
R2_BUCKET_NAME/
└── Wallpapers/
    ├── wallpaper1.jpg
    ├── wallpaper2.png
    ├── wallpaper3.webp
    └── ...
```

**NOT:**
```
R2_BUCKET_NAME/
└── sadhaks/
    └── Wallpapers/
        └── ...
```

## Supported Image Formats
- `.jpg` / `.jpeg`
- `.png`
- `.webp`
- `.gif`

## How to Upload Wallpapers

### Option 1: Using Cloudflare Dashboard
1. Go to Cloudflare R2 Dashboard
2. Select your bucket (R2_BUCKET_NAME)
3. Create a folder named `Wallpapers` if it doesn't exist
4. Upload images directly to the `Wallpapers/` folder

### Option 2: Using R2 API/CLI
```bash
# Using wrangler CLI
wrangler r2 object put <BUCKET_NAME>/Wallpapers/image1.jpg --file ./image1.jpg

# Or using AWS S3 CLI (compatible with R2)
aws s3 cp ./image1.jpg s3://<BUCKET_NAME>/Wallpapers/image1.jpg \
  --endpoint-url https://<ACCOUNT_ID>.r2.cloudflarestorage.com
```

## Environment Variables Required

Make sure these are set in `sks-backend/.env`:

```env
R2_BUCKET_NAME=your-bucket-name
R2_ACCESS_KEY_ID=your-access-key
R2_SECRET_ACCESS_KEY=your-secret-key
R2_PUBLIC_URL=https://pub-xxxxx.r2.dev
R2_ACCOUNT_ID=your-account-id (optional)
```

## Testing

### 1. Check Backend API
```bash
curl http://localhost:3000/api/wallpapers
```

Expected response:
```json
{
  "success": true,
  "wallpapers": [
    {
      "key": "Wallpapers/image1.jpg",
      "filename": "image1.jpg",
      "url": "https://pub-xxxxx.r2.dev/Wallpapers/image1.jpg",
      "size": 123456,
      "lastModified": "2024-01-01T00:00:00.000Z"
    }
  ],
  "count": 1
}
```

### 2. Check in App
1. Open the app
2. Go to Home page
3. Scroll to "Wisdom Wallpaper" section
4. Tap on it
5. You should see the list of available wallpapers

## Troubleshooting

### "No wallpapers available"
**Possible causes:**
1. Wallpapers are in wrong folder (should be `Wallpapers/` not `sadhaks/Wallpapers/`)
2. R2 credentials are incorrect
3. Bucket name is wrong
4. Images are not in supported formats

**Solution:**
1. Check backend logs: `npm run dev` in sks-backend
2. Look for these log messages:
   ```
   📸 Fetching wallpapers from R2...
      Bucket: your-bucket-name
      Prefix: Wallpapers/
   ✅ Found X wallpapers
   ```
3. If you see errors, check R2 configuration

### Images not loading in app
**Possible causes:**
1. R2_PUBLIC_URL is incorrect
2. Bucket is not public
3. CORS is not configured

**Solution:**
1. Make sure R2_PUBLIC_URL is correct and accessible
2. Configure R2 bucket to allow public access
3. Add CORS rules if needed:
   ```json
   [
     {
       "AllowedOrigins": ["*"],
       "AllowedMethods": ["GET"],
       "AllowedHeaders": ["*"]
     }
   ]
   ```

## Migration from Old Structure

If you have wallpapers in `sadhaks/Wallpapers/`, you need to move them:

### Using Cloudflare Dashboard:
1. Download all images from `sadhaks/Wallpapers/`
2. Upload them to `Wallpapers/`
3. Delete old `sadhaks/Wallpapers/` folder

### Using CLI:
```bash
# List current wallpapers
wrangler r2 object list <BUCKET_NAME> --prefix sadhaks/Wallpapers/

# Copy each file (repeat for each file)
wrangler r2 object get <BUCKET_NAME>/sadhaks/Wallpapers/image1.jpg --file ./temp.jpg
wrangler r2 object put <BUCKET_NAME>/Wallpapers/image1.jpg --file ./temp.jpg

# Delete old files after verification
wrangler r2 object delete <BUCKET_NAME>/sadhaks/Wallpapers/image1.jpg
```

## Recommended Wallpaper Specifications

For best results:
- **Resolution**: 1080x1920 (portrait) or higher
- **Format**: JPEG or WebP for smaller file sizes
- **File size**: < 500KB per image
- **Aspect ratio**: 9:16 (portrait) for mobile devices
- **Quality**: 80-90% JPEG quality is sufficient

## Auto-Rotation Feature

The app automatically rotates wallpapers every 15 minutes when enabled:
1. User enables "Auto-Rotate" in Wallpaper Settings
2. App downloads and caches wallpaper list
3. Changes wallpaper every 15 minutes
4. Cycles through all available wallpapers

## API Endpoints

### GET /api/wallpapers
Returns list of all available wallpapers

### GET /api/wallpapers/random
Returns a random wallpaper (used for auto-rotation)

Both endpoints now use the correct `Wallpapers/` prefix.
