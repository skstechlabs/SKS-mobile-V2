# Meditation Sounds - Cloudflare R2 Setup

## Overview
Meditation timer sounds are downloaded from Cloudflare R2 CDN and cached locally on the device. This allows language-specific sounds without bloating the APK.

## Cloudflare R2 Folder Structure

```
sks-audio-files/
└── audio/
    └── meditation/
        ├── en/
        │   ├── Meditation_start.mp3
        │   └── Meditation_end.mp3
        ├── te/
        │   ├── Meditation_start.mp3
        │   └── Meditation_end.mp3
        ├── hi/
        │   ├── Meditation_start.mp3
        │   └── Meditation_end.mp3
        └── [other language codes]/
            ├── Meditation_start.mp3
            └── Meditation_end.mp3
```

## Full CDN URLs

### English (en)
- **Start Sound**: `https://pub-feda269d36484d78b7cfc71353b6d67c.r2.dev/sks-audio-files/audio/meditation/en/Meditation_start.mp3`
- **End Sound**: `https://pub-feda269d36484d78b7cfc71353b6d67c.r2.dev/sks-audio-files/audio/meditation/en/Meditation_end.mp3`

### Telugu (te)
- **Start Sound**: `https://pub-feda269d36484d78b7cfc71353b6d67c.r2.dev/sks-audio-files/audio/meditation/te/Meditation_start.mp3`
- **End Sound**: `https://pub-feda269d36484d78b7cfc71353b6d67c.r2.dev/sks-audio-files/audio/meditation/te/Meditation_end.mp3`

### Hindi (hi) - Future
- **Start Sound**: `https://pub-feda269d36484d78b7cfc71353b6d67c.r2.dev/sks-audio-files/audio/meditation/hi/Meditation_start.mp3`
- **End Sound**: `https://pub-feda269d36484d78b7cfc71353b6d67c.r2.dev/sks-audio-files/audio/meditation/hi/Meditation_end.mp3`

## How It Works

1. **First Launch**: App downloads meditation sounds based on selected language
2. **Caching**: Files stored in app's documents directory (`meditation_sounds/`)
3. **Subsequent Uses**: Sounds played from cache (no internet needed)
4. **Language Change**: New sounds downloaded automatically for new language
5. **Fallback**: If download fails, app shows error (no fallback assets)

## Local Cache Location

**Android**: `/data/data/com.spiritual.app/app_flutter/meditation_sounds/`
- `en_Meditation_start.mp3`
- `en_Meditation_end.mp3`
- `te_Meditation_start.mp3`
- `te_Meditation_end.mp3`

Files are prefixed with language code to support multiple languages simultaneously.

## Upload Instructions

### Upload to Cloudflare R2

1. **Create folder structure** in your R2 bucket:
   ```
   sks-audio-files/audio/meditation/en/
   sks-audio-files/audio/meditation/te/
   ```

2. **Upload English files** to `meditation/en/`:
   - `Meditation_start.mp3` (English start sound)
   - `Meditation_end.mp3` (English end sound)

3. **Upload Telugu files** to `meditation/te/`:
   - `Meditation_start.mp3` (Telugu start sound)
   - `Meditation_end.mp3` (Telugu end sound)

4. **Verify URLs** are accessible:
   ```bash
   curl -I https://pub-feda269d36484d78b7cfc71353b6d67c.r2.dev/sks-audio-files/audio/meditation/en/Meditation_start.mp3
   ```

5. **Test in app**: Change language and open meditation timer

## File Requirements

- **Format**: MP3 (recommended for compatibility)
- **Size**: Keep under 2MB per file for fast downloads
- **Quality**: 128-192 kbps is sufficient for meditation sounds
- **Duration**: 
  - Start sound: 3-10 seconds
  - End sound: 3-10 seconds

## Adding New Languages

To add a new language (e.g., Hindi):

1. **Create folder**: `sks-audio-files/audio/meditation/hi/`
2. **Upload files**: `Meditation_start.mp3`, `Meditation_end.mp3`
3. **Add language** to app's supported languages
4. **No code changes needed** - app automatically uses language code

## Testing

1. **Test download**: Open meditation timer for first time
2. **Check logs**: Look for download success messages
3. **Test offline**: Enable airplane mode, play sounds should work
4. **Test language switch**: Change language, sounds should re-download

## Troubleshooting

### Sounds not playing?
- Check Cloudflare R2 URLs are publicly accessible
- Verify folder structure matches exactly
- Check file names are case-sensitive: `Meditation_start.mp3` not `meditation_start.mp3`
- Look at app logs for download errors

### Wrong language playing?
- Clear app cache and restart
- Check language code is correct (en, te, hi, etc.)
- Verify files exist for that language code

### Download failing?
- Check internet connection
- Verify R2 bucket has public read access
- Check file sizes are reasonable (<2MB)

## Current Status

✅ Code updated to download from CDN
✅ Caching implemented with language support
✅ Fallback removed (CDN-only approach)
⏳ **PENDING**: Upload files to Cloudflare R2

**Next Step**: Upload meditation sound files to R2 bucket following the folder structure above.
