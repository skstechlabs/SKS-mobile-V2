import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

/// SIMPLE HLS Video Player using native Android/iOS video player
/// This works with SSL certificates that WebView rejects
class SimpleHLSPlayer extends StatefulWidget {
  final String hlsUrl;
  final String? thumbnailUrl;
  final int lastPositionSeconds;
  final bool allowSkip;
  final Function(int positionSeconds, int durationSeconds, String eventType) onProgress;
  final VoidCallback? onComplete;
  final VoidCallback? onStart;

  const SimpleHLSPlayer({
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
  State<SimpleHLSPlayer> createState() => _SimpleHLSPlayerState();
}

class _SimpleHLSPlayerState extends State<SimpleHLSPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasStarted = false;
  bool _isCompleted = false;
  double _maxWatchedPosition = 0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      debugPrint('🎬 Initializing video player');
      debugPrint('   URL: ${widget.hlsUrl}');
      
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.hlsUrl),
      );

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: widget.thumbnailUrl != null
            ? Image.network(
                widget.thumbnailUrl!,
                fit: BoxFit.contain,
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Video Error',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _retry();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      );

      // Seek to last position
      if (widget.lastPositionSeconds > 0) {
        await _videoPlayerController.seekTo(
          Duration(seconds: widget.lastPositionSeconds),
        );
        _maxWatchedPosition = widget.lastPositionSeconds.toDouble();
      }

      // Listen to playback events
      _videoPlayerController.addListener(_videoListener);

      setState(() {
        _isInitialized = true;
      });

      debugPrint('✅ Video player initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing video player: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _videoListener() {
    if (!mounted) return;

    final position = _videoPlayerController.value.position.inSeconds;
    final duration = _videoPlayerController.value.duration.inSeconds;

    // Track progress
    if (position > _maxWatchedPosition) {
      _maxWatchedPosition = position.toDouble();
    }

    // Prevent skipping
    if (!widget.allowSkip && position > _maxWatchedPosition + 5) {
      _videoPlayerController.seekTo(Duration(seconds: _maxWatchedPosition.toInt()));
      return;
    }

    // Check if started
    if (!_hasStarted && position > 0) {
      _hasStarted = true;
      widget.onStart?.call();
    }

    // Report progress every 5 seconds
    if (position % 5 == 0) {
      widget.onProgress(position, duration, 'timeupdate');
    }

    // Check completion
    if (_videoPlayerController.value.isPlaying == false &&
        _videoPlayerController.value.position >= _videoPlayerController.value.duration &&
        !_isCompleted) {
      _isCompleted = true;
      widget.onComplete?.call();
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _isInitialized = false;
    });
    _initializePlayer();
  }

  @override
  void dispose() {
    _videoPlayerController.removeListener(_videoListener);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load video',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _retry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _chewieController == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Chewie(controller: _chewieController!);
  }
}
