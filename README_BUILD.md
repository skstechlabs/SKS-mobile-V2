# 🚀 SKS Mobile App - Build Guide

Welcome! This guide will help you build a production APK for the SKS mobile app.

---

## 📚 Documentation Overview

We have created comprehensive documentation to help you:

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **BUILD_APK_SUMMARY.md** | Quick visual summary | Start here! |
| **QUICK_START_BUILD.md** | Quick reference guide | For quick lookups |
| **BUILD_PRODUCTION_APK.md** | Complete detailed guide | For in-depth understanding |
| **setup-signing.sh** | Automated setup script | First time setup |
| **build-release.sh** | Automated build script | Every release |

---

## 🎯 Choose Your Path

### 👉 I'm New - Show Me the Basics
**Start with:** `BUILD_APK_SUMMARY.md`

This gives you a visual overview of the 3 simple steps needed to build an APK.

### 👉 I Want Quick Commands
**Start with:** `QUICK_START_BUILD.md`

This provides quick reference commands and troubleshooting tips.

### 👉 I Want Complete Details
**Start with:** `BUILD_PRODUCTION_APK.md`

This provides step-by-step detailed instructions with explanations.

---

## ⚡ Super Quick Start

If you just want to build an APK right now:

```bash
# 1. First time setup (one-time only)
./setup-signing.sh

# 2. Build APK
./build-release.sh

# 3. Install on device
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

That's it! 🎉

---

## 📁 What's in This Directory

```
SKS-mobile-V2/
├── README_BUILD.md                 ← You are here
├── BUILD_APK_SUMMARY.md           ← Visual summary (START HERE)
├── QUICK_START_BUILD.md           ← Quick reference
├── BUILD_PRODUCTION_APK.md        ← Detailed guide
├── setup-signing.sh               ← Setup script
├── build-release.sh               ← Build script
├── ONESIGNAL_MOBILE_INTEGRATION.md ← OneSignal docs
└── ... (app source code)
```

---

## 🔄 Typical Workflow

### First Time (One-time setup):
1. Read `BUILD_APK_SUMMARY.md`
2. Run `./setup-signing.sh`
3. Configure `.env` file
4. Run `./build-release.sh`
5. Test APK on device

### Every Release After That:
1. Update version in `android/app/build.gradle`
2. Run `./build-release.sh`
3. Test APK on device
4. Distribute to users

---

## 🎓 Learning Path

### Beginner:
1. `BUILD_APK_SUMMARY.md` - Understand the basics
2. Run `./setup-signing.sh` - Set up signing
3. Run `./build-release.sh` - Build your first APK

### Intermediate:
1. `QUICK_START_BUILD.md` - Learn quick commands
2. Understand version management
3. Learn troubleshooting

### Advanced:
1. `BUILD_PRODUCTION_APK.md` - Deep dive into details
2. Customize build configuration
3. Optimize APK size
4. Set up CI/CD

---

## ✅ Prerequisites

Before you start, make sure you have:

- [ ] Flutter installed (`flutter --version`)
- [ ] Java JDK installed (`java -version`)
- [ ] Android device or emulator
- [ ] USB debugging enabled (for device)
- [ ] Production environment variables ready

---

## 🆘 Getting Help

### Quick Issues:
Check `QUICK_START_BUILD.md` → Troubleshooting section

### Build Errors:
Check `BUILD_PRODUCTION_APK.md` → Troubleshooting section

### Environment Issues:
Check `.env` file and `BUILD_PRODUCTION_APK.md` → Step 6

### Signing Issues:
Run `./setup-signing.sh` again

---

## 📊 Build Types Explained

### Universal APK
- **Size:** Larger (~60-80 MB)
- **Compatibility:** Works on all devices
- **Use case:** Quick testing, direct distribution
- **Command:** `flutter build apk --release`

### Split APKs (Recommended)
- **Size:** Smaller (~20-30 MB each)
- **Compatibility:** One APK per architecture
- **Use case:** Production distribution
- **Command:** `flutter build apk --split-per-abi --release`

### App Bundle
- **Size:** Smallest (Google optimizes)
- **Compatibility:** All devices (Google handles it)
- **Use case:** Google Play Store only
- **Command:** `flutter build appbundle --release`

---

## 🎯 Quick Commands Cheat Sheet

```bash
# Setup (first time)
./setup-signing.sh

# Build
./build-release.sh

# Or manually
flutter build apk --split-per-abi --release

# Install
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# Check version
grep "versionCode\|versionName" android/app/build.gradle

# Clean build
flutter clean && flutter pub get

# Check APK size
flutter build apk --analyze-size --release

# View logs
adb logcat | grep flutter
```

---

## 📱 Distribution Options

### Option 1: Direct Distribution (APK)
- Build APK using scripts
- Share APK file directly with users
- Users install manually
- **Pros:** Quick, no approval needed
- **Cons:** Users need to enable "Unknown sources"

### Option 2: Google Play Store (AAB)
- Build App Bundle
- Upload to Play Console
- Google reviews and publishes
- **Pros:** Professional, automatic updates
- **Cons:** Review process, fees

### Option 3: Internal Testing
- Use Google Play Internal Testing
- Share with testers via link
- No public release
- **Pros:** Easy testing, no manual installation
- **Cons:** Requires Play Console setup

---

## 🔐 Security Reminders

### Always:
- ✅ Keep keystore file safe
- ✅ Use strong passwords
- ✅ Store passwords in password manager
- ✅ Backup keystore file
- ✅ Use production credentials

### Never:
- ❌ Commit keystore to Git
- ❌ Commit key.properties to Git
- ❌ Share keystore with others
- ❌ Use development credentials in production
- ❌ Lose keystore file

---

## 📈 Version Management

### Version Code (Integer)
- Increment for each release: 1, 2, 3, 4...
- Used by Google Play for updates
- Must always increase

### Version Name (String)
- User-facing version: 1.0.0, 1.0.1, 1.1.0...
- Follows semantic versioning
- Shows in app info

### Example:
```gradle
versionCode 1      // First release
versionName "1.0.0"

versionCode 2      // Bug fix
versionName "1.0.1"

versionCode 3      // New features
versionName "1.1.0"

versionCode 4      // Major update
versionName "2.0.0"
```

---

## 🎉 Success Indicators

You'll know everything is working when:

1. ✅ Setup script completes without errors
2. ✅ Build script produces APK files
3. ✅ APK installs on device
4. ✅ App launches successfully
5. ✅ All features work correctly
6. ✅ No crashes or errors

---

## 📞 Support Resources

### Documentation:
- `BUILD_APK_SUMMARY.md` - Quick overview
- `QUICK_START_BUILD.md` - Quick reference
- `BUILD_PRODUCTION_APK.md` - Detailed guide

### Scripts:
- `./setup-signing.sh` - Setup helper
- `./build-release.sh` - Build helper

### External:
- [Flutter Docs](https://docs.flutter.dev/deployment/android)
- [Android Signing](https://developer.android.com/studio/publish/app-signing)
- [Google Play Console](https://play.google.com/console)

---

## 🚀 Ready to Start?

1. **Read:** `BUILD_APK_SUMMARY.md` (5 minutes)
2. **Setup:** Run `./setup-signing.sh` (5 minutes)
3. **Build:** Run `./build-release.sh` (5 minutes)
4. **Test:** Install and test APK (10 minutes)

**Total time:** ~25 minutes for your first build!

---

## 💡 Pro Tips

1. **Use split APKs** for smaller file sizes
2. **Test on real devices** before distributing
3. **Keep keystore backed up** in multiple locations
4. **Use semantic versioning** for version names
5. **Document changes** in release notes
6. **Test thoroughly** before each release

---

## 🎯 Next Steps

After building your APK:

1. ✅ Test on multiple devices
2. ✅ Verify all features work
3. ✅ Check for crashes
4. ✅ Test notifications
5. ✅ Verify API connectivity
6. ✅ Test login/logout
7. ✅ Distribute to users

---

**Happy Building! 🚀**

For questions or issues, refer to the detailed documentation files listed above.

---

**Last Updated:** April 14, 2026
**Status:** ✅ Ready to Use
