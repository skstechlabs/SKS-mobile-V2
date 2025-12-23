# Assets Folder

This folder contains all static assets for the Divine Path application.

## 📁 Folder Structure

```
assets/
├── images/          # Photos, backgrounds, thumbnails
├── icons/           # App icons, spiritual symbols
└── audio/           # Meditation music, bhajans (future)
```

## 📝 Guidelines

### Images
- Format: JPG (photos), PNG (with transparency)
- Optimization: Compress before adding
- Naming: Use lowercase with underscores (e.g., `guruji_photo.jpg`)

### Icons
- Format: PNG with transparency
- Size: 512x512px or higher
- Naming: Descriptive (e.g., `meditation_icon.png`)

### Audio
- Format: MP3 (compressed) or AAC
- Bitrate: 128-192 kbps
- Naming: Descriptive (e.g., `morning_meditation.mp3`)

## 🎨 Asset Generation

Refer to `ASSETS_GUIDE.md` in the root directory for:
- AI prompts for generating spiritual assets
- Technical specifications
- Color palette reference
- Optimization guidelines

## 📦 Adding New Assets

1. Place file in appropriate folder
2. Ensure proper naming convention
3. Optimize file size
4. Update `pubspec.yaml` if adding new folder
5. Run `flutter pub get`
6. Test on device

## 🔗 Current Assets

### Placeholder Images (Using Unsplash URLs)
The app currently uses online placeholder images. Replace with custom assets:

- Guruji image
- Event backgrounds
- Bhajan artwork
- Video thumbnails

### Required Custom Assets
- [ ] App launcher icon
- [ ] Spiritual symbol icons
- [ ] Custom backgrounds
- [ ] Meditation music files
- [ ] Bhajan audio files

## 📏 Size Recommendations

| Asset Type | Recommended Size | Format |
|------------|------------------|--------|
| App Icon | 1024x1024px | PNG |
| Feature Icons | 512x512px | PNG |
| Backgrounds | 1080x1920px | JPG/PNG |
| Event Images | 1200x800px | JPG |
| Thumbnails | 800x800px | JPG |
| Audio | 128-192 kbps | MP3 |

---

**Note**: Keep total asset size under 10MB for optimal app performance.
