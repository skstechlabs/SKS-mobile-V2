import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../core/theme/app_theme.dart';

class RingtoneSettingsPage extends StatefulWidget {
  const RingtoneSettingsPage({Key? key}) : super(key: key);

  @override
  State<RingtoneSettingsPage> createState() => _RingtoneSettingsPageState();
}

class _RingtoneSettingsPageState extends State<RingtoneSettingsPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  
  static const platform = MethodChannel('com.spiritual.app/ringtone');

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
          _showPermissionDialog();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error setting ringtone: $e');

      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  Future<void> _setAsNotification() async {
    if (!Platform.isAndroid) {
      _showPlatformNotSupported();
      return;
    }

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
          _showPermissionDialog();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error setting notification: $e');

      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  Future<void> _setAsAlarm() async {
    if (!Platform.isAndroid) {
      _showPlatformNotSupported();
      return;
    }

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
          _showPermissionDialog();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error setting alarm: $e');

      if (mounted) {
        _showPermissionDialog();
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

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'To set ringtones, you need to grant "Modify system settings" permission.\n\n'
          'Please go to Settings > Apps > SKS > Permissions and enable this permission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
        title: const Text('Sivoham Ringtone'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with preview
            Container(
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
                  const Text(
                    'Sivoham Ringtone',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sacred mantra for your device',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _playPreview,
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    label: Text(_isPlaying ? 'Stop Preview' : 'Play Preview'),
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
                    'Set as Device Sound',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose where you want to use this sacred sound',
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
              title: 'Phone Ringtone',
              description: 'Set as your default phone ringtone',
              color: Colors.blue,
              onTap: _isLoading ? null : _setAsRingtone,
            ),

            _buildOptionCard(
              icon: Icons.notifications_active,
              title: 'Notification Sound',
              description: 'Set as your default notification sound',
              color: Colors.green,
              onTap: _isLoading ? null : _setAsNotification,
            ),

            _buildOptionCard(
              icon: Icons.alarm,
              title: 'Alarm Sound',
              description: 'Set as your default alarm sound',
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
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback? onTap,
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
              border: Border.all(color: AppTheme.softGray),
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
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
                if (_isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
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
