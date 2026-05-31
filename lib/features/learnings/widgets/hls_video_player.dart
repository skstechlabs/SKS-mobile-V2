import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

/// HLS Video Player for multi-language video streaming
/// 
/// Supports:
/// - HLS adaptive bitrate streaming (1080p, 720p, 480p, 360p)
/// - Automatic quality switching based on network speed
/// - Progress tracking and completion detection
/// - Skip prevention
/// - Fullscreen support with seamless rotation
/// - Smooth streaming for high concurrent users
/// - Single-tap play with thumbnail preview
class HLSVideoPlayer extends StatefulWidget {
  final String hlsUrl;
  final String? thumbnailUrl;
  final int lastPositionSeconds;
  final bool allowSkip;
  final Function(int positionSeconds, int durationSeconds, String eventType)
      onProgress;
  final VoidCallback? onComplete;
  final VoidCallback? onStart;

  const HLSVideoPlayer({
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
  State<HLSVideoPlayer> createState() => _HLSVideoPlayerState();
}

class _HLSVideoPlayerState extends State<HLSVideoPlayer> {
  WebViewController? _controller;
  final GlobalKey _webViewKey = GlobalKey(); // Preserve WebView across rebuilds

  bool _isInitialLoading = true; // Only show loader on first load
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
  void initState() {
    super.initState();
    // Initialize player immediately
    _initWebView();
  }

  @override
  void dispose() {
    if (_isFullscreen) _exitFullscreen();
    super.dispose();
  }

  void _initWebView() {
    if (widget.hlsUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Invalid video URL';
        _isInitialLoading = false;
      });
      return;
    }

    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (_) {
            // Don't show loading overlay after initial load
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isInitialLoading = false); // Hide loader permanently
              // Seek to last position if available
              if (widget.lastPositionSeconds > 0) {
                _controller?.runJavaScript(
                    'if(video && video.duration > 0) { video.currentTime = ${widget.lastPositionSeconds}; }');
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame == true) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage = 'Failed to load video. Tap retry.';
                  _isInitialLoading = false;
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
          _isInitialLoading = false;
        });
      }
    }
  }

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
      _isInitialLoading = true;
    });
    _initWebView();
  }

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

  /// Build HTML with HLS.js player
  /// HLS.js provides:
  /// - Adaptive bitrate streaming
  /// - Automatic quality switching
  /// - Buffer management
  /// - Error recovery
  /// - Works on all browsers (including those without native HLS support)
  String _buildHtml() {
    final skipJs = widget.allowSkip
        ? ''
        : r'''
      var maxWatchedTime = 0;
      video.addEventListener('timeupdate', function() {
        var t = video.currentTime || 0;
        if (t > maxWatchedTime) maxWatchedTime = t;
      });
      video.addEventListener('seeking', function() {
        var t = video.currentTime || 0;
        if (t > maxWatchedTime + 5) {
          video.currentTime = maxWatchedTime;
        }
      });
    ''';

    final thumbnailHtml = widget.thumbnailUrl != null
        ? 'poster="${widget.thumbnailUrl}"'
        : '';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no">
  <style>
    * { 
      margin: 0; 
      padding: 0; 
      box-sizing: border-box;
      -webkit-tap-highlight-color: transparent;
    }
    html, body { 
      width: 100%; 
      height: 100%; 
      background: #000; 
      overflow: hidden;
      position: fixed; /* Prevent scrolling flicker */
    }
    #container {
      position: fixed; /* Prevent any movement */
      width: 100%;
      height: 100%;
      background: #000;
    }
    #video {
      position: absolute;
      top: 0; 
      left: 0;
      width: 100%; 
      height: 100%;
      object-fit: contain;
      background: #000;
    }
    #poster {
      z-index: 1;
    }
    #video[poster] {
      background: #000;
    }
    .play-overlay {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      background: rgba(0,0,0,0.3);
      z-index: 5;
      cursor: pointer;
      transition: opacity 0.3s;
    }
    .play-overlay.hidden {
      opacity: 0;
      pointer-events: none;
    }
    .play-button {
      width: 80px;
      height: 80px;
      border-radius: 50%;
      background: rgba(255,255,255,0.15);
      border: 2.5px solid white;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: transform 0.2s, background 0.2s;
    }
    .play-button:hover {
      transform: scale(1.1);
      background: rgba(255,255,255,0.25);
    }
    .play-button svg {
      width: 48px;
      height: 48px;
      fill: white;
      margin-left: 4px;
    }
    .controls {
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      background: linear-gradient(transparent, rgba(0,0,0,0.8));
      padding: 20px 15px 15px;
      z-index: 10;
      opacity: 0;
      transition: opacity 0.3s ease-in-out;
      pointer-events: none;
      will-change: opacity; /* GPU acceleration */
    }
    .controls.show {
      opacity: 1;
      pointer-events: auto;
    }
    #container:hover .controls {
      opacity: 1;
      pointer-events: auto;
    }
    .progress-bar {
      width: 100%;
      height: 4px;
      background: rgba(255,255,255,0.3);
      border-radius: 2px;
      cursor: pointer;
      margin-bottom: 10px;
    }
    .progress-filled {
      height: 100%;
      background: #ff6b00;
      border-radius: 2px;
      width: 0%;
      transition: width 0.1s;
    }
    .control-buttons {
      display: flex;
      align-items: center;
      justify-content: space-between;
      color: white;
      font-family: Arial, sans-serif;
      font-size: 14px;
    }
    .btn {
      background: none;
      border: none;
      color: white;
      font-size: 24px;
      cursor: pointer;
      padding: 5px;
      display: flex;
      align-items: center;
    }
    .time {
      font-size: 13px;
      margin: 0 10px;
    }
    .quality-selector {
      position: relative;
    }
    .quality-menu {
      position: absolute;
      bottom: 100%;
      right: 0;
      background: rgba(0,0,0,0.9);
      border-radius: 4px;
      padding: 5px 0;
      margin-bottom: 5px;
      display: none;
    }
    .quality-menu.show {
      display: block;
    }
    .quality-option {
      padding: 8px 15px;
      cursor: pointer;
      white-space: nowrap;
      font-size: 13px;
    }
    .quality-option:hover {
      background: rgba(255,255,255,0.1);
    }
    .quality-option.active {
      color: #ff6b00;
    }
  </style>
</head>
<body>
  <div id="container">
    <video id="video" playsinline webkit-playsinline $thumbnailHtml></video>
    
    <div class="play-overlay" id="play-overlay">
      <div class="play-button">
        <svg viewBox="0 0 24 24">
          <path d="M8 5v14l11-7z"/>
        </svg>
      </div>
    </div>
    
    <div class="controls">
      <div class="progress-bar" id="progress-bar">
        <div class="progress-filled" id="progress-filled"></div>
      </div>
      <div class="control-buttons">
        <div style="display:flex;align-items:center;">
          <button class="btn" id="play-btn">▶</button>
          <span class="time" id="time">0:00 / 0:00</span>
        </div>
        <div style="display:flex;align-items:center;">
          <div class="quality-selector">
            <button class="btn" id="quality-btn">HD</button>
            <div class="quality-menu" id="quality-menu"></div>
          </div>
          <button class="btn" id="fullscreen-btn">⛶</button>
        </div>
      </div>
    </div>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
  <script>
    var video = document.getElementById('video');
    var playBtn = document.getElementById('play-btn');
    var progressBar = document.getElementById('progress-bar');
    var progressFilled = document.getElementById('progress-filled');
    var timeDisplay = document.getElementById('time');
    var qualityBtn = document.getElementById('quality-btn');
    var qualityMenu = document.getElementById('quality-menu');
    var fullscreenBtn = document.getElementById('fullscreen-btn');
    var container = document.getElementById('container');
    var playOverlay = document.getElementById('play-overlay');
    
    var hls = null;
    var isCompleted = false;
    var hasStarted = false;
    var lastReportedTime = 0;
    var hideControlsTimeout = null;
    var controlsElement = document.querySelector('.controls');

    function send(obj) {
      try { FlutterChannel.postMessage(JSON.stringify(obj)); } catch(e) {}
    }

    function formatTime(seconds) {
      var mins = Math.floor(seconds / 60);
      var secs = Math.floor(seconds % 60);
      return mins + ':' + (secs < 10 ? '0' : '') + secs;
    }

    function updateProgress() {
      if (video.duration > 0) {
        var percent = (video.currentTime / video.duration) * 100;
        progressFilled.style.width = percent + '%';
        timeDisplay.textContent = formatTime(video.currentTime) + ' / ' + formatTime(video.duration);
      }
    }

    function showControls() {
      controlsElement.classList.add('show');
      clearTimeout(hideControlsTimeout);
      
      // Auto-hide controls after 3 seconds if video is playing
      if (!video.paused) {
        hideControlsTimeout = setTimeout(function() {
          controlsElement.classList.remove('show');
        }, 3000);
      }
    }

    function hideControls() {
      controlsElement.classList.remove('show');
    }
    
    function hidePlayOverlay() {
      playOverlay.classList.add('hidden');
      setTimeout(function() {
        playOverlay.style.display = 'none';
      }, 300);
    }
    
    function playVideo() {
      hidePlayOverlay();
      video.play().catch(function(err) {
        console.error('Play failed:', err);
      });
    }

    // Initialize HLS
    if (Hls.isSupported()) {
      hls = new Hls({
        enableWorker: true,
        lowLatencyMode: false,
        
        // Buffer settings - more conservative for mobile
        backBufferLength: 90,
        maxBufferLength: 60,        // Increased from 30
        maxMaxBufferLength: 120,    // Increased from 60
        maxBufferSize: 120 * 1000 * 1000, // Increased buffer size
        maxBufferHole: 1.0,         // Increased tolerance
        highBufferWatchdogPeriod: 3,
        nudgeOffset: 0.1,
        nudgeMaxRetry: 5,           // Increased retries
        maxFragLookUpTolerance: 0.5,
        
        // Live streaming settings
        liveSyncDurationCount: 3,
        liveMaxLatencyDurationCount: 10,
        liveDurationInfinity: false,
        
        // Encryption
        enableSoftwareAES: true,
        
        // Manifest loading - more retries and longer timeouts
        manifestLoadingTimeOut: 20000,  // Increased from 10s
        manifestLoadingMaxRetry: 5,     // Increased from 3
        manifestLoadingRetryDelay: 2000, // Increased from 1s
        
        // Level loading - more retries and longer timeouts
        levelLoadingTimeOut: 20000,     // Increased from 10s
        levelLoadingMaxRetry: 6,        // Increased from 4
        levelLoadingRetryDelay: 2000,   // Increased from 1s
        
        // Fragment loading - more retries and longer timeouts
        fragLoadingTimeOut: 30000,      // Increased from 20s
        fragLoadingMaxRetry: 10,        // Increased from 6
        fragLoadingRetryDelay: 2000,    // Increased from 1s
        
        // Quality settings
        startLevel: -1, // Auto quality
        abrEwmaDefaultEstimate: 500000,
        abrBandWidthFactor: 0.95,
        abrBandWidthUpFactor: 0.7,
        abrMaxWithRealBitrate: false,
        
        // Starvation settings
        maxStarvationDelay: 6,          // Increased from 4
        maxLoadingDelay: 6,             // Increased from 4
        minAutoBitrate: 0,
        
        // Enable debug logging
        debug: false
      });

      hls.loadSource('${widget.hlsUrl}');
      hls.attachMedia(video);

      hls.on(Hls.Events.MANIFEST_PARSED, function(event, data) {
        console.log('Manifest parsed, levels:', hls.levels.length);
        send({ type: 'ready', duration: Math.floor(video.duration || 0) });
        
        // Build quality menu
        if (hls.levels.length > 1) {
          qualityMenu.innerHTML = '<div class="quality-option" data-level="-1">Auto</div>';
          hls.levels.forEach(function(level, index) {
            var height = level.height;
            var label = height + 'p';
            console.log('Quality level ' + index + ':', label, level.bitrate);
            qualityMenu.innerHTML += '<div class="quality-option" data-level="' + index + '">' + label + '</div>';
          });
          
          // Quality selection
          qualityMenu.querySelectorAll('.quality-option').forEach(function(option) {
            option.addEventListener('click', function() {
              var level = parseInt(this.getAttribute('data-level'));
              hls.currentLevel = level;
              qualityMenu.classList.remove('show');
              
              qualityMenu.querySelectorAll('.quality-option').forEach(function(opt) {
                opt.classList.remove('active');
              });
              this.classList.add('active');
              
              if (level === -1) {
                qualityBtn.textContent = 'Auto';
              } else {
                qualityBtn.textContent = hls.levels[level].height + 'p';
              }
            });
          });
        }
      });
      
      // Track fragment loading
      hls.on(Hls.Events.FRAG_LOADING, function(event, data) {
        console.log('Loading fragment:', data.frag.sn, 'level:', data.frag.level);
      });
      
      hls.on(Hls.Events.FRAG_LOADED, function(event, data) {
        console.log('Fragment loaded:', data.frag.sn, 'duration:', data.frag.duration);
      });
      
      hls.on(Hls.Events.FRAG_LOAD_EMERGENCY_ABORTED, function(event, data) {
        console.log('Fragment load aborted:', data.frag.sn);
      });

      var networkErrorCount = 0;
      var mediaErrorCount = 0;
      
      hls.on(Hls.Events.ERROR, function(event, data) {
        console.log('HLS Error:', data.type, data.details, data.fatal);
        
        if (data.fatal) {
          switch(data.type) {
            case Hls.ErrorTypes.NETWORK_ERROR:
              networkErrorCount++;
              console.log('Network error count:', networkErrorCount);
              
              if (networkErrorCount <= 5) {
                console.log('Attempting to recover from network error...');
                setTimeout(function() {
                  hls.startLoad();
                }, 1000 * networkErrorCount); // Exponential backoff
              } else {
                send({ type: 'error', message: 'Network error - Unable to load video' });
              }
              break;
              
            case Hls.ErrorTypes.MEDIA_ERROR:
              mediaErrorCount++;
              console.log('Media error count:', mediaErrorCount);
              
              if (mediaErrorCount <= 3) {
                console.log('Attempting to recover from media error...');
                hls.recoverMediaError();
              } else {
                console.log('Too many media errors, swapping audio codec...');
                hls.swapAudioCodec();
                hls.recoverMediaError();
              }
              break;
              
            default:
              send({ type: 'error', message: 'Fatal playback error' });
              break;
          }
        } else {
          // Non-fatal errors - just log them
          console.log('Non-fatal HLS error:', data.details);
        }
      });
    } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
      // Native HLS support (iOS/Safari)
      video.src = '${widget.hlsUrl}';
    } else {
      send({ type: 'error', message: 'HLS not supported' });
    }

    // Video events
    video.addEventListener('loadedmetadata', function() {
      updateProgress();
      // Seek to last position if provided
      if (${widget.lastPositionSeconds} > 0 && video.duration > 0) {
        video.currentTime = ${widget.lastPositionSeconds};
      }
    });

    video.addEventListener('play', function() {
      hidePlayOverlay();
      if (isCompleted) { video.pause(); return; }
      if (!hasStarted) {
        hasStarted = true;
        send({
          type: 'start',
          position: Math.floor(video.currentTime || 0),
          duration: Math.floor(video.duration || 0)
        });
      }
      playBtn.textContent = '⏸';
      
      // Hide controls after 3 seconds when playing
      showControls();
      
      send({
        type: 'play',
        position: Math.floor(video.currentTime || 0),
        duration: Math.floor(video.duration || 0)
      });
    });

    video.addEventListener('pause', function() {
      playBtn.textContent = '▶';
      
      // Show controls when paused
      showControls();
      clearTimeout(hideControlsTimeout);
      
      send({
        type: 'pause',
        position: Math.floor(video.currentTime || 0),
        duration: Math.floor(video.duration || 0)
      });
    });

    video.addEventListener('timeupdate', function() {
      updateProgress();
      var t = video.currentTime || 0;
      var d = video.duration || 0;
      if (d > 0 && Math.abs(t - lastReportedTime) >= 3) {
        lastReportedTime = t;
        send({ type: 'progress', position: Math.floor(t), duration: Math.floor(d) });
      }
    });

    video.addEventListener('ended', function() {
      if (isCompleted) return;
      isCompleted = true;
      send({
        type: 'complete',
        position: Math.floor(video.duration || 0),
        duration: Math.floor(video.duration || 0)
      });
    });

    // Controls
    playOverlay.addEventListener('click', playVideo);
    
    playBtn.addEventListener('click', function() {
      if (video.paused) {
        video.play();
      } else {
        video.pause();
      }
    });

    progressBar.addEventListener('click', function(e) {
      var rect = progressBar.getBoundingClientRect();
      var percent = (e.clientX - rect.left) / rect.width;
      video.currentTime = percent * video.duration;
    });

    qualityBtn.addEventListener('click', function() {
      qualityMenu.classList.toggle('show');
    });

    fullscreenBtn.addEventListener('click', function() {
      send({ type: 'fullscreen' });
    });

    container.addEventListener('click', function(e) {
      if (e.target === container || e.target === video) {
        if (controlsElement.classList.contains('show')) {
          hideControls();
        } else {
          showControls();
        }
      }
    });

    container.addEventListener('touchstart', function(e) {
      if (e.target === container || e.target === video) {
        if (controlsElement.classList.contains('show')) {
          hideControls();
        } else {
          showControls();
        }
      }
    });

    $skipJs

    // Prevent context menu
    document.addEventListener('contextmenu', function(e) { e.preventDefault(); });
  </script>
</body>
</html>
''';
  }

  void _handleEvent(String message) {
    try {
      final data = json.decode(message) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';
      final position = (data['position'] as num?)?.toInt() ?? 0;
      final duration = (data['duration'] as num?)?.toInt() ?? 0;

      switch (type) {
        case 'ready':
          debugPrint('✅ HLS player ready, duration: ${duration}s');
          return;
        case 'error':
          debugPrint('❌ Player error: ${data['message']}');
          return;
        case 'fullscreen':
          _toggleFullscreen();
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
          break;
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

  @override
  Widget build(BuildContext context) {
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

    // Build WebView widget once with GlobalKey to preserve state
    final webViewWidget = _controller != null
        ? WebViewWidget(
            key: _webViewKey, // Preserve across rebuilds
            controller: _controller!,
          )
        : const SizedBox.shrink();

    final videoArea = Stack(
      children: [
        // WebView always visible - NEVER conditionally rendered
        Positioned.fill(child: webViewWidget),

        // Loading overlay - ONLY on initial load, never during playback
        if (_isInitialLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),

        // Completion overlay
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

    return AspectRatio(aspectRatio: 16 / 9, child: videoArea);
  }
}
