import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/localization_service.dart';

class RingtoneSettingsPage extends StatefulWidget {
  const RingtoneSettingsPage({Key? key}) : super(key: key);

  @override
  State<RingtoneSettingsPage> createState() => _RingtoneSettingsPageState();
}

class _RingtoneSettingsPageState extends State<RingtoneSettingsPage> with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _pendingAction; // Track which action is pending after permission grant
  
  static const platform = MethodChannel('com.spiritual.app/ringtone');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes from settings, retry the pending action
    if (state == AppLifecycleState.resumed && _pendingAction != null) {
      debugPrint('App resumed, retrying pending action: $_pendingAction');
      Future.delayed(const Duration(milliseconds: 500), () {
        _retryPendingAction();
      });
    }
  }

  Future<void> _retryPendingAction() async {
    if (_pendingAction == null) return;
    
    final action = _pendingAction;
    _pendingAction = null;
    
    // Check if permission is now granted
    try {
      final hasPermission = await platform.invokeMethod('checkPermission');
      if (hasPermission == true) {
        debugPrint('Permission granted, executing: $action');
        switch (action) {
          case 'ringtone':
            await _executeSetRingtone();
            break;
          case 'notification':
            await _executeSetNotification();
            break;
          case 'alarm':
            await _executeSetAlarm();
            break;
        }
      } else {
        debugPrint('Permission still not granted');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission not granted. Please enable "Modify system settings" permission.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error retrying action: $e');
    }
  }

  Future<void> _playPreview() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        setState(() => _isPlaying = false);
        return;
      }

      setState(() => _isPlaying = true);

      await _audioPlayer.setAudioSource(
        AudioSource.asset('assets/audio/Sivoham_ringtone.mp3'),
      );
      await _audioPlayer.play();

      // Listen for completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() => _isPlaying = false);
          }
        }
      });
    } catch (e) {
      debugPrint('Error playing preview: $e');
      setState(() => _isPlaying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not play preview: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<File> _copyAssetToFile() async {
    try {
      // Load asset
      final byteData = await rootBundle.load('assets/audio/Sivoham_ringtone.mp3');
      
      // Get external storage directory
      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/Sivoham_ringtone.mp3';
      
      // Write to file
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      
      return file;
    } catch (e) {
      debugPrint('Error copying asset: $e');
      rethrow;
    }
  }

  Future<void> _setAsRingtone() async {
    if (!Platform.isAndroid) {
      _showPlatformNotSupported();
      return;
    }

    // Check permission first
    try {
      final hasPermission = await platform.invokeMethod('checkPermission');
      if (hasPermission != true) {
        _pendingAction = 'ringtone';
        _showPermissionDialog('ringtone');
        return;
      }
    } catch (e) {
      debugPrint('Error checking permission: $e');
    }

    await _executeSetRingtone();
  }

  Future<void> _executeSetRingtone() async {
    setState(() => _isLoading = true);

    try {
      // Copy asset to file
      final file = await _copyAssetToFile();
      
      // Call platform method
      final result = await platform.invokeMethod('setRingtone', {
        'path': file.path,
        'title': 'Sivoham',
      });

      setState(() => _isLoading = false);

      if (mounted) {
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Sivoham ringtone set successfully!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to set ringtone. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error setting ringtone: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setAsNotification() async {
    if (!Platform.isAndroid) {
      _showPlatformNotSupported();
      return;
    }

    // Check permission first
    try {
      final hasPermission = await platform.invokeMethod('checkPermission');
      if (hasPermission != true) {
        _pendingAction = 'notification';
        _showPermissionDialog('notification');
        return;
      }
    } catch (e) {
      debugPrint('Error checking permission: $e');
    }

    await _executeSetNotification();
  }

  Future<void> _executeSetNotification() async {
    setState(() => _isLoading = true);

    try {
      // Copy asset to file
      final file = await _copyAssetToFile();
      
      // Call platform method
      final result = await platform.invokeMethod('setNotification', {
        'path': file.path,
        'title': 'Sivoham',
      });

      setState(() => _isLoading = false);

      if (mounted) {
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Sivoham notification sound set successfully!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to set notification sound. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error setting notification: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setAsAppNotification() async {
    if (!Platform.isAndroid) {
      _showPlatformNotSupported();
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Copy asset to file
      final file = await _copyAssetToFile();
      
      debugPrint('Setting app notification sound with file: ${file.path}');
      
      // Call platform method to set as app notification sound
      final result = await platform.invokeMethod('setAppNotification', {
        'path': file.path,
        'title': 'Sivoham',
      });

      debugPrint('App notification result: $result');
      
      setState(() => _isLoading = false);

      if (mounted) {
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Sivoham set as app notification sound! All app notifications will use this sound.'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to set app notification sound. This feature requires Android 8.0 or higher.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error setting app notification: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _setAsAlarm() async {
    if (!Platform.isAndroid) {
      _showPlatformNotSupported();
      return;
    }

    // Check permission first
    try {
      final hasPermission = await platform.invokeMethod('checkPermission');
      if (hasPermission != true) {
        _pendingAction = 'alarm';
        _showPermissionDialog('alarm');
        return;
      }
    } catch (e) {
      debugPrint('Error checking permission: $e');
    }

    await _executeSetAlarm();
  }

  Future<void> _executeSetAlarm() async {
    setState(() => _isLoading = true);

    try {
      // Copy asset to file
      final file = await _copyAssetToFile();
      
      // Call platform method
      final result = await platform.invokeMethod('setAlarm', {
        'path': file.path,
        'title': 'Sivoham',
      });

      setState(() => _isLoading = false);

      if (mounted) {
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Sivoham alarm sound set successfully!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to set alarm sound. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error setting alarm: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPlatformNotSupported() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not Supported'),
        content: const Text('Setting ringtones is currently only supported on Android devices.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog(String actionType) {
    String actionName = '';
    switch (actionType) {
      case 'ringtone':
        actionName = 'phone ringtone';
        break;
      case 'notification':
        actionName = 'notification sound';
        break;
      case 'alarm':
        actionName = 'alarm sound';
        break;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          'To set $actionName, you need to grant "Modify system settings" permission.\n\n'
          'Steps:\n'
          '1. Tap "Open Settings" below\n'
          '2. Enable "Allow modifying system settings"\n'
          '3. Return to this app\n\n'
          'The ringtone will be set automatically when you return.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              _pendingAction = null; // Cancel pending action
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await platform.invokeMethod('openSettings');
              } catch (e) {
                debugPrint('Error opening settings: $e');
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: Text(context.tr('sivoham_ringtone_page_title')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with preview - Full width within constraints
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.saffron,
                        AppTheme.saffron.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.saffron.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('sivoham_ringtone_page_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('sacred_mantra_device'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _playPreview,
                          icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                          label: Text(_isPlaying ? context.tr('stop_preview') : context.tr('play_preview')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.saffron,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

            // Info section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('set_device_sound'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('choose_sacred_sound'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Options
            _buildOptionCard(
              icon: Icons.phone_in_talk,
              title: context.tr('phone_ringtone'),
              description: context.tr('set_default_ringtone'),
              color: Colors.blue,
              onTap: _isLoading ? null : _setAsRingtone,
            ),

            _buildOptionCard(
              icon: Icons.notifications_active,
              title: context.tr('system_notification_sound'),
              description: context.tr('set_default_notification'),
              color: Colors.green,
              onTap: _isLoading ? null : _setAsNotification,
            ),

            _buildOptionCard(
              icon: Icons.notifications,
              title: context.tr('app_notification_sound'),
              description: context.tr('set_app_notification_only'),
              color: Colors.purple,
              onTap: _isLoading ? null : _setAsAppNotification,
              isRecommended: true,
            ),

            _buildOptionCard(
              icon: Icons.alarm,
              title: context.tr('alarm_sound'),
              description: context.tr('set_default_alarm'),
              color: Colors.orange,
              onTap: _isLoading ? null : _setAsAlarm,
            ),

            const SizedBox(height: 20),

            // Info note
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Note: You may need to grant system settings permission to change ringtones on some devices.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback? onTap,
    bool isRecommended = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: isRecommended ? color : AppTheme.softGray,
                width: isRecommended ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isRecommended)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'RECOMMENDED',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.textSecondary,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
