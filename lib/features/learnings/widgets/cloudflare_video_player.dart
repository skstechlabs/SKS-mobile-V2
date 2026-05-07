import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

/// Cloudflare Stream video player.
///
/// Architecture decision:
/// ─────────────────────────────────────────────────────────────────────────
/// We use the Cloudflare Stream iframe with controls=1 (native player UI).
/// This is the ONLY reliable approach in Android WebView because:
///   - play() requires a user gesture — calling it from Dart JS bridge fails
///   - The iframe is sandboxed — postMessage is unreliable for control
///   - Native controls (play/pause/seek/volume) always work correctly
///
/// Flutter only handles:
///   1. Deferred loading (iframe not loaded until user taps → no autoplay)
///   2. Fullscreen toggle (orientation + system UI)
///   3. Progress tracking via JS events (timeupdate, ended, etc.)
///   4. Skip prevention (seeking blocked via JS if allowSkip=false)
///
/// Video always starts from the beginning (position 0) regardless of
/// lastPositionSeconds — user explicitly opens the video to rewatch.
/// ─────────────────────────────────────────────────────────────────────────
class CloudflareVideoPlayer extends StatefulWidget {
  final String videoId;
  final String accountId;
  final int lastPositionSeconds;
  final bool allowSkip;
  final Function(int positionSeconds, int durationSeconds, String eventType)
      onProgress;
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

  bool _iframeLoaded = false; // false = show tap-to-play poster
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  bool _isFullscreen = false;
  bool _hasStarted = false;
  bool _isCompleted = false;

  final Set<int> _reportedMilestones = {};
  static const List<int> _milestones = [25, 50, 75, 90, 100];

  @override
  void dispose() {
    if (_isFullscreen) _exitFullscreen();
    super.dispose();
  }

  // ── Tap-to-play: load the iframe on first user tap ─────────────────────────
  void _onTapPlay() {
    if (_isCompleted) return;
    setState(() {
      _iframeLoaded = true;
      _isLoading = true;
    });
    _initWebView();
  }

  // ── WebView init ───────────────────────────────────────────────────────────
  void _initWebView() {
    if (widget.videoId.isEmpty || widget.accountId.isEmpty) {
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
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame == true) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage = 'Failed to load video. Tap retry.';
                  _isLoading = false;
                });
              }
            }
          },
        ))
        ..addJavaScriptChannel(
          'FlutterChannel',
          onMessageReceived: (JavaScriptMessage msg) {
            _handleEvent(msg.message);
          },
        )
        ..loadHtmlString(_buildHtml());
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize player';
          _isLoading = false;
        });
      }
    }
  }

  // ── Retry ──────────────────────────────────────────────────────────────────
  void _retry() {
    if (_retryCount >= _maxRetries) {
      setState(() {
        _errorMessage =
            'Video unavailable. Please check your connection and try again.';
      });
      return;
    }
    _retryCount++;
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _isLoading = true;
    });
    _initWebView();
  }

  // ── Fullscreen ─────────────────────────────────────────────────────────────
  void _enterFullscreen() {
    setState(() => _isFullscreen = true);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullscreen() {
    setState(() => _isFullscreen = false);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
  }

  void _toggleFullscreen() {
    if (_isFullscreen) {
      _exitFullscreen();
    } else {
      _enterFullscreen();
    }
  }

  // ── HTML ───────────────────────────────────────────────────────────────────
  // Key decisions:
  //   controls=1  → native Cloudflare player UI (play/pause/seek/volume/mute)
  //   autoplay=1  → starts immediately because user just tapped (user gesture)
  //   muted=0     → audio on from the start
  //   startTime=0 → always start from beginning (user wants to rewatch)
  //   loop=false  → no looping
  //
  // We only use JS for:
  //   - Tracking progress (timeupdate, ended events)
  //   - Skip prevention (seeking blocked if allowSkip=false)
  //   - Reporting start/complete to Flutter
  String _buildHtml() {
    // Always start from beginning — user opens video to watch from start
    const startTime = '';

    final iframeSrc =
        'https://${widget.accountId}.cloudflarestream.com/${widget.videoId}/iframe'
        '?preload=auto&autoplay=1&loop=false&muted=false&controls=true$startTime';

    final skipJs = widget.allowSkip
        ? ''
        : r'''
      var maxWatchedTime = 0;
      player.addEventListener('timeupdate', function() {
        var t = player.currentTime || 0;
        if (t > maxWatchedTime) maxWatchedTime = t;
      });
      player.addEventListener('seeking', function() {
        var t = player.currentTime || 0;
        if (t > maxWatchedTime + 5) {
          player.currentTime = maxWatchedTime;
        }
      });
    ''';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no">
  <style>
    * { margin:0; padding:0; box-sizing:border-box; }
    html, body { width:100%; height:100%; background:#000; overflow:hidden; }
    #wrap {
      position: relative;
      width: 100%;
      height: 100%;
    }
    #player {
      position: absolute;
      top: 0; left: 0;
      width: 100%; height: 100%;
      border: none;
    }
  </style>
</head>
<body>
  <div id="wrap">
    <iframe
      id="player"
      src="$iframeSrc"
      allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture; fullscreen;"
      allowfullscreen="true"
      webkitallowfullscreen="true"
      mozallowfullscreen="true">
    </iframe>
  </div>

  <script src="https://embed.cloudflarestream.com/embed/sdk.latest.js"></script>
  <script>
    var player = null;
    var isCompleted = false;
    var lastReportedTime = 0;
    var hasStarted = false;

    function send(obj) {
      try { FlutterChannel.postMessage(JSON.stringify(obj)); } catch(e) {}
    }

    function initPlayer() {
      var iframe = document.getElementById('player');
      try {
        player = Stream(iframe);
      } catch(e) {
        send({ type: 'error', message: 'SDK init failed: ' + e.message });
        return;
      }

      player.addEventListener('loadedmetadata', function() {
        // Ensure audio is on
        player.muted = false;
        player.volume = 1.0;
        send({ type: 'ready', duration: Math.floor(player.duration || 0) });
      });

      player.addEventListener('play', function() {
        if (isCompleted) { player.pause(); return; }
        if (!hasStarted) {
          hasStarted = true;
          send({
            type: 'start',
            position: Math.floor(player.currentTime || 0),
            duration: Math.floor(player.duration || 0)
          });
        }
        send({
          type: 'play',
          position: Math.floor(player.currentTime || 0),
          duration: Math.floor(player.duration || 0)
        });
      });

      player.addEventListener('pause', function() {
        send({
          type: 'pause',
          position: Math.floor(player.currentTime || 0),
          duration: Math.floor(player.duration || 0)
        });
      });

      player.addEventListener('timeupdate', function() {
        var t = player.currentTime || 0;
        var d = player.duration || 0;
        if (d > 0 && Math.abs(t - lastReportedTime) >= 3) {
          lastReportedTime = t;
          send({ type: 'progress', position: Math.floor(t), duration: Math.floor(d) });
        }
      });

      player.addEventListener('ended', function() {
        if (isCompleted) return;
        isCompleted = true;
        send({
          type: 'complete',
          position: Math.floor(player.duration || 0),
          duration: Math.floor(player.duration || 0)
        });
      });

      player.addEventListener('error', function(e) {
        send({ type: 'error', message: 'Playback error: ' + (e.message || 'unknown') });
      });

      $skipJs
    }

    // Retry SDK init — it may not be available immediately
    function waitForSDK(attempts) {
      if (typeof Stream !== 'undefined') {
        initPlayer();
      } else if (attempts > 0) {
        setTimeout(function() { waitForSDK(attempts - 1); }, 300);
      } else {
        send({ type: 'sdk_unavailable', message: 'Stream SDK not loaded' });
      }
    }

    // Try on iframe load and also immediately
    document.getElementById('player').addEventListener('load', function() {
      waitForSDK(15);
    });
    waitForSDK(5);

    // Prevent right-click context menu
    document.addEventListener('contextmenu', function(e) { e.preventDefault(); });
  </script>
</body>
</html>
''';
  }

  // ── Event handler ──────────────────────────────────────────────────────────
  void _handleEvent(String message) {
    try {
      final data = json.decode(message) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';
      final position = (data['position'] as num?)?.toInt() ?? 0;
      final duration = (data['duration'] as num?)?.toInt() ?? 0;

      switch (type) {
        case 'ready':
          debugPrint('✅ Video player ready, duration: ${duration}s');
          return;
        case 'sdk_unavailable':
          debugPrint('⚠️ Cloudflare Stream SDK unavailable');
          return;
        case 'error':
          debugPrint('❌ Player error: ${data['message']}');
          return;
        case 'start':
          if (!_hasStarted) {
            _hasStarted = true;
            widget.onStart?.call();
          }
          break;
        case 'complete':
          if (!_isCompleted) {
            _isCompleted = true;
            if (mounted) setState(() {});
            widget.onComplete?.call();
          }
          return;
        case 'play':
        case 'pause':
          break; // state tracked by native controls
      }

      // Milestone tracking
      if (duration > 0 && !_isCompleted &&
          (type == 'progress' || type == 'complete')) {
        final pct = (position / duration) * 100;
        for (final m in _milestones) {
          if (pct >= m && !_reportedMilestones.contains(m)) {
            _reportedMilestones.add(m);
            widget.onProgress(position, duration, 'milestone_$m');
          }
        }
      }

      if (!_isCompleted &&
          duration > 0 &&
          (type == 'progress' || type == 'play' || type == 'pause')) {
        widget.onProgress(position, duration, type);
      }
    } catch (e) {
      debugPrint('❌ Event parse error: $e  raw=$message');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Error state
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage ?? 'Failed to load video',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_retryCount < _maxRetries)
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: Text('Retry (${_maxRetries - _retryCount} left)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // The video area — either poster or live WebView
    final videoArea = Stack(
      children: [
        // ── Tap-to-play poster (before first tap) ──────────────────────────
        if (!_iframeLoaded)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onTapPlay,
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: const Icon(Icons.play_arrow,
                            color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tap to play',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── WebView (after first tap) ───────────────────────────────────────
        if (_iframeLoaded && _controller != null)
          Positioned.fill(child: WebViewWidget(controller: _controller!)),

        // ── Loading spinner ─────────────────────────────────────────────────
        if (_isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black54,
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          ),

        // ── Fullscreen button (top-right corner, always visible after load) ─
        if (_iframeLoaded && !_isLoading)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _toggleFullscreen,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

        // ── Completion overlay ──────────────────────────────────────────────
        if (_isCompleted)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.88),
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
                      child: const Icon(Icons.check_circle,
                          color: Colors.green, size: 72),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Video Completed!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.5),
                            width: 1.5),
                      ),
                      child: const Text(
                        '✓ Progress saved',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    // Fullscreen: expand to fill entire screen with back gesture support
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: PopScope(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) _exitFullscreen();
          },
          child: SizedBox.expand(child: videoArea),
        ),
      );
    }

    // Normal: 16:9 aspect ratio
    return AspectRatio(aspectRatio: 16 / 9, child: videoArea);
  }
}
