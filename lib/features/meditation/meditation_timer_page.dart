import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/services/enhanced_audio_player_service.dart';
import '../auth/auth_state.dart';

class MeditationTimerPage extends StatefulWidget {
  const MeditationTimerPage({Key? key}) : super(key: key);

  @override
  State<MeditationTimerPage> createState() => _MeditationTimerPageState();
}

class _MeditationTimerPageState extends State<MeditationTimerPage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  // Two separate players so start and end sounds never conflict with each other
  final AudioPlayer _startPlayer = AudioPlayer();
  final AudioPlayer _endPlayer = AudioPlayer();

  // Timer state
  Timer? _timer;
  int _seconds = 0;
  int _targetSeconds = 0;
  bool _isRunning = false;
  bool _hasStarted = false;
  DateTime? _startTime;

  // Auth state — uses cached AuthState, works offline
  bool get _isLoggedIn => AuthState().isAuthenticated;

  // Cached audio file paths (kept for debug logging only)
  String? _cachedStartSoundPath;  // ignore: unused_field
  String? _cachedEndSoundPath;    // ignore: unused_field

  // Preload states: 'idle' | 'loading' | 'ready' | 'error'
  String _startSoundState = 'idle';
  String _endSoundState = 'idle';

  bool get _soundsLoading =>
      _startSoundState == 'idle' || _endSoundState == 'idle';

  // Animation
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // Download, cache, AND pre-buffer both sounds on page open
    _downloadAndCacheSounds();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    _startPlayer.dispose();
    _endPlayer.dispose();
    super.dispose();
  }

  /// Fetch URLs from API, download to disk, then pre-buffer into the players
  /// so playback starts instantly with zero latency.
  Future<void> _downloadAndCacheSounds() async {
    try {
      final languageCode = LocalizationService().currentLocale.languageCode;
      final languageMap = {
        'en': 'english',
        'hi': 'hindi',
        'te': 'telugu',
        'kn': 'kannada',
      };
      final dbLanguage = languageMap[languageCode] ?? 'english';

      debugPrint('Fetching meditation sounds for language: $dbLanguage');

      final response = await _apiService.get(
        '/api/audios',
        queryParameters: {'category': 'meditation_sound', 'language': dbLanguage},
      );

      if (response['success'] == true && response['audios'] != null) {
        final audios = response['audios'] as List;

        final startAudio = audios.firstWhere(
          (a) => a['title']?.toString().contains('Start') ?? false,
          orElse: () => null,
        );
        final endAudio = audios.firstWhere(
          (a) => a['title']?.toString().contains('End') ?? false,
          orElse: () => null,
        );

        // Download both in parallel
        await Future.wait([
          if (startAudio?['audio_url'] != null)
            _cacheAndPreload(
              url: startAudio['audio_url'] as String,
              filename: 'meditation_start_$dbLanguage.mp3',
              player: _startPlayer,
              onReady: () {
                if (mounted) setState(() => _startSoundState = 'ready');
              },
              onError: () {
                if (mounted) setState(() => _startSoundState = 'error');
              },
            ),
          if (endAudio?['audio_url'] != null)
            _cacheAndPreload(
              url: endAudio['audio_url'] as String,
              filename: 'meditation_end_$dbLanguage.mp3',
              player: _endPlayer,
              onReady: () {
                if (mounted) setState(() => _endSoundState = 'ready');
              },
              onError: () {
                if (mounted) setState(() => _endSoundState = 'error');
              },
            ),
        ]);

        debugPrint('✅ Meditation sounds ready — start:$_startSoundState end:$_endSoundState');
      } else {
        debugPrint('⚠️ No meditation sounds in API response');
        if (mounted) {
          setState(() {
            _startSoundState = 'error';
            _endSoundState = 'error';
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching meditation sounds: $e');
      if (mounted) {
        setState(() {
          _startSoundState = 'error';
          _endSoundState = 'error';
        });
      }
    }
  }

  /// Download audio to disk (skips if already cached), then pre-buffer it
  /// into [player] so it's ready for instant playback.
  Future<void> _cacheAndPreload({
    required String url,
    required String filename,
    required AudioPlayer player,
    required VoidCallback onReady,
    required VoidCallback onError,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/meditation_sounds');
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

      final cachedFile = File('${cacheDir.path}/$filename');

      if (!await cachedFile.exists()) {
        debugPrint('Downloading: $url');
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await cachedFile.writeAsBytes(response.bodyBytes);
          debugPrint('✅ Cached: ${cachedFile.path}');
        } else {
          debugPrint('❌ Download failed (${response.statusCode}): $url');
          onError();
          return;
        }
      } else {
        debugPrint('✅ Using cached: ${cachedFile.path}');
      }

      // setFilePath() already loads AND buffers the audio.
      // Do NOT call player.load() after it — that resets the player to idle
      // and wipes the buffer, causing silence when play() is called.
      await player.setFilePath(cachedFile.path);

      // Store path for reference
      if (filename.contains('start')) {
        _cachedStartSoundPath = cachedFile.path;
      } else {
        _cachedEndSoundPath = cachedFile.path;
      }

      onReady();
      debugPrint('✅ Preloaded and ready: $filename (state: ${player.processingState})');
    } catch (e) {
      debugPrint('❌ Error caching/preloading $filename: $e');
      onError();
    }
  }

  /// Play the start sound then begin the timer tick.
  Future<void> _playStartSoundAndBeginTimer() async {
    if (_startSoundState != 'ready') {
      debugPrint('⚠️ Start sound not ready (state: $_startSoundState), starting timer without audio');
      _beginTimerTick();
      return;
    }

    try {
      // Seek to beginning in case it was played before
      await _startPlayer.seek(Duration.zero);
      await _startPlayer.play();
      debugPrint('✅ Start sound play() called');
    } catch (e) {
      debugPrint('⚠️ Start sound play error: $e');
    }

    // Start the timer immediately — don't wait for audio confirmation.
    // Waiting on playerStateStream can hang if AudioService holds audio focus.
    _beginTimerTick();
  }

  void _beginTimerTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_targetSeconds > 0) {
          _seconds--;
          if (_seconds <= 0) {
            _seconds = 0;
            _completeTimer();
          }
        } else {
          _seconds++;
        }
      });
    });
  }

  Future<void> _playEndSound() async {
    if (_endSoundState != 'ready') {
      debugPrint('⚠️ End sound not ready (state: $_endSoundState), skipping');
      return;
    }
    try {
      await _endPlayer.seek(Duration.zero);
      await _endPlayer.play();
      debugPrint('✅ End sound play() called');

      // Wait for completion so the dialog shows after the sound finishes.
      // Use a safe timeout — if it never completes (e.g. audio focus lost),
      // continue after the timeout rather than hanging forever.
      await _endPlayer.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('⚠️ End sound timeout — continuing');
          return _endPlayer.playerState;
        },
      );
      debugPrint('✅ End sound finished');
    } catch (e) {
      debugPrint('⚠️ End sound error: $e');
    }
  }

  Future<void> _startTimer() async {
    if (_isRunning) return;

    if (!mounted) return;
    setState(() {
      _isRunning = true;
      _startTime = _startTime ?? DateTime.now();
      if (_targetSeconds > 0 && _seconds == 0) {
        _seconds = _targetSeconds;
      }
    });

    // Pause the global audio/bhajan player if it's running so it doesn't
    // hold the audio session and block the meditation sounds from playing.
    final globalPlayer = EnhancedAudioPlayerService();
    if (globalPlayer.isPlaying) {
      await globalPlayer.pause();
      debugPrint('⏸️ Paused global audio player for meditation');
    }

    if (!_hasStarted) {
      _hasStarted = true;
      await _playStartSoundAndBeginTimer();
    } else {
      // Resume after pause
      if (_startPlayer.processingState != ProcessingState.idle &&
          _startPlayer.processingState != ProcessingState.completed &&
          !_startPlayer.playing) {
        _startPlayer.play();
      }
      _beginTimerTick();
    }
  }

  void _pauseTimer() {
    if (!_isRunning) return;

    _timer?.cancel();
    if (mounted) setState(() => _isRunning = false);

    // Pause the start-sound if it's still playing
    if (_startPlayer.playing) _startPlayer.pause();
  }

  Future<void> _completeTimer() async {
    _timer?.cancel();
    if (_startPlayer.playing) _startPlayer.pause();
    if (mounted) setState(() => _isRunning = false);

    final endTime = DateTime.now();
    final actualDuration =
        _targetSeconds > 0 ? _targetSeconds : _seconds;
    final startTime =
        _startTime ?? endTime.subtract(Duration(seconds: actualDuration));

    // Play end sound — already pre-buffered
    await _playEndSound();

    if (!mounted) return;
    
    // Auto-save for logged-in users
    if (_isLoggedIn) {
      await _saveMeditationSession(startTime, endTime, actualDuration);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Expanded(child: Text('Meditation Complete!')),
              ],
            ),
            content: Text(
              'Congratulations! You meditated for ${_formatDuration(actualDuration)}.\n\n'
              'Your session has been saved.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/meditation/history');
                },
                child: const Text('View History'),
              ),
            ],
          ),
        );
      }
    } else {
      // Show login prompt for non-logged-in users
      if (mounted) {
        final shouldLogin = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Expanded(child: Text('Meditation Complete!')),
              ],
            ),
            content: Text(
              'Congratulations! You meditated for ${_formatDuration(actualDuration)}.\n\n'
              'Login to save your meditation sessions and track your progress over time.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Login'),
              ),
            ],
          ),
        );
        
        if (shouldLogin == true && mounted) {
          context.push('/login');
        }
      }
    }
    
    // Reset timer
    setState(() {
      _seconds = 0;
      _startTime = null;
      _hasStarted = false;
    });
  }

  void _resetTimer() {
    // Cancel timer
    _timer?.cancel();
    
    // Reset all state
    setState(() {
      _seconds = 0;
      _targetSeconds = 0;
      _isRunning = false;
      _hasStarted = false;
      _startTime = null;
    });
  }

  Future<void> _stopTimer() async {
    if (_seconds == 0 && _targetSeconds == 0) return;

    _timer?.cancel();
    if (_startPlayer.playing) _startPlayer.pause();

    if (mounted) setState(() => _isRunning = false);

    final endTime = DateTime.now();
    final actualDuration =
        _targetSeconds > 0 ? (_targetSeconds - _seconds) : _seconds;
    final startTime =
        _startTime ?? endTime.subtract(Duration(seconds: actualDuration));

    // Play end sound — it's already pre-buffered so this is instant
    await _playEndSound();

    if (!mounted) return;
    
    // Check if user is logged in
    if (!_isLoggedIn) {
      // Show login prompt
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.saffron),
              SizedBox(width: 12),
              Expanded(child: Text('Login Required')),
            ],
          ),
          content: Text(
            'You meditated for ${_formatDuration(actualDuration)}.\n\n'
            'Login to save your meditation sessions and track your progress over time.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Login'),
            ),
          ],
        ),
      );
      
      if (shouldLogin == true && mounted) {
        context.push('/login');
      }
      
      // Reset timer
      setState(() {
        _seconds = 0;
        _startTime = null;
        _hasStarted = false;
      });
      return;
    }
    
    // Show confirmation dialog for logged-in users
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Meditation Session?'),
        content: Text(
          'You meditated for ${_formatDuration(actualDuration)}.\nWould you like to save this session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (shouldSave == true) {
      await _saveMeditationSession(startTime, endTime, actualDuration);
    }
    
    // Reset timer
    setState(() {
      _seconds = 0;
      _startTime = null;
      _hasStarted = false;
    });
  }

  Future<void> _saveMeditationSession(
    DateTime startTime,
    DateTime endTime,
    int durationSeconds,
  ) async {
    try {
      // Ask for journal entry
      String? journalEntry;
      if (mounted) {
        journalEntry = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final controller = TextEditingController();
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.edit_note, color: AppTheme.saffron),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Journal Your Experience')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How was your meditation? Share your thoughts, feelings, or insights.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'I felt peaceful and calm...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.saffron, width: 2),
                      ),
                    ),
                    autofocus: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, ''),
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, controller.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.saffron,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      }
      
      if (!mounted) return;
      
      final response = await _apiService.recordMeditationSession(
        startTime: startTime.toIso8601String(),
        endTime: endTime.toIso8601String(),
        durationSeconds: durationSeconds,
        notes: journalEntry?.isNotEmpty == true ? journalEntry : null,
      );
      
      if (response['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meditation session saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        final errorMsg = response['message'] ?? 'Failed to save session';
        debugPrint('❌ Meditation save failed: $errorMsg');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Exception saving meditation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save session: ${e.toString().length > 50 ? 'Network error' : e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _showDurationPicker() async {
    int selectedHours = _targetSeconds ~/ 3600;
    int selectedMinutes = (_targetSeconds % 3600) ~/ 60;
    
    // Ensure at least 1 minute is selected by default
    if (selectedHours == 0 && selectedMinutes == 0) {
      selectedMinutes = 5;
    }
    
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Set Meditation Duration'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick presets
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetChip('5 min', 0, 5, selectedHours, selectedMinutes, setDialogState, context),
                      _buildPresetChip('10 min', 0, 10, selectedHours, selectedMinutes, setDialogState, context),
                      _buildPresetChip('15 min', 0, 15, selectedHours, selectedMinutes, setDialogState, context),
                      _buildPresetChip('20 min', 0, 20, selectedHours, selectedMinutes, setDialogState, context),
                      _buildPresetChip('30 min', 0, 30, selectedHours, selectedMinutes, setDialogState, context),
                      _buildPresetChip('45 min', 0, 45, selectedHours, selectedMinutes, setDialogState, context),
                      _buildPresetChip('1 hour', 1, 0, selectedHours, selectedMinutes, setDialogState, context),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('custom_duration'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Custom time picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hours
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_drop_up),
                            onPressed: () {
                              setDialogState(() {
                                selectedHours = (selectedHours + 1) % 24;
                              });
                            },
                          ),
                          Container(
                            width: 60,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.saffron.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.saffron.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              selectedHours.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.saffron,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_drop_down),
                            onPressed: () {
                              setDialogState(() {
                                selectedHours = selectedHours > 0 ? selectedHours - 1 : 23;
                              });
                            },
                          ),
                          const Text('Hours', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(width: 16),
                      const Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      // Minutes
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_drop_up),
                            onPressed: () {
                              setDialogState(() {
                                selectedMinutes = (selectedMinutes + 1) % 60;
                              });
                            },
                          ),
                          Container(
                            width: 60,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.saffron.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.saffron.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              selectedMinutes.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.saffron,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_drop_down),
                            onPressed: () {
                              setDialogState(() {
                                selectedMinutes = selectedMinutes > 0 ? selectedMinutes - 1 : 59;
                              });
                            },
                          ),
                          const Text('Minutes', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedHours == 0 && selectedMinutes == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select at least 1 minute'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pop({
                      'hours': selectedHours,
                      'minutes': selectedMinutes,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.saffron,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Set'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _targetSeconds = (result['hours']! * 3600) + (result['minutes']! * 60);
      });
    }
  }

  Widget _buildPresetChip(String label, int hours, int minutes, int currentHours, int currentMinutes, StateSetter setDialogState, BuildContext dialogContext) {
    final isSelected = currentHours == hours && currentMinutes == minutes;
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected 
          ? AppTheme.saffron.withValues(alpha: 0.2)
          : Colors.grey.withValues(alpha: 0.1),
      side: BorderSide(
        color: isSelected 
            ? AppTheme.saffron 
            : Colors.grey.withValues(alpha: 0.3),
        width: isSelected ? 2 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.saffron : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onPressed: () {
        // Use dialogContext (not the page context) so only the dialog is popped
        Navigator.of(dialogContext).pop({'hours': hours, 'minutes': minutes});
      },
    );
  }


  // ── Preset session options shown on idle state ─────────────────────────
  static const _presets = [
    _PresetSession('Morning Meditation', '☀️', 15 * 60),
    _PresetSession('Evening Meditation', '🌙', 20 * 60),
    _PresetSession('Night Relaxation', '⭐', 10 * 60),
  ];

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.height < 700;
    // Show timer screen when a session is running or started
    final showTimer = _hasStarted || _isRunning || _seconds > 0;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Meditation',
          style: TextStyle(color: AppTheme.primary, fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded,
                  color: AppTheme.primary, size: 22),
              onPressed: () async {
                final wasRunning = _isRunning;
                if (_isRunning) _pauseTimer();
                await context.push('/meditation/history');
                if (wasRunning && mounted) _startTimer();
              },
            ),
        ],
      ),
      body: showTimer ? _buildTimerView(isSmall) : _buildHomeView(isSmall),
    );
  }

  // ── Home view: Guruji image + play/schedule/stop controls ──────────────────
  Widget _buildHomeView(bool isSmall) {
    return Column(
      children: [
        // ── Hero image ────────────────────────────────────────────────
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Breathing Guruji image
                AnimatedBuilder(
                  animation: _breathingAnimation,
                  builder: (_, __) => Transform.scale(
                    scale: _isRunning ? _breathingAnimation.value : 1.0,
                    child: Container(
                      width: isSmall ? 200 : 240,
                      height: isSmall ? 200 : 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.35), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.18),
                            blurRadius: 30, spreadRadius: 8),
                          BoxShadow(
                            color: AppTheme.gold.withValues(alpha: 0.12),
                            blurRadius: 50, spreadRadius: 12),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/Guruji_Meditation.PNG',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.tagBg,
                            child: const Icon(Icons.self_improvement,
                                size: 80, color: AppTheme.primary)),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Text(context.tr('daily_meditation_title'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(context.tr('daily_meditation_subtitle'),
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),

                const SizedBox(height: 20),

                // Timer display (shows 00:00 when idle)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.2)),
                    boxShadow: [AppTheme.softShadow],
                  ),
                  child: Text(
                    _formatDuration(_seconds),
                    style: const TextStyle(
                      fontSize: 52, fontWeight: FontWeight.w200,
                      color: AppTheme.textPrimary, letterSpacing: 4),
                  ),
                ),

                if (_targetSeconds > 0 && _seconds == 0) ...[
                  const SizedBox(height: 8),
                  Text('Duration: ${_formatDuration(_targetSeconds)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],

                if (!_isLoggedIn) ...[
                  const SizedBox(height: 12),
                  Text(context.tr('login_to_save_sessions'),
                      style: TextStyle(fontSize: 11, color: AppTheme.textHint,
                          fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ),

        // ── Controls bottom sheet ─────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, isSmall ? 24 : 32),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.textSecondary.withValues(alpha: 0.08),
                blurRadius: 20, offset: const Offset(0, -4))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Duration picker
              _buildRoundBtn(Icons.timer_outlined, _showDurationPicker,
                  bg: AppTheme.tagBg, iconColor: AppTheme.primary),
              const SizedBox(width: 20),
              // Main play button
              GestureDetector(
                onTap: _soundsLoading ? null : _startTimer,
                child: Container(
                  width: isSmall ? 70 : 80, height: isSmall ? 70 : 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.40),
                      blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: _soundsLoading
                      ? const Padding(padding: EdgeInsets.all(22),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Icon(Icons.play_arrow_rounded,
                          size: 44, color: Colors.white),
                ),
              ),
              const SizedBox(width: 20),
              // View history
              _buildRoundBtn(Icons.bar_chart_rounded,
                  () => context.push('/meditation/history'),
                  bg: AppTheme.tagBg, iconColor: AppTheme.primary),
            ],
          ),
        ),
      ],
    );
  }


  // ── Timer view: shown while session is active / paused ───────────────────
  Widget _buildTimerView(bool isSmall) {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Breathing Guruji image
              AnimatedBuilder(
                animation: _breathingAnimation,
                builder: (_, __) => Transform.scale(
                  scale: _isRunning ? _breathingAnimation.value : 1.0,
                  child: Container(
                    width: isSmall ? 180 : 220,
                    height: isSmall ? 180 : 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.20),
                          blurRadius: 30, spreadRadius: 8),
                        BoxShadow(
                          color: AppTheme.gold.withValues(alpha: 0.15),
                          blurRadius: 50, spreadRadius: 12),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/Guruji_Meditation.PNG',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.tagBg,
                          child: const Icon(Icons.self_improvement, size: 80, color: AppTheme.primary)),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Status text
              Text(
                _isRunning ? '🌸  Breathe in... Breathe out...' :
                    _hasStarted ? '⏸  Paused' : '✨  Ready',
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic, letterSpacing: 0.5),
              ),

              const SizedBox(height: 20),

              // Timer display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                  boxShadow: [AppTheme.softShadow],
                ),
                child: Text(
                  _formatDuration(_seconds),
                  style: const TextStyle(
                    fontSize: 56, fontWeight: FontWeight.w200,
                    color: AppTheme.textPrimary, letterSpacing: 4),
                ),
              ),

              const SizedBox(height: 12),

              if (_targetSeconds > 0)
                Text('Target: ${_formatDuration(_targetSeconds)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),

        // Controls
        Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, isSmall ? 24 : 32),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [BoxShadow(
              color: AppTheme.textSecondary.withValues(alpha: 0.08),
              blurRadius: 20, offset: const Offset(0, -4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isRunning && (_seconds > 0 || _targetSeconds > 0)) ...[
                _buildRoundBtn(Icons.refresh_rounded, _resetTimer,
                    bg: AppTheme.tagBg, iconColor: AppTheme.textSecondary),
                const SizedBox(width: 16),
              ],
              if (_isRunning) ...[
                _buildRoundBtn(Icons.stop_rounded, _stopTimer,
                    bg: Colors.red.shade50, iconColor: Colors.red.shade400),
                const SizedBox(width: 16),
              ],
              // Main play/pause
              GestureDetector(
                onTap: _soundsLoading && !_isRunning
                    ? null
                    : (_isRunning ? _pauseTimer : _startTimer),
                child: Container(
                  width: isSmall ? 70 : 80, height: isSmall ? 70 : 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: _soundsLoading && !_isRunning
                      ? const Padding(padding: EdgeInsets.all(22),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: isSmall ? 38 : 44, color: Colors.white),
                ),
              ),
              if (!_isRunning && _seconds == 0) ...[
                const SizedBox(width: 16),
                _buildRoundBtn(Icons.timer_outlined, _showDurationPicker,
                    bg: AppTheme.tagBg, iconColor: AppTheme.primary),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoundBtn(IconData icon, VoidCallback onTap,
      {required Color bg, required Color iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: bg,
          border: Border.all(color: AppTheme.softGray),
          boxShadow: [AppTheme.softShadow],
        ),
        child: Icon(icon, size: 24, color: iconColor),
      ),
    );
  }

  // Legacy helpers kept so _showDurationPicker / dialogs still compile ──────
  Widget _buildGlassButton({required IconData icon, required VoidCallback onPressed,
      required Color color, required Color iconColor, double size = 60}) =>
      _buildRoundBtn(icon, onPressed, bg: color, iconColor: iconColor);

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed,
      required Color color, required Color iconColor, double size = 60}) =>
      _buildRoundBtn(icon, onPressed, bg: color, iconColor: iconColor);

  Widget _buildInfoCard({required IconData icon, required String message,
      required Color color, bool isSmall = false}) =>
      const SizedBox.shrink();
}

// ── Preset session data ───────────────────────────────────────────────────────
class _PresetSession {
  final String label;
  final String emoji;
  final int durationSecs;
  const _PresetSession(this.label, this.emoji, this.durationSecs);
}
