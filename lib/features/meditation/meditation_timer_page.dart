import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
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

  // Preload states: 'idle' | 'loading' | 'ready' | 'error'
  String _startSoundState = 'idle';
  String _endSoundState = 'idle';

  bool get _soundsLoading => false; // Assets are always available instantly

  // Animation
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // Load bundled asset audio files — instant, no network needed.
    _loadSoundsFromAssets();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable();
    _breathingController.dispose();
    _startPlayer.dispose();
    _endPlayer.dispose();
    super.dispose();
  }

  /// Load bundled asset audio files directly — no network, no disk cache.
  /// Called once in initState so both players are buffered before the user
  /// ever taps Play.
  Future<void> _loadSoundsFromAssets() async {
    try {
      await Future.wait([
        _startPlayer.setAsset('assets/audio/Meditation_start.mp3').then((_) {
          _startSoundState = 'ready';
          debugPrint('✅ Start sound loaded from assets');
        }),
        _endPlayer.setAsset('assets/audio/Meditation_end.mp3').then((_) {
          _endSoundState = 'ready';
          debugPrint('✅ End sound loaded from assets');
        }),
      ]);
    } catch (e) {
      debugPrint('❌ Failed to load meditation sounds from assets: $e');
      _startSoundState = 'error';
      _endSoundState = 'error';
    }
  }

  /// Play the start sound then begin the timer tick.
  void _playStartSoundAndBeginTimer() {
    // Start the timer immediately — fire-and-forget the sound.
    _beginTimerTick();

    if (_startSoundState != 'ready') {
      debugPrint('⚠️ Start sound not ready (state: $_startSoundState), skipping audio');
      return;
    }
    // Fire and forget — no await so the timer is never delayed by audio.
    _startPlayer.seek(Duration.zero).then((_) => _startPlayer.play()).catchError((e) {
      debugPrint('⚠️ Start sound play error: $e');
    });
    debugPrint('✅ Start sound triggered');
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

    // Stop end sound if it's still playing from a previous session
    if (_endPlayer.playing) {
      await _endPlayer.stop();
      await _endPlayer.setAsset('assets/audio/Meditation_end.mp3'); // re-buffer for next use
      _endSoundState = 'ready';
    }

    setState(() {
      _isRunning = true;
      _startTime = _startTime ?? DateTime.now();
      if (_targetSeconds > 0 && _seconds == 0) {
        _seconds = _targetSeconds;
      }
    });

    // Pause the global bhajan player in the background — don't block the timer.
    final globalPlayer = EnhancedAudioPlayerService();
    if (globalPlayer.isPlaying) {
      globalPlayer.pause().catchError((e) => debugPrint('⚠️ Could not pause global player: $e'));
      debugPrint('⏸️ Pausing global audio player for meditation');
    }

    if (!_hasStarted) {
      _hasStarted = true;
      WakelockPlus.enable();
      _playStartSoundAndBeginTimer(); // sync — timer starts immediately
    } else {
      // Resume after pause — don't replay start sound
      WakelockPlus.enable();
      _beginTimerTick();
    }
  }

  void _pauseTimer() {
    if (!_isRunning) return;

    _timer?.cancel();
    WakelockPlus.disable();
    if (mounted) setState(() => _isRunning = false);

    // Pause the start-sound if it's still playing
    if (_startPlayer.playing) _startPlayer.pause();
  }

  Future<void> _completeTimer() async {
    _timer?.cancel();
    WakelockPlus.disable();
    if (_startPlayer.playing) _startPlayer.pause();
    if (mounted) setState(() => _isRunning = false);

    final endTime = DateTime.now();
    final actualDuration = _targetSeconds > 0 ? _targetSeconds : _seconds;
    final startTime =
        _startTime ?? endTime.subtract(Duration(seconds: actualDuration));

    // Play end sound
    await _playEndSound();

    if (!mounted) return;

    // Same save flow as _stopTimer
    await _handleSessionEnd(startTime, endTime, actualDuration, completed: true);
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
    WakelockPlus.disable();
    if (_startPlayer.playing) _startPlayer.pause();
    if (mounted) setState(() => _isRunning = false);

    final endTime = DateTime.now();
    final actualDuration =
        _targetSeconds > 0 ? (_targetSeconds - _seconds) : _seconds;
    final startTime =
        _startTime ?? endTime.subtract(Duration(seconds: actualDuration));

    // Play end sound
    await _playEndSound();

    if (!mounted) return;

    await _handleSessionEnd(startTime, endTime, actualDuration, completed: false);
  }

  /// Shared post-session flow: ask to save (logged-in) or prompt login (guest).
  /// [completed] = true when the timer ran to zero; false when stopped early.
  Future<void> _handleSessionEnd(
    DateTime startTime,
    DateTime endTime,
    int actualDuration, {
    required bool completed,
  }) async {
    if (!mounted) return;

    final title = completed ? 'Meditation Complete! 🎉' : 'End Meditation?';
    final durationText = _formatDuration(actualDuration);

    if (_isLoggedIn) {
      // Ask to save
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(completed ? Icons.check_circle : Icons.stop_circle,
                  color: completed ? Colors.green : AppTheme.saffron),
              const SizedBox(width: 12),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(
            'You meditated for $durationText.\nWould you like to save this session?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.saffron,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (shouldSave == true && mounted) {
        await _saveMeditationSession(startTime, endTime, actualDuration);
      }
    } else {
      // Guest — prompt login
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(completed ? Icons.check_circle : Icons.info_outline,
                  color: completed ? Colors.green : AppTheme.saffron),
              const SizedBox(width: 12),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(
            'You meditated for $durationText.\n\n'
            'Login to save your sessions and track your progress.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.saffron,
                foregroundColor: Colors.white,
              ),
              child: const Text('Login'),
            ),
          ],
        ),
      );

      if (shouldLogin == true && mounted) {
        context.push('/login');
      }
    }

    // Reset for next session
    if (mounted) {
      // Stop end sound in case it's still playing
      _endPlayer.stop().catchError((_) {});
      setState(() {
        _seconds = 0;
        _targetSeconds = 0;
        _startTime = null;
        _hasStarted = false;
      });
    }
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
    // Show timer screen when a session is running, started, or a duration is set
    final showTimer = _hasStarted || _isRunning || _seconds > 0 || _targetSeconds > 0;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: null,
      ),
      extendBodyBehindAppBar: true,
      body: showTimer ? _buildTimerView(isSmall) : _buildHomeView(isSmall),
    );
  }

  // ── Home view — full-screen bg, light footer with timer + icons ─────────────
  Widget _buildHomeView(bool isSmall) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen background image
        Image.asset(
          'assets/images/Guruji_Meditation.PNG',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),

        // Footer pinned to bottom
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: _buildFooterPanel(isSmall, isTimerView: false),
        ),
      ],
    );
  }

  // ── Timer view — same bg, footer shows active controls ───────────────────
  Widget _buildTimerView(bool isSmall) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-page background
        AnimatedBuilder(
          animation: _breathingAnimation,
          builder: (_, __) => Image.asset(
            'assets/images/Guruji_Meditation.PNG',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            opacity: AlwaysStoppedAnimation(
              _isRunning ? (0.85 + _breathingAnimation.value * 0.15) : 1.0,
            ),
          ),
        ),

        // Timer + footer pinned to bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Timer display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isRunning || _seconds > 0
                          ? _formatDuration(_seconds)
                          : _targetSeconds > 0
                              ? _formatDuration(_targetSeconds)
                              : _formatDuration(0),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmall ? 52 : 64,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 4,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 12),
                        ],
                      ),
                    ),

                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Footer — buttons
              _buildFooterPanel(isSmall, isTimerView: true),
            ],
          ),
        ),
      ],
    );
  }

  /// Shared footer panel — timer on top, icons row at bottom, light transparent bg
  Widget _buildFooterPanel(bool isSmall, {required bool isTimerView}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.50), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, isSmall ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(height: 8),

              // ── Icon buttons row — light pill background ──────────────
              Builder(builder: (context) {
                final screenW = MediaQuery.of(context).size.width;
                // Icons sized as % of screen width — always fits, never overflows
                final large = screenW * 0.22; // ~80px on 360px screen
                final small = screenW * 0.16; // ~58px on 360px screen

                final iconRow = isTimerView
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isRunning || _seconds > 0 || _targetSeconds > 0) ...[
                            _buildImgBtn('assets/images/icons/stop-icon.png',
                                _isRunning ? _stopTimer : _resetTimer, size: small),
                            SizedBox(width: screenW * 0.04),
                          ],
                          _buildImgBtn(
                            _isRunning
                                ? 'assets/images/icons/pause-icon.png'
                                : 'assets/images/icons/play-icon.png',
                            _soundsLoading && !_isRunning
                                ? () {}
                                : (_isRunning ? _pauseTimer : _startTimer),
                            size: large,
                          ),
                          if (!_isRunning && _seconds == 0) ...[
                            SizedBox(width: screenW * 0.04),
                            _buildImgBtn('assets/images/icons/timer-icon.png',
                                _showDurationPicker, size: small),
                          ],
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildImgBtn('assets/images/icons/timer-icon.png',
                              _showDurationPicker, size: small),
                          SizedBox(width: screenW * 0.06),
                          _buildImgBtn('assets/images/icons/play-icon.png',
                              _soundsLoading ? () {} : _startTimer, size: large),
                          SizedBox(width: screenW * 0.06),
                          _buildImgBtn('assets/images/icons/stats-icon.png',
                              () => context.push('/meditation/history'), size: small),
                        ],
                      );

                return Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenW * 0.06, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.70),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.60), width: 1),
                  ),
                  child: iconRow,
                );
              }),

              if (_soundsLoading) ...[
                const SizedBox(height: 8),
                const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Bare image button — no background circle, just the icon.
  Widget _buildImgBtn(String iconPath, VoidCallback onTap, {double size = 80.0}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Image.asset(
        iconPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
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
class _PresetSession {
  final String label;
  final String emoji;
  final int durationSecs;
  const _PresetSession(this.label, this.emoji, this.durationSecs);
}
