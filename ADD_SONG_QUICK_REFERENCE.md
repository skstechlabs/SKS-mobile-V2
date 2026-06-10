# 🎵 Add New Song - Quick Reference Card

**3 Simple Steps to Add a New Song (No App Rebuild Required!)**

---

## Step 1: Upload to Cloudflare R2

### Using Wrangler CLI (Recommended)

```bash
wrangler r2 object put sks-audio-files/audio/bhajans/new-song.mp3 --file ./new-song.mp3
```

### Using Cloudflare Dashboard

1. Go to R2 → `sks-audio-files` bucket
2. Navigate to `audio/bhajans/` (or appropriate folder)
3. Click "Upload"
4. Select your audio file
5. Copy the public URL

**Public URL Format:**
```
https://pub-xxxxx.r2.dev/audio/bhajans/new-song.mp3
```

---

## Step 2: Get Audio Duration

### Using ffprobe (Recommended)

```bash
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 ./new-song.mp3
```

Output: `245.123` (seconds)

### Using Media Player

1. Open file in VLC or Windows Media Player
2. Note duration (e.g., 4:05)
3. Convert to seconds: `4 × 60 + 5 = 245`

---

## Step 3: Add to Database

```sql
USE [your_database_name];
GO

INSERT INTO audios (
    title, 
    artist, 
    description, 
    audio_url, 
    thumbnail_url,
    duration_seconds, 
    category, 
    language, 
    order_index
) 
VALUES (
    'New Song Title',                                                    -- title
    'Artist Name',                                                       -- artist
    'Beautiful devotional song',                                         -- description
    'https://pub-xxxxx.r2.dev/audio/bhajans/new-song.mp3',             -- audio_url (from Step 1)
    'https://pub-xxxxx.r2.dev/thumbnails/bhajan-thumb.jpg',            -- thumbnail_url (optional)
    245,                                                                 -- duration_seconds (from Step 2)
    'bhajan',                                                            -- category: meditation, bhajan, chant
    'telugu',                                                            -- language: telugu, english, sanskrit
    10                                                                   -- order_index (display order)
);
GO
```

---

## ✅ Done!

The app will automatically fetch the new song on next launch. No rebuild needed!

---

## 📋 Field Reference

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `title` | ✅ Yes | Song title | `'Sri Jeeveswarastakam'` |
| `artist` | ❌ No | Artist/composer name | `'Sai Vijay'` |
| `description` | ❌ No | Brief description | `'Sacred hymn'` |
| `audio_url` | ✅ Yes | R2 public URL | `'https://pub-xxx.r2.dev/...'` |
| `thumbnail_url` | ❌ No | Thumbnail image URL | `'https://pub-xxx.r2.dev/...'` |
| `duration_seconds` | ✅ Yes | Duration in seconds | `309` |
| `category` | ✅ Yes | Song category | `'bhajan'`, `'meditation'`, `'chant'` |
| `language` | ✅ Yes | Song language | `'telugu'`, `'english'`, `'sanskrit'` |
| `order_index` | ❌ No | Display order (default: 0) | `1`, `2`, `3` |
| `lyrics` | ❌ No | Song lyrics | `'Om Namah Shivaya...'` |

---

## 🎯 Categories

- `meditation` - Meditation music, chanting
- `bhajan` - Devotional songs
- `chant` - Mantras, chants

---

## 🌐 Languages

- `telugu` - Telugu songs
- `english` - English songs
- `sanskrit` - Sanskrit chants
- `hindi` - Hindi songs
- `tamil` - Tamil songs

---

## 📁 R2 Folder Structure

```
sks-audio-files/
├── audio/
│   ├── meditation/
│   │   └── your-meditation.mp3
│   ├── bhajans/
│   │   └── your-bhajan.mp3
│   └── chants/
│       └── your-chant.mp3
└── thumbnails/
    ├── meditation-thumb.jpg
    └── bhajan-thumb.jpg
```

---

## 🔄 Update Existing Song

```sql
UPDATE audios 
SET 
    title = 'Updated Title',
    artist = 'Updated Artist',
    audio_url = 'https://pub-xxxxx.r2.dev/audio/bhajans/updated.mp3',
    updated_at = GETDATE()
WHERE id = 5;
```

---

## 🗑️ Remove Song (Soft Delete)

```sql
-- Hide from app (recommended)
UPDATE audios 
SET is_active = 0, updated_at = GETDATE() 
WHERE id = 5;

-- Reactivate later
UPDATE audios 
SET is_active = 1, updated_at = GETDATE() 
WHERE id = 5;

-- Permanent delete (not recommended)
DELETE FROM audios WHERE id = 5;
```

---

## 🔍 Verify Addition

```sql
-- Check if song was added
SELECT id, title, category, language, duration_seconds 
FROM audios 
WHERE title = 'New Song Title';

-- Check all songs in category
SELECT id, title, artist, order_index 
FROM audios 
WHERE category = 'bhajan' AND is_active = 1 
ORDER BY order_index;
```

---

## 🧪 Test in App

1. **Restart Flutter app**
2. **Navigate to songs section**
3. **New song should appear in list**
4. **Play to verify**

---

## 💡 Pro Tips

### Batch Insert Multiple Songs

```sql
INSERT INTO audios (title, artist, audio_url, duration_seconds, category, language, order_index) 
VALUES
('Song 1', 'Artist 1', 'https://pub-xxx.r2.dev/audio/bhajans/song1.mp3', 240, 'bhajan', 'telugu', 1),
('Song 2', 'Artist 2', 'https://pub-xxx.r2.dev/audio/bhajans/song2.mp3', 300, 'bhajan', 'telugu', 2),
('Song 3', 'Artist 3', 'https://pub-xxx.r2.dev/audio/bhajans/song3.mp3', 180, 'bhajan', 'telugu', 3);
```

### Reorder Songs

```sql
-- Update order_index to change display order
UPDATE audios SET order_index = 1 WHERE id = 10;
UPDATE audios SET order_index = 2 WHERE id = 8;
UPDATE audios SET order_index = 3 WHERE id = 12;
```

### Add Lyrics

```sql
UPDATE audios 
SET lyrics = 'Om Namah Shivaya
Om Namah Shivaya
Om Namah Shivaya
Shivaya Namah Om',
    updated_at = GETDATE()
WHERE id = 5;
```

### Check Popular Songs

```sql
SELECT TOP 10 
    title, 
    artist, 
    play_count, 
    category 
FROM audios 
WHERE is_active = 1 
ORDER BY play_count DESC;
```

---

## 🚨 Common Mistakes

❌ **Wrong URL format**
```sql
-- Wrong: Local file path
audio_url = 'C:\Users\audio\song.mp3'

-- Correct: R2 public URL
audio_url = 'https://pub-xxxxx.r2.dev/audio/bhajans/song.mp3'
```

❌ **Duration in minutes instead of seconds**
```sql
-- Wrong: 4 minutes
duration_seconds = 4

-- Correct: 4 minutes = 240 seconds
duration_seconds = 240
```

❌ **Invalid category**
```sql
-- Wrong: Custom category
category = 'my-songs'

-- Correct: Use predefined categories
category = 'bhajan'  -- or 'meditation', 'chant'
```

---

## 📞 Need Help?

1. Check if R2 file is publicly accessible:
   ```bash
   curl -I https://pub-xxxxx.r2.dev/audio/bhajans/new-song.mp3
   ```

2. Verify database record:
   ```sql
   SELECT * FROM audios WHERE id = [your_new_id];
   ```

3. Test API endpoint:
   ```bash
   curl https://app.sivakundalini.org/api/audios/[your_new_id]
   ```

---

**That's it! Your new song is live! 🎉**
