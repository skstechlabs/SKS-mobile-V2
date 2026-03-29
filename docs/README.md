# 📚 SKS Mobile App Documentation

Complete documentation for the SKS spiritual mobile application.

## 📖 Table of Contents

- [Quick Start](#-quick-start)
- [Setup Guides](#-setup-guides)
- [User Guides](#-user-guides)
- [Troubleshooting](#-troubleshooting)
- [Reference](#-reference)

---

## 🚀 Quick Start

**New to the project?** Start here:

1. **[Installation Guide](setup/INSTALLATION_GUIDE.md)** - Set up your development environment
2. **[Setup Checklist](setup/SETUP_CHECKLIST.md)** - Complete setup verification
3. **[Quick Start Notifications](guides/QUICK_START_NOTIFICATIONS.md)** - Test notifications in 3 minutes

---

## 🛠️ Setup Guides

Complete setup instructions for all components:

### Development Environment
- **[Installation Guide](setup/INSTALLATION_GUIDE.md)** - Flutter, Android Studio, dependencies
- **[Android Emulator Setup](setup/ANDROID_EMULATOR_SETUP.md)** - Create and configure virtual devices
- **[Setup Checklist](setup/SETUP_CHECKLIST.md)** - Verify your setup is complete

### Backend & Services
- **[Backend Firebase Setup](setup/BACKEND_FIREBASE_SETUP.md)** - Configure Firebase Admin SDK
- **[Firebase OneSignal Setup](setup/FIREBASE_ONESIGNAL_SETUP_GUIDE.md)** - Connect Firebase with OneSignal
- **[OneSignal Setup](setup/ONESIGNAL_SETUP.md)** - Configure push notifications

---

## 📖 User Guides

Step-by-step guides for common tasks:

### Building & Deployment
- **[Build APK Guide](guides/BUILD_APK_GUIDE.md)** - Create APK for testing and production
- **[APK Size Optimization](guides/APK_SIZE_OPTIMIZATION.md)** - Reduce app size

### API Integration
- **[API Integration Guide](guides/API_INTEGRATION_GUIDE.md)** - Integrate backend APIs
- **[Quick Start API](guides/QUICK_START_API.md)** - API quick reference

### Notifications
- **[OneSignal Integration Guide](guides/ONESIGNAL_INTEGRATION_GUIDE.md)** - Complete OneSignal setup
- **[Notification Testing Guide](guides/NOTIFICATION_TESTING_GUIDE.md)** - Test push notifications
- **[Quick Start Notifications](guides/QUICK_START_NOTIFICATIONS.md)** - 3-minute notification test

---

## 🔧 Troubleshooting

Solutions to common issues:

### Critical Fixes
- **[OneSignal ProGuard Fix](troubleshooting/ONESIGNAL_PROGUARD_FIX.md)** - Fix "Missing Plugin Exception"
- **[Critical Fixes Applied](troubleshooting/CRITICAL_FIXES_APPLIED.md)** - Login loop and plugin issues
- **[Final Fix Summary](troubleshooting/FINAL_FIX_SUMMARY.md)** - Complete fix overview

### Common Issues
- **[Notification Permission Troubleshooting](troubleshooting/NOTIFICATION_PERMISSION_TROUBLESHOOTING.md)** - Permission issues
- **[Web vs Mobile OneSignal](troubleshooting/WEB_VS_MOBILE_ONESIGNAL.md)** - Platform-specific issues
- **[Quick Fix Guide](troubleshooting/QUICK_FIX_GUIDE.md)** - Quick solutions
- **[Fix Commands](troubleshooting/FIX_COMMANDS.md)** - Command reference for fixes
- **[Fixes Applied](troubleshooting/FIXES_APPLIED.md)** - History of fixes

---

## 📚 Reference

Technical reference and architecture documentation:

### Architecture & Design
- **[Design Architecture](reference/DESIGN_ARCHITECTURE.md)** - App architecture overview
- **[Complete Implementation Summary](reference/COMPLETE_IMPLEMENTATION_SUMMARY.md)** - Full implementation details
- **[Updated User Flow](reference/UPDATED_USER_FLOW.md)** - User journey and flows

### API Reference
- **[API Flow Diagram](reference/API_FLOW_DIAGRAM.md)** - API integration flow
- **[Backend Integration Summary](reference/BACKEND_INTEGRATION_SUMMARY.md)** - Backend overview

### OneSignal Reference
- **[OneSignal Implementation Summary](reference/ONESIGNAL_IMPLEMENTATION_SUMMARY.md)** - Implementation details
- **[OneSignal Quick Reference](reference/ONESIGNAL_QUICK_REFERENCE.md)** - Quick API reference
- **[OneSignal Notification Examples](reference/ONESIGNAL_NOTIFICATION_EXAMPLES.md)** - Example notifications
- **[OneSignal README](reference/ONESIGNAL_README.md)** - OneSignal overview
- **[Firebase OneSignal Connection](reference/FIREBASE_ONESIGNAL_CONNECTION_DIAGRAM.md)** - Connection diagram

### Build & Deployment
- **[APK Size Summary](reference/APK_SIZE_SUMMARY.md)** - APK size analysis
- **[Quick Commands](reference/QUICK_COMMANDS.md)** - Command reference

### Assets
- **[Assets Guide](reference/ASSETS_GUIDE.md)** - Asset management
- **[Notification Implementation](reference/NOTIFICATION_IMPLEMENTATION_COMPLETE.md)** - Notification system details

---

## 🎯 Common Tasks

### I want to...

#### Set up the project
1. Follow [Installation Guide](setup/INSTALLATION_GUIDE.md)
2. Complete [Setup Checklist](setup/SETUP_CHECKLIST.md)
3. Run [Quick Start Notifications](guides/QUICK_START_NOTIFICATIONS.md)

#### Build an APK
1. Read [Build APK Guide](guides/BUILD_APK_GUIDE.md)
2. Optimize with [APK Size Optimization](guides/APK_SIZE_OPTIMIZATION.md)

#### Fix notification issues
1. Check [Notification Permission Troubleshooting](troubleshooting/NOTIFICATION_PERMISSION_TROUBLESHOOTING.md)
2. Review [OneSignal ProGuard Fix](troubleshooting/ONESIGNAL_PROGUARD_FIX.md)
3. See [Web vs Mobile OneSignal](troubleshooting/WEB_VS_MOBILE_ONESIGNAL.md)

#### Integrate backend APIs
1. Follow [API Integration Guide](guides/API_INTEGRATION_GUIDE.md)
2. Set up [Backend Firebase](setup/BACKEND_FIREBASE_SETUP.md)
3. Use [Quick Start API](guides/QUICK_START_API.md)

#### Set up push notifications
1. Complete [OneSignal Setup](setup/ONESIGNAL_SETUP.md)
2. Follow [OneSignal Integration Guide](guides/ONESIGNAL_INTEGRATION_GUIDE.md)
3. Test with [Notification Testing Guide](guides/NOTIFICATION_TESTING_GUIDE.md)

---

## 📂 Documentation Structure

```
docs/
├── README.md                          # This file
├── INDEX.md                           # Legacy index
├── DOCUMENTATION_INDEX.md             # Legacy documentation index
│
├── setup/                             # Setup & Installation
│   ├── INSTALLATION_GUIDE.md
│   ├── ANDROID_EMULATOR_SETUP.md
│   ├── BACKEND_FIREBASE_SETUP.md
│   ├── FIREBASE_ONESIGNAL_SETUP_GUIDE.md
│   ├── ONESIGNAL_SETUP.md
│   └── SETUP_CHECKLIST.md
│
├── guides/                            # How-to Guides
│   ├── BUILD_APK_GUIDE.md
│   ├── APK_SIZE_OPTIMIZATION.md
│   ├── API_INTEGRATION_GUIDE.md
│   ├── ONESIGNAL_INTEGRATION_GUIDE.md
│   ├── NOTIFICATION_TESTING_GUIDE.md
│   ├── QUICK_START_API.md
│   └── QUICK_START_NOTIFICATIONS.md
│
├── troubleshooting/                   # Problem Solutions
│   ├── ONESIGNAL_PROGUARD_FIX.md
│   ├── CRITICAL_FIXES_APPLIED.md
│   ├── FINAL_FIX_SUMMARY.md
│   ├── NOTIFICATION_PERMISSION_TROUBLESHOOTING.md
│   ├── WEB_VS_MOBILE_ONESIGNAL.md
│   ├── QUICK_FIX_GUIDE.md
│   ├── FIX_COMMANDS.md
│   └── FIXES_APPLIED.md
│
└── reference/                         # Technical Reference
    ├── DESIGN_ARCHITECTURE.md
    ├── COMPLETE_IMPLEMENTATION_SUMMARY.md
    ├── API_FLOW_DIAGRAM.md
    ├── BACKEND_INTEGRATION_SUMMARY.md
    ├── ONESIGNAL_IMPLEMENTATION_SUMMARY.md
    ├── ONESIGNAL_QUICK_REFERENCE.md
    ├── ONESIGNAL_NOTIFICATION_EXAMPLES.md
    ├── ONESIGNAL_README.md
    ├── FIREBASE_ONESIGNAL_CONNECTION_DIAGRAM.md
    ├── NOTIFICATION_IMPLEMENTATION_COMPLETE.md
    ├── APK_SIZE_SUMMARY.md
    ├── QUICK_COMMANDS.md
    ├── UPDATED_USER_FLOW.md
    └── ASSETS_GUIDE.md
```

---

## 🔗 Quick Links

### Most Used Documents
- [Build APK Guide](guides/BUILD_APK_GUIDE.md)
- [OneSignal ProGuard Fix](troubleshooting/ONESIGNAL_PROGUARD_FIX.md)
- [Quick Commands](reference/QUICK_COMMANDS.md)
- [Notification Testing](guides/NOTIFICATION_TESTING_GUIDE.md)

### Setup Documents
- [Installation Guide](setup/INSTALLATION_GUIDE.md)
- [Android Emulator Setup](setup/ANDROID_EMULATOR_SETUP.md)
- [Firebase Setup](setup/BACKEND_FIREBASE_SETUP.md)

### Reference Documents
- [Complete Implementation](reference/COMPLETE_IMPLEMENTATION_SUMMARY.md)
- [API Reference](reference/API_FLOW_DIAGRAM.md)
- [OneSignal Reference](reference/ONESIGNAL_QUICK_REFERENCE.md)

---

## 📝 Document Categories

### 🛠️ Setup (6 documents)
Complete setup instructions for development environment, backend services, and push notifications.

### 📖 Guides (7 documents)
Step-by-step tutorials for building, deploying, and integrating features.

### 🔧 Troubleshooting (8 documents)
Solutions to common issues and problems encountered during development.

### 📚 Reference (15 documents)
Technical documentation, architecture details, and API references.

---

## 🎯 Getting Started

1. **New Developer?**
   - Start with [Installation Guide](setup/INSTALLATION_GUIDE.md)
   - Follow [Setup Checklist](setup/SETUP_CHECKLIST.md)

2. **Building APK?**
   - Read [Build APK Guide](guides/BUILD_APK_GUIDE.md)
   - Check [APK Size Optimization](guides/APK_SIZE_OPTIMIZATION.md)

3. **Having Issues?**
   - Check [Troubleshooting](troubleshooting/) folder
   - Most common: [OneSignal ProGuard Fix](troubleshooting/ONESIGNAL_PROGUARD_FIX.md)

4. **Need Reference?**
   - Browse [Reference](reference/) folder
   - Quick commands: [Quick Commands](reference/QUICK_COMMANDS.md)

---

## 📞 Support

For issues not covered in documentation:
- Check [Troubleshooting](troubleshooting/) section
- Review [Complete Implementation Summary](reference/COMPLETE_IMPLEMENTATION_SUMMARY.md)
- See [Fixes Applied](troubleshooting/FIXES_APPLIED.md) for known issues

---

**Last Updated**: March 28, 2026
**Version**: 1.0.0
