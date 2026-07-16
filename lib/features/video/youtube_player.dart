import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';

/// In-app YouTube player using youtube_player_iframe (official IFrame API).
///
/// If the video has embedding disabled (e.g. Shorts, restricted videos),
/// the player automatically falls back to opening in the YouTube app/browser.
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
  YoutubePlayerController? _controller;
  bool _hasError = false;
  bool _launched = false;

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

  String get _externalUrl => _isPlaylist
      ? 'https://www.youtube.com/playlist?list=$_listId'
      : 'https://www.youtube.com/watch?v=${widget.videoId}';

  @override
  void initState() {
    super.initState();

    // Playlists: open in YouTube app directly (IFrame playlist support is limited)
    if (_isPlaylist) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openExternal());
      return;
    }

    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableCaption: false,
        playsInline: true,
        strictRelatedVideos: true,
        loop: false,
      ),
    );

    // Listen for errors — auto-launch external if embedding is blocked
    _controller!.listen((value) {
      if (value.hasError && !_hasError && mounted) {
        debugPrint('YouTube IFrame error: ${value.error} — opening external');
        setState(() => _hasError = true);
        // Auto-open in YouTube app after brief delay so user sees the transition
        Future.delayed(const Duration(milliseconds: 300), _openExternal);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller!.loadVideoById(videoId: widget.videoId);
    });
  }

  @override
  void dispose() {
    _controller?.close();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _openExternal() async {
    if (_launched) return;
    _launched = true;

    final ytApp = Uri.parse(_isPlaylist
        ? 'vnd.youtube://www.youtube.com/playlist?list=$_listId'
        : 'vnd.youtube://${widget.videoId}');
    final web = Uri.parse(_externalUrl);

    try {
      if (await canLaunchUrl(ytApp)) {
        await launchUrl(ytApp, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(web, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Playlist or error: show loading while opening YouTube
    if (_isPlaylist || _hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Opening in YouTube…',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return YoutubePlayerScaffold(
      controller: _controller!,
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
          title: Text(widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Colors.white54,
                  size: 20),
              tooltip: 'Open in YouTube',
              onPressed: _openExternal,
            ),
          ],
        ),
        body: Column(
          children: [
            player,
            Expanded(
              child: Container(
                color: const Color(0xFF0F0F0F),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: const TextStyle(color: Colors.white,
                              fontSize: 16, fontWeight: FontWeight.w600,
                              height: 1.4)),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: _openExternal,
                        icon: const Icon(Icons.open_in_new, size: 15,
                            color: Colors.white38),
                        label: const Text('Open in YouTube',
                            style: TextStyle(color: Colors.white38,
                                fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
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
