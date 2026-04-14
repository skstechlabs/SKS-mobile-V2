# Quick Build Reference

## 📦 Build Artifacts

### APK (Direct Installation)
```
Location: build/app/outputs/flutter-apk/app-release.apk
Size: 135 MB
Use: Direct installation, testing, sideloading
```

### AAB (Play Store)
```
Location: build/app/outputs/bundle/release/app-release.aab
Size: 124 MB
Use: Google Play Store upload
```

---

## 🚀 Quick Commands

### Build APK
```bash
cd SKS-mobile-V2
flutter clean
flutter pub get
flutter build apk --release
```

### Build App Bundle
```bash
cd SKS-mobile-V2
flutter clean
flutter pub get
flutter build appbundle --release
```

### Install on Device
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## ✅ What's New in This Build

1. ✅ Videos auto-play with sound (unmuted)
2. ✅ Wallpapers auto-rotate every 15 minutes
3. ✅ Enhanced profile with 14 fields + photo
4. ✅ Wallpapers load from CDN dynamically
5. ✅ Database-driven day unlock timing

---

## 📱 Installation

### For Testing (APK)
1. Copy APK to device
2. Enable "Unknown Sources" in Settings
3. Tap APK to install

### For Play Store (AAB)
1. Login to Play Console
2. Create new release
3. Upload app-release.aab
4. Submit for review

---

## 🔍 Quick Test

After installation, test:
- [ ] Login works
- [ ] Profile setup with photo
- [ ] Video plays with sound
- [ ] Wallpapers load from CDN
- [ ] Auto-rotation works

---

## 📞 Quick Support

**Backend Logs**: `pm2 logs sks-api`
**Mobile Logs**: `adb logcat | grep Flutter`
**API Test**: `curl https://sivakundalini.org/api/health`

---

**Build Date**: April 10, 2026
**Status**: ✅ Ready for Distribution
