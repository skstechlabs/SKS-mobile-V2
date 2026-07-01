import 'package:flutter/material.dart';
import '../services/enhanced_audio_player_service.dart';
import '../models/audio_model.dart';
import '../theme/app_theme.dart';
import '../../features/audio/now_playing_screen.dart';

class MiniAudioPlayer extends StatefulWidget {
  const MiniAudioPlayer({super.key});

  @override
  State<MiniAudioPlayer> createState() => _MiniAudioPlayerState();
}

class _MiniAudioPlayerState extends State<MiniAudioPlayer> {
  final EnhancedAudioPlayerService _service = EnhancedAudioPlayerService();

  @override
  void initState() {
    super.initState();
    _service.initialize();
    // Listen only to play/pause/song-change events — NOT position updates.
    // Position updates are handled by StreamBuilder so the progress bar
    // always moves, even if notifyListeners() is throttled.
    _service.addListener(_onAudioStateChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onAudioStateChanged);
    super.dispose();
  }

  void _onAudioStateChanged() {
    if (mounted) setState(() {});
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _openPlayer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const NowPlayingScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = _service.currentSong;
    if (song == null) return const SizedBox.shrink();

    final String title;
    final String artist;
    if (song is AudioModel) {
      title = song.title;
      artist = song.artist ?? song.description ?? 'Divine Chants';
    } else {
      final m = song as Map;
      title = m['title'] ?? 'Unknown Title';
      artist = m['artist'] ?? m['description'] ?? 'Divine Chants';
    }

    return GestureDetector(
      onTap: _openPlayer,
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            gradient: AppTheme.saffronGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Progress bar (StreamBuilder → always live) ──
              StreamBuilder<Duration>(
                stream: _service.player.positionStream,
                builder: (ctx, snap) {
                  final pos = snap.data ?? Duration.zero;
                  final dur = _service.duration;
                  final ratio = dur.inMilliseconds > 0
                      ? (pos.inMilliseconds / dur.inMilliseconds)
                          .clamp(0.0, 1.0)
                      : 0.0;
                  return SliderTheme(
                    data: SliderTheme.of(ctx).copyWith(
                      trackHeight: 2.5,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 10),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor:
                          Colors.white.withValues(alpha: 0.30),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: Slider(
                      value: ratio,
                      onChanged: (v) {
                        final target = Duration(
                          milliseconds:
                              (v * dur.inMilliseconds).round(),
                        );
                        _service.seekTo(target);
                      },
                    ),
                  );
                },
              ),

              // ── Controls row ──────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 4, bottom: 4),
                  child: Row(
                    children: [
                      // Title + artist
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              artist,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Prev
                      IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.skip_previous_rounded,
                            color: Colors.white, size: 26),
                        onPressed: () => _service.previousSong(),
                      ),

                      // Play / Pause
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: _service.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  _service.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                onPressed: () {
                                  if (_service.isPlaying) {
                                    _service.pause();
                                  } else {
                                    _service.play();
                                  }
                                },
                              ),
                      ),

                      // Next
                      IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.skip_next_rounded,
                            color: Colors.white, size: 26),
                        onPressed: () => _service.nextSong(),
                      ),

                      // Close
                      IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.close,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 20),
                        onPressed: () => _service.stop(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
