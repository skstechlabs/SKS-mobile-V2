import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/localization_service.dart';
import 'widgets/cloudflare_video_player.dart';
import 'widgets/hls_video_player.dart';
import 'widgets/secure_screen_wrapper.dart';

class DayVideoScreen extends StatefulWidget {
  final int dayId;
  final String dayTitle;
  final int dayNumber;

  const DayVideoScreen({
    super.key,
    required this.dayId,
    required this.dayTitle,
    required this.dayNumber,
  });

  @override
  State<DayVideoScreen> createState() => _DayVideoScreenState();
}

class _DayVideoScreenState extends State<DayVideoScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final String _sessionId = const Uuid().v4();
  
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _videoConfig;
  Timer? _trackingTimer;
  Timer? _screenRecordingTimer;
  int _lastTrackedPosition = 0;
  bool _hasStarted = false;
  bool _isCompleted = false;
  bool _isScreenRecording = false;
  
  // CRITICAL: Cache the video player widget to prevent rebuilds during rotation
  Widget? _cachedVideoPlayer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Note: do NOT call _enableSecureMode here — it sets immersiveSticky which
    // conflicts with the video player's fullscreen toggle.
    _loadVideoConfig();
    _startScreenRecordingDetection();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Pause video when app goes to background (prevents screen recording)
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      debugPrint('⚠️ App went to background - potential screen recording attempt');
      _logSecurityEvent('app_backgrounded');
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('✅ App resumed');
      _checkScreenRecordingStatus();
    }
  }

  void _startScreenRecordingDetection() {
    // Check for screen recording every 2 seconds
    _screenRecordingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _checkScreenRecordingStatus();
    });
  }

  Future<void> _checkScreenRecordingStatus() async {
    // Note: Flutter doesn't have direct API to detect screen recording
    // This is a placeholder for platform-specific implementation
    // You would need to use platform channels to implement this
    
    // For now, we log suspicious activity patterns
    if (_isScreenRecording) {
      _logSecurityEvent('screen_recording_detected');
      _showSecurityWarning();
    }
  }

  Future<void> _logSecurityEvent(String eventType) async {
    try {
      await _apiService.post(
        '/api/classes/days/${widget.dayId}/security-event',
        {
          'eventType': eventType,
          'sessionId': _sessionId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error logging security event: $e');
    }
  }

  void _showSecurityWarning() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.security, color: Colors.red, size: 32),
            const SizedBox(width: 12),
            Text(context.tr('security_warning')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('screen_recording_detected'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('recording_prohibited_message'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(context.tr('immediate_account_suspension'), style: const TextStyle(fontSize: 14)),
            Text(context.tr('legal_action_copyright'), style: const TextStyle(fontSize: 14)),
            Text(context.tr('loss_of_access_courses'), style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Text(
              context.tr('incident_logged'),
              style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Exit video screen
            },
            child: Text(context.tr('i_understand')),
          ),
        ],
      ),
    );
  }

  Future<void> _loadVideoConfig() async {
    try {
      debugPrint('🎥 Loading video config for day ${widget.dayId}');
      
      // Get user's current language preference
      final currentLanguage = LocalizationService().currentLocale.languageCode;
      debugPrint('🌐 Using language: $currentLanguage');
      
      final response = await _apiService.get(
        '/api/classes-v2/days/${widget.dayId}/video-config',
        queryParameters: {'language': currentLanguage},
      );

      debugPrint('📦 Video config response: $response');

      if (response['success'] == true) {
        final videoConfig = response['videoConfig'];
        
        // Detect streaming type
        final streamingType = videoConfig['streamingType'] ?? 'cloudflare';
        
        // Validate required fields based on streaming type
        if (streamingType == 'hls') {
          if (videoConfig == null || videoConfig['hlsUrl'] == null) {
            setState(() {
              _error = 'HLS video configuration is incomplete';
              _isLoading = false;
            });
            return;
          }
        } else {
          // Cloudflare Stream validation
          if (videoConfig == null || 
              videoConfig['cloudflareVideoId'] == null || 
              videoConfig['cloudflareAccountId'] == null) {
            setState(() {
              _error = 'Video configuration is incomplete';
              _isLoading = false;
            });
            return;
          }
        }
        
        setState(() {
          _videoConfig = videoConfig;
          _isLoading = false;
        });
        debugPrint('✅ Video config loaded successfully (Type: $streamingType, Language: ${videoConfig['language']})');
      } else {
        final errorMsg = response['message'] ?? 'Failed to load video';
        debugPrint('❌ Failed to load video: $errorMsg');
        setState(() {
          _error = errorMsg;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading video: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _error = 'Error loading video. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _markDayAsStarted() async {
    if (_hasStarted) return;
    
    try {
      await _apiService.post(
        '/api/classes/days/${widget.dayId}/start',
        {},
      );
      setState(() => _hasStarted = true);
    } catch (e) {
      debugPrint('Error marking day as started: $e');
    }
  }

  Future<void> _trackProgress(int positionSeconds, int durationSeconds, String eventType) async {
    // Don't track if already completed
    if (_isCompleted && eventType != 'complete' && !eventType.startsWith('milestone_')) {
      debugPrint('⏭️ Skipping tracking - already completed');
      return;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // OPTIMIZED MILESTONE-BASED TRACKING
    // ═══════════════════════════════════════════════════════════════
    // Only make backend calls at critical milestones:
    // - 25% completion
    // - 50% completion  
    // - 75% completion
    // - 90%+ completion (considered complete)
    // - Manual start/complete events
    //
    // This reduces from 1 call every 30s to only 4-5 calls total!
    // ═══════════════════════════════════════════════════════════════
    
    final isMilestone = eventType.startsWith('milestone_');
    final isStartOrComplete = eventType == 'start' || eventType == 'complete';
    
    // Only make backend calls for milestones or start/complete events
    if (!isMilestone && !isStartOrComplete) {
      debugPrint('⏭️ Skipping non-milestone tracking: $eventType at ${positionSeconds}s');
      return;
    }

    try {
      debugPrint('📡 Tracking MILESTONE: $eventType at ${positionSeconds}s / ${durationSeconds}s (${(positionSeconds / durationSeconds * 100).toStringAsFixed(1)}%)');
      
      final response = await _apiService.post(
        '/api/classes/days/${widget.dayId}/track',
        {
          'eventType': eventType,
          'positionSeconds': positionSeconds,
          'durationSeconds': durationSeconds,
          'sessionId': _sessionId,
          'deviceInfo': {
            'platform': Theme.of(context).platform.toString(),
            'userAgent': 'Flutter Mobile App',
          },
        },
      );

      if (response['success'] == true) {
        // Log milestones reached
        final milestonesReached = response['milestonesReached'] as List?;
        if (milestonesReached != null && milestonesReached.isNotEmpty) {
          debugPrint('🎯 Backend confirmed milestones: ${milestonesReached.join('%, ')}%');
          
          // Show toast for 50% milestone
          if (mounted && milestonesReached.contains(50)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text('${context.tr('halfway_there')}! 50% ${context.tr('completed')}'),
                  ],
                ),
                backgroundColor: AppTheme.gold,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
        
        // Check for day completion
        if (response['dayCompleted'] == true && !_isCompleted) {
          setState(() => _isCompleted = true);
          
          final classCompleted = response['classCompleted'] ?? false;
          final completedAt = response['completedAt'] as String?;
          final nextDayInfo = response['nextDay'] as Map<String, dynamic>?;
          final nextLevelInfo = response['nextLevel'] as Map<String, dynamic>?;
          final levelInfo = response['levelInfo'] as Map<String, dynamic>?;
          
          debugPrint('🎉 Day completed! Class completed: $classCompleted');
          
          // Show toast notification
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        classCompleted 
                          ? '${context.tr('congratulations')}! ${context.tr('class_completed')}'
                          : '${context.tr('congratulations')}! ${context.tr('day_completed')}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.saffron,
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Wait a moment before showing dialog so toast is visible
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _showCompletionDialog(
                  classCompleted: classCompleted,
                  completedAt: completedAt,
                  nextDayInfo: nextDayInfo,
                  nextLevelInfo: nextLevelInfo,
                  levelInfo: levelInfo,
                );
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error tracking progress: $e');
      
      // Show error toast only for important events
      if (mounted && (isStartOrComplete || eventType.contains('milestone'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('error')}: ${context.tr('failed_to_save_progress')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showCompletionDialog({
    required bool classCompleted,
    String? completedAt,
    Map<String, dynamic>? nextDayInfo,
    Map<String, dynamic>? nextLevelInfo,
    Map<String, dynamic>? levelInfo,
  }) {
    // Parse completion time
    DateTime? completionTime;
    if (completedAt != null) {
      try {
        completionTime = DateTime.parse(completedAt);
      } catch (e) {
        debugPrint('Error parsing completion time: $e');
      }
    }

    // Parse next unlock time
    DateTime? nextUnlockTime;
    if (nextDayInfo != null && nextDayInfo['willUnlockAt'] != null) {
      try {
        nextUnlockTime = DateTime.parse(nextDayInfo['willUnlockAt']);
      } catch (e) {
        debugPrint('Error parsing unlock time: $e');
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.saffron, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                classCompleted 
                  ? context.tr('class_completed') 
                  : context.tr('day_completed')
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Completion message
              Text(
                classCompleted
                  ? '${context.tr('congratulations_completed_class')} ${widget.dayTitle}!'
                  : '${context.tr('congratulations_completed')} ${widget.dayTitle}.',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              
              // Completion timestamp
              if (completionTime != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 18, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Completed at: ${_formatDateTime(completionTime)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Class completion info
              if (classCompleted) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.saffron.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.saffron.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.celebration, color: AppTheme.saffron, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.tr('all_days_completed'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.saffron,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (levelInfo != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${levelInfo['level']} - ${levelInfo['title']}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.darkBrown,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Completed ${levelInfo['completedDays']}/${levelInfo['totalDays']} days',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Next level info
                if (nextLevelInfo != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.arrow_forward, size: 20, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Next Level Unlocked!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${nextLevelInfo['level']} - ${nextLevelInfo['title']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (nextLevelInfo['isUnlocked'] == true)
                          Text(
                            'You can start now!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                // Next day info
                if (nextDayInfo != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.beige.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock_clock, color: AppTheme.gold, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Next Day: Day ${nextDayInfo['dayNumber']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.darkBrown,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          nextDayInfo['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.darkBrown,
                          ),
                        ),
                        if (nextUnlockTime != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.schedule, size: 16, color: AppTheme.gold),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Will unlock at: ${_formatDateTime(nextUnlockTime)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.darkBrown,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getTimeUntilUnlock(nextUnlockTime),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.orange),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Next day will unlock after ${nextDayInfo['hoursUntilUnlock'] ?? 24} hours',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.darkBrown,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Go back to class days list
            },
            child: Text(context.tr('continue')),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final localTime = dateTime.toLocal();
    
    if (localTime.year == now.year && localTime.month == now.month && localTime.day == now.day) {
      // Today - show time only
      return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Different day - show date and time
      return '${localTime.day}/${localTime.month}/${localTime.year} ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getTimeUntilUnlock(DateTime unlockTime) {
    final now = DateTime.now();
    final difference = unlockTime.difference(now);
    
    if (difference.isNegative) {
      return 'Available now!';
    }
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    
    if (hours > 0) {
      return 'Unlocks in $hours hour${hours > 1 ? 's' : ''} ${minutes} minute${minutes != 1 ? 's' : ''}';
    } else {
      return 'Unlocks in $minutes minute${minutes != 1 ? 's' : ''}';
    }
  }

  int _parseIntSafely(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  /// Build video player based on streaming type
  /// Uses a single instance with key to prevent rebuilds
  /// CRITICAL: Cached to prevent recreation during orientation changes
  Widget _buildVideoPlayer() {
    // Return cached player if available (prevents rebuilds during rotation)
    if (_cachedVideoPlayer != null) {
      return _cachedVideoPlayer!;
    }
    
    final streamingType = _videoConfig!['streamingType'] ?? 'cloudflare';
    final videoDuration = _parseIntSafely(_videoConfig!['videoDurationSeconds']);
    
    Widget player;
    if (streamingType == 'hls') {
      // Use HLS Video Player
      player = HLSVideoPlayer(
        key: const ValueKey('hls_player'), // Preserve player instance
        hlsUrl: _videoConfig!['hlsUrl']?.toString() ?? '',
        thumbnailUrl: _videoConfig!['thumbnailUrl']?.toString(),
        lastPositionSeconds: _parseIntSafely(_videoConfig!['lastPositionSeconds']),
        allowSkip: _videoConfig!['allowSkip'] == true,
        onStart: _markDayAsStarted,
        onProgress: _trackProgress,
        onComplete: () {
          _trackProgress(videoDuration, videoDuration, 'complete');
        },
      );
    } else {
      // Use Cloudflare Video Player (backward compatibility)
      player = CloudflareVideoPlayer(
        key: const ValueKey('cloudflare_player'), // Preserve player instance
        videoId: _videoConfig!['cloudflareVideoId']?.toString() ?? '',
        accountId: _videoConfig!['cloudflareAccountId']?.toString() ?? '',
        lastPositionSeconds: 0,
        allowSkip: _videoConfig!['allowSkip'] == true,
        onStart: _markDayAsStarted,
        onProgress: _trackProgress,
        onComplete: () {
          _trackProgress(videoDuration, videoDuration, 'complete');
        },
      );
    }
    
    // Cache the player to prevent rebuilds
    _cachedVideoPlayer = player;
    return player;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trackingTimer?.cancel();
    _screenRecordingTimer?.cancel();
    _cachedVideoPlayer = null; // Clear cache
    _disableSecureMode();
    super.dispose();
  }

  Future<void> _disableSecureMode() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
    } catch (e) {
      debugPrint('Error disabling secure mode: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return SecureScreenWrapper(
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false, // Prevent rebuilds on keyboard
        // Hide AppBar in landscape — video fills the screen
        appBar: isLandscape ? null : AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.dayTitle,
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Day ${widget.dayNumber}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        body: _buildBody(isLandscape: isLandscape),
      ),
    );
  }

  Widget _buildBody({bool isLandscape = false}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: Text(context.tr('go_back')),
              ),
            ],
          ),
        ),
      );
    }

    final videoDuration = _parseIntSafely(_videoConfig!['videoDurationSeconds']);
    final durationMinutes = videoDuration ~/ 60;
    final durationSeconds = videoDuration % 60;
    final durationText = '$durationMinutes:${durationSeconds.toString().padLeft(2, '0')}';

    // ═══════════════════════════════════════════════════════════════
    // CRITICAL: Video player is built ONCE and reused across orientations
    // This prevents flickering and double frames during rotation
    // ═══════════════════════════════════════════════════════════════
    final videoPlayer = _buildVideoPlayer();

    // In landscape: video fills the entire screen, no info panel
    if (isLandscape) {
      return SafeArea(
        child: Stack(
          children: [
            // Video player fills entire screen - SAME INSTANCE as portrait
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: videoPlayer, // Reuse same player instance
                  ),
                ),
              ),
            ),
            // Back button overlay in landscape (top-left)
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () {
                  // Rotate back to portrait when back is pressed
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                  ]).then((_) => context.pop());
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                ),
              ),
            ),
            // Fullscreen exit hint (top-right)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.screen_rotation, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Rotate to exit fullscreen',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Portrait mode: video + info panel
    return Column(
      children: [
        // Video Player - wrapped in Container to prevent size changes
        // SAME INSTANCE as landscape mode
        Container(
          color: Colors.black,
          child: videoPlayer, // Reuse same player instance
        ),
        
        // Video Duration Display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.black87,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                'Video Length: $durationText',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Video Info with Security Warning
        Expanded(
          child: Container(
            color: AppTheme.white,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Security Warning Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.shade300,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.security,
                          color: Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('protected_content'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.tr('recording_prohibited_short'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Text(
                    widget.dayTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.saffron.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Day ${widget.dayNumber}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.saffron,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_parseIntSafely(_videoConfig!['videoDurationSeconds']) ~/ 60} ${context.tr('min')}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Important Notes
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.beige.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppTheme.gold,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('important_notes'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkBrown,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildNote(
                          context.tr('watch_complete_video'),
                        ),
                        _buildNote(
                          context.tr('next_day_unlock_after_24h'),
                        ),
                        if (!(_videoConfig!['allowSkip'] ?? false))
                          _buildNote(
                            context.tr('video_seeking_disabled'),
                          ),
                        _buildNote(
                          context.tr('progress_auto_saved'),
                        ),
                        _buildNote(
                          context.tr('screen_recording_monitored'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNote(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.gold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
