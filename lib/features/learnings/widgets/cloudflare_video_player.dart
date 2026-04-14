import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class CloudflareVideoPlayer extends StatefulWidget {
  final String videoId;
  final String accountId;
  final int lastPositionSeconds;
  final bool allowSkip;
  final Function(int positionSeconds, int durationSeconds, String eventType) onProgress;
  final VoidCallback? onComplete;
  final VoidCallback? onStart;

  const CloudflareVideoPlayer({
    super.key,
    required this.videoId,
    required this.accountId,
    this.lastPositionSeconds = 0,
    this.allowSkip = false,
    required this.onProgress,
    this.onComplete,
    this.onStart,
  });

  @override
  State<CloudflareVideoPlayer> createState() => _CloudflareVideoPlayerState();
}

class _CloudflareVideoPlayerState extends State<CloudflareVideoPlayer> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasStarted = false;
  bool _isCompleted = false;
  
  // Track which milestones have been reported
  final Set<int> _reportedMilestones = {};
  static const List<int> _milestones = [25, 50, 75, 90, 100];

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    debugPrint('🎬 Initializing Cloudflare Stream player');
    debugPrint('   Video ID: ${widget.videoId}');
    debugPrint('   Account ID: ${widget.accountId}');
    debugPrint('   Last Position: ${widget.lastPositionSeconds}s');
    
    if (widget.videoId.isEmpty || widget.accountId.isEmpty) {
      debugPrint('❌ Invalid video configuration');
      setState(() {
        _hasError = true;
        _errorMessage = 'Invalid video configuration';
        _isLoading = false;
      });
      return;
    }
    
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              debugPrint('🔄 Page loading started');
            },
            onPageFinished: (String url) {
              debugPrint('✅ Page loaded successfully');
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('❌ Web resource error: ${error.description}');
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage = 'Failed to load video';
                  _isLoading = false;
                });
              }
            },
          ),
        )
        ..addJavaScriptChannel(
          'FlutterChannel',
          onMessageReceived: (JavaScriptMessage message) {
            _handleVideoEvent(message.message);
          },
        )
        ..loadHtmlString(_buildHtmlPlayer());

      debugPrint('✅ WebView controller initialized');
    } catch (e) {
      debugPrint('❌ Error initializing player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize player';
          _isLoading = false;
        });
      }
    }
  }

  String _buildHtmlPlayer() {
    // Build complete HTML page with Cloudflare Stream player and SDK
    final startTime = widget.lastPositionSeconds > 0 ? '&startTime=${widget.lastPositionSeconds}' : '';
    
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    body {
      background: #000;
      overflow: hidden;
    }
    #player-container {
      position: relative;
      width: 100%;
      padding-top: 56.25%; /* 16:9 aspect ratio */
    }
    #stream-player {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      border: none;
    }
  </style>
</head>
<body>
  <div id="player-container">
    <iframe
      id="stream-player"
      src="https://${widget.accountId}.cloudflarestream.com/${widget.videoId}/iframe?preload=auto&autoplay=false&loop=false&muted=false&controls=true&defaultTextTrack=en$startTime"
      loading="lazy"
      allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;"
      allowfullscreen="true">
    </iframe>
  </div>

  <!-- Load Cloudflare Stream SDK -->
  <script src="https://embed.cloudflarestream.com/embed/sdk.latest.js"></script>
  
  <script>
    console.log('🎬 Initializing Cloudflare Stream Player');
    
    let player = null;
    let isCompleted = false;
    let lastReportedTime = 0;
    let hasStarted = false;
    
    // Wait for iframe to load
    const iframe = document.getElementById('stream-player');
    
    iframe.addEventListener('load', function() {
      console.log('✅ Iframe loaded, initializing Stream SDK');
      
      try {
        // Initialize Stream player with SDK
        player = Stream(iframe);
        console.log('✅ Stream player initialized');
        
        // Explicitly ensure video doesn't autoplay
        setTimeout(function() {
          if (player && !player.paused) {
            console.log('⏸️ Force pausing video on init');
            player.pause();
          }
        }, 100);
        
        // Listen to loadedmetadata to get duration
        player.addEventListener('loadedmetadata', function() {
          const duration = Math.floor(player.duration || 0);
          console.log('📊 Video metadata loaded - Duration:', duration, 'seconds');
          
          // Ensure video is paused on load (no autoplay)
          if (!player.paused) {
            console.log('⏸️ Pausing video - no autoplay');
            player.pause();
          }
          
          FlutterChannel.postMessage(JSON.stringify({
            type: 'metadata',
            position: Math.floor(player.currentTime || 0),
            duration: duration
          }));
        });
        
        // Listen to play event
        player.addEventListener('play', function() {
          if (isCompleted) {
            console.log('🚫 Blocking replay - video already completed');
            player.pause();
            FlutterChannel.postMessage(JSON.stringify({
              type: 'replay_blocked',
              position: Math.floor(player.currentTime || 0),
              duration: Math.floor(player.duration || 0)
            }));
            return;
          }
          
          if (!hasStarted) {
            hasStarted = true;
            console.log('▶️ Video started playing');
            FlutterChannel.postMessage(JSON.stringify({
              type: 'start',
              position: Math.floor(player.currentTime || 0),
              duration: Math.floor(player.duration || 0)
            }));
          }
          
          console.log('▶️ Video playing');
          FlutterChannel.postMessage(JSON.stringify({
            type: 'play',
            position: Math.floor(player.currentTime || 0),
            duration: Math.floor(player.duration || 0)
          }));
        });
        
        // Listen to pause event
        player.addEventListener('pause', function() {
          console.log('⏸️ Video paused');
          FlutterChannel.postMessage(JSON.stringify({
            type: 'pause',
            position: Math.floor(player.currentTime || 0),
            duration: Math.floor(player.duration || 0)
          }));
        });
        
        // Listen to timeupdate event (fires frequently during playback)
        player.addEventListener('timeupdate', function() {
          const currentTime = player.currentTime || 0;
          const duration = player.duration || 0;
          
          // Only send updates every 2 seconds to reduce API calls
          if (Math.abs(currentTime - lastReportedTime) >= 2) {
            lastReportedTime = currentTime;
            const percentage = duration > 0 ? (currentTime / duration * 100).toFixed(1) : 0;
            console.log('⏱️ Progress:', Math.floor(currentTime), '/', Math.floor(duration), '(' + percentage + '%)');
            
            FlutterChannel.postMessage(JSON.stringify({
              type: 'progress',
              position: Math.floor(currentTime),
              duration: Math.floor(duration)
            }));
          }
        });
        
        // Listen to ended event
        player.addEventListener('ended', function() {
          console.log('🏁 Video ended - marking as complete');
          isCompleted = true;
          
          // Immediately pause to prevent any auto-replay
          player.pause();
          
          // Seek to end to ensure it stays there
          player.currentTime = player.duration;
          
          // Disable loop explicitly
          player.loop = false;
          
          // Hide controls to prevent replay
          iframe.style.pointerEvents = 'none';
          
          console.log('✅ Video playback stopped, replay blocked, controls disabled');
          
          FlutterChannel.postMessage(JSON.stringify({
            type: 'complete',
            position: Math.floor(player.duration || 0),
            duration: Math.floor(player.duration || 0)
          }));
        });
        
        // Listen to error event
        player.addEventListener('error', function(e) {
          console.log('❌ Player error:', e);
          FlutterChannel.postMessage(JSON.stringify({
            type: 'error',
            message: 'Playback error: ' + (e.message || 'Unknown error')
          }));
        });
        
        ${!widget.allowSkip ? '''
        // Prevent seeking forward (anti-skip protection)
        player.addEventListener('seeking', function() {
          const currentTime = player.currentTime || 0;
          if (currentTime > lastReportedTime + 5) {
            console.log('🚫 Blocking forward seek');
            player.currentTime = lastReportedTime;
          }
        });
        
        // Disable right-click
        document.addEventListener('contextmenu', function(e) {
          e.preventDefault();
        });
        ''' : ''}
        
        console.log('✅ All event listeners attached');
        
      } catch (error) {
        console.log('❌ Error initializing Stream player:', error);
        FlutterChannel.postMessage(JSON.stringify({
          type: 'error',
          message: 'Failed to initialize player: ' + error.message
        }));
      }
    });
    
    // Error handler for iframe load failure
    iframe.addEventListener('error', function(e) {
      console.log('❌ Iframe failed to load:', e);
      FlutterChannel.postMessage(JSON.stringify({
        type: 'error',
        message: 'Failed to load video iframe'
      }));
    });
  </script>
</body>
</html>
''';
  }

  void _handleVideoEvent(String message) {
    try {
      debugPrint('📨 Received event: $message');
      
      final data = json.decode(message);
      final type = data['type'] as String;
      final position = data['position'] as int? ?? 0;
      final duration = data['duration'] as int? ?? 0;

      // Update state
      if (mounted) {
        setState(() {
          if (duration > 0) {
            // State updated for UI
          }
        });
      }

      // Handle start event
      if (type == 'start' && !_hasStarted) {
        _hasStarted = true;
        debugPrint('▶️ Video started');
        widget.onStart?.call();
      }

      // Handle completion
      if (type == 'complete' && !_isCompleted) {
        _isCompleted = true;
        debugPrint('✅ Video completed');
        widget.onComplete?.call();
      }
      
      // Handle replay blocking
      if (type == 'replay_blocked') {
        debugPrint('🚫 Replay blocked');
        return;
      }
      
      // Handle errors
      if (type == 'error') {
        debugPrint('❌ Player error: ${data['message']}');
        return;
      }

      // Check for milestone thresholds
      if (duration > 0 && !_isCompleted && (type == 'progress' || type == 'complete')) {
        final completionPercentage = (position / duration) * 100;
        
        for (final milestone in _milestones) {
          if (completionPercentage >= milestone && !_reportedMilestones.contains(milestone)) {
            _reportedMilestones.add(milestone);
            debugPrint('🎯 Milestone reached: $milestone%');
            
            // Report milestone immediately
            widget.onProgress(position, duration, 'milestone_$milestone');
          }
        }
      }

      // Report progress (only if not completed)
      if (!_isCompleted && duration > 0 && (type == 'progress' || type == 'play' || type == 'pause')) {
        widget.onProgress(position, duration, type);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error handling event: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Raw message: $message');
    }
  }

  @override
  void dispose() {
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
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Failed to load video',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_controller == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: WebViewWidget(controller: _controller!),
        ),
        if (_isLoading)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        // Completion overlay - shows immediately when video ends
        if (_isCompleted)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.95),
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
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Video Completed!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: const Text(
                        '✓ Progress saved successfully',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Please wait for completion details...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
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
}
