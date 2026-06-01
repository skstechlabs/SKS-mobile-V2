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
    // Exit fullscreen if active
    _controller?.runJavaScript('exitFullscreenMode();');
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

  /// Build HTML with HLS.js player
  /// HLS.js provides:
  /// - Adaptive bitrate streaming
  /// - Automatic quality switching
  /// - Buffer management
  /// - Error recovery
  /// - Works on all browsers (including those without native HLS support)
  /// - Native fullscreen API for seamless fullscreen transitions
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
      position: fixed;
    }
    #container {
      position: fixed;
      width: 100%;
      height: 100%;
      background: #000;
    }
    /* Fullscreen styles */
    #container:-webkit-full-screen {
      width: 100%;
      height: 100%;
    }
    #container:-moz-full-screen {
      width: 100%;
      height: 100%;
    }
    #container:-ms-fullscreen {
      width: 100%;
      height: 100%;
    }
    #container:fullscreen {
      width: 100%;
      height: 100%;
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
      background: linear-gradient(transparent, rgba(0,0,0,0.9));
      padding: 30px 15px 15px;
      z-index: 10;
      opacity: 0;
      transition: opacity 0.3s ease-in-out;
      pointer-events: none;
      will-change: opacity;
    }
    .controls.show {
      opacity: 1;
      pointer-events: auto;
    }
    #container:hover .controls {
      opacity: 1;
      pointer-events: auto;
    }
    .progress-container {
      width: 100%;
      margin-bottom: 12px;
    }
    .progress-bar {
      width: 100%;
      height: 5px;
      background: rgba(255,255,255,0.3);
      border-radius: 3px;
      cursor: pointer;
      position: relative;
    }
    .progress-bar:hover {
      height: 7px;
    }
    .progress-filled {
      height: 100%;
      background: #ff6b00;
      border-radius: 3px;
      width: 0%;
      transition: width 0.1s;
      position: relative;
    }
    .progress-handle {
      position: absolute;
      right: -6px;
      top: 50%;
      transform: translateY(-50%);
      width: 12px;
      height: 12px;
      background: #ff6b00;
      border-radius: 50%;
      opacity: 0;
      transition: opacity 0.2s;
    }
    .progress-bar:hover .progress-handle {
      opacity: 1;
    }
    .control-buttons {
      display: flex;
      align-items: center;
      justify-content: space-between;
      color: white;
      font-family: Arial, sans-serif;
      font-size: 14px;
    }
    .left-controls, .right-controls {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .btn {
      background: none;
      border: none;
      color: white;
      cursor: pointer;
      padding: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 4px;
      transition: background 0.2s;
      min-width: 36px;
      height: 36px;
    }
    .btn:hover {
      background: rgba(255,255,255,0.1);
    }
    .btn svg {
      width: 24px;
      height: 24px;
      fill: white;
    }
    .time {
      font-size: 13px;
      font-weight: 500;
      margin: 0 4px;
      min-width: 100px;
      text-align: center;
    }
    .speed-selector, .quality-selector {
      position: relative;
    }
    .speed-menu, .quality-menu {
      position: absolute;
      bottom: 100%;
      right: 0;
      background: rgba(28,28,28,0.95);
      border-radius: 8px;
      padding: 8px 0;
      margin-bottom: 8px;
      display: none;
      min-width: 120px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.3);
    }
    .speed-menu.show, .quality-menu.show {
      display: block;
    }
    .speed-option, .quality-option {
      padding: 10px 16px;
      cursor: pointer;
      white-space: nowrap;
      font-size: 14px;
      transition: background 0.2s;
    }
    .speed-option:hover, .quality-option:hover {
      background: rgba(255,255,255,0.1);
    }
    .speed-option.active, .quality-option.active {
      color: #ff6b00;
      font-weight: 600;
    }
    .volume-container {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .volume-slider {
      width: 0;
      opacity: 0;
      transition: width 0.3s, opacity 0.3s;
      -webkit-appearance: none;
      height: 4px;
      background: rgba(255,255,255,0.3);
      border-radius: 2px;
      outline: none;
    }
    .volume-container:hover .volume-slider {
      width: 60px;
      opacity: 1;
    }
    .volume-slider::-webkit-slider-thumb {
      -webkit-appearance: none;
      width: 12px;
      height: 12px;
      background: #ff6b00;
      border-radius: 50%;
      cursor: pointer;
    }
    .volume-slider::-moz-range-thumb {
      width: 12px;
      height: 12px;
      background: #ff6b00;
      border-radius: 50%;
      cursor: pointer;
      border: none;
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
      <div class="progress-container">
        <div class="progress-bar" id="progress-bar">
          <div class="progress-filled" id="progress-filled">
            <div class="progress-handle"></div>
          </div>
        </div>
      </div>
      <div class="control-buttons">
        <div class="left-controls">
          <button class="btn" id="play-btn" title="Play/Pause">
            <svg viewBox="0 0 24 24" id="play-icon">
              <path d="M8 5v14l11-7z"/>
            </svg>
            <svg viewBox="0 0 24 24" id="pause-icon" style="display:none;">
              <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z"/>
            </svg>
          </button>
          <div class="volume-container">
            <button class="btn" id="volume-btn" title="Mute/Unmute">
              <svg viewBox="0 0 24 24" id="volume-icon">
                <path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02z"/>
              </svg>
              <svg viewBox="0 0 24 24" id="mute-icon" style="display:none;">
                <path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z"/>
              </svg>
            </button>
            <input type="range" class="volume-slider" id="volume-slider" min="0" max="100" value="100">
          </div>
          <span class="time" id="time">0:00 / 0:00</span>
        </div>
        <div class="right-controls">
          <div class="speed-selector">
            <button class="btn" id="speed-btn" title="Playback Speed">1x</button>
            <div class="speed-menu" id="speed-menu">
              <div class="speed-option" data-speed="0.25">0.25x</div>
              <div class="speed-option" data-speed="0.5">0.5x</div>
              <div class="speed-option" data-speed="0.75">0.75x</div>
              <div class="speed-option active" data-speed="1">Normal</div>
              <div class="speed-option" data-speed="1.25">1.25x</div>
              <div class="speed-option" data-speed="1.5">1.5x</div>
              <div class="speed-option" data-speed="1.75">1.75x</div>
              <div class="speed-option" data-speed="2">2x</div>
            </div>
          </div>
          <div class="quality-selector">
            <button class="btn" id="quality-btn" title="Quality">Auto</button>
            <div class="quality-menu" id="quality-menu"></div>
          </div>
          <button class="btn" id="fullscreen-btn" title="Fullscreen">
            <svg viewBox="0 0 24 24" id="fullscreen-icon">
              <path d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z"/>
            </svg>
            <svg viewBox="0 0 24 24" id="fullscreen-exit-icon" style="display:none;">
              <path d="M5 16h3v3h2v-5H5v2zm3-8H5v2h5V5H8v3zm6 11h2v-3h3v-2h-5v5zm2-11V5h-2v5h5V8h-3z"/>
            </svg>
          </button>
        </div>
      </div>
    </div>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
  <script>
    var video = document.getElementById('video');
    var playBtn = document.getElementById('play-btn');
    var playIcon = document.getElementById('play-icon');
    var pauseIcon = document.getElementById('pause-icon');
    var progressBar = document.getElementById('progress-bar');
    var progressFilled = document.getElementById('progress-filled');
    var timeDisplay = document.getElementById('time');
    var volumeBtn = document.getElementById('volume-btn');
    var volumeIcon = document.getElementById('volume-icon');
    var muteIcon = document.getElementById('mute-icon');
    var volumeSlider = document.getElementById('volume-slider');
    var speedBtn = document.getElementById('speed-btn');
    var speedMenu = document.getElementById('speed-menu');
    var qualityBtn = document.getElementById('quality-btn');
    var qualityMenu = document.getElementById('quality-menu');
    var fullscreenBtn = document.getElementById('fullscreen-btn');
    var fullscreenIcon = document.getElementById('fullscreen-icon');
    var fullscreenExitIcon = document.getElementById('fullscreen-exit-icon');
    var container = document.getElementById('container');
    var playOverlay = document.getElementById('play-overlay');
    
    var hls = null;
    var isCompleted = false;
    var hasStarted = false;
    var lastReportedTime = 0;
    var hideControlsTimeout = null;
    var controlsElement = document.querySelector('.controls');
    var isFullscreen = false;

    function send(obj) {
      try { FlutterChannel.postMessage(JSON.stringify(obj)); } catch(e) {}
    }

    // Fullscreen functions
    function enterFullscreen() {
      var elem = container;
      if (elem.requestFullscreen) {
        elem.requestFullscreen();
      } else if (elem.webkitRequestFullscreen) {
        elem.webkitRequestFullscreen();
      } else if (elem.mozRequestFullScreen) {
        elem.mozRequestFullScreen();
      } else if (elem.msRequestFullscreen) {
        elem.msRequestFullscreen();
      }
    }

    function exitFullscreenMode() {
      if (document.exitFullscreen) {
        document.exitFullscreen();
      } else if (document.webkitExitFullscreen) {
        document.webkitExitFullscreen();
      } else if (document.mozCancelFullScreen) {
        document.mozCancelFullScreen();
      } else if (document.msExitFullscreen) {
        document.msExitFullscreen();
      }
    }

    function toggleFullscreen() {
      if (!isFullscreen) {
        enterFullscreen();
      } else {
        exitFullscreenMode();
      }
    }

    // Listen for fullscreen changes
    document.addEventListener('fullscreenchange', handleFullscreenChange);
    document.addEventListener('webkitfullscreenchange', handleFullscreenChange);
    document.addEventListener('mozfullscreenchange', handleFullscreenChange);
    document.addEventListener('MSFullscreenChange', handleFullscreenChange);

    function handleFullscreenChange() {
      isFullscreen = !!(document.fullscreenElement || 
                        document.webkitFullscreenElement || 
                        document.mozFullScreenElement ||
                        document.msFullscreenElement);
      
      // Update fullscreen button icon
      if (isFullscreen) {
        fullscreenIcon.style.display = 'none';
        fullscreenExitIcon.style.display = 'block';
      } else {
        fullscreenIcon.style.display = 'block';
        fullscreenExitIcon.style.display = 'none';
      }
      
      // Show controls briefly when entering/exiting fullscreen
      showControls();
      
      send({ type: 'fullscreenChange', isFullscreen: isFullscreen });
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
        
        // ═══════════════════════════════════════════════════════════════
        // ULTRA-SMOOTH QUALITY SWITCHING CONFIGURATION
        // ═══════════════════════════════════════════════════════════════
        
        // Buffer settings - CRITICAL for seamless quality transitions
        backBufferLength: 90,           // Keep 90s of back buffer
        maxBufferLength: 60,            // Forward buffer: 60s
        maxMaxBufferLength: 120,        // Max forward buffer: 120s
        maxBufferSize: 150 * 1000 * 1000, // 150MB buffer (increased)
        maxBufferHole: 0.5,             // Reduced for smoother playback
        highBufferWatchdogPeriod: 2,    // Check buffer health every 2s
        nudgeOffset: 0.05,              // Smaller nudge for smoother transitions
        nudgeMaxRetry: 10,              // More retries for stability
        maxFragLookUpTolerance: 0.25,   // Tighter fragment lookup
        
        // Progressive loading - ESSENTIAL for smooth quality switches
        progressive: true,
        
        // Live streaming settings
        liveSyncDurationCount: 3,
        liveMaxLatencyDurationCount: 10,
        liveDurationInfinity: false,
        
        // Encryption
        enableSoftwareAES: true,
        
        // Manifest loading - more retries and longer timeouts
        manifestLoadingTimeOut: 20000,
        manifestLoadingMaxRetry: 5,
        manifestLoadingRetryDelay: 2000,
        
        // Level loading - more retries and longer timeouts
        levelLoadingTimeOut: 20000,
        levelLoadingMaxRetry: 6,
        levelLoadingRetryDelay: 2000,
        
        // Fragment loading - more retries and longer timeouts
        fragLoadingTimeOut: 30000,
        fragLoadingMaxRetry: 10,
        fragLoadingRetryDelay: 2000,
        
        // ═══════════════════════════════════════════════════════════════
        // QUALITY SWITCHING - ZERO FLICKER CONFIGURATION
        // ═══════════════════════════════════════════════════════════════
        startLevel: -1,                 // Auto quality
        abrEwmaDefaultEstimate: 500000,
        abrBandWidthFactor: 0.95,
        abrBandWidthUpFactor: 0.7,
        abrMaxWithRealBitrate: false,
        
        // CRITICAL: Smooth level switching without video interruption
        capLevelToPlayerSize: false,    // Don't limit quality by player size
        capLevelOnFPSDrop: false,       // Don't drop quality on FPS issues
        
        // Starvation settings - prevent buffering during quality switch
        maxStarvationDelay: 4,
        maxLoadingDelay: 4,
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
          qualityMenu.innerHTML = '<div class="quality-option active" data-level="-1">Auto</div>';
          hls.levels.forEach(function(level, index) {
            var height = level.height;
            var label = height + 'p';
            console.log('Quality level ' + index + ':', label, level.bitrate);
            qualityMenu.innerHTML += '<div class="quality-option" data-level="' + index + '">' + label + '</div>';
          });
          
          // Quality selection with ULTRA-SMOOTH switching
          qualityMenu.querySelectorAll('.quality-option').forEach(function(option) {
            option.addEventListener('click', function() {
              var level = parseInt(this.getAttribute('data-level'));
              var wasPlaying = !video.paused;
              var currentTime = video.currentTime;
              var currentVolume = video.volume;
              var wasMuted = video.muted;
              
              console.log('Switching quality to level:', level, 'at time:', currentTime);
              
              // CRITICAL: Use nextLevel ONLY for seamless switching
              // Do NOT pause or seek - let HLS.js handle the transition
              if (level === -1) {
                // Auto quality - smooth transition
                hls.nextLevel = -1;
                qualityBtn.textContent = 'Auto';
              } else {
                // Manual quality - nextLevel ensures smooth transition without interruption
                hls.nextLevel = level;
                qualityBtn.textContent = hls.levels[level].height + 'p';
              }
              
              // Update active state
              qualityMenu.querySelectorAll('.quality-option').forEach(function(opt) {
                opt.classList.remove('active');
              });
              this.classList.add('active');
              
              // Close menu
              qualityMenu.classList.remove('show');
              
              // Preserve playback state - video continues playing seamlessly
              // No need to call play() again - HLS.js handles it
              console.log('Quality switch initiated - seamless transition in progress');
            });
          });
        }
      });
      
      // ═══════════════════════════════════════════════════════════════
      // SEAMLESS QUALITY SWITCHING - NO FLICKER, NO PAUSE
      // ═══════════════════════════════════════════════════════════════
      
      hls.on(Hls.Events.LEVEL_SWITCHING, function(event, data) {
        console.log('🔄 Switching to level:', data.level, '- seamless transition');
        // Don't pause, don't show loading - HLS.js handles it smoothly
      });
      
      hls.on(Hls.Events.LEVEL_SWITCHED, function(event, data) {
        console.log('✅ Switched to level:', data.level, hls.levels[data.level].height + 'p');
        
        // Update quality button to show current level (UI only, no video interruption)
        if (hls.currentLevel === -1 || hls.nextLevel === -1) {
          var autoLevel = hls.levels[hls.loadLevel] || hls.levels[0];
          qualityBtn.textContent = 'Auto (' + autoLevel.height + 'p)';
        } else {
          qualityBtn.textContent = hls.levels[data.level].height + 'p';
        }
      });
      
      // Track buffering during quality switch (should be minimal)
      hls.on(Hls.Events.BUFFER_APPENDING, function(event, data) {
        // Buffer is being filled - quality switch is in progress
        // Video continues playing from existing buffer
      });
      
      hls.on(Hls.Events.BUFFER_APPENDED, function(event, data) {
        // New quality buffer appended - transition complete
      });
      
      // Track auto level changes
      hls.on(Hls.Events.LEVEL_LOADED, function(event, data) {
        // Update Auto button to show current auto-selected quality
        if (hls.currentLevel === -1 && hls.loadLevel >= 0) {
          var currentLevel = hls.levels[hls.loadLevel];
          if (currentLevel) {
            qualityBtn.textContent = 'Auto (' + currentLevel.height + 'p)';
          }
        }
      });
      
      // Track fragment loading (reduced logging)
      hls.on(Hls.Events.FRAG_LOADING, function(event, data) {
        // Silent - only log if debugging
      });
      
      hls.on(Hls.Events.FRAG_LOADED, function(event, data) {
        // Silent - only log if debugging
      });
      
      hls.on(Hls.Events.FRAG_LOAD_EMERGENCY_ABORTED, function(event, data) {
        console.warn('Fragment load aborted:', data.frag.sn);
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
      playIcon.style.display = 'none';
      pauseIcon.style.display = 'block';
      
      // Hide controls after 3 seconds when playing
      showControls();
      
      send({
        type: 'play',
        position: Math.floor(video.currentTime || 0),
        duration: Math.floor(video.duration || 0)
      });
    });

    video.addEventListener('pause', function() {
      playIcon.style.display = 'block';
      pauseIcon.style.display = 'none';
      
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
    
    playBtn.addEventListener('click', function(e) {
      e.stopPropagation();
      if (video.paused) {
        video.play();
      } else {
        video.pause();
      }
    });

    // Volume controls
    volumeBtn.addEventListener('click', function(e) {
      e.stopPropagation();
      if (video.muted || video.volume === 0) {
        video.muted = false;
        video.volume = volumeSlider.value / 100;
        volumeIcon.style.display = 'block';
        muteIcon.style.display = 'none';
      } else {
        video.muted = true;
        volumeIcon.style.display = 'none';
        muteIcon.style.display = 'block';
      }
    });

    volumeSlider.addEventListener('input', function(e) {
      e.stopPropagation();
      var volume = this.value / 100;
      video.volume = volume;
      video.muted = volume === 0;
      if (volume === 0) {
        volumeIcon.style.display = 'none';
        muteIcon.style.display = 'block';
      } else {
        volumeIcon.style.display = 'block';
        muteIcon.style.display = 'none';
      }
    });

    video.addEventListener('volumechange', function() {
      volumeSlider.value = video.muted ? 0 : video.volume * 100;
    });

    // Progress bar
    progressBar.addEventListener('click', function(e) {
      e.stopPropagation();
      var rect = progressBar.getBoundingClientRect();
      var percent = (e.clientX - rect.left) / rect.width;
      video.currentTime = percent * video.duration;
    });

    // Speed controls
    speedBtn.addEventListener('click', function(e) {
      e.stopPropagation();
      speedMenu.classList.toggle('show');
      qualityMenu.classList.remove('show');
    });

    speedMenu.querySelectorAll('.speed-option').forEach(function(option) {
      option.addEventListener('click', function(e) {
        e.stopPropagation();
        var speed = parseFloat(this.getAttribute('data-speed'));
        video.playbackRate = speed;
        speedMenu.classList.remove('show');
        
        speedMenu.querySelectorAll('.speed-option').forEach(function(opt) {
          opt.classList.remove('active');
        });
        this.classList.add('active');
        
        if (speed === 1) {
          speedBtn.textContent = '1x';
        } else {
          speedBtn.textContent = speed + 'x';
        }
      });
    });

    // Quality controls
    qualityBtn.addEventListener('click', function(e) {
      e.stopPropagation();
      qualityMenu.classList.toggle('show');
      speedMenu.classList.remove('show');
    });

    // Fullscreen
    fullscreenBtn.addEventListener('click', function(e) {
      e.stopPropagation();
      toggleFullscreen();
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

    // Close menus when clicking outside
    document.addEventListener('click', function(e) {
      if (!speedBtn.contains(e.target) && !speedMenu.contains(e.target)) {
        speedMenu.classList.remove('show');
      }
      if (!qualityBtn.contains(e.target) && !qualityMenu.contains(e.target)) {
        qualityMenu.classList.remove('show');
      }
    });

    // Keyboard shortcuts
    document.addEventListener('keydown', function(e) {
      switch(e.key) {
        case ' ':
        case 'k':
          e.preventDefault();
          if (video.paused) video.play();
          else video.pause();
          break;
        case 'ArrowLeft':
          e.preventDefault();
          video.currentTime = Math.max(0, video.currentTime - 5);
          break;
        case 'ArrowRight':
          e.preventDefault();
          video.currentTime = Math.min(video.duration, video.currentTime + 5);
          break;
        case 'ArrowUp':
          e.preventDefault();
          video.volume = Math.min(1, video.volume + 0.1);
          break;
        case 'ArrowDown':
          e.preventDefault();
          video.volume = Math.max(0, video.volume - 0.1);
          break;
        case 'm':
          e.preventDefault();
          video.muted = !video.muted;
          break;
        case 'f':
          e.preventDefault();
          toggleFullscreen();
          break;
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
        case 'fullscreenChange':
          // Fullscreen state changed in JS - just log it
          debugPrint('🖥️ Fullscreen: ${data['isFullscreen']}');
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

    // Build WebView widget once with GlobalKey to preserve state across rebuilds
    // This ensures the video never restarts when toggling fullscreen
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          // WebView - NEVER conditionally rendered, always present
          if (_controller != null)
            Positioned.fill(
              child: WebViewWidget(
                key: _webViewKey, // Preserve state across rebuilds
                controller: _controller!,
              ),
            ),

          // Loading overlay - ONLY on initial load
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
      ),
    );
  }
}
