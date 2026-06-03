import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/services/enhanced_audio_player_service.dart';
import '../../core/models/audio_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/sks_loader.dart';

/// Helper function to get the correct ImageProvider for CDN or asset images
ImageProvider _getImageProvider(String imageUrl) {
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return CachedNetworkImageProvider(imageUrl);
  }
  return AssetImage(imageUrl);
}


class PlaylistScreen extends StatefulWidget {
  final String title;
  final List<dynamic> songs; // Can be List<Map> or List<AudioModel>

  const PlaylistScreen({
    Key? key,
    required this.title,
    required this.songs,
  }) : super(key: key);

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
                  
                  // Handle both AudioModel and Map types
                  final String title = song is AudioModel ? song.title : (song['title'] ?? '');
                  final String? artist = song is AudioModel ? song.artist : song['artist'];
                  final String? description = song is AudioModel ? song.description : song['description'];
                  final String? imageUrl = song is AudioModel ? song.thumbnailUrl : song['imageUrl'];
                  final String? duration = song is AudioModel 
                      ? '${song.durationSeconds ~/ 60}:${(song.durationSeconds % 60).toString().padLeft(2, '0')}' 
                      : song['duration'];
                  
                  final currentSong = _audioService.currentSong;
                  final bool isCurrentSong = currentSong != null &&
                      (currentSong is AudioModel && song is AudioModel
                          ? currentSong.id == song.id
                          : currentSong == song);
                  
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
                          image: imageUrl != null
                              ? DecorationImage(
                                  image: _getImageProvider(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          gradient: imageUrl == null
                              ? AppTheme.saffronGradient
                              : null,
                        ),
                        child: imageUrl == null
                            ? const Icon(Icons.music_note, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                          color: isCurrentSong ? AppTheme.saffron : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (artist != null)
                            Text(artist),
                          if (description != null)
                            Text(
                              description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (duration != null)
                            Text(
                              duration,
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
                                }
                              },
                            ),
                        ],
                      ),
                      onTap: () async {
                        await _audioService.playSong(widget.songs, index);
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}