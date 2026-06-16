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
import '../auth/auth_state.dart';

class MeditationTimerPage extends StatefulWidget {
  const MeditationTimerPage({Key? key}) : super(key: key);

  @override
  State<MeditationTimerPage> createState() => _MeditationTimerPageState();
}

class _MeditationTimerPageState extends State<MeditationTimerPage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Timer state
  Timer? _timer;
  int _seconds = 0;
  int _targetSeconds = 0; // 0 means no target (free meditation)
  bool _isRunning = false;
  bool _hasStarted = false; // Track if meditation has started (to prevent start sound on resume)
  DateTime? _startTime;
  
  // Auth state — uses cached AuthState, works offline
  bool get _isLoggedIn => AuthState().isAuthenticated;
  
  // CDN Configuration
  static const String _cdnBaseUrl = 'https://pub-feda269d36484d78b7cfc71353b6d67c.r2.dev';
  static const String _audioBasePath = 'audio/meditation';
  
  // Cached audio file paths
  String? _cachedStartSoundPath;
  String? _cachedEndSoundPath;
  bool _soundsReady = false; // Flag to track if sounds are downloaded and ready
  
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
    
    // Download and cache meditation sounds on init
    _downloadAndCacheSounds();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Download meditation sounds from API based on user's language
  Future<void> _downloadAndCacheSounds() async {
    try {
      // Get current language from LocalizationService
      final currentLocale = LocalizationService().currentLocale;
      final languageCode = currentLocale.languageCode;
      
      // Map language code to database language name
      final languageMap = {
        'en': 'english',
        'hi': 'hindi',
        'te': 'telugu',
        'kn': 'kannada',
      };
      
      final dbLanguage = languageMap[languageCode] ?? 'english';
      
      debugPrint('Fetching meditation sounds for language: $dbLanguage (code: $languageCode)');
      
      // Fetch meditation sounds from API
      final response = await _apiService.get(
        '/api/audios',
        queryParameters: {
          'category': 'meditation_sound',
          'language': dbLanguage,
        },
      );
      
      if (response['success'] == true && response['audios'] != null) {
        final audios = response['audios'] as List;
        
        // Find start and end sounds
        final startSound = audios.firstWhere(
          (audio) => audio['title']?.toString().contains('Start') ?? false,
          orElse: () => null,
        );
        
        final endSound = audios.firstWhere(
          (audio) => audio['title']?.toString().contains('End') ?? false,
          orElse: () => null,
        );
        
        // Download and cache start sound
        if (startSound != null && startSound['audio_url'] != null) {
          _cachedStartSoundPath = await _downloadAndCacheAudioFromUrl(
            startSound['audio_url'],
            'meditation_start_$dbLanguage.mp3',
          );
          debugPrint('✅ Start sound cached: $_cachedStartSoundPath');
        }
        
        // Download and cache end sound
        if (endSound != null && endSound['audio_url'] != null) {
          _cachedEndSoundPath = await _downloadAndCacheAudioFromUrl(
            endSound['audio_url'],
            'meditation_end_$dbLanguage.mp3',
          );
          debugPrint('✅ End sound cached: $_cachedEndSoundPath');
        }
        
        if (_cachedStartSoundPath != null && _cachedEndSoundPath != null) {
          setState(() {
            _soundsReady = true;
          });
          debugPrint('✅ All meditation sounds cached successfully and ready to play');
        } else {
          debugPrint('⚠️ Some meditation sounds could not be cached');
        }
      } else {
        debugPrint('⚠️ No meditation sounds found in API response');
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ Error fetching meditation sounds: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Download and cache audio file from URL
  Future<String?> _downloadAndCacheAudioFromUrl(String audioUrl, String filename) async {
    try {
      // Get cache directory
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/meditation_sounds');
      
      // Create cache directory if it doesn't exist
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      // Check if file already exists in cache
      final cachedFile = File('${cacheDir.path}/$filename');
      if (await cachedFile.exists()) {
        debugPrint('✅ Using cached file: ${cachedFile.path}');
        return cachedFile.path;
      }
      
      // Download from URL
      debugPrint('Downloading meditation sound from: $audioUrl');
      
      final response = await http.get(Uri.parse(audioUrl));
      
      if (response.statusCode == 200) {
        // Save to cache
        await cachedFile.writeAsBytes(response.bodyBytes);
        debugPrint('✅ Downloaded and cached: ${cachedFile.path} (${response.bodyBytes.length} bytes)');
        return cachedFile.path;
      } else {
        debugPrint('❌ Download failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error downloading audio from URL: $e');
      return null;
    }
  }

  Future<void> _playStartSound() async {
    try {
      debugPrint('Attempting to play meditation start sound... (soundsReady: $_soundsReady)');
      
      // Check if sounds are ready
      if (!_soundsReady) {
        debugPrint('⚠️ Start sound not ready yet - still downloading');
        return;
      }
      
      // Use cached file
      if (_cachedStartSoundPath != null && await File(_cachedStartSoundPath!).exists()) {
        debugPrint('Playing cached start sound: $_cachedStartSoundPath');
        await _audioPlayer.setFilePath(_cachedStartSoundPath!);
        
        // Set volume and play
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play();
        
        debugPrint('✅ Start sound playing');
      } else {
        debugPrint('⚠️ Start sound file not found - please check internet connection');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error playing start sound: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _playEndSound() async {
    try {
      debugPrint('Attempting to play meditation end sound... (soundsReady: $_soundsReady)');
      
      // Check if sounds are ready
      if (!_soundsReady) {
        debugPrint('⚠️ End sound not ready yet - still downloading');
        return;
      }
      
      // Use cached file
      if (_cachedEndSoundPath != null && await File(_cachedEndSoundPath!).exists()) {
        debugPrint('Playing cached end sound: $_cachedEndSoundPath');
        await _audioPlayer.setFilePath(_cachedEndSoundPath!);
        
        // Set volume and play
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play();
        
        // Wait for completion
        await _audioPlayer.playerStateStream.firstWhere(
          (state) => state.processingState == ProcessingState.completed,
        );
        
        debugPrint('✅ End sound completed');
      } else {
        debugPrint('⚠️ End sound file not found - please check internet connection');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error playing end sound: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _startTimer() async {
    if (_isRunning) return;
    
    // Check if sounds are ready before starting
    if (!_soundsReady && !_hasStarted) {
      // Show warning that sounds are still downloading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meditation sounds are still loading. Starting timer anyway...'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
    
    setState(() {
      _isRunning = true;
      _startTime = _startTime ?? DateTime.now();
      if (_targetSeconds > 0 && _seconds == 0) {
        _seconds = _targetSeconds;
      }
    });
    
    // Play start sound only on very first start.
    // Do NOT play again on resume — the audio player may still be active.
    if (!_hasStarted) {
      _hasStarted = true;
      _playStartSound(); // Fire and forget
    } else {
      // Resume: only play if the player is paused (not already playing)
      if (!_audioPlayer.playing &&
          _audioPlayer.processingState != ProcessingState.idle &&
          _audioPlayer.processingState != ProcessingState.completed) {
        _audioPlayer.play();
      }
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  void _pauseTimer() {
    if (!_isRunning) return;
    
    setState(() {
      _isRunning = false;
    });
    
    _timer?.cancel();
    
    // Pause the audio if it's playing
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    }
  }

  Future<void> _completeTimer() async {
    _timer?.cancel();
    
    setState(() {
      _isRunning = false;
    });
    
    final endTime = DateTime.now();
    final actualDuration = _targetSeconds > 0 ? _targetSeconds : _seconds;
    final startTime = _startTime ?? endTime.subtract(Duration(seconds: actualDuration));
    
    // Play end sound and wait for it to complete
    await _playEndSound();
    
    // Now show the dialog after sound completes
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
    
    // Stop timer immediately
    _timer?.cancel();
    
    setState(() {
      _isRunning = false;
    });
    
    final endTime = DateTime.now();
    final actualDuration = _targetSeconds > 0 ? (_targetSeconds - _seconds) : _seconds;
    final startTime = _startTime ?? endTime.subtract(Duration(seconds: actualDuration));
    
    // Play end sound and wait for it to complete
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to save session'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session saved locally. Will sync when online.'),
            backgroundColor: Colors.blue,
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
    final isSmallScreen = screenHeight < 700;
    
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
                              onTap: _isRunning ? _pauseTimer : _startTimer,
                              customBorder: const CircleBorder(),
                              child: Icon(
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
