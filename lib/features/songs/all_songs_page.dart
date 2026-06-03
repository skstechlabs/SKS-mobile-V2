import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/enhanced_audio_player_service.dart';
import '../../core/providers/audio_provider.dart';
import '../../core/models/audio_model.dart';
import '../../core/services/localization_service.dart';

/// Helper function to get the correct ImageProvider for CDN or asset images
ImageProvider _getImageProvider(String imageUrl) {
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return CachedNetworkImageProvider(imageUrl);
  }
  return AssetImage(imageUrl);
}

class AllSongsPage extends StatefulWidget {
  const AllSongsPage({Key? key}) : super(key: key);

  @override
  State<AllSongsPage> createState() => _AllSongsPageState();
}

class _AllSongsPageState extends State<AllSongsPage> {
  final EnhancedAudioPlayerService _audioService = EnhancedAudioPlayerService();
  final AudioProvider _audioProvider = AudioProvider();
  bool _isLooping = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
    _audioService.addListener(_onAudioStateChanged);
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      await _audioProvider.fetchAllAudios();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load songs: $e';
        });
      }
    }
  }

  void _onAudioStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioStateChanged);
    super.dispose();
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
      if (_isLooping) {
        _audioService.setLoopMode(LoopMode.all);
      } else {
        _audioService.setLoopMode(LoopMode.off);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bhajans = _audioProvider.bhajans;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              context.tr('all_songs'),
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${bhajans.length} ${context.tr('songs').toLowerCase()}',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isLooping ? Icons.repeat_on : Icons.repeat,
              color: _isLooping ? AppTheme.primary : Colors.grey,
            ),
            onPressed: _toggleLoop,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSongs,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : bhajans.isEmpty
                  ? Center(child: Text('No songs available'))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: ElevatedButton(
                            onPressed: () async {
                              if (bhajans.isNotEmpty) {
                                await _audioService.playWithLoop(
                                  bhajans,
                                  0,
                                  loopMode: _isLooping ? LoopMode.all : LoopMode.off,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  context.tr('play'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: bhajans.length,
                            itemBuilder: (context, index) {
                              final song = bhajans[index];
                              return _buildSongCard(song, index);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildSongCard(AudioModel song, int index) {
    final currentSong = _audioService.currentSong;
    final bool isCurrentSong;
    if (currentSong == null) {
      isCurrentSong = false;
    } else if (currentSong is AudioModel) {
      isCurrentSong = currentSong.id == song.id;
    } else {
      isCurrentSong = (currentSong as Map)['title'] == song.title;
    }
    final isPlaying = isCurrentSong && _audioService.isPlaying;
    
    // Get translated song title
    String getSongTitle(String originalTitle) {
      final titleMap = {
        'Sri Jeeveswarastakam': 'song_sri_jeeveswarastakam',
        'Gundello Gudi': 'song_gundello_gudi',
        'Nirvana Shatkam': 'song_nirvana_shatkam',
        'Jeeveswara Yogi Taluva': 'song_jeeveswara_yogi_taluva',
        'Pralaya Kala Beekara': 'song_pralaya_kala_beekara',
        'Ni Namamalo Undhi Moksha Dwaram': 'song_ni_namamalo',
      };
      return context.tr(titleMap[originalTitle] ?? originalTitle);
    }
    
    // Format duration from seconds
    String formatDuration(int seconds) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '${minutes}:${secs.toString().padLeft(2, '0')}';
    }
    
    return GestureDetector(
      onTap: () async {
        if (isCurrentSong && _audioService.isPlaying) {
          await _audioService.pause();
        } else {
          await _audioService.playSong(_audioProvider.bhajans, index);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentSong ? AppTheme.saffron.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: isCurrentSong 
            ? Border.all(color: AppTheme.saffron, width: 2)
            : null,
        ),
        child: Row(
          children: [
            // Track number
            Container(
              width: 32,
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 16,
                  color: isCurrentSong ? AppTheme.saffron : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: 12),
            // Album art
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: _getImageProvider(song.thumbnailUrl ?? 'assets/images/placeholder.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (isCurrentSong)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
              ],
            ),
            SizedBox(width: 16),
            // Song details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getSongTitle(song.title),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isCurrentSong ? AppTheme.saffron : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    song.artist ?? song.description ?? 'Divine Chants',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Duration and play button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatDuration(song.durationSeconds),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Icon(
                  isCurrentSong && isPlaying ? Icons.pause : Icons.play_arrow,
                  color: isCurrentSong ? AppTheme.saffron : AppTheme.primary,
                  size: 28,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
