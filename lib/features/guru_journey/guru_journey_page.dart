import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/localization_service.dart';
import '../../core/widgets/cached_image.dart';
import '../video/youtube_player.dart';

class GuruJourneyPage extends StatefulWidget {
  const GuruJourneyPage({super.key});

  @override
  State<GuruJourneyPage> createState() => _GuruJourneyPageState();
}

class _GuruJourneyPageState extends State<GuruJourneyPage> {
  // YouTube video ID for Guru's journey video
  static const String _videoId = '6mf3Rmykov4';
  
  void _playYouTubeVideo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YouTubeVideoPlayer(
          videoId: _videoId,
          title: context.tr('guru_journey_title'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6D4C41)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('guru_journey_title'),
          style: const TextStyle(
            color: Color(0xFF6D4C41),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── YouTube thumbnail ──────────────────────────────────────────
            _buildVideoThumbnail(context),

            // ── Sacred header ──────────────────────────────────────────────
            _buildSacredHeader(context),

            // ── Timeline journey ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildTimelineItem(
                    context,
                    icon: Icons.auto_awesome,
                    iconColor: const Color(0xFFE65100),
                    year: context.tr('guru_journey_age_8'),
                    title: context.tr('guru_journey_title_1'),
                    body: context.tr('guru_journey_para1'),
                    isFirst: true,
                  ),
                  _buildTimelineItem(
                    context,
                    icon: Icons.temple_hindu,
                    iconColor: const Color(0xFF6A1B9A),
                    year: context.tr('guru_journey_age_13'),
                    title: context.tr('guru_journey_title_2'),
                    body: context.tr('guru_journey_para2'),
                  ),
                  _buildTimelineItem(
                    context,
                    icon: Icons.self_improvement,
                    iconColor: const Color(0xFF1565C0),
                    year: context.tr('guru_journey_enlightenment'),
                    title: context.tr('guru_journey_title_3'),
                    body: context.tr('guru_journey_para3'),
                  ),
                  _buildTimelineItem(
                    context,
                    icon: Icons.volunteer_activism,
                    iconColor: const Color(0xFF2E7D32),
                    year: '2017',
                    title: context.tr('guru_journey_title_4'),
                    body: context.tr('guru_journey_para4'),
                  ),
                  _buildTimelineItem(
                    context,
                    icon: Icons.brightness_high,
                    iconColor: AppTheme.saffron,
                    year: context.tr('guru_journey_today'),
                    title: context.tr('guru_journey_title_5'),
                    body: context.tr('guru_journey_para5'),
                    isLast: true,
                  ),
                ],
              ),
            ),

            // ── Pull quote ─────────────────────────────────────────────────
            _buildPullQuote(context),

            // ── Closing blessing ───────────────────────────────────────────
            _buildClosingBlessing(context),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Video thumbnail ────────────────────────────────────────────────────────

  Widget _buildVideoThumbnail(BuildContext context) {
    return GestureDetector(
      onTap: _playYouTubeVideo,
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // YouTube thumbnail via CachedNetworkImage
            CachedImage(
              imageUrl: 'https://img.youtube.com/vi/6mf3Rmykov4/maxresdefault.jpg',
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            // Play button
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 44),
              ),
            ),
            // Label
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle_outline,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('guru_journey_watch_youtube'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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

  // ── Sacred header ──────────────────────────────────────────────────────────

  Widget _buildSacredHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8F0),
      ),
      child: Column(
        children: [
          // Om symbol
          Text(
            'ॐ',
            style: TextStyle(
              fontSize: 48,
              color: AppTheme.saffron.withValues(alpha: 0.7),
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          // Decorative line
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(AppTheme.saffron.withValues(alpha: 0.3)),
              _line(AppTheme.saffron.withValues(alpha: 0.4)),
              _dot(AppTheme.saffron.withValues(alpha: 0.6)),
              _line(AppTheme.saffron.withValues(alpha: 0.4)),
              _dot(AppTheme.saffron.withValues(alpha: 0.3)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${context.tr('parama_pujya')}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.saffron.withValues(alpha: 0.8),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('sri_jeeveswara_yogi'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFBF360C),
              letterSpacing: 0.5,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('guru_journey_title'),
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              letterSpacing: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          // Decorative line
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(AppTheme.saffron.withValues(alpha: 0.3)),
              _line(AppTheme.saffron.withValues(alpha: 0.4)),
              _dot(AppTheme.saffron.withValues(alpha: 0.6)),
              _line(AppTheme.saffron.withValues(alpha: 0.4)),
              _dot(AppTheme.saffron.withValues(alpha: 0.3)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Timeline item ──────────────────────────────────────────────────────────

  Widget _buildTimelineItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String year,
    required String title,
    required String body,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: timeline line + icon ─────────────────────────────────
          SizedBox(
            width: 52,
            child: Column(
              children: [
                // Line above icon (hidden for first item)
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 20,
                    color: AppTheme.saffron.withValues(alpha: 0.3),
                  )
                else
                  const SizedBox(height: 4),
                // Icon circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                // Line below icon (hidden for last item)
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppTheme.saffron.withValues(alpha: 0.3),
                    ),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // ── Right: content card ────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Year / era badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        year,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: iconColor,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            body,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.75,
                              color: Color(0xFF5D4037),
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pull quote ─────────────────────────────────────────────────────────────

  Widget _buildPullQuote(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.saffron.withValues(alpha: 0.12),
            AppTheme.gold.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.saffron.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.format_quote,
            size: 36,
            color: AppTheme.saffron.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('guru_journey_quote'),
            style: const TextStyle(
              fontSize: 16,
              height: 1.7,
              color: Color(0xFF6D4C41),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(AppTheme.saffron.withValues(alpha: 0.4)),
              const SizedBox(width: 6),
              Text(
                '— ${context.tr('sri_jeeveswara_yogi')}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.saffron,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              _dot(AppTheme.saffron.withValues(alpha: 0.4)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Closing blessing ───────────────────────────────────────────────────────

  Widget _buildClosingBlessing(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          // Lotus divider
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _line(AppTheme.saffron.withValues(alpha: 0.3), width: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '🪷',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              _line(AppTheme.saffron.withValues(alpha: 0.3), width: 60),
            ],
          ),
          const SizedBox(height: 20),
          // Jai Gurudev pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              gradient: AppTheme.saffronGradient,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.saffron.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              context.tr('jai_gurudev'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Text(
          //   'ॐ नमः शिवाय',
          //   style: TextStyle(
          //     fontSize: 20,
          //     color: AppTheme.saffron.withValues(alpha: 0.7),
          //     letterSpacing: 2,
          //     fontWeight: FontWeight.w500,
          //   ),
          // ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _dot(Color color, {double size = 6}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _line(Color color, {double width = 40}) {
    return Container(width: width, height: 1.5, color: color);
  }
}
