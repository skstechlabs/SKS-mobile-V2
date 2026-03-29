import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/audio_player_service.dart';

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
  final AudioPlayerService _audioService = AudioPlayerService();
  bool _isLooping = false;

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
    _audioService.addListener(_onAudioStateChanged);
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
              'All Songs & Bhajans',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${AppConstants.bhajans.length} tracks',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () async {
                await _audioService.playWithLoop(
                  AppConstants.bhajans,
                  0,
                  loopMode: _isLooping ? LoopMode.all : LoopMode.off,
                );
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
                    'Play All',
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
              itemCount: AppConstants.bhajans.length,
              itemBuilder: (context, index) {
                final song = AppConstants.bhajans[index];
                return _buildSongCard(song, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongCard(Map<String, dynamic> song, int index) {
    final isCurrentSong = _audioService.currentSong?['title'] == song['title'];
    final isPlaying = isCurrentSong && _audioService.isPlaying;
    
    return GestureDetector(
      onTap: () async {
        if (isCurrentSong && _audioService.isPlaying) {
          await _audioService.pause();
        } else {
          await _audioService.playSong(AppConstants.bhajans, index);
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
                      image: _getImageProvider(song['imageUrl'] ?? 'assets/images/placeholder.png'),
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
                    song['title'] ?? 'Untitled',
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
                    song['artist'] ?? 'Divine Chants',
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
                  song['duration'] ?? '5:30',
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
