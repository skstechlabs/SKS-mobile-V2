import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/localization_service.dart';
import '../../core/widgets/cached_image.dart';
import '../../core/constants/app_constants.dart';
import '../video/youtube_player.dart';

const Map<String, String> _enFallbacks = {
  'guru_journey_gift_of_grace': 'THE GIFT OF GRACE',
  'guru_journey_seekers_label': 'Lives Transformed',
  'guru_journey_shaktipatham_label': 'Shakthipatham In a Single Night',
};
const Map<String, String> _teFallbacks = {
  'guru_journey_gift_of_grace': 'అనుగ్రహ ప్రసాదం',
  'guru_journey_seekers_label': 'జీవితాలలో పరివర్తన',
  'guru_journey_shaktipatham_label': 'ఒకే రాత్రిలో',
};

// ── Slide accent colours (1 per chapter slide) ─────────────────────────────
const List<Color> _accentColors = [
  Color(0xFFE65100), // ch1 — awakening
  Color(0xFF6A1B9A), // ch2 — Srisailam
  Color(0xFF1565C0), // ch3 — enlightenment
  Color(0xFF2E7D32), // ch4 — mission
  Color(0xFFC4622D), // ch5 — grace
];

class GuruJourneyPage extends StatefulWidget {
  const GuruJourneyPage({super.key});
  @override
  State<GuruJourneyPage> createState() => _GuruJourneyPageState();
}

class _GuruJourneyPageState extends State<GuruJourneyPage>
    with TickerProviderStateMixin {
  static const String _videoId = '6mf3Rmykov4';

  late PageController _pageController;
  late AnimationController _swipeHintCtrl;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  int _currentPage = 0;
  bool _hintDismissed = false;

  String _tr(BuildContext context, String key) {
    final live = context.tr(key);
    if (live != key) return live;
    final lang = LocalizationService().currentLocale.languageCode;
    return (lang == 'te' ? _teFallbacks : _enFallbacks)[key] ?? key;
  }

  // Total slides: 1 cover + 5 chapters + 1 YouTube = 7
  static const int _totalSlides = 7;

  @override
  void initState() {
    super.initState();
    final lang = LocalizationService().currentLocale.languageCode;
    LocalizationService().patchStrings(lang == 'te' ? _teFallbacks : _enFallbacks);

    _pageController = PageController();

    // Swipe hint: bouncing arrow animation
    _bounceCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: 16).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    // Swipe hint: subtle shimmer on the hint label
    _swipeHintCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    // Auto-dismiss after 5 s
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _hintDismissed = true);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _swipeHintCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: SafeArea(
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          SafeArea(
            child: Container(
              margin: const EdgeInsets.only(right: 14, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Text(
                '${_currentPage + 1} / $_totalSlides',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) {
              setState(() {
                _currentPage = i;
                if (i > 0) _hintDismissed = true;
              });
            },
            itemCount: _totalSlides,
            itemBuilder: (ctx, i) {
              if (i == 0) return _buildCoverSlide(ctx);
              if (i == _totalSlides - 1) return _buildYouTubeSlide(ctx);
              return _buildChapterSlide(ctx, i - 1); // chapter index 0–4
            },
          ),

          // Swipe hint — only on cover
          if (!_hintDismissed && _currentPage == 0)
            _buildSwipeHint(context),

          // Bottom dot nav — always visible
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildDotNav(),
          ),
        ],
      ),
    );
  }

  // ── Slide 0: Cover — full screen image, Guruji name at bottom ─────────────

  Widget _buildCoverSlide(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen CDN image
        CachedImage(
          imageUrl: AppConstants.guruJourneySlide1,
          width: double.infinity,
          fit: BoxFit.cover,
        ),

        // Very light vignette top — just enough to read back button
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: const Alignment(0, 0.2),
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // Bottom gradient — dark band for text
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 110),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.92),
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Gold ornamental rule
                _ornamentalRule(),
                const SizedBox(height: 14),
                // MOKSHA GURU label
                Text(
                  context.tr('parama_pujya').toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.gold.withValues(alpha: 0.9),
                    fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Guruji's name — large
                Text(
                  context.tr('sri_jeeveswara_yogi'),
                  style: const TextStyle(
                    color: Colors.white, fontSize: 30,
                    fontWeight: FontWeight.bold, letterSpacing: 0.5, height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                // Subtitle
                Text(
                  context.tr('guru_journey_title'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13, letterSpacing: 2, fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                _ornamentalRule(),
                const SizedBox(height: 20),
                // Impact stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _coverStat('1,00,000+', _tr(context, 'guru_journey_seekers_label')),
                    _statDivider(),
                    _coverStat('2,316', _tr(context, 'guru_journey_shaktipatham_label')),
                    _statDivider(),
                    _coverStat('Asia', 'Book of Records'),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Gold top line
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                AppTheme.gold.withValues(alpha: 0.85),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _coverStat(String value, String label) {
    return Column(children: [
      Text(value, style: TextStyle(
          fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.gold)),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(
          fontSize: 9, color: Colors.white.withValues(alpha: 0.65), letterSpacing: 0.2),
          textAlign: TextAlign.center, maxLines: 2),
    ]);
  }

  Widget _statDivider() {
    return Container(
      width: 1, height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  // ── Slides 1–5: Chapter slides ─────────────────────────────────────────────

  Widget _buildChapterSlide(BuildContext context, int chapterIndex) {
    final accent = _accentColors[chapterIndex];

    // CDN image per chapter
    final cdnImages = [
      AppConstants.guruJourneySlide2,
      AppConstants.guruJourneySlide3,
      AppConstants.guruJourneySlide4,
      AppConstants.guruJourneySlide5,
      AppConstants.guruJourneySlide6,
    ];
    final symbols = ['🌅', '🕉️', '✨', '🌿', '🙏'];
    final numbers = ['01', '02', '03', '04', '05'];

    final eras = [
      context.tr('guru_journey_age_8'),
      context.tr('guru_journey_age_13'),
      context.tr('guru_journey_enlightenment'),
      context.tr('guru_journey_today'),
      _tr(context, 'guru_journey_gift_of_grace'),
    ];
    final titles = [
      context.tr('guru_journey_title_1'),
      context.tr('guru_journey_title_2'),
      context.tr('guru_journey_title_3'),
      context.tr('guru_journey_title_4'),
      context.tr('guru_journey_title_5'),
    ];
    final bodies = [
      context.tr('guru_journey_para1'),
      context.tr('guru_journey_para2'),
      context.tr('guru_journey_para3'),
      context.tr('guru_journey_para4'),
      context.tr('guru_journey_para5'),
    ];

    final isLast = chapterIndex == 4;
    final paragraphs = bodies[chapterIndex]
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    return Container(
      color: const Color(0xFFFFF8F0),
      child: CustomScrollView(
        slivers: [
          // ── Sticky hero image ──────────────────────────────────────────
          SliverAppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            expandedHeight: 310,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildChapterImage(
                cdnImages[chapterIndex],
                accent,
                numbers[chapterIndex],
                symbols[chapterIndex],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Era + title
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(color: accent.withValues(alpha: 0.1),
                          blurRadius: 18, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Era pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(eras[chapterIndex],
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                              color: accent, letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 10),
                    Text(titles[chapterIndex],
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                            color: accent, height: 1.25, letterSpacing: 0.2)),
                    const SizedBox(height: 10),
                    Container(height: 2, width: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [accent, Colors.transparent]),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ]),
                ),

                // Body
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withValues(alpha: 0.1)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (int i = 0; i < paragraphs.length; i++) ...[
                      if (i > 0) ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          Container(width: 20, height: 1, color: accent.withValues(alpha: 0.2)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Container(width: 5, height: 5,
                                decoration: BoxDecoration(color: accent.withValues(alpha: 0.4),
                                    shape: BoxShape.circle)),
                          ),
                          Expanded(child: Container(height: 1, color: accent.withValues(alpha: 0.08))),
                        ]),
                        const SizedBox(height: 10),
                      ],
                      Text(paragraphs[i].trim(),
                          style: const TextStyle(fontSize: 15, height: 1.85,
                              color: Color(0xFF4A3728), letterSpacing: 0.1),
                          textAlign: TextAlign.justify),
                    ],
                    const SizedBox(height: 16),
                    Container(height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [accent.withValues(alpha: 0.35), Colors.transparent]),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ]),
                ),

                // Quote + blessing on last chapter
                if (isLast) ...[
                  _buildPullQuote(context),
                  _buildClosingBlessing(context),
                ],

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterImage(String url, Color accent, String number, String symbol) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedImage(imageUrl: url, width: double.infinity, fit: BoxFit.cover),
        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.08),
                accent.withValues(alpha: 0.65),
              ],
              stops: const [0.35, 1.0],
            ),
          ),
        ),
        // Large watermark number
        Positioned(
          top: 90, right: 16,
          child: Text(number,
              style: TextStyle(fontSize: 110, fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.07), height: 1)),
        ),
        // Gold bottom accent line
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                AppTheme.gold.withValues(alpha: 0.7),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // ── Last slide: YouTube ────────────────────────────────────────────────────

  Widget _buildYouTubeSlide(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // YouTube thumbnail — full screen
        CachedImage(
          imageUrl: 'https://img.youtube.com/vi/$_videoId/maxresdefault.jpg',
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        // Dark overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                const Color(0xFF1A0A00).withValues(alpha: 0.9),
              ],
              stops: const [0.3, 1.0],
            ),
          ),
        ),
        // Gold top line
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                AppTheme.gold.withValues(alpha: 0.85),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        // Center: play button
        Center(
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => YouTubeVideoPlayer(
                  videoId: _videoId,
                  title: context.tr('guru_journey_title'),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing play button
                AnimatedBuilder(
                  animation: _swipeHintCtrl,
                  builder: (_, __) => Transform.scale(
                    scale: 1.0 + (_swipeHintCtrl.value * 0.06),
                    child: Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.red.shade900.withValues(alpha: 0.6),
                              blurRadius: 32, spreadRadius: 6),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 50),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(context.tr('guru_journey_watch_youtube'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5,
                    )),
              ],
            ),
          ),
        ),
        // Bottom: Guruji name + blessing
        Positioned(
          bottom: 100, left: 24, right: 24,
          child: Column(children: [
            _ornamentalRule(),
            const SizedBox(height: 14),
            Text(
              context.tr('sri_jeeveswara_yogi'),
              style: const TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,
                letterSpacing: 0.5, height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Pull quote
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
              ),
              child: Column(children: [
                Icon(Icons.format_quote, color: AppTheme.gold.withValues(alpha: 0.6), size: 24),
                const SizedBox(height: 8),
                Text(
                  context.tr('guru_journey_quote'),
                  style: TextStyle(
                    fontSize: 14, height: 1.7,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text('— ${context.tr('sri_jeeveswara_yogi')}',
                    style: TextStyle(fontSize: 11, color: AppTheme.gold.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 16),
            // Jai Gurudev pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.saffronGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.4),
                    blurRadius: 16, offset: const Offset(0, 5))],
              ),
              child: Text(context.tr('jai_gurudev'),
                  style: const TextStyle(color: Colors.white, fontSize: 17,
                      fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ]),
        ),
      ],
    );
  }

  // ── Swipe Hint ─────────────────────────────────────────────────────────────

  Widget _buildSwipeHint(BuildContext context) {
    return Positioned(
      // Vertically centered on screen, just below mid
      top: MediaQuery.of(context).size.height * 0.62,
      left: 0, right: 0,
      child: Column(
        children: [
          // Large animated arrow pointing right
          AnimatedBuilder(
            animation: _bounceAnim,
            builder: (_, __) => Transform.translate(
              offset: Offset(_bounceAnim.value, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.saffron,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.5),
                        blurRadius: 20, spreadRadius: 4),
                  ],
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 32),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Label
          AnimatedBuilder(
            animation: _swipeHintCtrl,
            builder: (_, __) => Opacity(
              opacity: 0.7 + (_swipeHintCtrl.value * 0.3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swipe_right, color: AppTheme.gold, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('swipe_to_explore'),
                      style: const TextStyle(
                        color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w600, letterSpacing: 0.5,
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

  // ── Bottom dot nav ─────────────────────────────────────────────────────────

  Widget _buildDotNav() {
    // Dot 0 = cover (gold), dots 1–5 = chapter accent, dot 6 = red (YouTube)
    Color dotColorFor(int i) {
      if (i == 0) return AppTheme.gold;
      if (i == _totalSlides - 1) return Colors.red.shade600;
      return _accentColors[i - 1];
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Prev
          if (_currentPage > 0)
            GestureDetector(
              onTap: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 350), curve: Curves.easeInOut),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 15),
              ),
            )
          else
            const SizedBox(width: 36),

          const SizedBox(width: 12),

          // Dots
          Row(
            children: List.generate(_totalSlides, (i) {
              final isActive = i == _currentPage;
              final c = dotColorFor(i);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isActive ? 22 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                  color: isActive ? c : Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isActive
                      ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)]
                      : null,
                ),
              );
            }),
          ),

          const SizedBox(width: 12),

          // Next
          if (_currentPage < _totalSlides - 1)
            GestureDetector(
              onTap: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 350), curve: Curves.easeInOut),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: dotColorFor(_currentPage),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: dotColorFor(_currentPage).withValues(alpha: 0.45),
                      blurRadius: 8)],
                ),
                child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 15),
              ),
            )
          else
            const SizedBox(width: 36),
        ],
      ),
    );
  }

  // ── Pull Quote ─────────────────────────────────────────────────────────────

  Widget _buildPullQuote(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3E1A00).withValues(alpha: 0.94),
            const Color(0xFF5D2A00).withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.22),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(children: [
        Positioned(right: 18, top: 14,
            child: Text('ॐ', style: TextStyle(fontSize: 80,
                color: Colors.white.withValues(alpha: 0.04), height: 1))),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Icon(Icons.format_quote, size: 28, color: AppTheme.gold.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(context.tr('guru_journey_quote'),
                style: const TextStyle(fontSize: 16, height: 1.75, color: Colors.white,
                    fontStyle: FontStyle.italic, letterSpacing: 0.3),
                textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Container(width: 48, height: 1.5,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [
                  Colors.transparent, AppTheme.gold.withValues(alpha: 0.6), Colors.transparent]))),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 5, height: 5, decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.5), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('— ${context.tr('sri_jeeveswara_yogi')}',
                  style: TextStyle(fontSize: 12, color: AppTheme.gold.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(width: 8),
              Container(width: 5, height: 5, decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.5), shape: BoxShape.circle)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildClosingBlessing(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(children: [
        Row(children: [
          Expanded(child: Container(height: 1, color: AppTheme.saffron.withValues(alpha: 0.2))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('🪷', style: TextStyle(fontSize: 22))),
          Expanded(child: Container(height: 1, color: AppTheme.saffron.withValues(alpha: 0.2))),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          decoration: BoxDecoration(
            gradient: AppTheme.saffronGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.4),
                blurRadius: 18, offset: const Offset(0, 5))],
          ),
          child: Text(context.tr('jai_gurudev'),
              style: const TextStyle(color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
      ]),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _ornamentalRule() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _dot(AppTheme.gold.withValues(alpha: 0.3), size: 5),
      const SizedBox(width: 4),
      Container(width: 28, height: 1, color: AppTheme.gold.withValues(alpha: 0.4)),
      const SizedBox(width: 4),
      _dot(AppTheme.gold.withValues(alpha: 0.7), size: 7),
      const SizedBox(width: 4),
      Container(width: 28, height: 1, color: AppTheme.gold.withValues(alpha: 0.4)),
      const SizedBox(width: 4),
      _dot(AppTheme.gold.withValues(alpha: 0.3), size: 5),
    ]);
  }

  Widget _dot(Color color, {double size = 6}) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
