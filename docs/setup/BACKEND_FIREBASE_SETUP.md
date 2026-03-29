# Backend Firebase Admin SDK Setup

## 🎯 Fix: "Firebase authentication not configured" Error

Your backend needs Firebase Admin SDK to verify user tokens.

---

## Step 1: Get Firebase Service Account Key

1. **Go to Firebase Console**
   - https://console.firebase.google.com/
   - Select project: `sks-login-mobile` (your authentication project)

2. **Go to Service Accounts**
   - Click Settings (⚙️) icon
   - Click "Project settings"
   - Click "Service accounts" tab

3. **Generate Private Key**
   - Scroll down to "Firebase Admin SDK" section
   - Select language: "Node.js"
   - Click "Generate new private key" button
   - Click "Generate key" in popup
   - Save the JSON file (e.g., `sks-login-mobile-firebase-adminsdk-xxxxx.json`)

---

## Step 2: Add to Backend Project

### Place the File

```bash
# Copy to your backend project root
cp ~/Downloads/sks-login-mobile-firebase-adminsdk-xxxxx.json backend/firebase-admin-key.json

# Or on Windows:
# copy %USERPROFILE%\Downloads\sks-login-mobile-firebase-adminsdk-xxxxx.json backend\firebase-admin-key.json
```

### File Structure
```
backend/
├── firebase-admin-key.json  ← Place here
├── server.js
├── package.json
└── ...
```

---

## Step 3: Install Firebase Admin SDK

```bash
cd backend
npm install firebase-admin
```

---

## Step 4: Initialize Firebase Admin in Backend

### Update server.js (or your main file)

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-admin-key.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

console.log('✅ Firebase Admin SDK initialized');
```

---

## Step 5: Verify Token in Auth Middleware

### Example Middleware

```javascript
// middleware/auth.js
const admin = require('firebase-admin');

async function verifyFirebaseToken(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized'
      });
    }

    const idToken = authHeader.split('Bearer ')[1];
    
    // Verify token with Firebase Admin
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    // Add user info to request
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      phone: decodedToken.phone_number
    };
    
    next();
  } catch (error) {
    console.error('Token verification error:', error);
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired token'
    });
  }
}

module.exports = { verifyFirebaseToken };
```

---

## Step 6: Use Middleware in Routes

```javascript
const express = require('express');
const { verifyFirebaseToken } = require('./middleware/auth');

const app = express();

// Public routes (no auth needed)
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Protected routes (auth required)
app.post('/api/auth/login', verifyFirebaseToken, async (req, res) => {
  try {
    const { auth_provider, mobile, email, name, photo } = req.body;
    const uid = req.user.uid; // From verified token
    
    // Your login logic here
    // Save user to database, etc.
    
    res.json({
      success: true,
      is_new_user: false,
      user: {
        uid,
        mobile,
        email,
        name,
        photo,
        is_profile_complete: true,
        permissions_granted: true
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

app.post('/api/user/profile', verifyFirebaseToken, async (req, res) => {
  // Profile update logic
});

app.post('/api/user/permissions', verifyFirebaseToken, async (req, res) => {
  // Permissions save logic
});
```

---

## Step 7: Test Backend

### Start Server
```bash
cd backend
npm start
```

### Test with cURL
```bash
# Get Firebase ID token from your Flutter app first
# Then test:

curl -X POST http://localhost:3009/api/auth/login \
  -H "Authorization: Bearer YOUR_FIREBASE_ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "auth_provider": "phone",
    "mobile": "+919876543210"
  }'
```

---

## 🔐 Security Best Practices

### 1. Add to .gitignore
```bash
# .gitignore
firebase-admin-key.json
*.json
!package.json
```

### 2. Use Environment Variables (Production)
```javascript
// For production, use environment variable
const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT 
  ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)
  : require('./firebase-admin-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
```

### 3. Never Commit the Key File
- ❌ Never commit `firebase-admin-key.json` to Git
- ✅ Add to .gitignore
- ✅ Use environment variables in production
- ✅ Store securely in deployment platform

---

## 🧪 Testing Checklist

- [ ] Firebase Admin SDK installed
- [ ] Service account key file placed in backend
- [ ] Firebase Admin initialized in server.js
- [ ] Middleware created for token verification
- [ ] Routes protected with middleware
- [ ] Backend server starts without errors
- [ ] Test API call with valid token succeeds
- [ ] Test API call without token returns 401
- [ ] Test API call with invalid token returns 401

---

## 🐛 Troubleshooting

### Error: "Cannot find module './firebase-admin-key.json'"
**Solution:** Check file path and name
```bash
ls backend/firebase-admin-key.json
```

### Error: "Credential implementation provided to initializeApp() via the 'credential' property failed"
**Solution:** 
1. Re-download service account key from Firebase
2. Make sure JSON file is valid
3. Check file permissions

### Error: "Firebase ID token has expired"
**Solution:**
- Token expires after 1 hour
- Get new token from Flutter app
- Implement token refresh in Flutter

### Error: "Firebase ID token has invalid signature"
**Solution:**
- Make sure you're using the correct Firebase project
- Verify service account is from same project as Flutter app

---

## 📊 Complete Backend Example

```javascript
// server.js
const express = require('express');
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-admin-key.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const app = express();
app.use(express.json());

// Auth Middleware
async function verifyToken(req, res, next) {
  try {
    const token = req.headers.authorization?.split('Bearer ')[1];
    if (!token) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }
    
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    res.status(401).json({ success: false, message: 'Invalid token' });
  }
}

// Routes
app.post('/api/auth/login', verifyToken, async (req, res) => {
  const { auth_provider, mobile, email, name, photo } = req.body;
  
  // Your database logic here
  
  res.json({
    success: true,
    is_new_user: false,
    user: {
      uid: req.user.uid,
      mobile,
      email,
      name,
      photo,
      is_profile_complete: true,
      permissions_granted: false
    }
  });
});

app.post('/api/user/profile', verifyToken, async (req, res) => {
  // Profile logic
  res.json({ success: true, user: req.body });
});

app.post('/api/user/permissions', verifyToken, async (req, res) => {
  // Permissions logic
  res.json({ success: true });
});

const PORT = process.env.PORT || 3009;
app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`✅ Firebase Admin SDK initialized`);
});
```

---

## 🎉 Success!

Once configured, your backend will:
- ✅ Verify Firebase ID tokens
- ✅ Authenticate users securely
- ✅ Work with both phone and Google login
- ✅ Handle guest users (skip login)
- ✅ Be production-ready

---

**Your backend is now ready to handle Firebase authentication!** 🚀
