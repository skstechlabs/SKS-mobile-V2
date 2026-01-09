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

  @override
  Widget build(BuildContext context) {
    final currentSong = _audioService.currentSong;
    
    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Container(
        height: 80,
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
            // Progress bar
            LinearProgressIndicator(
              value: _audioService.duration.inMilliseconds > 0
                  ? _audioService.position.inMilliseconds / _audioService.duration.inMilliseconds
                  : 0.0,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 2,
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