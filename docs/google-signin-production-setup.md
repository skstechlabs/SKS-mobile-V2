# Google Sign-In — Production Setup Guide

This document covers every step required to make Google Sign-In work in production for the SKS mobile app.

---

## 1. Firebase Console — Enable Google Sign-In

1. Go to [Firebase Console](https://console.firebase.google.com) and open project **sks-login-mobile**
2. Navigate to **Authentication → Sign-in method**
3. Click **Google** and toggle it **Enabled**
4. Add your **support email**
5. Click **Save**

---

## 2. Google Cloud Console — Configure OAuth Consent Screen

1. Go to [console.cloud.google.com](https://console.cloud.google.com) and select project **sks-login-mobile**
2. Navigate to **APIs & Services → OAuth consent screen**
3. Set **User type** to **External**
4. Fill in the required fields:
   - App name
   - Support email
   - Developer contact email
5. Under **Scopes**, add:
   - `email`
   - `profile`
   - `openid`
6. Under **Authorized domains**, add:
   - `sivakundalini.org`
   - `sks-login-mobile.firebaseapp.com`
7. Click **Save and Continue**
8. On the summary page click **Publish App** to move out of Testing mode

> ⚠️ While in Testing mode only explicitly listed test users can sign in. Publishing is required for all users to sign in.

---

## 3. Google Cloud Console — Add Authorized Redirect URIs

1. In the same project, go to **APIs & Services → Credentials**
2. Under **OAuth 2.0 Client IDs**, find the **Web client** (auto-created by Firebase) and click **Edit**
3. Under **Authorized JavaScript origins**, add:
   - `https://sivakundalini.org`
   - `https://sks-login-mobile.firebaseapp.com`
4. Under **Authorized redirect URIs**, add:
   - `https://sks-login-mobile.firebaseapp.com/__/auth/handler`
   - `https://sivakundalini.org`
5. Click **Save**
6. Copy the **Client ID** — it looks like `294856785598-xxxx.apps.googleusercontent.com`

---

## 4. Flutter — Update `.env.json`

The `GOOGLE_CLIENT_ID` in `.env.json` and `.env.prod.json` must match the Web client ID from step 3.

```json
{
  "GOOGLE_CLIENT_ID": "294856785598-xxxx.apps.googleusercontent.com"
}
```

The current value in `.env.json` is already set. Confirm it matches what you see in the Google Cloud Console after step 3.

---

## 5. Android — Register SHA-1 Fingerprint

Google Sign-In on Android requires your app's signing certificate to be registered in Firebase.

### Get your release SHA-1

```bash
keytool -list -v -keystore your-release-key.jks -alias your-alias
```

### Register it in Firebase

1. Go to **Firebase Console → Project Settings → Your apps → Android app**
2. Click **Add fingerprint**
3. Paste the SHA-1 value
4. Click **Save**

### Update google-services.json

1. After saving the SHA-1, click **Download google-services.json**
2. Replace the existing file at `android/app/google-services.json`

---

## 6. Verify `google-services.json` Has the OAuth Client Entry

Open `android/app/google-services.json` and confirm there is an entry with `"client_type": 3` under the `oauth_client` array:

```json
{
  "oauth_client": [
    {
      "client_id": "294856785598-xxxx.apps.googleusercontent.com",
      "client_type": 3
    }
  ]
}
```

If this entry is missing, re-download `google-services.json` from Firebase Console after the SHA-1 has been added (step 5).

---

## Checklist

| Step | What | Done? |
|------|------|-------|
| 1 | Google Sign-In enabled in Firebase Auth | ☐ |
| 2 | OAuth consent screen published (not in Testing mode) | ☐ |
| 3 | Authorized origins and redirect URIs added | ☐ |
| 4 | `GOOGLE_CLIENT_ID` in `.env.prod.json` matches Web client ID | ☐ |
| 5 | Release SHA-1 registered in Firebase | ☐ |
| 6 | `google-services.json` re-downloaded and replaced | ☐ |

Once all six steps are complete, Google Sign-In will work for all users in production.
