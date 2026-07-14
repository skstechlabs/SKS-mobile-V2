import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/localization_service.dart';

class RingtoneSettingsPage extends StatefulWidget {
  const RingtoneSettingsPage({super.key});

  @override
  State<RingtoneSettingsPage> createState() => _RingtoneSettingsPageState();
}

class _RingtoneSettingsPageState extends State<RingtoneSettingsPage>
    with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _loadingType; // which card is currently loading

  // Current enabled state for each type
  bool _ringtoneEnabled = false;
  bool _appNotificationEnabled = false;

  // Pending action to retry after returning from system settings
  String? _pendingType;

  static const _channel = MethodChannel('com.spiritual.app/ringtone');

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllStates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Always refresh states when returning to app (e.g. from system settings)
      _checkAllStates();
      // If user went to settings for a pending action, retry it
      if (_pendingType != null) {
        final type = _pendingType!;
        _pendingType = null;
        Future.delayed(const Duration(milliseconds: 600), () => _set(type));
      }
    }
  }

  // ── State checks ───────────────────────────────────────────────────────────

  Future<void> _checkAllStates() async {
    if (!Platform.isAndroid) return;
    try {
      final results = await Future.wait([
        _channel.invokeMethod<bool>('checkRingtone').catchError((_) => false),
        _channel.invokeMethod<bool>('checkAppNotification').catchError((_) => false),
      ]);
      if (mounted) {
        setState(() {
          _ringtoneEnabled        = results[0] ?? false;
          _appNotificationEnabled = results[1] ?? false;
        });
      }
    } catch (e) {
      debugPrint('checkAllStates error: $e');
    }
  }

  // ── Preview ────────────────────────────────────────────────────────────────

  Future<void> _togglePreview() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        if (mounted) setState(() => _isPlaying = false);
        return;
      }
      if (mounted) setState(() => _isPlaying = true);
      await _audioPlayer.setAudioSource(
          AudioSource.asset('assets/audio/Sivoham_ringtone.mp3'));
      await _audioPlayer.play();
      _audioPlayer.playerStateStream.listen((s) {
        if (s.processingState == ProcessingState.completed && mounted) {
          setState(() => _isPlaying = false);
        }
      });
    } catch (e) {
      if (mounted) setState(() => _isPlaying = false);
      _snack('Could not play preview', Colors.orange);
    }
  }

  // ── Copy asset to external storage ────────────────────────────────────────

  Future<File> _copyAsset() async {
    final data = await rootBundle.load('assets/audio/Sivoham_ringtone.mp3');
    final dir = await getExternalStorageDirectory();
    final file = File('${dir!.path}/Sivoham_ringtone.mp3');
    await file.writeAsBytes(data.buffer.asUint8List());
    return file;
  }

  // ── Set a sound type ───────────────────────────────────────────────────────

  Future<void> _set(String type) async {
    if (!Platform.isAndroid) {
      _snack('Only supported on Android', Colors.orange);
      return;
    }
    if (_loadingType != null) return; // already busy

    // App notification doesn't need WRITE_SETTINGS
    if (type != 'appNotification') {
      bool hasPermission = false;
      try {
        hasPermission =
            await _channel.invokeMethod<bool>('checkPermission') ?? false;
      } catch (_) {}

      if (!hasPermission) {
        // Store pending action BEFORE opening settings dialog
        _pendingType = type;
        _showPermissionDialog(type);
        return;
      }
    }

    await _executeSet(type);
  }

  Future<void> _executeSet(String type) async {
    final methodMap = {
      'ringtone': 'setRingtone',
      'appNotification': 'setAppNotification',
    };

    if (mounted) setState(() => _loadingType = type);
    try {
      final file = await _copyAsset();
      final ok = await _channel.invokeMethod<bool>(methodMap[type]!, {
            'path': file.path,
            'title': 'Sivoham',
          }) ??
          false;

      if (ok) {
        await _checkAllStates();
        _snack('Sivoham set successfully ✓', Colors.green);
      } else {
        _snack('Failed to set. Please try again.', Colors.red);
      }
    } catch (e) {
      _snack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _loadingType = null);
    }
  }

  // ── Disable / reset a sound type ──────────────────────────────────────────

  Future<void> _disable(String type) async {
    if (!Platform.isAndroid) return;

    if (type != 'appNotification') {
      bool hasPermission = false;
      try {
        hasPermission =
            await _channel.invokeMethod<bool>('checkPermission') ?? false;
      } catch (_) {}
      if (!hasPermission) {
        _pendingType = null; // no pending action for disable
        _showPermissionDialog(type);
        return;
      }
    }

    final methodMap = {
      'ringtone': 'resetRingtone',
      'appNotification': 'resetAppNotification',
    };

    if (mounted) setState(() => _loadingType = type);
    try {
      final ok =
          await _channel.invokeMethod<bool>(methodMap[type]!) ?? false;
      if (ok) {
        await _checkAllStates();
        _snack('Reset to system default', Colors.orange);
      } else {
        _snack('Failed to reset. Please try again.', Colors.red);
      }
    } catch (e) {
      _snack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _loadingType = null);
    }
  }

  // ── Permission dialog ──────────────────────────────────────────────────────
  // Key fix: use a local BuildContext from the dialog builder, and use
  // Navigator.of(dialogContext) to pop — avoids navigating the main route.

  void _showPermissionDialog(String type) {
    final names = {
      'ringtone': 'phone ringtone',
    };

    showDialog(
      context: context,
      barrierDismissible: false, // prevent accidental dismiss
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.settings, color: AppTheme.saffron),
            SizedBox(width: 10),
            Text('Permission Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To set the ${names[type] ?? 'sound'} to Sivoham, '
              'grant "Modify system settings" permission.',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.saffron.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Steps:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 4),
                  Text('1. Tap "Open Settings"', style: TextStyle(fontSize: 13)),
                  Text('2. Enable "Allow modifying system settings"', style: TextStyle(fontSize: 13)),
                  Text('3. Press Back — app will continue automatically', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _pendingType = null; // cancel pending
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // Close dialog first, THEN open settings
              Navigator.of(dialogContext).pop();
              try {
                await _channel.invokeMethod('openSettings');
              } catch (e) {
                debugPrint('openSettings error: $e');
              }
              // didChangeAppLifecycleState(resumed) will retry _pendingType
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.saffron,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Confirm disable dialog ─────────────────────────────────────────────────

  void _confirmDisable(String type, String title, Color color) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.music_off, color: color, size: 24),
            const SizedBox(width: 10),
            const Text('Disable Sivoham?'),
          ],
        ),
        content: Text(
          'This will reset "$title" back to your device\'s default sound.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _disable(type);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  // ── Snackbar ───────────────────────────────────────────────────────────────

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(context.tr('sivoham_ringtone_page_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh status',
            onPressed: _loadingType != null ? null : _checkAllStates,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header card ──────────────────────────────────────────────
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
                        AppTheme.saffron.withValues(alpha: 0.8)
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
                        child: const Icon(Icons.music_note,
                            color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('sivoham_ringtone_page_title'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('sacred_mantra_device'),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loadingType != null ? null : _togglePreview,
                          icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                          label: Text(_isPlaying
                              ? context.tr('stop_preview')
                              : context.tr('play_preview')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cream,
                            foregroundColor: AppTheme.saffron,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Active summary banner ────────────────────────────────────
                _buildActiveSummary(),

                // ── Section title ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('set_device_sound'),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('choose_sacred_sound'),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Sound type cards ─────────────────────────────────────────
                _buildCard(
                  icon: Icons.phone_in_talk,
                  title: context.tr('phone_ringtone'),
                  description: context.tr('set_default_ringtone'),
                  color: Colors.blue,
                  type: 'ringtone',
                  isEnabled: _ringtoneEnabled,
                ),
                _buildCard(
                  icon: Icons.notifications,
                  title: context.tr('app_notification_sound'),
                  description: context.tr('set_app_notification_only'),
                  color: Colors.purple,
                  type: 'appNotification',
                  isEnabled: _appNotificationEnabled,
                  isRecommended: true,
                ),

                // ── Info note ────────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tap SET to activate Sivoham for that sound type. '
                          'Tap the ON badge to disable it. '
                          'Some devices require "Modify system settings" permission — '
                          'the app will guide you automatically.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.blue.shade700, height: 1.4),
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

  // ── Active summary banner ──────────────────────────────────────────────────

  Widget _buildActiveSummary() {
    final activeCount = [
      _ringtoneEnabled,
      _appNotificationEnabled,
    ].where((e) => e).length;

    if (activeCount == 0) return const SizedBox.shrink();

    final activeNames = <String>[];
    if (_ringtoneEnabled) activeNames.add('Ringtone');
    if (_appNotificationEnabled) activeNames.add('App Notification');

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sivoham active for: ${activeNames.join(', ')}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card widget ────────────────────────────────────────────────────────────

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required String type,
    required bool isEnabled,
    bool isRecommended = false,
  }) {
    final isLoading = _loadingType == type;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isEnabled ? color.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEnabled ? color : Colors.grey.shade200,
          width: isEnabled ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isEnabled ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isEnabled ? color : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (isRecommended && !isEnabled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: TextStyle(
                                color: color,
                                fontSize: 8,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isEnabled ? '✓ Sivoham is active' : description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isEnabled ? color : AppTheme.textSecondary,
                      fontWeight:
                          isEnabled ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Action button
            if (isLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else if (isEnabled)
              // ON badge — tap to disable
              GestureDetector(
                onTap: () => _confirmDisable(type, title, color),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: color, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        'ON',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              // SET button
              GestureDetector(
                onTap: _loadingType != null ? null : () => _set(type),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _loadingType != null
                        ? Colors.grey.shade300
                        : color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'SET',
                    style: TextStyle(
                      color: _loadingType != null
                          ? Colors.grey.shade600
                          : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
