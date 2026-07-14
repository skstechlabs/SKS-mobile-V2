import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/audio_model.dart';
import '../../core/services/enhanced_audio_player_service.dart';
import '../../core/services/now_playing_state.dart';
import '../../core/theme/app_theme.dart';

/// Full-screen Spotify-style Now Playing screen.
/// Opened from MiniAudioPlayer tap or from AllSongsPage song tap.
class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  final EnhancedAudioPlayerService _service = EnhancedAudioPlayerService();
  late AnimationController _artController;
  late Animation<double> _artScale;

  @override
  void initState() {
    super.initState();
    // nowPlayingVisible is already set to true by openNowPlaying() before push.
    // We set it here as well to handle the /now-playing named route case.
    nowPlayingVisible.value = true;

    _service.addListener(_onStateChanged);

    _artController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _artScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _artController, curve: Curves.easeOutBack),
    );

    if (_service.isPlaying) _artController.forward();
  }

  @override
  void dispose() {
    // Signal that the full-screen player is gone — show mini player again.
    nowPlayingVisible.value = false;
    _service.removeListener(_onStateChanged);
    _artController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;
    if (_service.isPlaying) {
      _artController.forward();
    } else {
      _artController.reverse();
    }
    // Only rebuild if we still have a song — never rebuild to show empty state
    if (_service.currentSong != null) {
      setState(() {});
    }
    // When stop() clears the playlist, pop the screen.
    // Schedule after the current frame so we don't pop mid-build.
    if (_service.currentSong == null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  ImageProvider _thumb(AudioModel? song) {
    final url = song?.thumbnailUrl ?? '';
    if (url.startsWith('http')) return CachedNetworkImageProvider(url);
    return const AssetImage('assets/images/Guruji_logo.JPG');
  }

  @override
  Widget build(BuildContext context) {
    final song = _service.currentSong;
    final playlist = _service.playlist;
    final idx = _service.currentIndex;

    // If song is gone (stop() was called), show nothing and pop.
    // Never render the "no song playing" placeholder.
    if (song == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const Scaffold(backgroundColor: Colors.black);
    }

    // Make status bar icons white on the dark background
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Blurred album art background ────────────────────────────────
          if (song != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: _thumb(song),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

          // Dark overlay for readability
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.55)),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      // Down arrow — minimize (keep playing)
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Colors.white, size: 32),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'NOW PLAYING',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                            if (playlist.isNotEmpty)
                              Text(
                                '${idx + 1} / ${playlist.length}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Close button — pop first, then stop
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 24,
                        ),
                        onPressed: () {
                          // Detach listener before popping so _onStateChanged
                          // can't fire on a half-disposed widget
                          _service.removeListener(_onStateChanged);
                          Navigator.of(context).pop();
                          _service.stop();
                        },
                      ),
                    ],
                  ),
                ),

                // ── Album art — flexible so it shrinks on small screens ──
                Flexible(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 12),
                    child: ScaleTransition(
                      scale: _artScale,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 40,
                                spreadRadius: 8,
                                offset: const Offset(0, 16),
                              ),
                            ],
                            image: DecorationImage(
                              image: _thumb(song),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: song == null
                              ? const Icon(Icons.music_note,
                                  color: Colors.white38, size: 80)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Song info ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song?.title ?? 'No song playing',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song?.artist ??
                                  song?.description ??
                                  'Divine Chants',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Language badge
                      if (song != null && song.language.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.saffron.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    AppTheme.saffron.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            song.language[0].toUpperCase() +
                                song.language.substring(1),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Seek bar ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: StreamBuilder<Duration>(
                    stream: _service.player.positionStream,
                    builder: (ctx, snap) {
                      final pos = snap.data ?? _service.position;
                      final dur = _service.duration;
                      final progress = dur.inMilliseconds > 0
                          ? (pos.inMilliseconds / dur.inMilliseconds)
                              .clamp(0.0, 1.0)
                          : 0.0;
                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 7),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 18),
                              activeTrackColor: Colors.white,
                              inactiveTrackColor:
                                  Colors.white.withValues(alpha: 0.25),
                              thumbColor: Colors.white,
                              overlayColor:
                                  Colors.white.withValues(alpha: 0.15),
                            ),
                            child: Slider(
                              value: progress,
                              onChanged: (v) {
                                final target = Duration(
                                  milliseconds:
                                      (v * dur.inMilliseconds).round(),
                                );
                                _service.seekTo(target);
                              },
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_fmt(pos),
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                                Text(_fmt(dur),
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ── Playback controls ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Loop toggle
                      IconButton(
                        icon: Icon(
                          _service.loopMode == LoopMode.one
                              ? Icons.repeat_one
                              : Icons.repeat,
                          color: _service.loopMode != LoopMode.off
                              ? AppTheme.saffron
                              : Colors.white54,
                          size: 24,
                        ),
                        onPressed: () => _service.toggleLoopMode(),
                      ),

                      // Previous
                      _CtrlBtn(
                        icon: Icons.skip_previous_rounded,
                        size: 40,
                        onTap: _service.playlist.length > 1
                            ? () => _service.previousSong()
                            : null,
                      ),

                      // Play / Pause
                      GestureDetector(
                        onTap: () {
                          if (_service.isPlaying) {
                            _service.pause();
                          } else {
                            _service.play();
                          }
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: _service.isLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppTheme.saffron),
                                )
                              : Icon(
                                  _service.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: AppTheme.saffron,
                                  size: 42,
                                ),
                        ),
                      ),

                      // Next
                      _CtrlBtn(
                        icon: Icons.skip_next_rounded,
                        size: 40,
                        onTap: _service.playlist.length > 1
                            ? () => _service.nextSong()
                            : null,
                      ),

                      // Placeholder to balance loop button
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Queue / Playlist strip — flexible so it disappears if
                //    there's not enough vertical space ────────────────────
                if (playlist.length > 1)
                  Flexible(
                    flex: 2,
                    child: _buildQueueStrip(playlist, idx),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueStrip(List<AudioModel> playlist, int currentIdx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 6),
          child: Text(
            'UP NEXT',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            itemCount: playlist.length,
            itemBuilder: (ctx, i) {
              final s = playlist[i];
              final isCurrent = i == currentIdx;
              final thumb = s.thumbnailUrl ?? '';
              return GestureDetector(
                onTap: () => _service.playSong(playlist, i),
                child: Container(
                  width: 56,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrent
                              ? Border.all(
                                  color: AppTheme.saffron, width: 2)
                              : null,
                          image: DecorationImage(
                            image: thumb.startsWith('http')
                                ? CachedNetworkImageProvider(thumb)
                                    as ImageProvider
                                : const AssetImage(
                                    'assets/images/Guruji_logo.JPG'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: isCurrent
                            ? Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.black.withValues(alpha: 0.4),
                                ),
                                child: const Icon(Icons.graphic_eq,
                                    color: Colors.white, size: 20),
                              )
                            : null,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.title,
                        style: TextStyle(
                          color: isCurrent
                              ? AppTheme.saffron
                              : Colors.white54,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Small icon button used in the controls row.
class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback? onTap;

  const _CtrlBtn({required this.icon, required this.size, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1.0,
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}
