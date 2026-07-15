import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/localization_service.dart';
import '../../core/services/sks_cache_manager.dart';
import '../../core/constants/cdn_images.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PATCH: inject new onboarding quote keys so they work even before a rebuild.
// rootBundle caches the asset JSON from build time; patchStrings() fills gaps.
// ─────────────────────────────────────────────────────────────────────────────
void _patchOnboardingStrings() {
  LocalizationService().patchStrings({
    'onb_slide1_quote': 'Liberation is not reserved for the few. It is the birthright of every human being.',
    'onb_slide2_quote': 'I am not here to prove that I am God. I am here to prove that you are God.',
    'onb_slide3_quote': 'Kundalini is not a metaphor. It is a living force within you, waiting to be awakened.',
    'onb_slide7_quote': 'I am not here to prove that I am God. I am here to prove that you are God.\n— Sri Jeeveswara Yogi Gurudev',
    // Updated bodies (in case old bundled JSON is still active)
    'onb_slide1_body': 'A non-profit spiritual organisation founded by Parama Pujya Sri Jeeveswara Yogi Gurudev — dedicated to guiding every soul on the path to Moksha.\n\nSalvation is the birthright of every human being. Freely given, open to all, with no barriers or prerequisites.',
    'onb_slide2_body': 'Born with an awakened Kundalini, Gurudev entered Samadhi at age 8. At 13, he set out alone to Srisailam — where Lord Shiva himself appeared as his Guru and bestowed Mantra Deeksha.\n\nAfter 24+ years of unbroken Sadhana and attaining Enlightenment, he left a flourishing career to devote his entire life to humanity.',
    'onb_slide3_body': 'Kundalini is the primordial cosmic energy lying coiled at the base of the spine — the very source of creation, resting within every human being.\n\nWhen awakened through Sadhana, it rises through the seven chakras, dissolving all blocks, and leads the seeker to Samadhi — union with the Divine.',
    'onb_slide7_title': 'Your Journey Begins Now',
    'onb_slide7_body': 'You are not alone on this path. A global family of seekers walks alongside you, held in Gurudev\'s boundless grace.\n\nEvery step in Sadhana brings you closer to the light that has always lived within you.\n\n🙏 Jai Gurudev 🙏',
  });
}

// ── Colors ────────────────────────────────────────────────────────────────────
const _kGold       = Color(0xFFD4A017);
const _kGoldLight  = Color(0xFFEDBB35);
const _kSaffron    = Color(0xFFC4622D);
const _kTextDark   = Color(0xFF2C1810);
const _kTextMid    = Color(0xFF6D4C2A);
const _kCardBg     = Color(0xFFFFFBF5); // warm cream, fully opaque

const String _kOnboardingDoneKey = 'onboarding_completed_v1';

Future<bool> hasCompletedOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDoneKey) ?? false;
}

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDoneKey, true);
}

// ── Slide model ───────────────────────────────────────────────────────────────

class _SlideData {
  final String imageUrl;     // CDN or asset path
  final String accentEmoji;  // small decorative emoji
  final String tagKey;
  final String titleKey;
  final String bodyKey;
  final String guruQuoteKey; // optional inline gurudev quote
  final List<_Bullet> bullets;
  final Color overlayColor;  // tint for the gradient overlay
  final bool imageOnBottom;  // image anchors to bottom (portrait shots)

  const _SlideData({
    required this.imageUrl,
    required this.accentEmoji,
    required this.tagKey,
    required this.titleKey,
    required this.bodyKey,
    this.guruQuoteKey = '',
    this.bullets = const [],
    this.overlayColor = const Color(0xFF1A0A00),
    this.imageOnBottom = false,
  });
}

class _Bullet {
  final String emoji;
  final String textKey;
  const _Bullet(this.emoji, this.textKey);
}

// ── Slide definitions (7 slides) ─────────────────────────────────────────────

final _slides = <_SlideData>[
  // 1 · Welcome — full Guruji portrait
  _SlideData(
    imageUrl: 'https://pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev/mobile/Guruji_dashboard.png',
    accentEmoji: '🕉️',
    tagKey: 'onb_tag_welcome',
    titleKey: 'onb_slide1_title',
    bodyKey: 'onb_slide1_body',
    guruQuoteKey: 'onb_slide1_quote',
    overlayColor: const Color(0xFF1A0500),
    imageOnBottom: true,
    bullets: const [
      _Bullet('🌍', 'onb_f1_a'),
      _Bullet('🆓', 'onb_f1_b'),
      _Bullet('🤲', 'onb_f1_c'),
    ],
  ),

  // 2 · Gurudev — divine encounter image
  _SlideData(
    imageUrl: CdnImages.guruJourneySlide2,
    accentEmoji: '🙏',
    tagKey: 'onb_tag_gurudev',
    titleKey: 'onb_slide2_title',
    bodyKey: 'onb_slide2_body',
    guruQuoteKey: 'onb_slide2_quote',
    overlayColor: const Color(0xFF0A1020),
    bullets: const [
      _Bullet('⚡', 'onb_f2_a'),
      _Bullet('🏔️', 'onb_f2_b'),
      _Bullet('✨', 'onb_f2_c'),
    ],
  ),

  // 3 · Kundalini — kundalini/chakra energy image
  _SlideData(
    imageUrl: CdnImages.kundalini,
    accentEmoji: '🌀',
    tagKey: 'onb_tag_kundalini',
    titleKey: 'onb_slide3_title',
    bodyKey: 'onb_slide3_body',
    guruQuoteKey: 'onb_slide3_quote',
    overlayColor: const Color(0xFF0A0020),
    bullets: const [
      _Bullet('🔥', 'onb_f3_a'),
      _Bullet('🌸', 'onb_f3_b'),
      _Bullet('☀️', 'onb_f3_c'),
    ],
  ),

  // 4 · Classes — meditation/guruji teaching image
  _SlideData(
    imageUrl: CdnImages.gurujiMeditation,
    accentEmoji: '📚',
    tagKey: 'onb_tag_learn',
    titleKey: 'onb_slide4_title',
    bodyKey: 'onb_slide4_body',
    overlayColor: const Color(0xFF001010),
    imageOnBottom: true,
    bullets: const [
      _Bullet('1️⃣', 'onb_f4_a'),
      _Bullet('🎥', 'onb_f4_b'),
      _Bullet('🔓', 'onb_f4_c'),
    ],
  ),

  // 5 · Meditation timer — serene meditation image
  _SlideData(
    imageUrl: CdnImages.meditation,
    accentEmoji: '🧘',
    tagKey: 'onb_tag_meditate',
    titleKey: 'onb_slide5_title',
    bodyKey: 'onb_slide5_body',
    overlayColor: const Color(0xFF001020),
    bullets: const [
      _Bullet('⏱️', 'onb_f5_a'),
      _Bullet('🔔', 'onb_f5_b'),
      _Bullet('📊', 'onb_f5_c'),
    ],
  ),

  // 6 · Bhajans — guruji smile / devotional image
  _SlideData(
    imageUrl: CdnImages.gurujiSmile,
    accentEmoji: '🎵',
    tagKey: 'onb_tag_bhajans',
    titleKey: 'onb_slide6_title',
    bodyKey: 'onb_slide6_body',
    overlayColor: const Color(0xFF200010),
    imageOnBottom: true,
    bullets: const [
      _Bullet('🎶', 'onb_f6_a'),
      _Bullet('📿', 'onb_f6_b'),
      _Bullet('🖼️', 'onb_f6_c'),
    ],
  ),

  // 7 · Begin — guruji30 contemplative
  _SlideData(
    imageUrl: CdnImages.guruji30,
    accentEmoji: '🌟',
    tagKey: 'onb_tag_begin',
    titleKey: 'onb_slide7_title',
    bodyKey: 'onb_slide7_body',
    guruQuoteKey: 'onb_slide7_quote',
    overlayColor: const Color(0xFF1A0500),
    imageOnBottom: true,
  ),
];

// ── Main screen ───────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  final String destination;
  const OnboardingScreen({super.key, this.destination = '/'});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;

  // Per-page entrance animation
  late AnimationController _entryCtrl;
  late Animation<double>   _entryFade;
  late Animation<Offset>   _entrySlide;

  // Glow pulse for CTA
  late AnimationController _glowCtrl;
  late Animation<double>   _glowAnim;

  @override
  void initState() {
    super.initState();

    // Inject new translation keys immediately (before first build)
    _patchOnboardingStrings();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.55, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _entryCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await markOnboardingDone();
    if (mounted) context.go(widget.destination);
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_page > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onPageChanged(int i) {
    setState(() => _page = i);
    _entryCtrl
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    final size   = MediaQuery.of(context).size;
    // Image zone = top 44% of screen; card zone = remaining below the wave
    final imageHeight = size.height * 0.44;

    return Scaffold(
      backgroundColor: _kCardBg,
      body: Stack(
        children: [
          // ── TOP: image zone (fixed height, image only) ──────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: imageHeight + 32, // +32 so image bleeds behind the wave
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: _slides.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (_, i) => _SlideImage(slide: _slides[i]),
            ),
          ),

          // ── Safe-area top bar (over image) ──────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(child: _buildTopBar(context)),
          ),

          // ── BOTTOM: cream card panel with wave top edge ─────────────
          Positioned(
            top: imageHeight - 24, // slightly overlaps image to create wave join
            left: 0, right: 0, bottom: 0,
            child: _WavePanel(
              child: Column(
                children: [
                  // Animated content
                  Expanded(
                    child: FadeTransition(
                      opacity: _entryFade,
                      child: SlideTransition(
                        position: _entrySlide,
                        child: _SlideContent(
                          slide: _slides[_page],
                          animCtrl: _entryCtrl,
                        ),
                      ),
                    ),
                  ),
                  // Dots + nav
                  _buildBottomControls(context, isLast),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          // Step pill — semi-transparent on top of image
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.30), width: 1),
            ),
            child: Text(
              '${_page + 1} / ${_slides.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _finish,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25), width: 1),
              ),
              child: Text(
                context.tr('skip'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, bool isLast) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 3.5),
                width: active ? 24 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: active ? _kGold : _kGold.withValues(alpha: 0.22),
                ),
              );
            }),
          ),

          const SizedBox(height: 14),

          // Nav row
          Row(
            children: [
              // Back button
              AnimatedOpacity(
                opacity: _page > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _page > 0 ? _back : null,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kGold.withValues(alpha: 0.10),
                      border: Border.all(
                          color: _kGold.withValues(alpha: 0.35), width: 1.5),
                    ),
                    child: Icon(Icons.arrow_back_ios_rounded,
                        color: _kSaffron, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Next / Begin
              Expanded(
                child: AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => GestureDetector(
                    onTap: _next,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: isLast
                              ? [_kSaffron, const Color(0xFFE07840)]
                              : [_kGold, _kGoldLight],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isLast ? _kSaffron : _kGold).withValues(
                                alpha: isLast
                                    ? _glowAnim.value * 0.50
                                    : 0.32),
                            blurRadius: isLast ? 26 : 14,
                            spreadRadius: isLast ? 2 : 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast
                                  ? context.tr('onb_get_started')
                                  : context.tr('next'),
                              style: TextStyle(
                                color: isLast ? Colors.white : _kTextDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              isLast
                                  ? Icons.auto_awesome_rounded
                                  : Icons.arrow_forward_rounded,
                              color: isLast ? Colors.white : _kTextDark,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Wave-top cream panel ──────────────────────────────────────────────────────
// Clips the top edge with a smooth upward curve so the image peeks above it.

class _WavePanel extends StatelessWidget {
  final Widget child;
  const _WavePanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        color: _kCardBg,
        child: child,
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Start from top-left
    path.moveTo(0, 32);
    // Cubic bezier curve for smooth wave at top
    path.cubicTo(
      size.width * 0.25, 0,
      size.width * 0.75, 0,
      size.width, 32,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper old) => false;
}

// ── Top image zone (image only, no overlay) ───────────────────────────────────

class _SlideImage extends StatelessWidget {
  final _SlideData slide;
  const _SlideImage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background colour while loading
        Container(color: slide.overlayColor),

        // Photo
        CachedNetworkImage(
          imageUrl: slide.imageUrl,
          fit: BoxFit.cover,
          cacheManager: SksCacheManager(),
          alignment: slide.imageOnBottom
              ? Alignment.bottomCenter
              : Alignment.center,
          fadeInDuration: const Duration(milliseconds: 400),
          placeholder: (_, __) => Center(
            child: Text(slide.accentEmoji,
                style: const TextStyle(fontSize: 72)),
          ),
          errorWidget: (_, __, ___) => Center(
            child: Text(slide.accentEmoji,
                style: const TextStyle(fontSize: 72)),
          ),
        ),

        // Thin bottom gradient so image blends into the cream card smoothly
        Positioned(
          bottom: 0, left: 0, right: 0,
          height: 80,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  _kCardBg.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
        ),

        // Subtle radial gold glow at top-center (brand accent)
        Positioned(
          top: -30, left: 0, right: 0,
          child: Center(
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _kGold.withValues(alpha: 0.14),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Slide content — staggered entry animations ────────────────────────────────

class _SlideContent extends StatefulWidget {
  final _SlideData slide;
  final AnimationController animCtrl;

  const _SlideContent({required this.slide, required this.animCtrl});

  @override
  State<_SlideContent> createState() => _SlideContentState();
}

class _SlideContentState extends State<_SlideContent> {
  // Each logical group enters with a small stagger offset
  late Animation<double> _tagFade;
  late Animation<Offset>  _tagSlide;
  late Animation<double> _titleFade;
  late Animation<Offset>  _titleSlide;
  late Animation<double> _bodyFade;
  late Animation<Offset>  _bodySlide;
  late Animation<double> _bulletFade;
  late Animation<double> _quoteFade;

  @override
  void initState() {
    super.initState();
    final c = widget.animCtrl;

    _tagFade   = _fadeIn(c, 0.00, 0.45);
    _tagSlide  = _slideIn(c, 0.00, 0.45);
    _titleFade = _fadeIn(c, 0.12, 0.55);
    _titleSlide= _slideIn(c, 0.12, 0.55);
    _bodyFade  = _fadeIn(c, 0.25, 0.70);
    _bodySlide = _slideIn(c, 0.25, 0.70);
    _bulletFade= _fadeIn(c, 0.40, 0.85);
    _quoteFade = _fadeIn(c, 0.55, 1.00);
  }

  Animation<double> _fadeIn(AnimationController c, double begin, double end) =>
      Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: c, curve: Interval(begin, end, curve: Curves.easeOut)));

  Animation<Offset> _slideIn(AnimationController c, double begin, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(parent: c, curve: Interval(begin, end, curve: Curves.easeOutCubic)));

  @override
  Widget build(BuildContext context) {
    final slide     = widget.slide;
    final title     = context.tr(slide.titleKey);
    final body      = context.tr(slide.bodyKey);
    final hasQuote  = slide.guruQuoteKey.isNotEmpty;
    final quote     = hasQuote ? context.tr(slide.guruQuoteKey) : '';
    final hasBullets= slide.bullets.isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Tag pill ──────────────────────────────────────────────
          FadeTransition(
            opacity: _tagFade,
            child: SlideTransition(
              position: _tagSlide,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _kGold.withValues(alpha: 0.35), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(slide.accentEmoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      context.tr(slide.tagKey).toUpperCase(),
                      style: const TextStyle(
                        color: _kGold,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Title ────────────────────────────────────────────────
          FadeTransition(
            opacity: _titleFade,
            child: SlideTransition(
              position: _titleSlide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _kTextDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Gold accent line
                  Container(
                    width: 44,
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_kGold, _kGoldLight]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Body text ────────────────────────────────────────────
          FadeTransition(
            opacity: _bodyFade,
            child: SlideTransition(
              position: _bodySlide,
              child: Text(
                body,
                style: const TextStyle(
                  color: _kTextMid,
                  fontSize: 14,
                  height: 1.75,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),

          // ── Bullets ──────────────────────────────────────────────
          if (hasBullets) ...[
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _bulletFade,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _kGold.withValues(alpha: 0.18), width: 1),
                ),
                child: Column(
                  children: slide.bullets.map((b) => _BulletRow(b)).toList(),
                ),
              ),
            ),
          ],

          // ── Gurudev quote ────────────────────────────────────────
          if (hasQuote && quote.isNotEmpty && quote != slide.guruQuoteKey) ...[
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _quoteFade,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _kGold.withValues(alpha: 0.10),
                      _kSaffron.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _kGold.withValues(alpha: 0.30), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\u201C',
                      style: TextStyle(
                        fontSize: 34,
                        height: 0.85,
                        color: _kGold.withValues(alpha: 0.65),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        quote,
                        style: const TextStyle(
                          color: _kTextDark,
                          fontSize: 13.5,
                          fontStyle: FontStyle.italic,
                          height: 1.62,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Bullet row ────────────────────────────────────────────────────────────────

class _BulletRow extends StatelessWidget {
  final _Bullet bullet;
  const _BulletRow(this.bullet);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kGold.withValues(alpha: 0.18),
                  _kSaffron.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _kGold.withValues(alpha: 0.25), width: 1),
            ),
            child: Center(
              child: Text(bullet.emoji,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                context.tr(bullet.textKey),
                style: const TextStyle(
                  color: _kTextDark,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
