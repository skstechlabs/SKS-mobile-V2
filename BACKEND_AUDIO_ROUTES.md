# Audio API Routes for Mobile Backend Service

Add these routes to your existing `sks-mobile-backend-service` that uses the same MSSQL database.

---

## Database Setup

### 1. Create Audios Table in Existing Database

Run this in your existing MSSQL database:

```sql
USE [your_existing_database];
GO

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
GO

-- Create indexes
CREATE INDEX idx_audios_category ON audios(category);
CREATE INDEX idx_audios_language ON audios(language);
CREATE INDEX idx_audios_is_active ON audios(is_active);
CREATE INDEX idx_audios_order_index ON audios(order_index);
CREATE INDEX idx_audios_created_at ON audios(created_at DESC);
GO

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

---

## Backend Routes Implementation

### File: `routes/audio.js`

Create this new file in your backend service:

```javascript
const express = require('express');
const router = express.Router();
const sql = require('mssql');

/**
 * Audio Routes
 * All routes are public (no authentication required)
 * Base path: /api/audios
 */

// ── GET /api/audios - Get all active audios ────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const pool = req.app.locals.db; // Use existing DB connection pool
    
    const result = await pool.request()
      .query(`
        SELECT 
          id,
          title,
          artist,
          description,
          audio_url,
          thumbnail_url,
          duration_seconds,
          category,
          lyrics,
          language,
          order_index,
          play_count,
          created_at,
          updated_at
        FROM audios 
        WHERE is_active = 1 
        ORDER BY order_index ASC, created_at DESC
      `);
    
    res.json({
      success: true,
      data: result.recordset
    });
  } catch (error) {
    console.error('Error fetching audios:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch audios',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// ── GET /api/audios/category/:category - Get audios by category ────────────
router.get('/category/:category', async (req, res) => {
  try {
    const { category } = req.params;
    const pool = req.app.locals.db;
    
    const result = await pool.request()
      .input('category', sql.NVarChar, category)
      .query(`
        SELECT 
          id,
          title,
          artist,
          description,
          audio_url,
          thumbnail_url,
          duration_seconds,
          category,
          lyrics,
          language,
          order_index,
          play_count,
          created_at,
          updated_at
        FROM audios 
        WHERE category = @category AND is_active = 1 
        ORDER BY order_index ASC, created_at DESC
      `);
    
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

// ── GET /api/audios/language/:language - Get audios by language ────────────
router.get('/language/:language', async (req, res) => {
  try {
    const { language } = req.params;
    const pool = req.app.locals.db;
    
    const result = await pool.request()
      .input('language', sql.NVarChar, language)
      .query(`
        SELECT 
          id,
          title,
          artist,
          description,
          audio_url,
          thumbnail_url,
          duration_seconds,
          category,
          lyrics,
          language,
          order_index,
          play_count,
          created_at,
          updated_at
        FROM audios 
        WHERE language = @language AND is_active = 1 
        ORDER BY order_index ASC, created_at DESC
      `);
    
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

// ── GET /api/audios/search - Search audios ──────────────────────────────────
router.get('/search', async (req, res) => {
  try {
    const { q } = req.query;
    
    if (!q) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }
    
    const pool = req.app.locals.db;
    const searchTerm = `%${q}%`;
    
    const result = await pool.request()
      .input('searchTerm', sql.NVarChar, searchTerm)
      .query(`
        SELECT 
          id,
          title,
          artist,
          description,
          audio_url,
          thumbnail_url,
          duration_seconds,
          category,
          lyrics,
          language,
          order_index,
          play_count,
          created_at,
          updated_at
        FROM audios 
        WHERE (
          title LIKE @searchTerm OR 
          artist LIKE @searchTerm OR 
          description LIKE @searchTerm
        ) 
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

// ── GET /api/audios/popular - Get popular audios ────────────────────────────
router.get('/popular', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    const pool = req.app.locals.db;
    
    const result = await pool.request()
      .input('limit', sql.Int, limit)
      .query(`
        SELECT TOP (@limit)
          id,
          title,
          artist,
          description,
          audio_url,
          thumbnail_url,
          duration_seconds,
          category,
          lyrics,
          language,
          order_index,
          play_count,
          created_at,
          updated_at
        FROM audios 
        WHERE is_active = 1 
        ORDER BY play_count DESC, created_at DESC
      `);
    
    res.json({
      success: true,
      data: result.recordset
    });
  } catch (error) {
    console.error('Error fetching popular audios:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch popular audios'
    });
  }
});

// ── GET /api/audios/:id - Get single audio by ID ────────────────────────────
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const pool = req.app.locals.db;
    
    const result = await pool.request()
      .input('id', sql.Int, id)
      .query(`
        SELECT 
          id,
          title,
          artist,
          description,
          audio_url,
          thumbnail_url,
          duration_seconds,
          category,
          lyrics,
          language,
          order_index,
          play_count,
          created_at,
          updated_at
        FROM audios 
        WHERE id = @id AND is_active = 1
      `);
    
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

// ── POST /api/audios/:id/play - Increment play count ────────────────────────
router.post('/:id/play', async (req, res) => {
  try {
    const { id } = req.params;
    const pool = req.app.locals.db;
    
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

module.exports = router;
```

---

## Integration with Existing Backend

### Update `server.js` or `app.js`

Add the audio routes to your existing server file:

```javascript
// ... existing imports ...
const audioRoutes = require('./routes/audio');

// ... existing middleware ...

// Add audio routes (public, no auth required)
app.use('/api/audios', audioRoutes);

// ... rest of your routes ...
```

---

## Sample Data

Insert sample data into your database:

```sql
-- Insert meditation music
INSERT INTO audios (title, artist, description, audio_url, duration_seconds, category, language, order_index) 
VALUES
('Sivoham Chanting (15 min)', 'Gurudev', 'Sivoham Chanting with Sivoham mantra', 'https://your-r2-bucket.r2.dev/audio/meditation/sivoham-15min.mp3', 900, 'meditation', 'sanskrit', 1),
('Sivoham Chanting (10 min)', 'Gurudev', 'Short Sivoham Chanting session', 'https://your-r2-bucket.r2.dev/audio/meditation/sivoham-10min.mp3', 600, 'meditation', 'sanskrit', 2);

-- Insert bhajans
INSERT INTO audios (title, artist, description, audio_url, duration_seconds, category, language, order_index) 
VALUES
('Sri Jeeveswarastakam', 'Sai Vijay', 'Sacred eight-verse hymn glorifying Gurudev', 'https://your-r2-bucket.r2.dev/audio/bhajans/sri-jeeveswarastakam.mp3', 309, 'bhajan', 'telugu', 1),
('Gundello Gudi', 'Divine Voices', 'Soulful Telugu devotional song', 'https://your-r2-bucket.r2.dev/audio/bhajans/gundello-gudi.mp3', 263, 'bhajan', 'telugu', 2),
('Nirvana Shatkam', 'Sacred Sounds', 'Timeless Advaita composition', 'https://your-r2-bucket.r2.dev/audio/bhajans/nirvana-shatkam.mp3', 347, 'bhajan', 'sanskrit', 3);
GO
```

---

## API Endpoints Summary

All endpoints are **public** (no authentication required):

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/audios` | Get all active audios |
| GET | `/api/audios/category/:category` | Get audios by category |
| GET | `/api/audios/language/:language` | Get audios by language |
| GET | `/api/audios/search?q=query` | Search audios |
| GET | `/api/audios/popular?limit=10` | Get popular audios |
| GET | `/api/audios/:id` | Get single audio by ID |
| POST | `/api/audios/:id/play` | Increment play count |

---

## Testing the API

```bash
# Get all audios
curl https://app.sivakundalini.org/api/audios

# Get bhajans
curl https://app.sivakundalini.org/api/audios/category/bhajan

# Get Telugu songs
curl https://app.sivakundalini.org/api/audios/language/telugu

# Search
curl "https://app.sivakundalini.org/api/audios/search?q=sivoham"

# Get single audio
curl https://app.sivakundalini.org/api/audios/1

# Increment play count
curl -X POST https://app.sivakundalini.org/api/audios/1/play

# Get popular audios
curl "https://app.sivakundalini.org/api/audios/popular?limit=5"
```

---

## Flutter Integration

The Flutter app is already configured to use these endpoints through:

1. **`ApiService`** - Handles HTTP requests to your backend
2. **`AudioRepository`** - Calls the audio endpoints
3. **`EnhancedAudioPlayerService`** - Plays audio with caching

No changes needed in Flutter code - it will automatically use your existing backend!

---

## Environment Variables

Make sure your backend has these environment variables:

```env
# Database (already configured)
DB_SERVER=your-mssql-server
DB_PORT=1433
DB_USER=your-username
DB_PASSWORD=your-password
DB_NAME=your-database-name

# Cloudflare R2 (for reference)
R2_PUBLIC_URL=https://your-bucket.r2.dev
```

---

## Summary

✅ Uses your existing MSSQL database
✅ Uses your existing database connection pool
✅ No authentication required (public endpoints)
✅ Integrates seamlessly with existing backend
✅ Flutter app already configured to use it
✅ Ready to deploy!

Just add the `routes/audio.js` file and register it in your server file. That's it! 🚀
