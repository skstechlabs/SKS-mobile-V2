# Image Upload Checklist for Recent Gatherings

## Images to Upload to CDN

The following images need to be uploaded to a CDN or web server:

### Location
`SKS-mobile-V2/assets/images/recentGatherings/`

### Files (Total: ~2.9 MB)
1. `Bliss_Center.jpeg` (288 KB)
2. `GuruPoornima_2025.jpg` (1.4 MB)
3. `MahaSivaratri_2025.jpg` (846 KB)
4. `SKS_8th_anniversary.jpg` (202 KB)
5. `Vastra_Daanam.jpeg` (219 KB)

## Upload Options

### Option 1: Firebase Storage (Recommended)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize Firebase in your project
firebase init storage

# Upload images
firebase storage:upload assets/images/recentGatherings/Bliss_Center.jpeg gatherings/Bliss_Center.jpeg
firebase storage:upload assets/images/recentGatherings/GuruPoornima_2025.jpg gatherings/GuruPoornima_2025.jpg
firebase storage:upload assets/images/recentGatherings/MahaSivaratri_2025.jpg gatherings/MahaSivaratri_2025.jpg
firebase storage:upload assets/images/recentGatherings/SKS_8th_anniversary.jpg gatherings/SKS_8th_anniversary.jpg
firebase storage:upload assets/images/recentGatherings/Vastra_Daanam.jpeg gatherings/Vastra_Daanam.jpeg

# Get public URLs from Firebase Console
# Storage > Files > Right-click > Get download URL
```

### Option 2: AWS S3
```bash
# Install AWS CLI
# Upload to S3
aws s3 cp assets/images/recentGatherings/ s3://your-bucket/gatherings/ --recursive

# Make public (if needed)
aws s3api put-object-acl --bucket your-bucket --key gatherings/Bliss_Center.jpeg --acl public-read
# Repeat for all files

# URLs will be:
# https://your-bucket.s3.amazonaws.com/gatherings/Bliss_Center.jpeg
```

### Option 3: Self-Hosted Backend
```bash
# Create uploads directory in backend
mkdir -p sks-backend/uploads/gatherings

# Copy images
cp SKS-mobile-V2/assets/images/recentGatherings/* sks-backend/uploads/gatherings/

# Images will be accessible at:
# http://your-server:3012/uploads/gatherings/Bliss_Center.jpeg
```

## After Upload: Update Database

Once images are uploaded, update the database with actual URLs:

```sql
-- Update with your actual CDN URLs
UPDATE gatherings SET image_url = 'https://your-cdn.com/gatherings/SKS_8th_anniversary.jpg' WHERE title = 'Grand celebrations of SKS 8th Anniversary';
UPDATE gatherings SET image_url = 'https://your-cdn.com/gatherings/Vastra_Daanam.jpeg' WHERE title = 'Vastra Daanam';
UPDATE gatherings SET image_url = 'https://your-cdn.com/gatherings/Bliss_Center.jpeg' WHERE title = 'Meditation in SKS Bliss Center';
UPDATE gatherings SET image_url = 'https://your-cdn.com/gatherings/GuruPoornima_2025.jpg' WHERE title = 'Guru Poornima & Gurudev Janmadinam';
UPDATE gatherings SET image_url = 'https://your-cdn.com/gatherings/MahaSivaratri_2025.jpg' WHERE title = 'MahaSivaratri 2025';
```

## Verification

1. Check images are accessible via browser
2. Restart mobile app
3. Navigate to Home page
4. Scroll to "Recent Gatherings" section
5. Verify all images load correctly
6. Tap on gathering to test video link

## Image Optimization (Optional)

To reduce load times and bandwidth:

```bash
# Install ImageMagick
brew install imagemagick  # macOS
# or
apt-get install imagemagick  # Linux

# Optimize images (reduce quality to 85%, resize if needed)
convert Bliss_Center.jpeg -quality 85 -resize 600x400^ Bliss_Center_optimized.jpeg
convert GuruPoornima_2025.jpg -quality 85 -resize 600x400^ GuruPoornima_2025_optimized.jpg
convert MahaSivaratri_2025.jpg -quality 85 -resize 600x400^ MahaSivaratri_2025_optimized.jpg
convert SKS_8th_anniversary.jpg -quality 85 -resize 600x400^ SKS_8th_anniversary_optimized.jpg
convert Vastra_Daanam.jpeg -quality 85 -resize 600x400^ Vastra_Daanam_optimized.jpeg
```

This can reduce total size from 2.9 MB to ~500 KB without visible quality loss.

## Troubleshooting

### Images not loading in app
- Check CORS settings on CDN
- Verify URLs are publicly accessible
- Check network connectivity
- Look for errors in app logs

### Images loading slowly
- Use CDN with global distribution
- Optimize image sizes
- Enable caching headers
- Consider WebP format for better compression

## Future Enhancements

1. **Lazy Loading** - Load images only when visible
2. **Caching** - Cache images locally on device
3. **Thumbnails** - Generate smaller thumbnails for list view
4. **Progressive Loading** - Show low-res first, then high-res
5. **Admin Panel** - Upload images directly from web interface
