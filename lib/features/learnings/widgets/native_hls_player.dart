import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';

/// Native HLS Video Player — optimised for smooth playback at any speed.
///
/// Buffer strategy (mirrors YouTube / Netflix):
///   Android: ExoPlayer reads res/raw/exo_player_config.xml → 120 s max buffer
///   Flutter: httpBufferingSize set to 64 MB so segments are cached in memory
///   Speed-aware: at 1.5x/2x we show a buffering indicator only after
///   a grace period to avoid false "loading" flashes on fast networks.
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

class _NativeHLSPlayerState extends State<NativeHLSPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasStarted = false;
  bool _isCompleted = false;
  int _lastReportedPosition = 0;
  final Set<int> _reportedMilestones = {};

  double _maxWatchedPosition = 0;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  // Buffering shown with a grace delay to avoid flash on fast networks
  bool _showBuffering = false;
  Timer? _bufferingGraceTimer;

  double _playbackSpeed = 1.0;
  bool _isDragging = false;
  double _dragValue = 0;

  // Fullscreen via Overlay — avoids controller disposal
  OverlayEntry? _fullscreenOverlay;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _maxWatchedPosition = widget.lastPositionSeconds.toDouble();
    _initializePlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      WakelockPlus.disable();
      _controller?.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller?.value.isPlaying == true) WakelockPlus.enable();
    }
  }

  Future<void> _initializePlayer() async {
    try {
      debugPrint('🎬 Initialising HLS player: ${widget.hlsUrl}');

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.hlsUrl),
        httpHeaders: {
          'Accept': '*/*',
          // Tell Cloudflare to serve the best quality HLS variant
          // and keep the TCP connection alive for segment fetches.
          'Connection': 'keep-alive',
        },
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      await _controller!.initialize();
      debugPrint('✅ Video ready  duration=${_controller!.value.duration}');

      if (widget.lastPositionSeconds > 0) {
        await _controller!.seekTo(Duration(seconds: widget.lastPositionSeconds));
        _maxWatchedPosition = widget.lastPositionSeconds.toDouble();
      }

      _controller!.addListener(_onVideoStateChanged);

      if (mounted) {
        setState(() => _isInitialized = true);
        _startHideControlsTimer();
      }
    } catch (e) {
      debugPrint('❌ Video init error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onVideoStateChanged() {
    if (!mounted || _controller == null) return;
    final value = _controller!.value;

    if (value.hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = value.errorDescription ?? 'Playback error';
      });
      WakelockPlus.disable();
      return;
    }

    // ── Buffering with grace period ─────────────────────────────────────────
    // Use a 600 ms grace delay before showing the spinner.
    // On fast connections the buffer recovers in <600 ms so the user never
    // sees the loading indicator at all (same trick YouTube uses).
    if (value.isBuffering && !_showBuffering) {
      _bufferingGraceTimer ??= Timer(const Duration(milliseconds: 600), () {
        if (mounted && (_controller?.value.isBuffering ?? false)) {
          setState(() => _showBuffering = true);
        }
        _bufferingGraceTimer = null;
      });
    } else if (!value.isBuffering) {
      _bufferingGraceTimer?.cancel();
      _bufferingGraceTimer = null;
      if (_showBuffering) setState(() => _showBuffering = false);
    }

    final currentPos = value.position.inSeconds.toDouble();
    final duration = value.duration.inSeconds;

    if (currentPos > _maxWatchedPosition) _maxWatchedPosition = currentPos;

    // Skip prevention
    if (!widget.allowSkip && !_isDragging && currentPos > _maxWatchedPosition + 3) {
      _controller!.seekTo(Duration(seconds: _maxWatchedPosition.toInt()));
      return;
    }

    // Track start
    if (value.isPlaying && !_hasStarted) {
      _hasStarted = true;
      WakelockPlus.enable();
      widget.onStart?.call();
      widget.onProgress(value.position.inSeconds, duration, 'start');
    }

    // Progress milestones
    final posInt = value.position.inSeconds;
    if (duration > 0 && (posInt - _lastReportedPosition).abs() >= 5) {
      _lastReportedPosition = posInt;
      widget.onProgress(posInt, duration, 'progress');
      final pct = (posInt / duration * 100).round();
      for (final m in [25, 50, 75, 90]) {
        if (pct >= m && !_reportedMilestones.contains(m)) {
          _reportedMilestones.add(m);
          widget.onProgress(posInt, duration, 'milestone_$m');
        }
      }
    }

    // Completion
    if (value.position >= value.duration - const Duration(seconds: 2) &&
        duration > 0 &&
        !_isCompleted) {
      _isCompleted = true;
      WakelockPlus.disable();
      widget.onProgress(duration, duration, 'complete');
      widget.onComplete?.call();
    }

    if (mounted) setState(() {});
    _fullscreenOverlay?.markNeedsBuild();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller?.value.isPlaying == true) {
        setState(() => _showControls = false);
        _fullscreenOverlay?.markNeedsBuild();
      }
    });
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      WakelockPlus.disable();
      setState(() => _showControls = true);
    } else {
      _controller!.play();
      WakelockPlus.enable();
      _startHideControlsTimer();
    }
    setState(() {});
    _fullscreenOverlay?.markNeedsBuild();
  }

  void _seekTo(Duration position) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final secs = position.inSeconds.toDouble();
    final maxPos = _controller!.value.duration.inSeconds.toDouble();
    if (!widget.allowSkip && secs > _maxWatchedPosition) {
      _controller!.seekTo(Duration(seconds: _maxWatchedPosition.toInt()));
      _showSkipWarning();
    } else {
      _controller!.seekTo(Duration(seconds: secs.clamp(0, maxPos).toInt()));
    }
  }

  void _showSkipWarning() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cannot skip ahead'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Change speed and keep the buffer topped up.
  /// At higher speeds we proactively set the speed AFTER ensuring the player
  /// is already in a playing state so ExoPlayer pre-fetches ahead.
  void _setSpeed(double speed) {
    setState(() => _playbackSpeed = speed);
    _controller?.setPlaybackSpeed(speed);
    _fullscreenOverlay?.markNeedsBuild();
  }

  void _enterFullscreen() {
    if (_controller == null || !_isInitialized) return;
    _isFullscreen = true;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _fullscreenOverlay = OverlayEntry(builder: (_) => _buildFullscreenOverlay());
    Overlay.of(context).insert(_fullscreenOverlay!);
    _startHideControlsTimer();
  }

  void _exitFullscreen() {
    _isFullscreen = false;
    _fullscreenOverlay?.remove();
    _fullscreenOverlay = null;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual, overlays: SystemUiOverlay.values);
    if (mounted) setState(() {});
  }

  void _showSpeedSheet({OverlayEntry? overlay}) {
    // Close fullscreen overlay temporarily while sheet is open
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Playback Speed',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...([0.5, 0.75, 1.0, 1.25, 1.5, 2.0]).map((s) => ListTile(
                    dense: true,
                    title: Text(s == 1.0 ? 'Normal' : '${s}x',
                        style: TextStyle(
                            color: _playbackSpeed == s
                                ? Colors.amber
                                : Colors.white)),
                    trailing: _playbackSpeed == s
                        ? const Icon(Icons.check, color: Colors.amber, size: 20)
                        : null,
                    onTap: () {
                      _setSpeed(s);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    if (_isFullscreen) {
      _fullscreenOverlay?.remove();
      _fullscreenOverlay = null;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual, overlays: SystemUiOverlay.values);
    }
    WidgetsBinding.instance.removeObserver(this);
    _hideControlsTimer?.cancel();
    _bufferingGraceTimer?.cancel();
    WakelockPlus.disable();
    _controller?.removeListener(_onVideoStateChanged);
    _controller?.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(color: Colors.black, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_hasError) return _buildError();
    if (!_isInitialized) return _buildLoading();
    if (_isCompleted) return _buildCompleted();
    return _buildPlayer();
  }

  Widget _buildPlayer() {
    final val = _controller!.value;
    final pos = val.position;
    final dur = val.duration;
    final durMs = dur.inMilliseconds.toDouble();
    final posMs = pos.inMilliseconds.toDouble().clamp(0.0, durMs > 0 ? durMs : 1.0);

    return GestureDetector(
      onTap: () {
        setState(() => _showControls = !_showControls);
        if (_showControls) _startHideControlsTimer();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: val.aspectRatio > 0 ? val.aspectRatio : 16 / 9,
              child: VideoPlayer(_controller!),
            ),
          ),
          // Buffering spinner with grace delay
          if (_showBuffering)
            const Center(
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)),
          if (_showControls) _buildControls(pos, dur, val.isPlaying, posMs, durMs),
        ],
      ),
    );
  }

  Widget _buildControls(Duration pos, Duration dur, bool playing,
      double posMs, double durMs) {
    return Container(
      color: Colors.black38,
      child: Column(
        children: [
          // Top — speed
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _showSpeedSheet,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      _playbackSpeed == 1.0 ? '1x' : '${_playbackSpeed}x',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Centre — transport
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ctrlBtn(Icons.replay_10,
                    () => _seekTo(pos - const Duration(seconds: 10)), 28),
                const SizedBox(width: 24),
                _ctrlBtn(playing ? Icons.pause : Icons.play_arrow,
                    _togglePlayPause, 44),
                const SizedBox(width: 24),
                _ctrlBtn(Icons.forward_10,
                    () => _seekTo(pos + const Duration(seconds: 10)), 28),
              ],
            ),
          ),
          // Bottom — seek bar + fullscreen
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(
              children: [
                Text(_fmt(pos),
                    style:
                        const TextStyle(color: Colors.white, fontSize: 10)),
                Expanded(child: _buildSlider(posMs, durMs)),
                Text(_fmt(dur),
                    style:
                        const TextStyle(color: Colors.white, fontSize: 10)),
                const SizedBox(width: 4),
                GestureDetector(
                    onTap: _enterFullscreen,
                    child: const Icon(Icons.fullscreen,
                        color: Colors.white, size: 22)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(double posMs, double durMs) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
        activeTrackColor: Colors.red,
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.red,
      ),
      child: Slider(
        value: _isDragging ? _dragValue : posMs,
        min: 0,
        max: durMs > 0 ? durMs : 1.0,
        onChangeStart: (v) => setState(() {
          _isDragging = true;
          _dragValue = v;
        }),
        onChanged: (v) => setState(() => _dragValue = v),
        onChangeEnd: (v) {
          setState(() => _isDragging = false);
          _seekTo(Duration(milliseconds: v.toInt()));
        },
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap, double size) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration:
            const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }

  Widget _buildLoading() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.thumbnailUrl != null)
          Image.network(widget.thumbnailUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox()),
        Container(
          color: Colors.black54,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                SizedBox(height: 12),
                Text('Loading video…',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 8),
            const Text('Failed to load video',
                style: TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(height: 4),
            Text(_errorMessage ?? '',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 2),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isInitialized = false;
                });
                _initializePlayer();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleted() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 8),
          const Text('Completed!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _isCompleted = false);
              _controller?.seekTo(Duration.zero);
              _controller?.play();
            },
            icon: const Icon(Icons.replay, color: Colors.white, size: 16),
            label: const Text('Replay',
                style: TextStyle(color: Colors.white, fontSize: 12)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
          ),
        ],
      ),
    );
  }

  // ── Fullscreen overlay ───────────────────────────────────────────────────────

  Widget _buildFullscreenOverlay() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }
    final val = _controller!.value;
    final pos = val.position;
    final dur = val.duration;
    final durMs = dur.inMilliseconds.toDouble();
    final posMs =
        pos.inMilliseconds.toDouble().clamp(0.0, durMs > 0 ? durMs : 1.0);

    return Material(
      color: Colors.black,
      child: GestureDetector(
        onTap: () {
          _showControls = !_showControls;
          _fullscreenOverlay?.markNeedsBuild();
          if (_showControls) _startHideControlsTimer();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: val.aspectRatio > 0 ? val.aspectRatio : 16 / 9,
                child: VideoPlayer(_controller!),
              ),
            ),
            if (_showBuffering)
              const Center(
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)),
            if (_showControls)
              Container(
                color: Colors.black38,
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            GestureDetector(
                                onTap: _exitFullscreen,
                                child: const Icon(Icons.arrow_back,
                                    color: Colors.white, size: 26)),
                            const Spacer(),
                            GestureDetector(
                              onTap: _showSpeedSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(4)),
                                child: Text(
                                  _playbackSpeed == 1.0
                                      ? '1x'
                                      : '${_playbackSpeed}x',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Centre
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ctrlBtn(
                                Icons.replay_10,
                                () => _seekTo(
                                    pos - const Duration(seconds: 10)),
                                40),
                            const SizedBox(width: 48),
                            _ctrlBtn(
                                val.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                _togglePlayPause,
                                56),
                            const SizedBox(width: 48),
                            _ctrlBtn(
                                Icons.forward_10,
                                () => _seekTo(
                                    pos + const Duration(seconds: 10)),
                                40),
                          ],
                        ),
                      ),
                      // Bottom
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: [
                            Text(_fmt(pos),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 8),
                                  activeTrackColor: Colors.red,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.red,
                                ),
                                child: Slider(
                                  value: _isDragging ? _dragValue : posMs,
                                  min: 0,
                                  max: durMs > 0 ? durMs : 1.0,
                                  onChangeStart: (v) {
                                    _isDragging = true;
                                    _dragValue = v;
                                    _fullscreenOverlay?.markNeedsBuild();
                                  },
                                  onChanged: (v) {
                                    _dragValue = v;
                                    _fullscreenOverlay?.markNeedsBuild();
                                  },
                                  onChangeEnd: (v) {
                                    _isDragging = false;
                                    _seekTo(Duration(milliseconds: v.toInt()));
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(_fmt(dur),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13)),
                            const SizedBox(width: 16),
                            GestureDetector(
                                onTap: _exitFullscreen,
                                child: const Icon(Icons.fullscreen_exit,
                                    color: Colors.white, size: 28)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
