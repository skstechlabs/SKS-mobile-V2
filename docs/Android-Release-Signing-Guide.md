# Android Release Signing Guide

This document explains how to create a release keystore, register it with Firebase, and build a production-signed APK for the SKS app.

---

## Why this matters

Android requires every APK to be digitally signed before it can be installed on a device. There are two types of signing:

- **Debug signing** — done automatically by Android Studio / Flutter using a shared debug keystore. Used during development. Google Sign-In works because the debug SHA-1 is already registered in Firebase.
- **Release signing** — done with your own private keystore. Required for Play Store distribution and for Google Sign-In to work in production builds.

The current `build.gradle.kts` was using `signingConfigs.debug` for release builds. This means the APK was signed with the debug key, which is why Google Sign-In worked. After switching to a proper release keystore, you must register the new SHA-1 in Firebase.

---

## What is a keystore?

A keystore is a password-protected file that contains a cryptographic key pair (private key + certificate). Android uses this to prove that an APK was built by you and not tampered with. The Play Store uses it to verify that app updates come from the same developer.

**Critical rule:** If you lose the keystore file or forget the password, you can never update your app on the Play Store. You would have to publish it as a completely new app with a new package name.

---

## Step 1 — Create a release keystore (one time only)

Run this command in your terminal. You can run it from any folder — it creates the file wherever you run it.

```bash
keytool -genkey -v \
  -keystore sks-release-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias sks
```

### What each flag means

| Flag | Value | Explanation |
|---|---|---|
| `-keystore` | `sks-release-key.jks` | Name of the keystore file to create |
| `-keyalg` | `RSA` | Encryption algorithm. RSA is the industry standard for Android signing |
| `-keysize` | `2048` | Key length in bits. **2048 bits** is the minimum recommended by Google for production apps. It means the private key has 2,048 binary digits of entropy — this makes it computationally infeasible to crack with current hardware. A 1024-bit key is considered weak; 4096-bit is stronger but slower. 2048 is the right balance for production. |
| `-validity` | `10000` | How many **days** the certificate is valid — that is **27.4 years** (10,000 ÷ 365). Google Play requires the certificate to be valid past October 22, 2033. 10,000 days comfortably exceeds this. After expiry, you cannot sign new APKs with this key. |
| `-alias` | `sks` | A label for the key entry inside the keystore. A single keystore can hold multiple keys; the alias identifies which one to use. |

### What it will ask you

```
Enter keystore password:          ← Choose a strong password e.g. SKSdhana2025!
Re-enter new password:            ← Repeat it
What is your first and last name? ← Your name or company name e.g. SKS Techlabs
What is your organizational unit? ← Press Enter to skip
What is your organization?        ← SKS or your company name
What is your City or Locality?    ← Your city e.g. Hyderabad
What is your State or Province?   ← Your state e.g. Telangana
What is the two-letter country code? ← IN (for India)
Is CN=..., OU=..., O=..., L=..., ST=..., C=... correct? [no]: yes
Enter key password for <sks>:     ← Can be same as keystore password
```

### ⚠️ Save these immediately

| What | Where to save |
|---|---|
| Keystore file `sks-release-key.jks` | Google Drive + USB drive + email to yourself |
| Keystore password | Password manager (1Password, Bitwarden, etc.) |
| Key alias | `sks` |
| Key password | Password manager |

**If you lose any of these, you cannot update the app on Play Store.**

---

## Step 2 — Get the SHA-1 fingerprint from your keystore

```bash
keytool -list -v -keystore sks-release-key.jks -alias sks
```

Enter your keystore password when prompted. Look for this section in the output:

```
Certificate fingerprints:
   MD5:  XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
   SHA1: AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12
   SHA-256: XX:XX:XX:...
```

Copy the **SHA1** value (the one that looks like `AB:CD:EF:...`).

### What is SHA-1?

SHA-1 (Secure Hash Algorithm 1) is a fingerprint of your signing certificate. Google uses it to verify that an APK was signed by you. When you register it in Firebase, Firebase will only accept Google Sign-In requests from APKs signed with that certificate.

---

## Step 3 — Register the SHA-1 in Firebase Console

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Select project **sks-login-mobile**
3. Click the **gear icon** (⚙️) → **Project Settings**
4. Scroll down to **Your apps**
5. Find the Android app with package name `com.spiritual.app`
6. Click **Add fingerprint**
7. Paste the SHA-1 value you copied → click **Save**
8. Click **Download google-services.json**
9. Replace the existing file at `SKS-mobile-V2/android/app/google-services.json` with the downloaded file

> **Keep both SHA-1s registered** — the existing debug SHA-1 (`e86a515c68af408a6148871ef70b4b48ab5fc78a`) and your new release SHA-1. This way Google Sign-In works in both debug builds (development) and release builds (production).

---

## Step 4 — Place the keystore file in the project

Copy `sks-release-key.jks` to:

```
SKS-mobile-V2/android/app/sks-release-key.jks
```

Then add it to `.gitignore` so it is never committed to version control:

```
# Add these lines to SKS-mobile-V2/android/.gitignore
*.jks
*.keystore
```

---

## Step 5 — Configure signing in `build.gradle.kts`

The file `SKS-mobile-V2/android/app/build.gradle.kts` has already been updated with the release signing config:

```kotlin
signingConfigs {
    create("release") {
        storeFile = file("sks-release-key.jks")
        storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "YOUR_KEYSTORE_PASSWORD"
        keyAlias = "sks"
        keyPassword = System.getenv("KEY_PASSWORD") ?: "YOUR_KEY_PASSWORD"
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = false
        isShrinkResources = false
    }
}
```

Replace `YOUR_KEYSTORE_PASSWORD` and `YOUR_KEY_PASSWORD` with your actual passwords.

> **Better approach for CI/CD:** Use environment variables instead of hardcoding passwords. Set `KEYSTORE_PASSWORD` and `KEY_PASSWORD` as environment variables on your build machine. The `System.getenv(...)` calls in the config already support this.

---

## Step 6 — Build the release APK

```bash
cd SKS-mobile-V2
flutter build apk --release --dart-define-from-file=.env.prod.json
```

The signed APK will be at:

```
SKS-mobile-V2/build/app/outputs/flutter-apk/app-release.apk
```

To build split APKs (smaller file size, recommended for distribution):

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=.env.prod.json
```

This produces:
```
app-arm64-v8a-release.apk    ← Use this for most modern devices
app-armeabi-v7a-release.apk  ← Older 32-bit devices
app-x86_64-release.apk       ← Emulators only
```

---

## Step 7 — Verify Google Sign-In works

After installing the release APK on a real device:

1. Open the app → tap **Continue with Google**
2. If you see `ApiException: 10` or "Google sign-in configuration error" → the release SHA-1 is not registered in Firebase yet (go back to Step 3)
3. If sign-in succeeds → you are production-ready ✅

---

## Summary checklist

| Step | Action | Done? |
|---|---|---|
| 1 | Run `keytool -genkey` to create `sks-release-key.jks` | ☐ |
| 2 | Back up the keystore file and passwords securely | ☐ |
| 3 | Run `keytool -list` to get the SHA-1 fingerprint | ☐ |
| 4 | Register SHA-1 in Firebase Console | ☐ |
| 5 | Download and replace `google-services.json` | ☐ |
| 6 | Copy keystore to `android/app/sks-release-key.jks` | ☐ |
| 7 | Add `*.jks` to `.gitignore` | ☐ |
| 8 | Update passwords in `build.gradle.kts` | ☐ |
| 9 | Run `flutter build apk --release` | ☐ |
| 10 | Test Google Sign-In on a real device | ☐ |

---

## Frequently asked questions

**Q: What happens if I use the debug keystore for production?**
A: It works, but it is a security risk. The debug keystore is shared across all Android developers' machines and its password (`android`) is publicly known. Anyone with the debug keystore can sign APKs that appear to come from your app.

**Q: Can I change the keystore later?**
A: No. Once you publish an app to the Play Store, the signing key is permanently associated with your app. You cannot change it without publishing a new app.

**Q: What is `-validity 10000`?**
A: It sets the certificate validity to 10,000 days (~27.4 years). Google Play requires the certificate to be valid past October 22, 2033. 10,000 days ensures you will never need to worry about expiry during the app's lifetime.

**Q: What is `-keysize 2048`?**
A: It sets the RSA key length to 2,048 bits. This is the current industry standard — strong enough to be secure for decades, and fast enough for signing operations. Keys shorter than 2,048 bits are considered insecure by modern standards.

**Q: Do I need to do this for iOS?**
A: iOS uses a different signing system (Apple certificates and provisioning profiles managed through Xcode and the Apple Developer portal). This guide covers Android only.
