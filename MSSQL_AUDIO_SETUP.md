# MSSQL Audio System Setup Guide

Complete guide for setting up the dynamic audio system with **Microsoft SQL Server**.

---

## Database Setup

### 1. Create Database

```sql
-- Create database (if not exists)
CREATE DATABASE sks_database;
GO

USE sks_database;
GO
```

### 2. Create Audios Table

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
GO
```

### 3. Create Indexes

```sql
-- Create indexes for better query performance
CREATE INDEX idx_category ON audios(category);
CREATE INDEX idx_language ON audios(language);
CREATE INDEX idx_is_active ON audios(is_active);
CREATE INDEX idx_order_index ON audios(order_index);
CREATE INDEX idx_created_at ON audios(created_at DESC);
GO
```

### 4. Create Trigger for Updated_At

```sql
-- Create trigger to automatically update updated_at timestamp
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

### 5. Insert Sample Data

```sql
-- Insert meditation music
INSERT INTO audios (title, artist, description, audio_url, duration_seconds, category, language, order_index) 
VALUES
('Sivoham Chanting (15 min)', 'Gurudev', 'Sivoham Chanting with Sivoham mantra', 'https://your-bucket.r2.dev/audio/meditation/sivoham-15min.mp3', 900, 'meditation', 'sanskrit', 1),
('Sivoham Chanting (10 min)', 'Gurudev', 'Short Sivoham Chanting session', 'https://your-bucket.r2.dev/audio/meditation/sivoham-10min.mp3', 600, 'meditation', 'sanskrit', 2);

-- Insert bhajans
INSERT INTO audios (title, artist, description, audio_url, duration_seconds, category, language, order_index) 
VALUES
('Sri Jeeveswarastakam', 'Sai Vijay', 'Sacred eight-verse hymn glorifying Gurudev', 'https://your-bucket.r2.dev/audio/bhajans/sri-jeeveswarastakam.mp3', 309, 'bhajan', 'telugu', 1),
('Gundello Gudi', 'Divine Voices', 'Soulful Telugu devotional song', 'https://your-bucket.r2.dev/audio/bhajans/gundello-gudi.mp3', 263, 'bhajan', 'telugu', 2),
('Nirvana Shatkam', 'Sacred Sounds', 'Timeless Advaita composition', 'https://your-bucket.r2.dev/audio/bhajans/nirvana-shatkam.mp3', 347, 'bhajan', 'sanskrit', 3);
GO
```

---

## Backend API Setup (Node.js with MSSQL)

### 1. Install Dependencies

```bash
npm install express mssql cors dotenv
```

### 2. Environment Variables

Create `.env` file:

```env
# MSSQL Configuration
DB_SERVER=localhost
DB_PORT=1433
DB_USER=sa
DB_PASSWORD=YourStrongPassword123!
DB_NAME=sks_database

# For Azure SQL Database
# DB_SERVER=your-server.database.windows.net
# DB_PORT=1433
# DB_USER=your-username
# DB_PASSWORD=your-password
# DB_NAME=sks_database

# Cloudflare R2
R2_PUBLIC_URL=https://your-bucket.r2.dev

# Server
PORT=3000
NODE_ENV=development
```

### 3. Database Connection (config/database.js)

```javascript
const sql = require('mssql');

const dbConfig = {
  server: process.env.DB_SERVER,
  port: parseInt(process.env.DB_PORT || '1433'),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  options: {
    encrypt: process.env.NODE_ENV === 'production', // Use encryption for Azure SQL
    trustServerCertificate: process.env.NODE_ENV === 'development', // For local dev
    enableArithAbort: true,
    connectTimeout: 30000,
    requestTimeout: 30000
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  }
};

let pool;

async function getPool() {
  if (!pool) {
    try {
      pool = await sql.connect(dbConfig);
      console.log('✓ Connected to MSSQL database');
    } catch (err) {
      console.error('✗ Database connection failed:', err);
      throw err;
    }
  }
  return pool;
}

// Graceful shutdown
process.on('SIGINT', async () => {
  if (pool) {
    await pool.close();
    console.log('Database connection closed');
  }
  process.exit(0);
});

module.exports = { getPool, sql };
```

### 4. Audio Routes (routes/audio.js)

```javascript
const express = require('express');
const router = express.Router();
const { getPool, sql } = require('../config/database');

// Get all audios
router.get('/audios', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request()
      .query(`
        SELECT * FROM audios 
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

// Get audios by category
router.get('/audios/category/:category', async (req, res) => {
  try {
    const { category } = req.params;
    const pool = await getPool();
    
    const result = await pool.request()
      .input('category', sql.NVarChar, category)
      .query(`
        SELECT * FROM audios 
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

// Get audios by language
router.get('/audios/language/:language', async (req, res) => {
  try {
    const { language } = req.params;
    const pool = await getPool();
    
    const result = await pool.request()
      .input('language', sql.NVarChar, language)
      .query(`
        SELECT * FROM audios 
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

// Get popular audios (most played)
router.get('/audios/popular', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    const pool = await getPool();
    
    const result = await pool.request()
      .input('limit', sql.Int, limit)
      .query(`
        SELECT TOP (@limit) * FROM audios 
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

module.exports = router;
```

### 5. Main Server File (server.js)

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
app.use(express.urlencoded({ extended: true }));

// Request logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Routes
app.use('/api', audioRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    database: 'MSSQL'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`✓ Server running on port ${PORT}`);
  console.log(`✓ Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`✓ Database: MSSQL Server`);
});
```

---

## Useful MSSQL Queries

### Get All Songs with Details

```sql
SELECT 
    id,
    title,
    artist,
    category,
    language,
    duration_seconds,
    play_count,
    created_at
FROM audios
WHERE is_active = 1
ORDER BY category, order_index;
```

### Get Most Popular Songs

```sql
SELECT TOP 10
    title,
    artist,
    category,
    play_count
FROM audios
WHERE is_active = 1
ORDER BY play_count DESC;
```

### Get Songs by Category with Count

```sql
SELECT 
    category,
    COUNT(*) as song_count,
    SUM(duration_seconds) as total_duration_seconds
FROM audios
WHERE is_active = 1
GROUP BY category
ORDER BY song_count DESC;
```

### Update Song Order

```sql
-- Reorder songs in a category
UPDATE audios SET order_index = 1 WHERE id = 1;
UPDATE audios SET order_index = 2 WHERE id = 2;
UPDATE audios SET order_index = 3 WHERE id = 3;
```

### Deactivate Song (Soft Delete)

```sql
UPDATE audios 
SET is_active = 0, updated_at = GETDATE() 
WHERE id = 123;
```

### Reactivate Song

```sql
UPDATE audios 
SET is_active = 1, updated_at = GETDATE() 
WHERE id = 123;
```

### Add Thumbnail to Song

```sql
UPDATE audios 
SET thumbnail_url = 'https://your-bucket.r2.dev/thumbnails/song-thumb.jpg',
    updated_at = GETDATE()
WHERE id = 123;
```

---

## Testing the API

### Test with curl

```bash
# Get all audios
curl http://localhost:3000/api/audios

# Get bhajans
curl http://localhost:3000/api/audios/category/bhajan

# Get Telugu songs
curl http://localhost:3000/api/audios/language/telugu

# Search
curl "http://localhost:3000/api/audios/search?q=sivoham"

# Get single audio
curl http://localhost:3000/api/audios/1

# Increment play count
curl -X POST http://localhost:3000/api/audios/1/play

# Health check
curl http://localhost:3000/health
```

---

## Connection String Examples

### Local SQL Server

```
Server=localhost,1433;Database=sks_database;User Id=sa;Password=YourPassword;Encrypt=false;TrustServerCertificate=true;
```

### Azure SQL Database

```
Server=tcp:your-server.database.windows.net,1433;Database=sks_database;User ID=your-username;Password=your-password;Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;
```

### Windows Authentication

```
Server=localhost;Database=sks_database;Trusted_Connection=yes;
```

---

## Troubleshooting

### Connection Issues

1. **Check SQL Server is running**
   ```bash
   # Windows
   services.msc
   # Look for "SQL Server (MSSQLSERVER)"
   ```

2. **Enable TCP/IP**
   - Open SQL Server Configuration Manager
   - Enable TCP/IP protocol
   - Restart SQL Server service

3. **Check Firewall**
   - Allow port 1433 in Windows Firewall

4. **Test Connection**
   ```bash
   sqlcmd -S localhost -U sa -P YourPassword
   ```

### Query Performance

1. **Check Indexes**
   ```sql
   SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('audios');
   ```

2. **Rebuild Indexes**
   ```sql
   ALTER INDEX ALL ON audios REBUILD;
   ```

3. **Update Statistics**
   ```sql
   UPDATE STATISTICS audios;
   ```

---

## Production Deployment

### Azure SQL Database

1. Create Azure SQL Database
2. Update connection string with Azure credentials
3. Enable firewall rules for your app server
4. Use connection pooling
5. Enable query performance insights

### Security Best Practices

1. **Use Strong Passwords**
2. **Enable SSL/TLS**
3. **Use Parameterized Queries** (already implemented)
4. **Limit Database User Permissions**
5. **Regular Backups**
6. **Monitor Query Performance**

---

## Summary

✅ MSSQL database configured
✅ Audios table created with indexes
✅ Node.js API with mssql package
✅ Parameterized queries for security
✅ Connection pooling for performance
✅ Error handling and logging
✅ Ready for production deployment

The system is now ready to use with Microsoft SQL Server! 🚀
