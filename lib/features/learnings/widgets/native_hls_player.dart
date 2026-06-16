import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

/// Native HLS Video Player using video_player + chewie
/// Works better with SSL certificates on Android
/// Prevents forward seeking (user can only go backward)
class NativeHLSPlayer extends StatefulWidget {
  final String hlsUrl;
  final String? thumbnailUrl;
  final int lastPositionSeconds;
  final bool allowSkip;
  final Function(int positionSeconds, int durationSeconds, String eventType) onProgress;
  final VoidCallback? onComplete;
  final VoidCallback? onStart;

  const NativeHLSPlayer({
    super.key,
    required this.hlsUrl,
    this.thumbnailUrl,
    this.lastPositionSeconds = 0,
    this.allowSkip = false,
    required this.onProgress,
    this.onComplete,
    this.onStart,
  });

  @override
  State<NativeHLSPlayer> createState() => _NativeHLSPlayerState();
}

class _NativeHLSPlayerState extends State<NativeHLSPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasStarted = false;
  bool _isCompleted = false;
  int _lastReportedPosition = 0;
  final Set<int> _reportedMilestones = {};
  
  // Track maximum watched position for skip prevention
  double _maxWatchedPosition = 0;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _maxWatchedPosition = widget.lastPositionSeconds.toDouble();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      debugPrint('🎬 Initializing native HLS player...');
      debugPrint('   URL: ${widget.hlsUrl}');
      debugPrint('   Allow Skip: ${widget.allowSkip}');

      // Create video player controller with network URL
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.hlsUrl),
        httpHeaders: {
          'Accept': '*/*',
        },
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      // Initialize the controller
      await _videoPlayerController!.initialize();
      
      debugPrint('✅ Video player initialized successfully');
      debugPrint('   Duration: ${_videoPlayerController!.value.duration}');
      debugPrint('   Size: ${_videoPlayerController!.value.size}');

      // Seek to last position if provided
      if (widget.lastPositionSeconds > 0) {
        await _videoPlayerController!.seekTo(
          Duration(seconds: widget.lastPositionSeconds),
        );
        _maxWatchedPosition = widget.lastPositionSeconds.toDouble();
        debugPrint('⏩ Seeked to ${widget.lastPositionSeconds}s');
      }

      // Create Chewie controller with customized controls
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        showControls: true,
        showControlsOnInitialize: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        playbackSpeeds: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
        // Disable dragging to prevent forward seeking when not allowed
        draggableProgressBar: widget.allowSkip,
        placeholder: widget.thumbnailUrl != null
            ? Image.network(
                widget.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.black);
                },
              )
            : Container(color: Colors.black),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Error loading video',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      // Listen for video state changes
      _videoPlayerController!.addListener(_onVideoStateChanged);
      
      // Listen for fullscreen changes
      _chewieController!.addListener(_onChewieStateChanged);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing video player: $e');
      debugPrint('   Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onChewieStateChanged() {
    if (!mounted || _chewieController == null) return;
    
    final isFullScreen = _chewieController!.isFullScreen;
    if (isFullScreen != _isFullScreen) {
      _isFullScreen = isFullScreen;
      debugPrint('📺 Fullscreen changed: $_isFullScreen');
      
      // Handle orientation changes for fullscreen
      if (isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    }
  }

  void _onVideoStateChanged() {
    if (!mounted || _videoPlayerController == null) return;

    final value = _videoPlayerController!.value;
    
    // Check for errors
    if (value.hasError) {
      debugPrint('❌ Video error: ${value.errorDescription}');
      setState(() {
        _hasError = true;
        _errorMessage = value.errorDescription ?? 'Unknown error';
      });
      return;
    }

    final currentPosition = value.position.inSeconds.toDouble();
    final duration = value.duration.inSeconds;

    // Update max watched position
    if (currentPosition > _maxWatchedPosition) {
      _maxWatchedPosition = currentPosition;
    }

    // SKIP PREVENTION: If user tries to seek forward beyond watched position
    if (!widget.allowSkip && currentPosition > _maxWatchedPosition + 3) {
      debugPrint('⚠️ Skip attempt blocked! Seeking back to $_maxWatchedPosition');
      _videoPlayerController!.seekTo(Duration(seconds: _maxWatchedPosition.toInt()));
      return;
    }

    // Track start
    if (value.isPlaying && !_hasStarted) {
      _hasStarted = true;
      debugPrint('▶️ Video started playing');
      widget.onStart?.call();
      widget.onProgress(
        value.position.inSeconds,
        duration,
        'start',
      );
    }

    // Track progress (every 5 seconds)
    final currentPositionInt = value.position.inSeconds;
    
    if (duration > 0 && (currentPositionInt - _lastReportedPosition).abs() >= 5) {
      _lastReportedPosition = currentPositionInt;
      widget.onProgress(currentPositionInt, duration, 'progress');
      
      // Check milestones
      final percentage = (currentPositionInt / duration * 100).round();
      for (final milestone in [25, 50, 75, 90]) {
        if (percentage >= milestone && !_reportedMilestones.contains(milestone)) {
          _reportedMilestones.add(milestone);
          widget.onProgress(currentPositionInt, duration, 'milestone_$milestone');
          debugPrint('🎯 Milestone reached: $milestone%');
        }
      }
    }

    // Check for completion
    if (value.position >= value.duration - const Duration(seconds: 2) && 
        duration > 0 && 
        !_isCompleted) {
      _isCompleted = true;
      debugPrint('✅ Video completed');
      widget.onProgress(duration, duration, 'complete');
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    // Reset orientation when disposing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    _videoPlayerController?.removeListener(_onVideoStateChanged);
    _chewieController?.removeListener(_onChewieStateChanged);
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load video',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _errorMessage ?? 'Unknown error',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _errorMessage = null;
                      _isInitialized = false;
                    });
                    _initializePlayer();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            // Thumbnail while loading
            if (widget.thumbnailUrl != null)
              Positioned.fill(
                child: Image.network(
                  widget.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Colors.black);
                  },
                ),
              ),
            // Loading overlay
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Completion overlay
    if (_isCompleted) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            Chewie(controller: _chewieController!),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.85),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 72,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Video Completed!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: const Text(
                          '✓ Progress saved',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
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

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Chewie(controller: _chewieController!),
    );
  }
}
