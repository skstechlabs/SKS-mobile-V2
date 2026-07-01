import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/services/enhanced_audio_player_service.dart';
import '../../core/models/audio_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/sks_loader.dart';
import '../audio/now_playing_screen.dart';

/// Helper function to get the correct ImageProvider for CDN or asset images
ImageProvider _getImageProvider(String imageUrl) {
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return CachedNetworkImageProvider(imageUrl);
  }
  return AssetImage(imageUrl);
}


class PlaylistScreen extends StatefulWidget {
  final String title;
  final List<AudioModel> songs;

  const PlaylistScreen({
    super.key,
    required this.title,
    required this.songs,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final EnhancedAudioPlayerService _audioService = EnhancedAudioPlayerService();

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.saffron,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_filled),
            onPressed: () async {
              if (widget.songs.isNotEmpty) {
                await _audioService.playSong(widget.songs, 0);
                if (mounted) _openPlayer();
              }
            },
            tooltip: 'Play All',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.spiritualGradient),
        child: widget.songs.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No songs available',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.songs.length,
                itemBuilder: (context, index) {
                  final song = widget.songs[index];
                  
                  final currentSong = _audioService.currentSong;
                  final bool isCurrentSong = currentSong != null && currentSong.id == song.id;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: isCurrentSong ? 8 : 2,
                    color: isCurrentSong ? AppTheme.saffron.withValues(alpha: 0.1) : null,
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: song.thumbnailUrl != null
                              ? DecorationImage(
                                  image: _getImageProvider(song.thumbnailUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          gradient: song.thumbnailUrl == null
                              ? AppTheme.saffronGradient
                              : null,
                        ),
                        child: song.thumbnailUrl == null
                            ? const Icon(Icons.music_note, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        song.title,
                        style: TextStyle(
                          fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                          color: isCurrentSong ? AppTheme.saffron : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (song.artist != null)
                            Text(song.artist!),
                          if (song.description != null)
                            Text(
                              song.description!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          Text(
                            '${song.durationSeconds ~/ 60}:${(song.durationSeconds % 60).toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.saffron,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCurrentSong && _audioService.isPlaying)
                            const SKSLoaderStatic(size: 24)
                          else
                            IconButton(
                              icon: Icon(
                                isCurrentSong && _audioService.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: AppTheme.saffron,
                              ),
                              onPressed: () async {
                                if (isCurrentSong && _audioService.isPlaying) {
                                  await _audioService.pause();
                                } else {
                                  await _audioService.playSong(widget.songs, index);
                                  if (mounted) _openPlayer();
                                }
                              },
                            ),
                        ],
                      ),
                      onTap: () async {
                        await _audioService.playSong(widget.songs, index);
                        if (mounted) _openPlayer();
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}