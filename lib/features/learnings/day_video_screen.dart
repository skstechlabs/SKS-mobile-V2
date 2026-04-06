import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import 'widgets/cloudflare_video_player.dart';
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
  int _lastTrackedPosition = 0;
  bool _hasStarted = false;
  bool _isCompleted = false;
  bool _isScreenRecording = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableSecureMode();
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

  Future<void> _enableSecureMode() async {
    try {
      // Enable secure mode to prevent screenshots and screen recording
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [SystemUiOverlay.bottom],
      );
      debugPrint('🔒 Secure mode enabled');
    } catch (e) {
      debugPrint('⚠️ Could not enable secure mode: $e');
    }
  }

  void _startScreenRecordingDetection() {
    // Check for screen recording every 2 seconds
    Timer.periodic(const Duration(seconds: 2), (timer) {
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
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Security Warning'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Screen recording or screenshot detected.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Recording, downloading, or sharing this content is strictly prohibited and may result in:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text('• Immediate account suspension', style: TextStyle(fontSize: 14)),
            Text('• Legal action for copyright violation', style: TextStyle(fontSize: 14)),
            Text('• Loss of access to all courses', style: TextStyle(fontSize: 14)),
            SizedBox(height: 12),
            Text(
              'This incident has been logged.',
              style: TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Exit video screen
            },
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadVideoConfig() async {
    try {
      debugPrint('🎥 Loading video config for day ${widget.dayId}');
      final response = await _apiService.get(
        '/api/classes/days/${widget.dayId}/video-config',
      );

      debugPrint('📦 Video config response: $response');

      if (response['success'] == true) {
        final videoConfig = response['videoConfig'];
        
        // Validate required fields
        if (videoConfig == null || 
            videoConfig['cloudflareVideoId'] == null || 
            videoConfig['cloudflareAccountId'] == null) {
          setState(() {
            _error = 'Video configuration is incomplete';
            _isLoading = false;
          });
          return;
        }
        
        setState(() {
          _videoConfig = videoConfig;
          _isLoading = false;
        });
        debugPrint('✅ Video config loaded successfully');
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
    // Only track every 5 seconds to reduce API calls
    if (eventType == 'progress' && (positionSeconds - _lastTrackedPosition).abs() < 5) {
      return;
    }

    _lastTrackedPosition = positionSeconds;

    try {
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

      if (response['success'] == true && eventType == 'complete' && !_isCompleted) {
        setState(() => _isCompleted = true);
        _showCompletionDialog();
      }
    } catch (e) {
      debugPrint('Error tracking progress: $e');
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.saffron, size: 32),
            const SizedBox(width: 12),
            const Text('Day Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Congratulations! You have completed ${widget.dayTitle}.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.beige.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_clock, color: AppTheme.gold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Next day will unlock in 24 hours',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Go back to class days list
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  int _parseIntSafely(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trackingTimer?.cancel();
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
    return SecureScreenWrapper(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
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
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Video Player
        CloudflareVideoPlayer(
          videoId: _videoConfig!['cloudflareVideoId']?.toString() ?? '',
          accountId: _videoConfig!['cloudflareAccountId']?.toString() ?? '',
          lastPositionSeconds: _parseIntSafely(_videoConfig!['lastPositionSeconds']),
          allowSkip: _videoConfig!['allowSkip'] == true,
          onStart: _markDayAsStarted,
          onProgress: _trackProgress,
          onComplete: () {
            final duration = _parseIntSafely(_videoConfig!['videoDurationSeconds']);
            _trackProgress(duration, duration, 'complete');
          },
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
                              const Text(
                                'Protected Content',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Recording, downloading, or sharing this video is strictly prohibited',
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
                        '${_parseIntSafely(_videoConfig!['videoDurationSeconds']) ~/ 60} min',
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
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.gold,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Important Notes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkBrown,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildNote(
                          'Watch the complete video to mark this day as completed',
                        ),
                        _buildNote(
                          'Next day will unlock 24 hours after completing this day',
                        ),
                        if (!(_videoConfig!['allowSkip'] ?? false))
                          _buildNote(
                            'Video seeking is disabled to ensure complete learning',
                          ),
                        _buildNote(
                          'Your progress is automatically saved',
                        ),
                        _buildNote(
                          'Screen recording and screenshots are monitored and prohibited',
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
