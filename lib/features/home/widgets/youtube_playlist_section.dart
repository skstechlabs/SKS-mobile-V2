import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';

/// A single playlist entry shown on the home page.
class PlaylistConfig {
  final String title;
  final String subtitle;
  final String playlistId;
  final Color accentColor;
  final Color bgColor;
  final String? emoji;

  const PlaylistConfig({
    required this.title,
    required this.subtitle,
    required this.playlistId,
    required this.accentColor,
    required this.bgColor,
    this.emoji,
  });
}

/// ── Static fallback data (from RSS, updated 2026-07) ─────────────────────────
/// Used immediately so the UI never shows blank on emulator/no-network.

const _energyAuraVideos = [
  PlaylistVideo(videoId: 't72O1Iz_i90', title: 'First time in human history..AURA captured in a Video', thumbnailUrl: 'https://i.ytimg.com/vi/t72O1Iz_i90/hqdefault.jpg'),
  PlaylistVideo(videoId: '8AHojegX06s', title: 'గురుదేవుల అద్భుత శక్తి మరియు ఆరా కళ్లారా చూడండి', thumbnailUrl: 'https://i.ytimg.com/vi/8AHojegX06s/hqdefault.jpg'),
  PlaylistVideo(videoId: 'OIcOvSfOA9c', title: 'ఇలాంటి ఫోటోస్ జీవితంలో చూసి ఉండరు.. చివరి ఫోటో మిస్ అవ్వద్దు', thumbnailUrl: 'https://i.ytimg.com/vi/OIcOvSfOA9c/hqdefault.jpg'),
  PlaylistVideo(videoId: 'uOcsLAH0_ys', title: 'శక్తిపాతం అంటే ఇదే! గురుదేవులు ఈ శివరాత్రి రోజు శక్తిపాతం ఇస్తున్నారు', thumbnailUrl: 'https://i.ytimg.com/vi/uOcsLAH0_ys/hqdefault.jpg'),
  PlaylistVideo(videoId: 'q3VvekCzs14', title: 'Unbelievable miraculous pics of Pujya Gurudev Sri Jeeveswara Yogi', thumbnailUrl: 'https://i.ytimg.com/vi/q3VvekCzs14/hqdefault.jpg'),
];

const _transformationVideos = [
  PlaylistVideo(videoId: '58X02gfQVFc', title: 'ఇంతటి నిరాడంబర గురువుని మీరు చూసి ఉండరు | Never seen such simple, honest and humble Guru', thumbnailUrl: 'https://i.ytimg.com/vi/58X02gfQVFc/hqdefault.jpg'),
  PlaylistVideo(videoId: 'IyH-7BgEy00', title: 'నాకు షాక్ ట్రీట్మెంట్ ఇచ్చారు.. | I was given Shock Treatment..', thumbnailUrl: 'https://i.ytimg.com/vi/IyH-7BgEy00/hqdefault.jpg'),
  PlaylistVideo(videoId: 'R2goDa9crdM', title: 'నాకు కాన్సర్.. పరామర్శకి వచ్చి పరేషాన్ అయ్యేవారు.. #miracles', thumbnailUrl: 'https://i.ytimg.com/vi/R2goDa9crdM/hqdefault.jpg'),
  PlaylistVideo(videoId: 'Yp-BPYOGwrE', title: 'I was an atheist.. Gurudev\'s miracles changed me... #kalpataru', thumbnailUrl: 'https://i.ytimg.com/vi/Yp-BPYOGwrE/hqdefault.jpg'),
  PlaylistVideo(videoId: 'NbdWJ2cpnqM', title: '60 గంటల ధ్యానం కేవలం 3 రోజుల్లో | ఇది గురుదేవుల అనుగ్రహం', thumbnailUrl: 'https://i.ytimg.com/vi/NbdWJ2cpnqM/hqdefault.jpg'),
  PlaylistVideo(videoId: 'Gxm8-uy4MOw', title: 'మరణానికి దగ్గరగా వెళ్లిన నన్ను తిరిగి తీసుకుని వచ్చిన నా గురుదేవులు', thumbnailUrl: 'https://i.ytimg.com/vi/Gxm8-uy4MOw/hqdefault.jpg'),
  PlaylistVideo(videoId: 'wkjk-8MkKjE', title: 'నాకు పునర్జన్మని ప్రసాదించిన నా సద్గురువు శ్రీ జీవేశ్వరులు', thumbnailUrl: 'https://i.ytimg.com/vi/wkjk-8MkKjE/hqdefault.jpg'),
  PlaylistVideo(videoId: 'ffI683d8Eyk', title: 'ఇంత గొప్ప గురువుని ఎవ్వరూ వదులుకోవద్దు | Do not miss such a great Guru', thumbnailUrl: 'https://i.ytimg.com/vi/ffI683d8Eyk/hqdefault.jpg'),
  PlaylistVideo(videoId: 'nUNc0zhFeeg', title: 'అజ్ఞానంతో గురుదేవుల ఎనర్జీ ఫోటోస్ ఎడిటింగ్ అనుకున్నాను.. ఆయన శక్తి అనంతం', thumbnailUrl: 'https://i.ytimg.com/vi/nUNc0zhFeeg/hqdefault.jpg'),
  PlaylistVideo(videoId: 'LDJgWnKI7mM', title: 'ధ్యానంలో ఒక్క నిమిషంలోనే శక్తి తెలుస్తోంది | Energy & Vibration in 1 min', thumbnailUrl: 'https://i.ytimg.com/vi/LDJgWnKI7mM/hqdefault.jpg'),
];

const _kalpataruVideos = [
  PlaylistVideo(videoId: 'V_Bw8U12zBQ', title: 'ఇంతటి గురువు ఇప్పటి వరకు లేరు.. Siva Kundalini Sadhana | Sri Jeeveswara Yogi', thumbnailUrl: 'https://i.ytimg.com/vi/V_Bw8U12zBQ/hqdefault.jpg'),
  PlaylistVideo(videoId: 'D53cVUtYKX8', title: 'మా 4 సం. పాపకు గుండెలో రంధ్రాలు శక్తిపాతం, కల్పతరుతో సర్జరీ లేకుండా తగ్గిపోయాయి', thumbnailUrl: 'https://i.ytimg.com/vi/D53cVUtYKX8/hqdefault.jpg'),
  PlaylistVideo(videoId: 'vjSXEVFdj5M', title: 'CANCER got CURED completely with KALPATARU.. check REPORTS..', thumbnailUrl: 'https://i.ytimg.com/vi/vjSXEVFdj5M/hqdefault.jpg'),
  PlaylistVideo(videoId: '8MJeO4uqKWU', title: 'సంవత్సరం నుండి జాబ్ లేదు.. కల్పతరు టెక్నిక్ చేసిన గంటలోనే అద్భుతం', thumbnailUrl: 'https://i.ytimg.com/vi/8MJeO4uqKWU/hqdefault.jpg'),
  PlaylistVideo(videoId: 'FOGibypNhF0', title: 'భరించలేని సర్జరీ నొప్పి నిమిషాల్లో మాయం అయ్యింది.. Mr. Kurt, USA', thumbnailUrl: 'https://i.ytimg.com/vi/FOGibypNhF0/hqdefault.jpg'),
  PlaylistVideo(videoId: 'Z0Oa317GdtA', title: 'Gurudev blessed me with New Life | మరణం అంచులదాక వెళ్లిన నాకు పునర్జన్మ', thumbnailUrl: 'https://i.ytimg.com/vi/Z0Oa317GdtA/hqdefault.jpg'),
  PlaylistVideo(videoId: 'wfve0hs-uLQ', title: 'Kalpataru - World\'s Fastest and Easiest Healing & Manifestation Technique', thumbnailUrl: 'https://i.ytimg.com/vi/wfve0hs-uLQ/hqdefault.jpg'),
  PlaylistVideo(videoId: 'rw1g4_GBY9w', title: 'నా PCOD ప్రాబ్లం, 3 cm గడ్డలు.. కల్పతరుతో తగ్గిపోయాయి', thumbnailUrl: 'https://i.ytimg.com/vi/rw1g4_GBY9w/hqdefault.jpg'),
  PlaylistVideo(videoId: 'dGBxwv_26Bs', title: 'Appendicitis cured in 1 day with Kalpataru.. without surgery', thumbnailUrl: 'https://i.ytimg.com/vi/dGBxwv_26Bs/hqdefault.jpg'),
  PlaylistVideo(videoId: 'J_kbdcu03VE', title: 'కల్పతరుతో నా మైగ్రేన్ తలనొప్పి 2 నిమిషాల్లో తగ్గింది.. మళ్లీ తిరిగి రాలేదు!', thumbnailUrl: 'https://i.ytimg.com/vi/J_kbdcu03VE/hqdefault.jpg'),
  PlaylistVideo(videoId: 's0wtZraiGVc', title: 'Sciatica Pain Gone in 3 Days with Kalpataru', thumbnailUrl: 'https://i.ytimg.com/vi/s0wtZraiGVc/hqdefault.jpg'),
  PlaylistVideo(videoId: 'KQdjejEGsd0', title: 'Three Years After Marriage… Pregnancy, Normal Delivery, Healthy Baby – Miracle of Kalpataru!', thumbnailUrl: 'https://i.ytimg.com/vi/KQdjejEGsd0/hqdefault.jpg'),
  PlaylistVideo(videoId: 'zjyt2sPf1nQ', title: '400 ఎకరాలకు కల్పతరు చేశాను.. చుట్టూ వర్షం పడింది.. మా ఊరిలో తప్ప..', thumbnailUrl: 'https://i.ytimg.com/vi/zjyt2sPf1nQ/hqdefault.jpg'),
  PlaylistVideo(videoId: 'ltV-OBOAegU', title: 'Cancer cells vanished after doing Kalpataru | Doctors are shocked in Australia', thumbnailUrl: 'https://i.ytimg.com/vi/ltV-OBOAegU/hqdefault.jpg'),
  PlaylistVideo(videoId: 'ZH4yE6S7b70', title: 'Doctors got shocked! Blood clots in Kidney got healed with Kalpataru', thumbnailUrl: 'https://i.ytimg.com/vi/ZH4yE6S7b70/hqdefault.jpg'),
];

const _fallbackMap = {
  'PL5n5gvsTFZLyL154q7-4Bp51EnACr2Kcr': _energyAuraVideos,
  'PL5n5gvsTFZLxNeqKLWpTPYfdWBU84zKzE': _transformationVideos,
  'PL5n5gvsTFZLwrGFrtAa3sLgq5BVOpL7K_': _kalpataruVideos,
};

class PlaylistVideo {
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final String? duration;

  const PlaylistVideo({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    this.duration,
  });
}

/// ── Fetch ──────────────────────────────────────────────────────────────────────

/// Returns static fallback immediately, then tries to refresh from RSS.
/// This ensures content is always visible even with no network.
Future<List<PlaylistVideo>> fetchPlaylistVideos(
    String playlistId, {int maxResults = 20}) async {
  // Try live RSS first (works on real device; may fail on emulator)
  try {
    final rssUrl =
        'https://www.youtube.com/feeds/videos.xml?playlist_id=$playlistId';
    final response = await http
        .get(Uri.parse(rssUrl), headers: {'User-Agent': 'Mozilla/5.0'})
        .timeout(const Duration(seconds: 6));

    if (response.statusCode == 200 && response.body.contains('<yt:videoId>')) {
      final videos = <PlaylistVideo>[];
      final videoIdRx = RegExp(r'<yt:videoId>(.*?)</yt:videoId>');
      final titleRx = RegExp(r'<media:title>(.*?)</media:title>', dotAll: true);
      final thumbRx = RegExp(r'<media:thumbnail url="(.*?)"');

      final ids = videoIdRx.allMatches(response.body).map((m) => m.group(1)!.trim()).toList();
      final titles = titleRx.allMatches(response.body).map((m) => _decodeXml(m.group(1)!.trim())).toList();
      final thumbs = thumbRx.allMatches(response.body).map((m) => m.group(1)!.trim()).toList();

      for (int i = 0; i < ids.length && videos.length < maxResults; i++) {
        if (ids[i].isEmpty) continue;
        videos.add(PlaylistVideo(
          videoId: ids[i],
          title: i < titles.length ? titles[i] : 'Video',
          thumbnailUrl: i < thumbs.length
              ? thumbs[i]
              : 'https://i.ytimg.com/vi/${ids[i]}/hqdefault.jpg',
        ));
      }
      if (videos.isNotEmpty) return videos;
    }
  } catch (e) {
    debugPrint('YouTube RSS fetch failed: $e — using static fallback');
  }

  // Fall back to static data (always available, no network needed)
  return List<PlaylistVideo>.from(
      _fallbackMap[playlistId] ?? <PlaylistVideo>[]);
}

String _decodeXml(String s) => s
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'");

/// ── Section widget ─────────────────────────────────────────────────────────

class YouTubePlaylistSection extends StatefulWidget {
  final PlaylistConfig config;

  const YouTubePlaylistSection({super.key, required this.config});

  @override
  State<YouTubePlaylistSection> createState() => _YouTubePlaylistSectionState();
}

class _YouTubePlaylistSectionState extends State<YouTubePlaylistSection> {
  late Future<List<PlaylistVideo>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchPlaylistVideos(widget.config.playlistId);
  }

  void _openVideo(String videoId, String title) {
    context.push('/youtube-player', extra: {'videoId': videoId, 'title': title});
  }

  Future<void> _openFullPlaylist() async {
    // Open the entire playlist in-app using youtube_player_iframe
    context.push('/youtube-player', extra: {
      'videoId': widget.config.playlistId,
      'title': widget.config.title,
    });
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ───────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Accent bar
              Container(
                width: 4, height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [cfg.accentColor, cfg.accentColor.withValues(alpha: 0.4)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              // Emoji badge (optional)
              if (cfg.emoji != null) ...[
                Text(cfg.emoji!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
              ],
              // Title + subtitle — takes all remaining space
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cfg.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      cfg.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // View all button — fixed width so it never pushes title
              GestureDetector(
                onTap: _openFullPlaylist,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cfg.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cfg.accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cfg.accentColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 14, color: cfg.accentColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Video cards ──────────────────────────────────────────────────
          FutureBuilder<List<PlaylistVideo>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingRow();
              }
              final videos = snapshot.data ?? [];
              if (videos.isEmpty) {
                return _buildEmptyState(cfg);
              }
              return SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 4),
                  itemCount: videos.length,
                  itemBuilder: (ctx, i) => _buildVideoCard(videos[i], cfg),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(PlaylistVideo video, PlaylistConfig cfg) {
    // Unique hue shift per card so each thumbnail area looks distinct
    final shift = video.videoId.codeUnits.fold(0, (a, b) => a + b) % 40 - 20;
    final base = HSLColor.fromColor(cfg.accentColor);
    final c1 = HSLColor.fromAHSL(1, (base.hue + shift) % 360, base.saturation, base.lightness).toColor();
    final c2 = HSLColor.fromAHSL(1, (base.hue + shift + 20) % 360, base.saturation, base.lightness - 0.1).toColor();

    return GestureDetector(
      onTap: () => _openVideo(video.videoId, video.title),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: cfg.accentColor.withValues(alpha: 0.1),
                blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                width: 200, height: 112,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Unique gradient — always visible, no network needed
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [c1, c2],
                        ),
                      ),
                    ),
                    // Network thumbnail on top when available
                    Image.network(
                      video.thumbnailUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, prog) =>
                          prog == null ? child : const SizedBox.shrink(),
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    // Bottom vignette
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                    // Play button
                    Center(
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25), blurRadius: 8)],
                        ),
                        child: Icon(Icons.play_arrow_rounded, color: cfg.accentColor, size: 26),
                      ),
                    ),
                    // YouTube badge
                    Positioned(
                      bottom: 6, right: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('YouTube',
                            style: TextStyle(color: Colors.white, fontSize: 7,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Text(video.title,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary, height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingRow() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          width: 220,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Column(
            children: [
              _shimmer(220, 124,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16))),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmer(180, 12),
                    const SizedBox(height: 6),
                    _shimmer(130, 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmer(double w, double h,
      {BorderRadius borderRadius = BorderRadius.zero}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      builder: (_, v, __) => Container(
        width: w, height: h,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: v),
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  Widget _buildEmptyState(PlaylistConfig cfg) {
    return GestureDetector(
      onTap: _openFullPlaylist,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cfg.accentColor.withValues(alpha: 0.12),
              cfg.accentColor.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cfg.accentColor.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: cfg.accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: cfg.accentColor.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Icon(Icons.play_arrow_rounded, color: cfg.accentColor, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Watch Playlist',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cfg.accentColor,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Opens in YouTube app',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cfg.accentColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
