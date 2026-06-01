# 🔔 Notification Permission Prompt - Implementation Guide

## Overview

This guide shows how to add an explicit notification permission prompt when users click the bell icon in the notifications page.

## Changes Required

### 1. Update `notifications_page.dart`

Add permission checking and prompting functionality.

## Implementation

### Step 1: Add Permission Check State

```dart
class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationStorageService _storageService = NotificationStorageService();
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _hasPermission = false; // ADD THIS
  bool _isCheckingPermission = true; // ADD THIS

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _cleanupExpiredNotifications();
    _checkNotificationPermission(); // ADD THIS
    
    _storageService.addListener(_onNotificationsChanged);
  }
  
  // ADD THIS METHOD
  Future<void> _checkNotificationPermission() async {
    final oneSignalService = OneSignalService();
    final hasPermission = await oneSignalService.hasPermission();
    setState(() {
      _hasPermission = hasPermission;
      _isCheckingPermission = false;
    });
  }
```

### Step 2: Add Permission Request Handler

```dart
// ADD THIS METHOD
Future<void> _requestNotificationPermission() async {
  final oneSignalService = OneSignalService();
  
  // Check current permission status
  final currentPermission = await oneSignalService.getPermissionStatus();
  
  if (currentPermission == OSNotificationPermission.denied) {
    // Permission was permanently denied, need to open settings
    _showOpenSettingsDialog();
    return;
  }
  
  // Request permission
  final granted = await oneSignalService.requestPermission();
  
  if (granted) {
    // Link user to OneSignal
    final authState = AuthState();
    if (authState.user != null) {
      await oneSignalService.setExternalUserId(authState.user!.uid);
      await oneSignalService.optIn();
    }
    
    setState(() {
      _hasPermission = true;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text(context.tr('notifications_enabled')),
            ],
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } else {
    // Permission denied
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('notifications_permission_denied')),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ADD THIS METHOD
void _showOpenSettingsDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr('enable_notifications')),
      content: Text(context.tr('notifications_settings_message')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Open app settings
            // Note: You'll need to add permission_handler package
            // and implement openAppSettings()
          },
          child: Text(
            context.tr('open_settings'),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
```

### Step 3: Add Permission Banner

```dart
@override
Widget build(BuildContext context) {
  final hasNotifications = _notifications.isNotEmpty;

  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      // ... existing app bar code
    ),
    body: Column(
      children: [
        // ADD THIS BANNER
        if (!_isCheckingPermission && !_hasPermission)
          _buildPermissionBanner(),
        
        // Existing body content
        Expanded(
          child: hasNotifications
              ? RefreshIndicator(
                  onRefresh: () async {
                    _loadNotifications();
                    await _checkNotificationPermission();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('stay_updated_spiritual'),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 60),
                        _buildEmptyState(context),
                        const SizedBox(height: 40),
                        _buildNotificationPreferences(context),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    ),
  );
}

// ADD THIS METHOD
Widget _buildPermissionBanner() {
  return Container(
    color: Colors.orange.shade50,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.notifications_off,
            color: Colors.orange.shade700,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('notifications_disabled'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.orange.shade900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr('enable_to_receive_updates'),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _requestNotificationPermission,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            context.tr('enable'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
```

### Step 4: Update Empty State

```dart
Widget _buildEmptyState(BuildContext context) {
  return Center(
    child: Column(
      children: [
        const Icon(
          Icons.notifications_off_outlined,
          size: 80,
          color: AppTheme.softGray,
        ),
        const SizedBox(height: 24),
        Text(
          context.tr('no_notifications_yet'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            context.tr('notifications_description'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // ADD THIS BUTTON IF PERMISSION NOT GRANTED
        if (!_hasPermission) ...[
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _requestNotificationPermission,
            icon: Icon(Icons.notifications_active),
            label: Text(context.tr('enable_notifications')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
```

## Step 5: Add Localization Strings

Add these keys to your localization files:

### English (en.json)
```json
{
  "notifications_enabled": "Notifications enabled successfully!",
  "notifications_permission_denied": "Notification permission denied",
  "enable_notifications": "Enable Notifications",
  "notifications_settings_message": "Please enable notifications in your device settings to receive updates.",
  "open_settings": "Open Settings",
  "notifications_disabled": "Notifications are disabled",
  "enable_to_receive_updates": "Enable to receive important updates",
  "enable": "Enable"
}
```

### Hindi (hi.json)
```json
{
  "notifications_enabled": "सूचनाएं सफलतापूर्वक सक्षम की गईं!",
  "notifications_permission_denied": "सूचना अनुमति अस्वीकृत",
  "enable_notifications": "सूचनाएं सक्षम करें",
  "notifications_settings_message": "अपडेट प्राप्त करने के लिए कृपया अपनी डिवाइस सेटिंग्स में सूचनाएं सक्षम करें।",
  "open_settings": "सेटिंग्स खोलें",
  "notifications_disabled": "सूचनाएं अक्षम हैं",
  "enable_to_receive_updates": "महत्वपूर्ण अपडेट प्राप्त करने के लिए सक्षम करें",
  "enable": "सक्षम करें"
}
```

## Step 6: Add Permission Handler Package (Optional)

To open app settings when permission is permanently denied:

### pubspec.yaml
```yaml
dependencies:
  permission_handler: ^11.0.0
```

### Update _showOpenSettingsDialog
```dart
import 'package:permission_handler/permission_handler.dart';

void _showOpenSettingsDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr('enable_notifications')),
      content: Text(context.tr('notifications_settings_message')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await openAppSettings();
          },
          child: Text(
            context.tr('open_settings'),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
```

## Testing Checklist

- [ ] Test on Android device
  - [ ] First time permission request
  - [ ] Permission granted flow
  - [ ] Permission denied flow
  - [ ] Open settings when permanently denied
  
- [ ] Test on iOS device
  - [ ] First time permission request
  - [ ] Permission granted flow
  - [ ] Permission denied flow
  - [ ] Open settings when permanently denied

- [ ] Test banner visibility
  - [ ] Banner shows when permission not granted
  - [ ] Banner hides when permission granted
  - [ ] Banner updates after permission change

- [ ] Test empty state button
  - [ ] Button shows when no notifications and no permission
  - [ ] Button triggers permission request
  - [ ] Button updates after permission granted

## UI Preview

### Permission Banner (When Disabled)
```
┌─────────────────────────────────────────────────────┐
│ 🔕 Notifications are disabled                       │
│    Enable to receive important updates              │
│                                        [Enable]      │
└─────────────────────────────────────────────────────┘
```

### Empty State (With Enable Button)
```
┌─────────────────────────────────────────────────────┐
│                                                      │
│                    🔕                                │
│                                                      │
│           No notifications yet                       │
│                                                      │
│    Enable notifications to stay updated with        │
│    spiritual content and important announcements    │
│                                                      │
│         [🔔 Enable Notifications]                   │
│                                                      │
└─────────────────────────────────────────────────────┘
```

## Notes

1. **Permission Flow:**
   - First request: Shows OS permission dialog
   - Granted: Links user to OneSignal and opts in
   - Denied: Shows message
   - Permanently denied: Shows dialog to open settings

2. **User Experience:**
   - Non-intrusive banner at top
   - Clear call-to-action button
   - Helpful messaging
   - Easy access to settings

3. **Best Practices:**
   - Check permission on page load
   - Update UI when permission changes
   - Provide clear instructions
   - Handle all permission states

## Support

If you encounter any issues, check:
1. OneSignal is initialized in main.dart
2. OneSignalService is properly configured
3. Localization strings are added
4. Permission handler package is installed (if using settings)
