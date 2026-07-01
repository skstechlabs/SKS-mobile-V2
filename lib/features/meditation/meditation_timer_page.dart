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
                    'Custom Duration',
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth  = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    // ── Spiritual colour palette ──────────────────────────────────────────
    const deepPurple    = Color(0xFF1A0533); // very dark violet — night sky
    const midPurple     = Color(0xFF2D0B55); // deep cosmic purple
    const saffronGlow   = Color(0xFFFF7B00); // warm saffron
    const goldGlow      = Color(0xFFFFD700); // sacred gold
    const petalPink     = Color(0xFFFF9E7A); // lotus petal
    const divineWhite   = Color(0xFFFFF8F0); // warm white
    const calmTeal      = Color(0xFF00BCD4); // peaceful teal accent

    return Scaffold(
      backgroundColor: deepPurple,
      body: Stack(
        fit: StackFit.expand,
        children: [

          // ── 1. Deep cosmic background gradient ──────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0D001A), // near-black violet top
                  Color(0xFF1A0533), // deep cosmic purple
                  Color(0xFF2D0B55), // mid purple
                  Color(0xFF1A0533),
                  Color(0xFF0D001A), // dark bottom
                ],
                stops: [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
          ),

          // ── 2. Radial glow from center (the divine light source) ─────────
          Center(
            child: AnimatedBuilder(
              animation: _breathingAnimation,
              builder: (_, __) => Container(
                width: screenWidth * 1.2,
                height: screenWidth * 1.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      saffronGlow.withValues(alpha: 0.18 * _breathingAnimation.value),
                      goldGlow.withValues(alpha: 0.10 * _breathingAnimation.value),
                      midPurple.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ── 3. Faint star particles (static dots simulated with Container) ─
          ..._buildStarField(screenWidth, screenHeight),

          // ── 4. Main scrollable content ───────────────────────────────────
          SafeArea(
            child: Column(
              children: [

                // ── Top bar ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: divineWhite),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      // Title
                      Text(
                        'Meditation',
                        style: TextStyle(
                          color: divineWhite.withValues(alpha: 0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 3,
                        ),
                      ),
                      // History
                      if (_isLoggedIn)
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.history, color: goldGlow.withValues(alpha: 0.9)),
                            onPressed: () async {
                              final wasRunning = _isRunning;
                              if (_isRunning) _pauseTimer();
                              await context.push('/meditation/history');
                              if (wasRunning && mounted) _startTimer();
                            },
                            tooltip: 'View History',
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),

                // ── Main body ───────────────────────────────────────────────
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final imageSize = isSmallScreen
                          ? 220.0
                          : (constraints.maxHeight * 0.42).clamp(220.0, 300.0);

                      return SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          height: constraints.maxHeight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [

                              // ── Sacred title text ────────────────────────
                              Text(
                                '✦  ॐ  श्री गुरुवे नमः  ✦',
                                style: TextStyle(
                                  color: goldGlow.withValues(alpha: 0.75),
                                  fontSize: isSmallScreen ? 12 : 14,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 2.5,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              SizedBox(height: isSmallScreen ? 16 : 24),

                              // ── Guruji image with aura rings ─────────────
                              _buildGurujiAura(imageSize, saffronGlow, goldGlow, petalPink, calmTeal),

                              SizedBox(height: isSmallScreen ? 20 : 28),

                              // ── Status label ─────────────────────────────
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 600),
                                child: Text(
                                  _isRunning
                                      ? '🌸  Breathe in... Breathe out...'
                                      : _hasStarted
                                          ? '⏸  Paused — tap to resume'
                                          : '✨  Begin your journey within',
                                  key: ValueKey(_isRunning ? 'running' : _hasStarted ? 'paused' : 'idle'),
                                  style: TextStyle(
                                    color: divineWhite.withValues(alpha: 0.70),
                                    fontSize: isSmallScreen ? 13 : 15,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.2,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              SizedBox(height: isSmallScreen ? 14 : 20),

                              // ── Timer display ─────────────────────────────
                              _buildTimerDisplay(isSmallScreen, saffronGlow, goldGlow, divineWhite),

                              SizedBox(height: isSmallScreen ? 10 : 16),

                              // ── Duration chip ─────────────────────────────
                              if (_targetSeconds > 0 && !_isRunning && _seconds == 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: goldGlow.withValues(alpha: 0.35)),
                                    color: goldGlow.withValues(alpha: 0.08),
                                  ),
                                  child: Text(
                                    'Duration: ${_formatDuration(_targetSeconds)}',
                                    style: TextStyle(
                                      color: goldGlow.withValues(alpha: 0.85),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Bottom control panel ─────────────────────────────────────
                _buildControlPanel(isSmallScreen, saffronGlow, goldGlow, divineWhite),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Decorative static star field — 12 small white dots scattered around
  List<Widget> _buildStarField(double w, double h) {
    final positions = [
      [0.08, 0.12], [0.88, 0.08], [0.15, 0.45], [0.82, 0.38],
      [0.05, 0.72], [0.93, 0.65], [0.25, 0.85], [0.70, 0.90],
      [0.45, 0.07], [0.60, 0.15], [0.35, 0.55], [0.75, 0.50],
    ];
    return positions.map((p) {
      final opacity = (p[0] + p[1]) % 0.6 + 0.2;
      return Positioned(
        left: p[0] * w,
        top: p[1] * h,
        child: AnimatedBuilder(
          animation: _breathingAnimation,
          builder: (_, __) => Opacity(
            opacity: (opacity * _breathingAnimation.value).clamp(0.1, 0.7),
            child: Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFD700),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  /// The Guruji image surrounded by multi-layer glowing aura rings
  Widget _buildGurujiAura(
    double size,
    Color saffron,
    Color gold,
    Color petal,
    Color teal,
  ) {
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (_, __) {
        final pulse = _isRunning ? _breathingAnimation.value : 1.0;
        final softPulse = _isRunning
            ? 0.85 + (_breathingAnimation.value - 0.8) * 0.75
            : 1.0;

        return SizedBox(
          width: size + 80,
          height: size + 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outermost ring — very faint teal/gold
              Opacity(
                opacity: 0.12 * pulse,
                child: Container(
                  width: size + 72,
                  height: size + 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.transparent,
                        teal.withValues(alpha: 0.0),
                        gold.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.75, 0.88, 1.0],
                    ),
                    border: Border.all(
                      color: teal.withValues(alpha: 0.20 * pulse),
                      width: 1,
                    ),
                  ),
                ),
              ),

              // Second ring — petal pink, dashed-look via opacity
              Opacity(
                opacity: 0.25 * softPulse,
                child: Container(
                  width: size + 48,
                  height: size + 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: petal.withValues(alpha: 0.55 * softPulse),
                      width: 1.5,
                    ),
                    gradient: RadialGradient(
                      colors: [
                        Colors.transparent,
                        petal.withValues(alpha: 0.08 * pulse),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.85, 1.0],
                    ),
                  ),
                ),
              ),

              // Third ring — saffron glow
              Container(
                width: size + 28,
                height: size + 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: saffron.withValues(alpha: 0.45 * softPulse),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: saffron.withValues(alpha: 0.30 * pulse),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: gold.withValues(alpha: 0.15 * pulse),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),

              // Immediate ring — bright gold
              Container(
                width: size + 8,
                height: size + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gold.withValues(alpha: 0.70 * pulse),
                      saffron.withValues(alpha: 0.50 * pulse),
                      gold.withValues(alpha: 0.70 * pulse),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withValues(alpha: 0.50 * pulse),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),

              // The image itself
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF3D1278).withValues(alpha: 0.3),
                      const Color(0xFF1A0533).withValues(alpha: 0.6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: saffron.withValues(alpha: 0.35 * pulse),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/Guruji_Meditation.PNG',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [saffron, gold.withValues(alpha: 0.7)],
                        ),
                      ),
                      child: Icon(
                        Icons.self_improvement,
                        size: size * 0.5,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              ),

              // Lotus petal shimmer overlay at bottom of image
              Positioned(
                bottom: 4,
                child: Container(
                  width: size * 0.9,
                  height: size * 0.25,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        saffron.withValues(alpha: 0.18 * pulse),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The glowing timer display
  Widget _buildTimerDisplay(
    bool isSmall,
    Color saffron,
    Color gold,
    Color white,
  ) {
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (_, __) {
        final glow = _isRunning ? _breathingAnimation.value : 1.0;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 32 : 44,
            vertical: isSmall ? 14 : 18,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: gold.withValues(alpha: 0.30 * glow),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: saffron.withValues(alpha: 0.20 * glow),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            _formatDuration(_seconds),
            style: TextStyle(
              fontSize: isSmall ? 48 : 60,
              fontWeight: FontWeight.w200,
              color: white,
              letterSpacing: 6,
              shadows: [
                Shadow(
                  color: gold.withValues(alpha: 0.70 * glow),
                  blurRadius: 16,
                ),
                Shadow(
                  color: saffron.withValues(alpha: 0.40 * glow),
                  blurRadius: 32,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bottom control panel on dark glass card
  Widget _buildControlPanel(
    bool isSmall,
    Color saffron,
    Color gold,
    Color white,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, isSmall ? 16 : 20, 24, isSmall ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 3,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Duration picker
              if (!_isRunning && _seconds == 0) ...[
                _buildGlassButton(
                  icon: Icons.timer_outlined,
                  onPressed: _showDurationPicker,
                  color: gold.withValues(alpha: 0.20),
                  iconColor: gold,
                  size: isSmall ? 52 : 60,
                ),
                SizedBox(width: isSmall ? 14 : 18),
              ],

              // Reset
              if (!_isRunning && (_seconds > 0 || _targetSeconds > 0)) ...[
                _buildGlassButton(
                  icon: Icons.refresh,
                  onPressed: _resetTimer,
                  color: Colors.white.withValues(alpha: 0.10),
                  iconColor: white.withValues(alpha: 0.60),
                  size: isSmall ? 52 : 60,
                ),
                SizedBox(width: isSmall ? 14 : 18),
              ],

              // Stop
              if (_isRunning) ...[
                _buildGlassButton(
                  icon: Icons.stop_rounded,
                  onPressed: _stopTimer,
                  color: Colors.red.withValues(alpha: 0.15),
                  iconColor: Colors.red.shade300,
                  size: isSmall ? 52 : 60,
                ),
                SizedBox(width: isSmall ? 14 : 18),
              ],

              // Play / Pause — the hero button
              AnimatedBuilder(
                animation: _breathingAnimation,
                builder: (_, __) {
                  final glow = _isRunning ? _breathingAnimation.value : 1.0;
                  return GestureDetector(
                    onTap: _soundsLoading && !_isRunning
                        ? null
                        : (_isRunning ? _pauseTimer : _startTimer),
                    child: Container(
                      width: isSmall ? 74 : 84,
                      height: isSmall ? 74 : 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            saffron,
                            gold.withValues(alpha: 0.85),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: saffron.withValues(alpha: 0.55 * glow),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: gold.withValues(alpha: 0.30 * glow),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: _soundsLoading && !_isRunning
                          ? const Padding(
                              padding: EdgeInsets.all(22),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Icon(
                              _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: isSmall ? 40 : 46,
                              color: Colors.white,
                            ),
                    ),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: isSmall ? 12 : 16),

          // Info note
          if (!_isLoggedIn && _seconds == 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 14, color: white.withValues(alpha: 0.40)),
                const SizedBox(width: 6),
                Text(
                  'Login to save your meditation sessions',
                  style: TextStyle(
                    color: white.withValues(alpha: 0.40),
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required Color iconColor,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: size * 0.45, color: iconColor),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required Color iconColor,
    double size = 60,
  }) => _buildGlassButton(
        icon: icon,
        onPressed: onPressed,
        color: color,
        iconColor: iconColor,
        size: size,
      );

  Widget _buildInfoCard({
    required IconData icon,
    required String message,
    required Color color,
    bool isSmall = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 10 : 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: isSmall ? 18 : 22),
          SizedBox(width: isSmall ? 8 : 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontSize: isSmall ? 11 : 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFF8E1), // Light saffron/cream
              const Color(0xFFFFECB3), // Warm golden
              const Color(0xFFFFF8E1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button and history
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: AppTheme.saffron),
                      onPressed: () => context.pop(),
                    ),
                    if (_isLoggedIn)
                      IconButton(
                        icon: Icon(Icons.history, color: AppTheme.saffron),
                        onPressed: () async {
                          // Pause timer and audio while viewing history
                          final wasRunning = _isRunning;
                          if (_isRunning) _pauseTimer();
                          await context.push('/meditation/history');
                          // Resume when user comes back (if it was running)
                          if (wasRunning && mounted) _startTimer();
                        },
                        tooltip: 'View History',
                      ),
                  ],
                ),
              ),
              
              // Main content - Flexible to fit available space
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableHeight = constraints.maxHeight;
                    final imageSize = isSmallScreen ? 200.0 : (availableHeight * 0.4).clamp(200.0, 280.0);
                    final timerFontSize = isSmallScreen ? 42.0 : 56.0;
                    
                    return Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: isSmallScreen ? 10 : 20),
                            
                            // Guruji Meditation Image in Circle
                            AnimatedBuilder(
                              animation: _breathingAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _isRunning ? _breathingAnimation.value : 1.0,
                                  child: Container(
                                    width: imageSize,
                                    height: imageSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0.0),
                                          AppTheme.saffron.withValues(alpha: 0.1),
                                          AppTheme.saffron.withValues(alpha: 0.3),
                                        ],
                                        stops: const [0.7, 0.9, 1.0],
                                      ),
                                      boxShadow: _isRunning ? [] : [
                                        BoxShadow(
                                          color: AppTheme.saffron.withValues(alpha: 0.4),
                                          blurRadius: 40,
                                          spreadRadius: 10,
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          blurRadius: 20,
                                          spreadRadius: -5,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/images/Guruji_Meditation.PNG',
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppTheme.saffron,
                                                    AppTheme.saffron.withValues(alpha: 0.7),
                                                  ],
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.self_improvement,
                                                size: imageSize * 0.4,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            SizedBox(height: isSmallScreen ? 20 : 30),
                            
                            // Timer Display
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 24 : 32,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.saffron.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Text(
                                _formatDuration(_seconds),
                                style: TextStyle(
                                  fontSize: timerFontSize,
                                  fontWeight: FontWeight.w300,
                                  color: AppTheme.saffron,
                                  letterSpacing: 4,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            
                            SizedBox(height: isSmallScreen ? 12 : 20),
                            
                            // Status text
                            Text(
                              _isRunning ? 'Meditating...' : 'Ready to begin',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 20,
                                color: AppTheme.saffron.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                              ),
                            ),
                            
                            if (_isRunning) ...[
                              SizedBox(height: isSmallScreen ? 6 : 12),
                              // Text(
                              //   'Breathe in... Breathe out...',
                              //   style: TextStyle(
                              //     fontSize: isSmallScreen ? 13 : 16,
                              //     color: AppTheme.textSecondary,
                              //     fontStyle: FontStyle.italic,
                              //   ),
                              // ),
                            ],
                            
                            // Duration info
                            if (_targetSeconds > 0 && !_isRunning && _seconds == 0) ...[
                              SizedBox(height: isSmallScreen ? 12 : 20),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 16 : 20,
                                  vertical: isSmallScreen ? 8 : 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.saffron.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.saffron.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  'Duration: ${_formatDuration(_targetSeconds)}',
                                  style: TextStyle(
                                    color: AppTheme.saffron,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                              ),
                            ],
                            
                            SizedBox(height: isSmallScreen ? 10 : 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Control buttons - Compact on small screens
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  isSmallScreen ? 12 : 16,
                  20,
                  isSmallScreen ? 16 : 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Duration picker button
                        if (!_isRunning && _seconds == 0) ...[
                          _buildControlButton(
                            icon: Icons.timer_outlined,
                            onPressed: _showDurationPicker,
                            color: AppTheme.saffron.withValues(alpha: 0.2),
                            iconColor: AppTheme.saffron,
                            size: isSmallScreen ? 50 : 60,
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                        ],
                        
                        // Reset button
                        if (!_isRunning && (_seconds > 0 || _targetSeconds > 0)) ...[
                          _buildControlButton(
                            icon: Icons.refresh,
                            onPressed: _resetTimer,
                            color: Colors.grey.shade200,
                            iconColor: Colors.grey.shade600,
                            size: isSmallScreen ? 50 : 60,
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                        ],
                        
                        // Stop button
                        if (_isRunning) ...[
                          _buildControlButton(
                            icon: Icons.stop,
                            onPressed: _stopTimer,
                            color: Colors.red.shade50,
                            iconColor: Colors.red,
                            size: isSmallScreen ? 50 : 60,
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                        ],
                        
                        // Start/Pause button (larger)
                        Container(
                          width: isSmallScreen ? 70 : 80,
                          height: isSmallScreen ? 70 : 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.saffron,
                                AppTheme.saffron.withValues(alpha: 0.8),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.saffron.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _soundsLoading && !_isRunning
                                  ? null // Disable while sounds are loading
                                  : (_isRunning ? _pauseTimer : _startTimer),
                              customBorder: const CircleBorder(),
                              child: _soundsLoading && !_isRunning
                                  ? const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Icon(
                                      _isRunning ? Icons.pause : Icons.play_arrow,
                                      size: isSmallScreen ? 38 : 44,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: isSmallScreen ? 10 : 16),
                    
                    // Info message - Compact on small screens
                    if (!_isLoggedIn && _seconds == 0)
                      _buildInfoCard(
                        icon: Icons.info_outline,
                        message: 'Login to save your meditation sessions',
                        color: Colors.blue,
                        isSmall: isSmallScreen,
                      )
                    // else
                    //   _buildInfoCard(
                    //     icon: Icons.lightbulb_outline,
                    //     message: 'Find a quiet space, sit comfortably, and focus on your breath',
                    //     color: AppTheme.saffron,
                    //     isSmall: isSmallScreen,
                    //   ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required Color iconColor,
    double size = 60,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(icon, size: size * 0.47, color: iconColor),
        ),
      ),
    );
  }
  
  Widget _buildInfoCard({
    required IconData icon,
    required String message,
    required Color color,
    bool isSmall = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 10 : 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: isSmall ? 18 : 22),
          SizedBox(width: isSmall ? 8 : 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontSize: isSmall ? 11 : 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
