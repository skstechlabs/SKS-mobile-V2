import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/localization_service.dart';
import '../../core/widgets/cached_image.dart';
import '../../core/theme/app_theme.dart';

// Slide accent colours — one per content slide
const List<Color> _accentColors = [
  Color(0xFFB71C1C), // What Are Chakras
  Color(0xFFE65100), // Activation vs Awakening
  Color(0xFF1565C0), // How Kundalini Rises
  Color(0xFF2E7D32), // Blocks & Balance
  Color(0xFF6A1B9A), // Physical Experiences
];

const List<Color> _chakraColors = [
  Color(0xFFB71C1C), Color(0xFFE65100), Color(0xFFF9A825),
  Color(0xFF2E7D32), Color(0xFF1565C0), Color(0xFF4527A0), Color(0xFF6A1B9A),
];

const List<String> _chakraSanskrit = [
  'Mooladhara', 'Swadhisthana', 'Manipura',
  'Anahata', 'Vishuddha', 'Ajna', 'Sahasrara',
];

class ChakraLandingPage extends StatefulWidget {
  const ChakraLandingPage({super.key});
  @override
  State<ChakraLandingPage> createState() => _ChakraLandingPageState();
}

class _ChakraLandingPageState extends State<ChakraLandingPage>
    with TickerProviderStateMixin {

  late PageController _pageController;
  late AnimationController _bounceCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _bounceAnim;
  int _currentPage = 0;
  bool _hintDismissed = false;

  // 1 cover + 5 content slides + 1 closing/explore slide = 7
  static const int _totalSlides = 7;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: 16)
        .animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _hintDismissed = true);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bounceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _tr(BuildContext context, String key) => context.tr(key);

  List<Map<String, dynamic>> _slides(BuildContext context) => [
    {'type': 'cover'},
    {
      'type': 'content',
      'title': _tr(context, 'chakra_what_are_title'),
      'body': _tr(context, 'chakra_what_are_body'),
      'accent': _accentColors[0],
      'image': AppConstants.chakraSlide2,
      'num': '01',
    },
    {
      'type': 'content',
      'title': _tr(context, 'chakra_activation_title'),
      'body': _tr(context, 'chakra_activation_body'),
      'accent': _accentColors[1],
      'image': AppConstants.chakraSlide3,
      'num': '02',
    },
    {
      'type': 'content',
      'title': _tr(context, 'chakra_how_kundalini_title'),
      'body': _tr(context, 'chakra_how_kundalini_body'),
      'accent': _accentColors[2],
      'image': AppConstants.chakraSlide4,
      'num': '03',
    },
    {
      'type': 'content',
      'title': _tr(context, 'chakra_blocks_title'),
      'body': _tr(context, 'chakra_blocks_body'),
      'accent': _accentColors[3],
      'image': AppConstants.chakraSlide5,
      'num': '04',
    },
    {
      'type': 'content',
      'title': _tr(context, 'chakra_physical_title'),
      'body': _tr(context, 'chakra_physical_body'),
      'accent': _accentColors[4],
      'image': AppConstants.chakraSlide6,
      'num': '05',
    },
    {'type': 'explore'},
  ];

  @override
  Widget build(BuildContext context) {
    final slides = _slides(context);
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
              final slide = slides[i];
              if (slide['type'] == 'cover') return _buildCoverSlide(ctx);
              if (slide['type'] == 'explore') return _buildExploreSlide(ctx);
              return _buildContentSlide(ctx, slide);
            },
          ),
          if (!_hintDismissed && _currentPage < _totalSlides - 1)
            _buildSwipeHint(context),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildDotNav(),
          ),
        ],
      ),
    );
  }

  // ── Cover Slide ────────────────────────────────────────────────────────────

  Widget _buildCoverSlide(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedImage(
          imageUrl: AppConstants.chakraSlide1,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        // Top vignette
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: const Alignment(0, 0.25),
              colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
            ),
          ),
        ),
        // Bottom gradient band
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 110),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.95),
                  Colors.black.withValues(alpha: 0.75),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ornamentalRule(),
                const SizedBox(height: 14),
                // Text(
                //   _tr(context, 'vedic_tradition').toUpperCase(),
                //   style: TextStyle(
                //     color: AppTheme.gold.withValues(alpha: 0.9),
                //     fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 4,
                //   ),
                //   textAlign: TextAlign.center,
                // ),
                const SizedBox(height: 8),
                Text(
                  _tr(context, 'seven_chakras'),
                  style: const TextStyle(
                    color: Colors.white, fontSize: 30,
                    fontWeight: FontWeight.bold, letterSpacing: 0.5, height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _tr(context, 'chakra_understanding_title'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13, letterSpacing: 1.5, fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _ornamentalRule(),
                const SizedBox(height: 18),
                // Chakra rainbow strip
                // Container(
                //   height: 5,
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(3),
                //     gradient: const LinearGradient(colors: _chakraColors),
                //   ),
                // ),
                const SizedBox(height: 18),
                // Mini chakra pills — tapping jumps to explore slide
                // Wrap(
                //   spacing: 8, runSpacing: 8,
                //   alignment: WrapAlignment.center,
                //   children: List.generate(7, (i) => GestureDetector(
                //     onTap: () => context.push('/chakra-detail', extra: {'initialIndex': i}),
                //     child: Container(
                //       padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                //       decoration: BoxDecoration(
                //         color: _chakraColors[i].withValues(alpha: 0.18),
                //         borderRadius: BorderRadius.circular(18),
                //         border: Border.all(color: _chakraColors[i].withValues(alpha: 0.5), width: 1.5),
                //       ),
                //       child: Text(
                //         _chakraSanskrit[i],
                //         style: TextStyle(
                //           color: _chakraColors[i],
                //           fontSize: 11, fontWeight: FontWeight.w700,
                //         ),
                //       ),
                //     ),
                //   )),
                // ),
              ],
            ),
          ),
        ),
        // Purple top accent line
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                const Color(0xFF9C27B0).withValues(alpha: 0.9),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // ── Content Slide (slides 1–5) ─────────────────────────────────────────────

  Widget _buildContentSlide(BuildContext context, Map<String, dynamic> slide) {
    final accent = slide['accent'] as Color;
    final paragraphs = (slide['body'] as String)
        .split('\n\n').where((p) => p.trim().isNotEmpty).toList();

    return Container(
      color: const Color(0xFFFFF8F0),
      child: CustomScrollView(
        slivers: [
          // Sticky image header
          SliverAppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            expandedHeight: 300,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildSlideImage(
                  slide['image'] as String, accent, slide['num'] as String),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title card
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withValues(alpha: 0.15)),
                    boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.1),
                        blurRadius: 18, offset: const Offset(0, 4))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${_tr(context, 'chakra_understanding_title')} · ${slide['num']}',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                            color: accent, letterSpacing: 1.5),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(slide['title'] as String,
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold,
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
                // Body paragraphs
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
                                decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.4),
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
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideImage(String url, Color accent, String number) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedImage(imageUrl: url, width: double.infinity, fit: BoxFit.cover),
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
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                accent.withValues(alpha: 0.7),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // ── Explore Slide (last slide) ─────────────────────────────────────────────

  Widget _buildExploreSlide(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedImage(
          imageUrl: AppConstants.chakrasImageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                const Color(0xFF0D0028).withValues(alpha: 0.97),
              ],
              stops: const [0.2, 1.0],
            ),
          ),
        ),
        // Purple top accent
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                const Color(0xFF9C27B0).withValues(alpha: 0.9),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        // Content
        Positioned(
          bottom: 100, left: 24, right: 24,
          child: Column(children: [
            _ornamentalRule(),
            const SizedBox(height: 18),
            Text(
              _tr(context, 'seven_chakras'),
              style: const TextStyle(
                color: Colors.white, fontSize: 28,
                fontWeight: FontWeight.bold, letterSpacing: 0.5, height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _tr(context, 'explore_chakras'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14, letterSpacing: 1, fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Chakra rainbow strip
            Container(
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(colors: _chakraColors),
              ),
            ),
            const SizedBox(height: 24),
            // 7 chakra buttons in a grid
            Wrap(
              spacing: 10, runSpacing: 10,
              alignment: WrapAlignment.center,
              children: List.generate(7, (i) => GestureDetector(
                onTap: () => context.push('/chakra-detail', extra: {'initialIndex': i}),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _chakraColors[i].withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _chakraColors[i].withValues(alpha: 0.6), width: 1.5),
                    boxShadow: [BoxShadow(
                        color: _chakraColors[i].withValues(alpha: 0.3),
                        blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Text(
                    _chakraSanskrit[i],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3,
                    ),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 24),
            // Main CTA button
            GestureDetector(
              onTap: () => context.push('/chakra-detail', extra: {'initialIndex': 0}),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)]),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.5),
                      blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.explore_outlined, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      _tr(context, 'explore_chakras'),
                      style: const TextStyle(
                        color: Colors.white, fontSize: 17,
                        fontWeight: FontWeight.bold, letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  // ── Swipe Hint ─────────────────────────────────────────────────────────────

  Widget _buildSwipeHint(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        Positioned(
          right: 12,
          top: screenHeight * 0.42,
          child: AnimatedBuilder(
            animation: _bounceAnim,
            builder: (_, __) => Transform.translate(
              offset: Offset(-_bounceAnim.value, 0),
              child: const Icon(Icons.swipe_left_rounded, color: Colors.white, size: 48),
            ),
          ),
        ),
        Positioned(
          bottom: 100, left: 0, right: 0,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Opacity(
                opacity: 0.6 + (_pulseCtrl.value * 0.4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swipe_left_rounded,
                          color: AppTheme.gold.withValues(alpha: 0.9), size: 16),
                      const SizedBox(width: 6),
                      Text(_tr(context, 'swipe_to_explore'),
                          style: const TextStyle(color: Colors.white, fontSize: 12,
                              fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Dot Nav ────────────────────────────────────────────────────────────────

  Widget _buildDotNav() {
    Color dotFor(int i) {
      if (i == 0) return const Color(0xFF9C27B0);
      if (i == _totalSlides - 1) return const Color(0xFF6A1B9A);
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
          Row(
            children: List.generate(_totalSlides, (i) {
              final isActive = i == _currentPage;
              final c = dotFor(i);
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
          if (_currentPage < _totalSlides - 1)
            GestureDetector(
              onTap: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 350), curve: Curves.easeInOut),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: dotFor(_currentPage), shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: dotFor(_currentPage).withValues(alpha: 0.45), blurRadius: 8)],
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
