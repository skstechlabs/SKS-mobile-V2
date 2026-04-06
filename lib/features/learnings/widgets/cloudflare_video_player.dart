import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:async';

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
  Timer? _progressTimer;
  int _currentPosition = 0;
  int _duration = 0;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    debugPrint('🎬 Initializing video player');
    debugPrint('   Video ID: ${widget.videoId}');
    debugPrint('   Account ID: ${widget.accountId}');
    debugPrint('   Last Position: ${widget.lastPositionSeconds}s');
    
    if (widget.videoId.isEmpty || widget.accountId.isEmpty) {
      debugPrint('❌ Invalid video configuration - missing videoId or accountId');
      setState(() {
        _hasError = true;
        _errorMessage = 'Invalid video configuration';
        _isLoading = false;
      });
      return;
    }
    
    try {
      final iframeUrl = 'https://${widget.accountId}.cloudflarestream.com/${widget.videoId}/iframe'
          '?preload=true'
          '&autoplay=false'
          '&loop=false'
          '&muted=false'
          '&controls=true'
          '&defaultTextTrack=en'
          '${widget.lastPositionSeconds > 0 ? '&startTime=${widget.lastPositionSeconds}' : ''}';

      debugPrint('📺 Loading video from: $iframeUrl');

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              debugPrint('🔄 Page loading started: $url');
            },
            onPageFinished: (String url) {
              debugPrint('✅ Page loading finished: $url');
              if (mounted) {
                setState(() => _isLoading = false);
                _injectJavaScript();
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
          'VideoEvents',
          onMessageReceived: (JavaScriptMessage message) {
            _handleVideoEvent(message.message);
          },
        )
        ..loadRequest(Uri.parse(iframeUrl));

      // Start progress tracking timer
      _progressTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted && _controller != null) {
          _getVideoPosition();
        }
      });
    } catch (e) {
      debugPrint('❌ Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize video player';
          _isLoading = false;
        });
      }
    }
  }

  void _injectJavaScript() {
    if (_controller == null) return;
    
    // Inject JavaScript to communicate with Cloudflare Stream player
    final js = '''
      (function() {
        const iframe = document.querySelector('iframe');
        if (!iframe) return;
        
        const player = iframe.contentWindow;
        let duration = 0;
        let currentTime = 0;
        let hasPlayed = false;
        
        // Listen to player events via postMessage
        window.addEventListener('message', function(event) {
          if (event.data && event.data.event) {
            const data = event.data;
            
            switch(data.event) {
              case 'play':
                hasPlayed = true;
                VideoEvents.postMessage(JSON.stringify({
                  type: 'play',
                  position: Math.floor(currentTime),
                  duration: Math.floor(duration)
                }));
                break;
                
              case 'pause':
                VideoEvents.postMessage(JSON.stringify({
                  type: 'pause',
                  position: Math.floor(currentTime),
                  duration: Math.floor(duration)
                }));
                break;
                
              case 'ended':
                VideoEvents.postMessage(JSON.stringify({
                  type: 'complete',
                  position: Math.floor(duration),
                  duration: Math.floor(duration)
                }));
                break;
                
              case 'timeupdate':
                currentTime = data.currentTime || 0;
                duration = data.duration || 0;
                VideoEvents.postMessage(JSON.stringify({
                  type: 'progress',
                  position: Math.floor(currentTime),
                  duration: Math.floor(duration)
                }));
                break;
                
              case 'seeked':
                ${widget.allowSkip ? '' : '''
                // Prevent seeking forward
                if (data.currentTime > currentTime + 2) {
                  player.postMessage({
                    method: 'seek',
                    value: currentTime
                  }, '*');
                }
                '''}
                break;
            }
          }
        });
        
        // Request player state updates
        setInterval(function() {
          player.postMessage({ method: 'getCurrentTime' }, '*');
          player.postMessage({ method: 'getDuration' }, '*');
        }, 2000);
        
        // Disable download if not allowed
        ${widget.allowSkip ? '' : '''
        document.addEventListener('contextmenu', function(e) {
          e.preventDefault();
        });
        '''}
      })();
    ''';

    _controller!.runJavaScript(js);
  }

  void _handleVideoEvent(String message) {
    try {
      final data = json.decode(message);
      final type = data['type'] as String;
      final position = data['position'] as int? ?? 0;
      final duration = data['duration'] as int? ?? 0;

      debugPrint('📹 Video event: $type at ${position}s / ${duration}s');

      setState(() {
        _currentPosition = position;
        _duration = duration;
      });

      // Call callbacks
      if (type == 'play' && !_hasStarted) {
        _hasStarted = true;
        debugPrint('▶️ Video started playing');
        widget.onStart?.call();
      }

      if (type == 'complete') {
        debugPrint('✅ Video completed');
        widget.onComplete?.call();
      }

      // Report progress to parent
      widget.onProgress(position, duration, type);
    } catch (e) {
      debugPrint('❌ Error handling video event: $e');
    }
  }

  void _getVideoPosition() {
    if (_controller == null) return;
    
    _controller!.runJavaScript('''
      const iframe = document.querySelector('iframe');
      if (iframe) {
        iframe.contentWindow.postMessage({ method: 'getCurrentTime' }, '*');
        iframe.contentWindow.postMessage({ method: 'getDuration' }, '*');
      }
    ''');
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
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
        // Progress indicator
        if (_duration > 0)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black.withValues(alpha: 0.7),
              child: Row(
                children: [
                  Text(
                    _formatDuration(_currentPosition),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _duration > 0 ? _currentPosition / _duration : 0,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
