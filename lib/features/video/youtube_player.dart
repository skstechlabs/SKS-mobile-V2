import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';

/// In-app YouTube player using youtube_player_iframe (official IFrame API).
/// Plays single videos AND full playlists without leaving the app.
class YouTubeVideoPlayer extends StatefulWidget {
  final String videoId;
  final String title;

  const YouTubeVideoPlayer({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  State<YouTubeVideoPlayer> createState() => _YouTubeVideoPlayerState();
}

class _YouTubeVideoPlayerState extends State<YouTubeVideoPlayer> {
  late final YoutubePlayerController _controller;

  bool get _isPlaylist =>
      widget.videoId.startsWith('PL') ||
      widget.videoId.startsWith('videoseries') ||
      widget.videoId.contains('list=');

  String get _listId {
    if (widget.videoId.contains('list=')) {
      return widget.videoId.split('list=').last.split('&').first;
    }
    return widget.videoId;
  }

  @override
  void initState() {
    super.initState();

    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableCaption: false,
        playsInline: true,
        strictRelatedVideos: false,
        loop: false,
      ),
    );

    // Load immediately after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isPlaylist) {
        _controller.loadPlaylist(
          list: [_listId],
          listType: ListType.playlist,
          index: 0,
        );
      } else {
        _controller.loadVideoById(videoId: widget.videoId);
      }
    });
  }

  @override
  void dispose() {
    _controller.close();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _openExternal() async {
    final url = _isPlaylist
        ? 'https://www.youtube.com/playlist?list=$_listId'
        : 'https://www.youtube.com/watch?v=${widget.videoId}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerScaffold(
      controller: _controller,
      aspectRatio: 16 / 9,
      enableFullScreenOnVerticalDrag: true,
      builder: (context, player) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.open_in_new,
                  color: Colors.white54, size: 20),
              tooltip: 'Open in YouTube',
              onPressed: _openExternal,
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Video / Playlist player ──────────────────────────────
            player,

            // ── Info panel below player ──────────────────────────────
            Expanded(
              child: Container(
                color: const Color(0xFF0F0F0F),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Playlist indicator
                      if (_isPlaylist) ...[
                        Row(
                          children: [
                            Icon(Icons.playlist_play,
                                color: Colors.white54, size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'Playlist · swipe in player for next video',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      const Divider(color: Colors.white12),
                      const SizedBox(height: 4),

                      // Open external button
                      OutlinedButton.icon(
                        onPressed: _openExternal,
                        icon: const Icon(Icons.open_in_new,
                            size: 15, color: Colors.white38),
                        label: const Text(
                          'Open in YouTube',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: Colors.white12),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
