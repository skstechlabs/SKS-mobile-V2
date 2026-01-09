import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';

class MiniAudioPlayer extends StatefulWidget {
  const MiniAudioPlayer({Key? key}) : super(key: key);

  @override
  State<MiniAudioPlayer> createState() => _MiniAudioPlayerState();
}

class _MiniAudioPlayerState extends State<MiniAudioPlayer> {
  final AudioPlayerService _audioService = AudioPlayerService();

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
    _audioService.addListener(_onAudioStateChanged);
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioStateChanged);
    super.dispose();
  }

  void _onAudioStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = _audioService.currentSong;
    
    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: AppTheme.saffronGradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Draggable slider with time display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    _formatDuration(_audioService.position),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: _audioService.duration.inMilliseconds > 0
                            ? _audioService.position.inMilliseconds / _audioService.duration.inMilliseconds
                            : 0.0,
                        onChanged: (value) async {
                          final position = Duration(
                            milliseconds: (value * _audioService.duration.inMilliseconds).round(),
                          );
                          await _audioService.seek(position);
                        },
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(_audioService.duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            
            // Player controls
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Song info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentSong['title'] ?? 'Unknown Title',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            currentSong['artist'] ?? currentSong['description'] ?? 'Unknown Artist',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Control buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous, color: Colors.white),
                          onPressed: () async {
                            try {
                              await _audioService.previousSong();
                            } catch (e) {
                              debugPrint('Error playing previous song: $e');
                            }
                          },
                          iconSize: 28,
                        ),
                        
                        // Play/Pause button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _audioService.isLoading 
                                  ? Icons.hourglass_empty
                                  : _audioService.isPlaying 
                                      ? Icons.pause 
                                      : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: _audioService.isLoading 
                                ? null
                                : () async {
                                    try {
                                      if (_audioService.isPlaying) {
                                        await _audioService.pause();
                                      } else {
                                        await _audioService.play();
                                      }
                                    } catch (e) {
                                      debugPrint('Error toggling playback: $e');
                                    }
                                  },
                            iconSize: 28,
                          ),
                        ),
                        
                        IconButton(
                          icon: const Icon(Icons.skip_next, color: Colors.white),
                          onPressed: () async {
                            try {
                              await _audioService.nextSong();
                            } catch (e) {
                              debugPrint('Error playing next song: $e');
                            }
                          },
                          iconSize: 28,
                        ),
                        
                        // Loop indicator/toggle button
                        IconButton(
                          icon: Icon(
                            _audioService.loopMode == LoopMode.off 
                                ? Icons.repeat 
                                : _audioService.loopMode == LoopMode.all
                                    ? Icons.repeat
                                    : Icons.repeat_one,
                            color: _audioService.isLooping ? AppTheme.gold : Colors.white.withValues(alpha: 0.5),
                          ),
                          onPressed: () async {
                            try {
                              await _audioService.toggleLoopMode();
                            } catch (e) {
                              debugPrint('Error toggling loop mode: $e');
                            }
                          },
                          iconSize: 24,
                        ),
                        
                        // Close button
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () async {
                            try {
                              await _audioService.stop();
                            } catch (e) {
                              // Log error but don't crash the app
                              debugPrint('Error stopping audio: $e');
                            }
                          },
                          iconSize: 24,
                        ),
                      ],
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