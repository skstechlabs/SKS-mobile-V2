# Quick Guide: Adding a New Song

## 3-Step Process (Takes < 5 minutes)

---

## Step 1: Upload to Cloudflare R2

### Option A: Using Wrangler CLI (Recommended)
```bash
wrangler r2 object put sks-audio-files/audio/bhajans/telugu/new-song-name.mp3 --file ./new-song-name.mp3
```

### Option B: Using Cloudflare Dashboard
1. Go to Cloudflare Dashboard → R2
2. Open `sks-audio-files` bucket
3. Navigate to `audio/bhajans/telugu/` (or appropriate folder)
4. Click **Upload**
5. Select your MP3 file
6. Click **Upload**

### Option C: Using Node.js Script

Create `upload-song.js`:
```javascript
const AWS = require('aws-sdk');
const fs = require('fs');

const s3 = new AWS.S3({
  endpoint: 'https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com',
  accessKeyId: 'YOUR_ACCESS_KEY',
  secretAccessKey: 'YOUR_SECRET_KEY',
  signatureVersion: 'v4',
});

const fileName = 'new-song-name.mp3';
const fileContent = fs.readFileSync(`./${fileName}`);

s3.putObject({
  Bucket: 'sks-audio-files',
  Key: `audio/bhajans/telugu/${fileName}`,
  Body: fileContent,
  ContentType: 'audio/mpeg',
}, (err, data) => {
  if (err) {
    console.error('Upload failed:', err);
  } else {
    console.log('Upload successful!');
    console.log(`URL: https://your-bucket.r2.dev/audio/bhajans/telugu/${fileName}`);
  }
});
```

Run:
```bash
node upload-song.js
```

---

## Step 2: Add to Database

### Get Song Duration First
```bash
# Using ffprobe (part of ffmpeg)
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 new-song-name.mp3

# Or using online tool: https://www.metadata2go.com/
```

### Insert into Database

```sql
INSERT INTO audios (
  title,
  artist,
  description,
  audio_url,
  duration_seconds,
  category,
  language,
  order_index
) VALUES (
  'New Song Title',                                                    -- Song name
  'Artist Name',                                                       -- Artist (optional)
  'Beautiful devotional song about...',                                -- Description
  'https://your-bucket.r2.dev/audio/bhajans/telugu/new-song-name.mp3', -- R2 URL
  245,                                                                 -- Duration in seconds
  'bhajan',                                                            -- Category: meditation, bhajan, chant
  'telugu',                                                            -- Language: telugu, english, sanskrit
  7                                                                    -- Order (next number in sequence)
);
```

### Quick Copy-Paste Template

```sql
INSERT INTO audios (title, artist, description, audio_url, duration_seconds, category, language, order_index)
VALUES ('___TITLE___', '___ARTIST___', '___DESCRIPTION___', 'https://your-bucket.r2.dev/audio/___CATEGORY___/___LANGUAGE___/___FILENAME___.mp3', ___DURATION___, '___CATEGORY___', '___LANGUAGE___', ___ORDER___);
```

---

## Step 3: Clear Cache (If Using Redis)

```bash
# Clear all audio cache
redis-cli DEL audios:all

# Clear specific category cache
redis-cli DEL audios:category:bhajan
redis-cli DEL audios:category:meditation
```

Or restart your backend server to clear in-memory cache.

---

## Done! ✅

The new song will automatically appear in the mobile app within seconds!

- No app rebuild needed
- No app store submission needed
- Users will see it on next app launch or pull-to-refresh

---

## Verification

### Check if song is accessible:
```bash
curl https://your-bucket.r2.dev/audio/bhajans/telugu/new-song-name.mp3 -I
```

Should return:
```
HTTP/2 200
content-type: audio/mpeg
content-length: 3456789
```

### Check if song appears in API:
```bash
curl http://your-api-url/api/audios/category/bhajan
```

Should include your new song in the response.

---

## Common Issues & Solutions

### Issue: Song not appearing in app
**Solution**: 
- Clear Redis cache
- Restart backend server
- Force close and reopen mobile app

### Issue: Song URL not accessible
**Solution**:
- Check R2 bucket public access is enabled
- Verify URL is correct (no typos)
- Check CORS settings on R2 bucket

### Issue: Song plays but shows wrong duration
**Solution**:
- Update duration in database
- Use ffprobe to get accurate duration

---

## Bulk Upload Script

For uploading multiple songs at once:

```bash
#!/bin/bash
# bulk-upload.sh

CATEGORY="bhajans"
LANGUAGE="telugu"

for file in *.mp3; do
  echo "Uploading $file..."
  wrangler r2 object put "sks-audio-files/audio/$CATEGORY/$LANGUAGE/$file" --file "./$file"
  echo "✓ Uploaded: $file"
done

echo "All songs uploaded!"
```

Usage:
```bash
chmod +x bulk-upload.sh
./bulk-upload.sh
```

---

## Database Bulk Insert Template

```sql
INSERT INTO audios (title, artist, description, audio_url, duration_seconds, category, language, order_index) VALUES
('Song 1', 'Artist 1', 'Description 1', 'https://your-bucket.r2.dev/audio/bhajans/telugu/song1.mp3', 240, 'bhajan', 'telugu', 10),
('Song 2', 'Artist 2', 'Description 2', 'https://your-bucket.r2.dev/audio/bhajans/telugu/song2.mp3', 300, 'bhajan', 'telugu', 11),
('Song 3', 'Artist 3', 'Description 3', 'https://your-bucket.r2.dev/audio/bhajans/telugu/song3.mp3', 180, 'bhajan', 'telugu', 12);
```

---

## Pro Tips

1. **Naming Convention**: Use lowercase with hyphens
   - ✅ `sri-jeeveswarastakam.mp3`
   - ❌ `Sri Jeeveswarastakam.mp3`

2. **File Size**: Keep MP3 files under 10MB
   - Use 128kbps or 192kbps bitrate
   - Compress using: `ffmpeg -i input.mp3 -b:a 128k output.mp3`

3. **Order Index**: Use increments of 10 (10, 20, 30...)
   - Makes it easy to insert songs in between later

4. **Thumbnails**: Add thumbnail URLs for better UI
   ```sql
   UPDATE audios SET thumbnail_url = 'https://your-bucket.r2.dev/thumbnails/song-thumb.jpg' WHERE id = 123;
   ```

5. **Testing**: Always test the song in the app before announcing
   - Play the song
   - Check duration display
   - Verify artist/title info
   - Test pause/resume

---

## Automation Script (Node.js)

Create `add-song.js`:

```javascript
const AWS = require('aws-sdk');
const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

async function addSong(filePath, metadata) {
  try {
    // 1. Get duration
    const { stdout } = await execPromise(
      `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${filePath}"`
    );
    const duration = Math.round(parseFloat(stdout));

    // 2. Upload to R2
    const s3 = new AWS.S3({
      endpoint: process.env.R2_ENDPOINT,
      accessKeyId: process.env.R2_ACCESS_KEY,
      secretAccessKey: process.env.R2_SECRET_KEY,
      signatureVersion: 'v4',
    });

    const fileName = path.basename(filePath);
    const fileContent = fs.readFileSync(filePath);
    const key = `audio/${metadata.category}/${metadata.language}/${fileName}`;

    await s3.putObject({
      Bucket: 'sks-audio-files',
      Key: key,
      Body: fileContent,
      ContentType: 'audio/mpeg',
    }).promise();

    const audioUrl = `https://your-bucket.r2.dev/${key}`;
    console.log('✓ Uploaded to R2:', audioUrl);

    // 3. Insert into database
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
    });

    await connection.execute(
      `INSERT INTO audios (title, artist, description, audio_url, duration_seconds, category, language, order_index)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        metadata.title,
        metadata.artist,
        metadata.description,
        audioUrl,
        duration,
        metadata.category,
        metadata.language,
        metadata.orderIndex,
      ]
    );

    console.log('✓ Added to database');
    await connection.end();

    console.log('\n✅ Song added successfully!');
    console.log(`Title: ${metadata.title}`);
    console.log(`Duration: ${duration}s`);
    console.log(`URL: ${audioUrl}`);

  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Usage
addSong('./new-song.mp3', {
  title: 'New Song Title',
  artist: 'Artist Name',
  description: 'Song description',
  category: 'bhajan',
  language: 'telugu',
  orderIndex: 10,
});
```

Run:
```bash
node add-song.js
```

---

## Summary

Adding a new song is as simple as:

1. **Upload** → `wrangler r2 object put ...`
2. **Database** → `INSERT INTO audios ...`
3. **Clear Cache** → `redis-cli DEL audios:all`

**Total time: < 5 minutes** ⚡

No app rebuild, no app store submission, instant availability! 🎵
