import 'package:flutter/material.dart';
import '../services/enhanced_audio_player_service.dart';
import '../services/now_playing_state.dart';
import '../theme/app_theme.dart';
import '../utils/audio_navigation.dart';

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
    _service.addListener(_onAudioStateChanged);
    // Listen to the global notifier so we rebuild when NowPlayingScreen
    // opens or closes — regardless of who pushed it.
    nowPlayingVisible.addListener(_onPlayerVisibilityChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onAudioStateChanged);
    nowPlayingVisible.removeListener(_onPlayerVisibilityChanged);
    super.dispose();
  }

  void _onAudioStateChanged() {
    if (mounted) setState(() {});
  }

  void _onPlayerVisibilityChanged() {
    if (mounted) setState(() {});
  }

  void _openPlayer() {
    openNowPlaying(context);
  }

  @override
  Widget build(BuildContext context) {
    final song = _service.currentSong;

    // Hide when:
    //  - no song loaded
    //  - full-screen NowPlayingScreen is open (avoids duplicate controls)
    if (song == null || nowPlayingVisible.value) {
      return const SizedBox.shrink();
    }

    final String title = song.title;
    final String artist = song.artist ?? song.description ?? 'Divine Chants';

    // Fixed 64px — no SafeArea so it doesn't add bottom inset inside the
    // bottomNavigationBar Column (BottomNavigationBar handles that already).
    return GestureDetector(
      onTap: _openPlayer,
      child: Container(
        height: 64,
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
            // ── Thin progress bar (StreamBuilder → always live) ──────────
            SizedBox(
              height: 3,
              child: StreamBuilder<Duration>(
                stream: _service.player.positionStream,
                builder: (ctx, snap) {
                  final pos = snap.data ?? Duration.zero;
                  final dur = _service.duration;
                  final ratio = dur.inMilliseconds > 0
                      ? (pos.inMilliseconds / dur.inMilliseconds)
                          .clamp(0.0, 1.0)
                      : 0.0;
                  return LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  );
                },
              ),
            ),

            // ── Controls row ─────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      constraints: const BoxConstraints(
                          minWidth: 36, minHeight: 36),
                      icon: const Icon(Icons.skip_previous_rounded,
                          color: Colors.white, size: 26),
                      onPressed: () => _service.previousSong(),
                    ),

                    // Play / Pause
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: _service.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(9),
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
                                size: 24,
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
                      constraints: const BoxConstraints(
                          minWidth: 36, minHeight: 36),
                      icon: const Icon(Icons.skip_next_rounded,
                          color: Colors.white, size: 26),
                      onPressed: () => _service.nextSong(),
                    ),

                    // Close — stops playback only.
                    // NowPlayingScreen has its own × button to dismiss itself.
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
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
    );
  }
}
