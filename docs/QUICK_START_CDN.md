# CDN Images - Quick Start Guide

## For Developers

### Using CDN Images in Code

```dart
import '../../core/widgets/cached_image.dart';
import '../../core/constants/cdn_images.dart';

// Basic usage
CachedImage(
  imageUrl: CdnImages.guruji,
  width: 200,
  height: 200,
)

// With border radius
CachedImage(
  imageUrl: CdnImages.gurujiMeditation,
  width: double.infinity,
  height: 300,
  borderRadius: BorderRadius.circular(20),
)

// Circular image
CachedCircleImage(
  imageUrl: CdnImages.guruji,
  size: 100,
)
```

### Available Images

All images available in `CdnImages` class:
- `CdnImages.guruji`
- `CdnImages.gurujiLogo`
- `CdnImages.gurujiMeditation`
- `CdnImages.gurujiSmile`
- `CdnImages.kallaBairava`
- `CdnImages.kundalini`
- `CdnImages.meditation`
- `CdnImages.chakras`
- `CdnImages.shivaratri`
- `CdnImages.muladhara` (Root Chakra)
- `CdnImages.swadhisthana` (Sacral Chakra)
- `CdnImages.manipura` (Solar Plexus Chakra)
- `CdnImages.anahatha` (Heart Chakra)
- `CdnImages.vishuddha` (Throat Chakra)
- `CdnImages.ajna` (Third Eye Chakra)
- `CdnImages.sahasrara` (Crown Chakra)
- `CdnImages.guruji25` (Daily Wisdom)
- `CdnImages.guruji26` (Daily Wisdom)
- `CdnImages.guruji30` (Daily Wisdom)
- `CdnImages.guruji32` (Daily Wisdom)

## For Content Managers

### Adding New Images to CDN

1. **Upload to Cloudflare Images:**
   - Go to Cloudflare Dashboard
   - Navigate to Images
   - Upload new image
   - Copy the delivery URL

2. **Add to cdn_images.dart:**
   ```dart
   static const String newImage = '$_baseUrl/YOUR-IMAGE-ID/public';
   ```

3. **Use in app:**
   ```dart
   CachedImage(imageUrl: CdnImages.newImage)
   ```

## Benefits

✅ **Automatic Caching** - Images downloaded once, cached forever
✅ **Smooth Loading** - Skeleton loaders while images load
✅ **Offline Support** - Cached images work offline
✅ **Reduced App Size** - 12 MB saved (99% of images)
✅ **Fast Performance** - Lazy loading + memory optimization

## Troubleshooting

**Images not loading?**
- Check internet connection
- Verify CDN URL is correct
- Clear app cache

**Slow loading?**
- Check network speed
- Images cache after first load

**Build errors?**
- Run `flutter clean`
- Run `flutter pub get`
- Rebuild

## Need Help?

See full documentation:
- `CDN_MIGRATION_GUIDE.md` - Complete technical guide
- `CDN_IMPLEMENTATION_COMPLETE.md` - Implementation summary
