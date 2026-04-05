import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import 'widgets/cloudflare_video_player.dart';

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

class _DayVideoScreenState extends State<DayVideoScreen> {
  final ApiService _apiService = ApiService();
  final String _sessionId = const Uuid().v4();
  
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _videoConfig;
  Timer? _trackingTimer;
  int _lastTrackedPosition = 0;
  bool _hasStarted = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadVideoConfig();
  }

  Future<void> _loadVideoConfig() async {
    try {
      final response = await _apiService.get(
        '/api/classes/days/${widget.dayId}/video-config',
      );

      if (response['success'] == true) {
        setState(() {
          _videoConfig = response['videoConfig'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load video';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading video: $e';
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

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
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
                )
              : Column(
                  children: [
                    // Video Player
                    CloudflareVideoPlayer(
                      videoId: _videoConfig!['cloudflareVideoId'],
                      accountId: _videoConfig!['cloudflareAccountId'],
                      lastPositionSeconds: _videoConfig!['lastPositionSeconds'] ?? 0,
                      allowSkip: _videoConfig!['allowSkip'] ?? false,
                      onStart: _markDayAsStarted,
                      onProgress: _trackProgress,
                      onComplete: () {
                        _trackProgress(
                          _videoConfig!['videoDurationSeconds'] ?? 0,
                          _videoConfig!['videoDurationSeconds'] ?? 0,
                          'complete',
                        );
                      },
                    ),
                    
                    // Video Info
                    Expanded(
                      child: Container(
                        color: AppTheme.white,
                        padding: const EdgeInsets.all(20),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                      color: AppTheme.saffron.withOpacity(0.1),
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
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(_videoConfig!['videoDurationSeconds'] ?? 0) ~/ 60} min',
                                    style: TextStyle(
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
                                  color: AppTheme.beige.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.gold.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: AppTheme.gold,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
