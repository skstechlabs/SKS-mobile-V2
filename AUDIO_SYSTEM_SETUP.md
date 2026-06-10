# Dynamic Audio System Setup Guide

## Overview
This guide explains how to set up a dynamic audio system with Cloudflare R2 storage, caching, and database metadata for the SKS mobile app.

---

## 1. Database Schema (Microsoft SQL Server)

### Create Audio Table

```sql
-- Create audios table
CREATE TABLE audios (
    id INT IDENTITY(1,1) PRIMARY KEY,
    title NVARCHAR(255) NOT NULL,
    artist NVARCHAR(255),
    description NVARCHAR(MAX),
    audio_url NVARCHAR(500) NOT NULL,
    thumbnail_url NVARCHAR(500),
    duration_seconds INT NOT NULL,
    category NVARCHAR(50) NOT NULL, -- 'meditation', 'bhajan', 'chant', etc.
    lyrics NVARCHAR(MAX),
    language NVARCHAR(50) NOT NULL, -- 'telugu', 'english', 'sanskrit', etc.
    order_index INT DEFAULT 0,
    is_active BIT DEFAULT 1,
    play_count INT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

-- Create indexes for better performance
CREATE INDEX idx_category ON audios(category);
CREATE INDEX idx_language ON audios(language);
CREATE INDEX idx_is_active ON audios(is_active);
CREATE INDEX idx_order_index ON audios(order_index);

-- Create trigger for updated_at
CREATE TRIGGER trg_audios_updated_at
ON audios
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE audios
    SET updated_at = GETDATE()
    FROM audios a
    INNER JOIN inserted i ON a.id = i.id;
END;
GO
```

### Sample Data

```sql
-- Insert sample meditation music
INSERT INTO audios (title, artist, description, audio_url, duration_seconds, category, language, order_index) 
VALUES
('Sivoham Chanting (15 min)', 'Gurudev', 'Sivoham Chanting with Sivoham mantra', 'https://your-r2-bucket.r2.dev/audio/sivoham-15min.mp3', 900, 'meditation', 'sanskrit', 1),
('Sivoham Chanting (10 min)', 'Gurudev', 'Short Sivoham Chanting session', 'https://your-r2-bucket.r2.dev/audio/sivoham-10min.mp3', 600, 'meditation', 'sanskrit', 2);

-- Insert sample bhajans
INSERT INTO audios (title, artist, description, audio_url, duration_seconds, category, language, order_index) 
VALUES
('Sri Jeeveswarastakam', 'Sai Vijay', 'Sacred eight-verse hymn glorifying Gurudev', 'https://your-r2-bucket.r2.dev/audio/sri-jeeveswarastakam.mp3', 309, 'bhajan', 'telugu', 1),
('Gundello Gudi', 'Divine Voices', 'Soulful Telugu devotional song', 'https://your-r2-bucket.r2.dev/audio/gundello-gudi.mp3', 263, 'bhajan', 'telugu', 2),
('Nirvana Shatkam', 'Sacred Sounds', 'Timeless Advaita composition by Adi Shankaracharya', 'https://your-r2-bucket.r2.dev/audio/nirvana-shatkam.mp3', 347, 'bhajan', 'sanskrit', 3);
```

---

## 2. Cloudflare R2 Setup

### Step 1: Create R2 Bucket

1. Log in to Cloudflare Dashboard
2. Go to **R2 Object Storage**
3. Click **Create Bucket**
4. Name: `sks-audio-files` (or your preferred name)
5. Location: Choose closest to your users
6. Click **Create Bucket**

### Step 2: Configure Public Access

1. Go to your bucket settings
2. Click **Settings** → **Public Access**
3. Enable **Allow Public Access**
4. Note your R2 public URL: `https://your-bucket-name.r2.dev`

### Step 3: Upload Audio Files

#### Option A: Using Cloudflare Dashboard
1. Go to your bucket
2. Click **Upload**
3. Create folder structure:
   ```
   audio/
   ├── meditation/
   │   ├── sivoham-15min.mp3
   │   └── sivoham-10min.mp3
   ├── bhajans/
   │   ├── sri-jeeveswarastakam.mp3
   │   ├── gundello-gudi.mp3
   │   └── nirvana-shatkam.mp3
   └── chants/
       └── ...
   ```

#### Option B: Using Wrangler CLI
```bash
# Install Wrangler
npm install -g wrangler

# Login to Cloudflare
wrangler login

# Upload files
wrangler r2 object put sks-audio-files/audio/meditation/sivoham-15min.mp3 --file ./sivoham-15min.mp3
```

#### Option C: Using S3-Compatible API
```javascript
const AWS = require('aws-sdk');

const s3 = new AWS.S3({
  endpoint: 'https://your-account-id.r2.cloudflarestorage.com',
  accessKeyId: 'YOUR_ACCESS_KEY_ID',
  secretAccessKey: 'YOUR_SECRET_ACCESS_KEY',
  signatureVersion: 'v4',
});

// Upload file
const fs = require('fs');
const fileContent = fs.readFileSync('./sivoham-15min.mp3');

s3.putObject({
  Bucket: 'sks-audio-files',
  Key: 'audio/meditation/sivoham-15min.mp3',
  Body: fileContent,
  ContentType: 'audio/mpeg',
}, (err, data) => {
  if (err) console.error(err);
  else console.log('Upload successful:', data);
});
```

### Step 4: Get R2 API Credentials

1. Go to **R2** → **Manage R2 API Tokens**
2. Click **Create API Token**
3. Name: `sks-audio-upload`
4. Permissions: **Object Read & Write**
5. Save **Access Key ID** and **Secret Access Key**

---

## 3. Backend API Implementation (Node.js/Express)

### Install Dependencies

```bash
npm install express mssql cors dotenv
```

### Environment Variables (.env)

```env
DB_SERVER=localhost
DB_PORT=1433
DB_USER=sa
DB_PASSWORD=your_password
DB_NAME=sks_database
R2_PUBLIC_URL=https://your-bucket-name.r2.dev
PORT=3000
```

### API Routes (routes/audio.js)

```javascript
const express = require('express');
const router = express.Router();
const sql = require('mssql');

// Database configuration
const dbConfig = {
  server: process.env.DB_SERVER,
  port: parseInt(process.env.DB_PORT || '1433'),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  options: {
    encrypt: true, // Use encryption for Azure SQL
    trustServerCertificate: true, // For local dev
    enableArithAbort: true
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  }
};

// Create connection pool
let pool;

async function getPool() {
  if (!pool) {
    pool = await sql.connect(dbConfig);
  }
  return pool;
}

// Get all audios
router.get('/audios', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request()
      .query('SELECT * FROM audios WHERE is_active = 1 ORDER BY order_index ASC, created_at DESC');
    
    res.json({
      success: true,
      data: result.recordset
    });
  } catch (error) {
    console.error('Error fetching audios:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch audios'
    });
  }
});

// Get audios by category
router.get('/audios/category/:category', async (req, res) => {
  try {
    const { category } = req.params;
    const pool = await getPool();
    
    const result = await pool.request()
      .input('category', sql.NVarChar, category)
      .query('SELECT * FROM audios WHERE category = @category AND is_active = 1 ORDER BY order_index ASC, created_at DESC');
    
    res.json({
      success: true,
      data: result.recordset
    });
  } catch (error) {
    console.error('Error fetching audios by category:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch audios'
    });
  }
});

// Get audios by language
router.get('/audios/language/:language', async (req, res) => {
  try {
    const { language } = req.params;
    const pool = await getPool();
    
    const result = await pool.request()
      .input('language', sql.NVarChar, language)
      .query('SELECT * FROM audios WHERE language = @language AND is_active = 1 ORDER BY order_index ASC, created_at DESC');
    
    res.json({
      success: true,
      data: result.recordset
    });
  } catch (error) {
    console.error('Error fetching audios by language:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch audios'
    });
  }
});

// Get single audio by ID
router.get('/audios/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const pool = await getPool();
    
    const result = await pool.request()
      .input('id', sql.Int, id)
      .query('SELECT * FROM audios WHERE id = @id AND is_active = 1');
    
    if (result.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Audio not found'
      });
    }
    
    res.json({
      success: true,
      data: result.recordset[0]
    });
  } catch (error) {
    console.error('Error fetching audio:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch audio'
    });
  }
});

// Search audios
router.get('/audios/search', async (req, res) => {
  try {
    const { q } = req.query;
    
    if (!q) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }
    
    const pool = await getPool();
    const searchTerm = `%${q}%`;
    
    const result = await pool.request()
      .input('searchTerm', sql.NVarChar, searchTerm)
      .query(`
        SELECT * FROM audios 
        WHERE (title LIKE @searchTerm OR artist LIKE @searchTerm OR description LIKE @searchTerm) 
        AND is_active = 1 
        ORDER BY order_index ASC
      `);
    
    res.json({
      success: true,
      data: result.recordset
    });
  } catch (error) {
    console.error('Error searching audios:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to search audios'
    });
  }
});

// Increment play count (analytics)
router.post('/audios/:id/play', async (req, res) => {
  try {
    const { id } = req.params;
    const pool = await getPool();
    
    await pool.request()
      .input('id', sql.Int, id)
      .query('UPDATE audios SET play_count = play_count + 1 WHERE id = @id');
    
    res.json({
      success: true,
      message: 'Play count updated'
    });
  } catch (error) {
    console.error('Error updating play count:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update play count'
    });
  }
});

// Graceful shutdown
process.on('SIGINT', async () => {
  if (pool) {
    await pool.close();
  }
  process.exit(0);
});

module.exports = router;
```

### Main Server File (server.js)

```javascript
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const audioRoutes = require('./routes/audio');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api', audioRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

---

## 4. Flutter Integration

### Update pubspec.yaml

```yaml
dependencies:
  http: ^1.1.0
  path_provider: ^2.1.1
  crypto: ^3.0.3
  just_audio: ^0.9.36
  audio_service: ^0.18.12
  cached_network_image: ^3.3.0
```

### Initialize Services in main.dart

```dart
import 'package:flutter/material.dart';
import 'core/services/audio_cache_service.dart';
import 'core/services/enhanced_audio_player_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize audio cache service
  await AudioCacheService().initialize();
  
  // Initialize enhanced audio player
  await EnhancedAudioPlayerService().initialize();
  
  runApp(MyApp());
}
```

### Usage Example

```dart
import 'package:flutter/material.dart';
import 'core/services/enhanced_audio_player_service.dart';
import 'core/repositories/audio_repository.dart';
import 'core/models/audio_model.dart';

class BhajansPage extends StatefulWidget {
  @override
  _BhajansPageState createState() => _BhajansPageState();
}

class _BhajansPageState extends State<BhajansPage> {
  final EnhancedAudioPlayerService _audioService = EnhancedAudioPlayerService();
  final AudioRepository _audioRepo = AudioRepository();
  
  List<AudioModel> _bhajans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBhajans();
  }

  Future<void> _loadBhajans() async {
    setState(() => _isLoading = true);
    
    final bhajans = await _audioRepo.fetchBhajans();
    
    setState(() {
      _bhajans = bhajans;
      _isLoading = false;
    });
    
    // Preload audios in background
    _audioService.preloadPlaylist();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _bhajans.length,
      itemBuilder: (context, index) {
        final bhajan = _bhajans[index];
        
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: bhajan.thumbnailUrl != null
                ? NetworkImage(bhajan.thumbnailUrl!)
                : null,
            child: bhajan.thumbnailUrl == null
                ? Icon(Icons.music_note)
                : null,
          ),
          title: Text(bhajan.title),
          subtitle: Text(bhajan.artist ?? ''),
          trailing: _audioService.currentSong?.id == bhajan.id &&
                  _audioService.isPlaying
              ? Icon(Icons.pause_circle_filled)
              : Icon(Icons.play_circle_filled),
          onTap: () async {
            if (_audioService.currentSong?.id == bhajan.id &&
                _audioService.isPlaying) {
              await _audioService.pause();
            } else {
              await _audioService.playSong(_bhajans, index);
            }
          },
        );
      },
    );
  }
}
```

---

## 5. File Organization in Cloudflare R2

### Recommended Folder Structure

```
sks-audio-files/
├── audio/
│   ├── meditation/
│   │   ├── sivoham-15min.mp3
│   │   ├── sivoham-10min.mp3
│   │   └── guided-meditation-1.mp3
│   ├── bhajans/
│   │   ├── telugu/
│   │   │   ├── sri-jeeveswarastakam.mp3
│   │   │   ├── gundello-gudi.mp3
│   │   │   └── jeeveswara-yogi-taluva.mp3
│   │   ├── sanskrit/
│   │   │   ├── nirvana-shatkam.mp3
│   │   │   └── pralaya-kala-beekara.mp3
│   │   └── english/
│   │       └── ...
│   ├── chants/
│   │   ├── om-chanting.mp3
│   │   └── mantras.mp3
│   └── ringtones/
│       └── sivoham-ringtone.mp3
└── thumbnails/
    ├── meditation/
    ├── bhajans/
    └── chants/
```

### File Naming Convention

- Use lowercase
- Use hyphens instead of spaces
- Include category in path
- Example: `audio/bhajans/telugu/sri-jeeveswarastakam.mp3`

---

## 6. Performance Optimization

### Backend Caching (Redis)

```javascript
const redis = require('redis');
const client = redis.createClient();

// Cache audios list for 1 hour
router.get('/audios', async (req, res) => {
  const cacheKey = 'audios:all';
  
  // Check cache first
  const cached = await client.get(cacheKey);
  if (cached) {
    return res.json({
      success: true,
      data: JSON.parse(cached),
      cached: true
    });
  }
  
  // Fetch from database
  const [rows] = await pool.query('SELECT * FROM audios WHERE is_active = TRUE ORDER BY order_index ASC');
  
  // Cache for 1 hour
  await client.setEx(cacheKey, 3600, JSON.stringify(rows));
  
  res.json({
    success: true,
    data: rows
  });
});
```

### CDN Configuration

1. Enable Cloudflare CDN for R2 bucket
2. Set cache headers:
   ```
   Cache-Control: public, max-age=31536000
   ```
3. Enable Brotli compression

---

## 7. Adding New Songs (Easy Process)

### Step 1: Upload to R2
```bash
wrangler r2 object put sks-audio-files/audio/bhajans/telugu/new-song.mp3 --file ./new-song.mp3
```

### Step 2: Add to Database
```sql
INSERT INTO audios (title, artist, description, audio_url, duration_seconds, category, language, order_index)
VALUES (
  'New Song Title',
  'Artist Name',
  'Song description',
  'https://your-bucket.r2.dev/audio/bhajans/telugu/new-song.mp3',
  240,
  'bhajan',
  'telugu',
  10
);
```

### Step 3: Clear Cache (if using Redis)
```bash
redis-cli DEL audios:all audios:category:bhajan
```

That's it! The mobile app will automatically fetch and display the new song.

---

## 8. Monitoring & Analytics

### Track Popular Songs

```sql
SELECT title, artist, play_count, category
FROM audios
WHERE is_active = TRUE
ORDER BY play_count DESC
LIMIT 10;
```

### Monitor Cache Performance

```dart
// In Flutter app
final cacheSize = await _audioService.getCacheSize();
print('Audio cache size: $cacheSize');
```

---

## 9. Troubleshooting

### Issue: Audio not playing
- Check R2 bucket public access
- Verify audio URL is accessible
- Check network connectivity
- Clear app cache

### Issue: Slow downloads
- Enable CDN on Cloudflare
- Reduce audio file size (use 128kbps MP3)
- Preload popular songs

### Issue: Cache not working
- Check storage permissions
- Verify path_provider initialization
- Clear and rebuild cache

---

## 10. Security Considerations

1. **CORS Configuration**: Enable CORS on R2 bucket for your domain
2. **Rate Limiting**: Implement rate limiting on API endpoints
3. **Authentication**: Add JWT authentication for admin endpoints
4. **Content Protection**: Consider signed URLs for premium content

---

## Summary

This dynamic audio system provides:
- ✅ Cloudflare R2 storage for scalable audio hosting
- ✅ Local caching for offline playback
- ✅ Database-driven metadata
- ✅ Easy song management
- ✅ Fast, lag-free playback
- ✅ Background preloading
- ✅ Analytics tracking

The system is production-ready and can handle thousands of users efficiently!
