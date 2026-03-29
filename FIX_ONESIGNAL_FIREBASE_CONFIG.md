# Fix Wrong Firebase Project in OneSignal

## The Problem

You uploaded Service Account JSON from the wrong Firebase project to OneSignal.

OneSignal doesn't have a "delete" button, but you can **replace** it with the correct one.

## Solution: Upload Correct Service Account JSON

### Step 1: Generate Correct Service Account JSON

1. Go to https://console.firebase.google.com/
2. Select the **CORRECT** project: **sks-login-mobile**
3. Click gear icon → **Project Settings**
4. Click **"Service Accounts"** tab
5. Verify you see: **Project ID: sks-login-mobile**
6. Click **"Generate new private key"**
7. Click **"Generate key"**
8. Save the JSON file

### Step 2: Replace in OneSignal

1. Go to https://onesignal.com/
2. Select your app
3. Settings → **Platforms**
4. Find **"Google Android (FCM)"**
5. Click **"Edit Configuration"** or **"Configure"**
6. Select **"FCM v1"** tab
7. Click **"Upload Service Account JSON"** (or "Replace" if one exists)
8. Select the NEW JSON file from Step 1
9. Click **"Save"**

**The new file will REPLACE the old one automatically.**

### Step 3: Verify

After uploading, check:
- ✅ Green checkmark next to "Google Android (FCM)"
- ✅ Sender ID shows: **294856785598**
- ✅ Project ID in the JSON matches: **sks-login-mobile**

## How to Verify You Have the Right JSON File

Before uploading, open the JSON file in a text editor and check:

```json
{
  "type": "service_account",
  "project_id": "sks-login-mobile",  ← Must be this!
  "private_key_id": "...",
  ...
}
```

If `project_id` is anything other than `sks-login-mobile`, you downloaded from the wrong project.

## Common Mistakes

### Mistake 1: Downloaded from Wrong Firebase Project

**Fix**: Make sure you're in the **sks-login-mobile** project when downloading

### Mistake 2: Downloaded google-services.json Instead

**Wrong file**: `google-services.json` (goes in your app)
**Right file**: Service Account JSON (goes in OneSignal)

**Fix**: Go to Service Accounts tab (not Cloud Messaging tab)

### Mistake 3: Using Legacy Server Key

**Old method**: Server Key (deprecated)
**New method**: Service Account JSON (FCM v1)

**Fix**: Use FCM v1 tab in OneSignal, not Legacy tab

## After Replacing

1. **Reinstall app** on device (uninstall first)
2. **Grant permissions**
3. **Wait 30 seconds**
4. **Check OneSignal Dashboard** → Audience → Subscriptions
5. **Device should appear**

## If Device Still Doesn't Appear

### Check 1: Correct Project in Firebase

Firebase Console → Top left → Should show "sks-login-mobile"

### Check 2: Correct App ID in OneSignal

OneSignal Dashboard → Settings → Keys & IDs → App ID should be: `3586ffae-bd5f-4475-91c0-6dd24a129a05`

### Check 3: FCM API Enabled

Google Cloud Console → APIs & Services → Enabled APIs → Should see "Firebase Cloud Messaging API"

### Check 4: App Has Internet

Device must have active internet connection

### Check 5: Google Play Services

Device Settings → Apps → Google Play Services (must be installed)

## Quick Test

After uploading correct JSON:

1. Uninstall app from device
2. Reinstall: `build/app/outputs/flutter-apk/app-release.apk`
3. Open app
4. Grant permissions
5. Wait 30 seconds
6. Refresh OneSignal Dashboard → Audience → Subscriptions
7. Your device should appear with:
   - Platform: Android
   - Status: Subscribed
   - Last Active: Just now

## Contact OneSignal Support

If you still can't replace the configuration:

Email: support@onesignal.com
Include:
- Your OneSignal App ID: `3586ffae-bd5f-4475-91c0-6dd24a129a05`
- Issue: "Need to replace Firebase project configuration"
- Correct Firebase Project: sks-login-mobile

They can reset it for you.

---

**Key Point**: You don't need to "remove" the old config. Just upload the new Service Account JSON and it will replace the old one automatically.
