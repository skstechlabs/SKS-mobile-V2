import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late final WebViewController? controller;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      try {
        controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0x00000000))
          ..loadRequest(Uri.parse(
            'https://www.youtube.com/embed/${widget.videoId}?autoplay=1&fs=1&iv_load_policy=3&showinfo=0&rel=0&cc_load_policy=0&start=0&end=0&origin=https://flutter.dev',
          ));
      } catch (e) {
        controller = null;
        debugPrint('WebView not available: $e');
      }
    } else {
      controller = null;
    }
  }

  Future<void> _openYouTubeInNewTab() async {
    final url = Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: kIsWeb || controller == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_circle_fill,
                      size: 100,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Watch: ${widget.title}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _openYouTubeInNewTab,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open in YouTube'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : WebViewWidget(controller: controller!),
      ),
    );
  }
}