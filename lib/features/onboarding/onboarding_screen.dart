import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/localization_service.dart';

// ── Theme: light, warm, spiritual — matches the app's saffron/cream palette ─
const _kBg       = Color(0xFFFFFBF5);
const _kBgCard   = Color(0xFFFFF3E0);
const _kGold     = Color(0xFFD4A017);
const _kText     = Color(0xFF1A1100);
const _kSubtext  = Color(0xFF6D5A2C);

const String _kOnboardingDoneKey = 'onboarding_completed_v1';

Future<bool> hasCompletedOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDoneKey) ?? false;
}

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDoneKey, true);
}

// ── Slide data ────────────────────────────────────────────────────────────────

class _SlideData {
  final String icon;        // emoji used as hero icon
  final String tag;         // small label tag
  final String titleKey;
  final String bodyKey;
  final List<_Feature> features;

  const _SlideData({
    required this.icon,
    required this.tag,
    required this.titleKey,
    required this.bodyKey,
    this.features = const [],
  });
}

class _Feature {
  final String icon;
  final String labelKey;
  const _Feature(this.icon, this.labelKey);
}

// ── Onboarding Screen ─────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  final String destination;
  const OnboardingScreen({super.key, this.destination = '/'});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;

  static final _slides = <_SlideData>[
    const _SlideData(
      icon: '🕉️',
      tag: 'onb_tag_welcome',
      titleKey: 'onb_slide1_title',
      bodyKey: 'onb_slide1_body',
      features: [
        _Feature('🌍', 'onb_f1_a'),
        _Feature('🆓', 'onb_f1_b'),
        _Feature('🤲', 'onb_f1_c'),
      ],
    ),
    const _SlideData(
      icon: '🙏',
      tag: 'onb_tag_gurudev',
      titleKey: 'onb_slide2_title',
      bodyKey: 'onb_slide2_body',
      features: [
        _Feature('⚡', 'onb_f2_a'),
        _Feature('🏔️', 'onb_f2_b'),
        _Feature('🌅', 'onb_f2_c'),
      ],
    ),
    const _SlideData(
      icon: '🌀',
      tag: 'onb_tag_kundalini',
      titleKey: 'onb_slide3_title',
      bodyKey: 'onb_slide3_body',
      features: [
        _Feature('🔥', 'onb_f3_a'),
        _Feature('🌸', 'onb_f3_b'),
        _Feature('✨', 'onb_f3_c'),
      ],
    ),
    const _SlideData(
      icon: '📚',
      tag: 'onb_tag_learn',
      titleKey: 'onb_slide4_title',
      bodyKey: 'onb_slide4_body',
      features: [
        _Feature('1️⃣', 'onb_f4_a'),
        _Feature('2️⃣', 'onb_f4_b'),
        _Feature('🔓', 'onb_f4_c'),
      ],
    ),
    const _SlideData(
      icon: '🧘',
      tag: 'onb_tag_meditate',
      titleKey: 'onb_slide5_title',
      bodyKey: 'onb_slide5_body',
      features: [
        _Feature('⏱️', 'onb_f5_a'),
        _Feature('🔔', 'onb_f5_b'),
        _Feature('📊', 'onb_f5_c'),
      ],
    ),
    const _SlideData(
      icon: '🎵',
      tag: 'onb_tag_bhajans',
      titleKey: 'onb_slide6_title',
      bodyKey: 'onb_slide6_body',
      features: [
        _Feature('🎶', 'onb_f6_a'),
        _Feature('📿', 'onb_f6_b'),
        _Feature('🖼️', 'onb_f6_c'),
      ],
    ),
    const _SlideData(
      icon: '🌟',
      tag: 'onb_tag_begin',
      titleKey: 'onb_slide7_title',
      bodyKey: 'onb_slide7_body',
    ),
  ];

  Future<void> _finish() async {
    await markOnboardingDone();
    if (mounted) context.go(widget.destination);
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
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

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Subtle radial glow behind content
          Positioned(
            top: -100,
            left: -60,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _kGold.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      // Step indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _kGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _kGold.withValues(alpha: 0.25),
                              width: 1),
                        ),
                        child: Text(
                          '${_page + 1} / ${_slides.length}',
                          style: const TextStyle(
                            color: _kGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                          foregroundColor: _kSubtext,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                        child: Text(
                          context.tr('skip'),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Pages ────────────────────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (ctx, i) =>
                        _OnboardingPage(slide: _slides[i]),
                  ),
                ),

                // ── Dot indicators ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3.5),
                        width: active ? 24 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3.5),
                          color: active
                              ? _kGold
                              : _kGold.withValues(alpha: 0.22),
                        ),
                      );
                    }),
                  ),
                ),

                // ── Navigation buttons ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: Row(
                    children: [
                      // Back
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
                              border: Border.all(
                                  color: _kGold.withValues(alpha: 0.35),
                                  width: 1.5),
                              color: _kGold.withValues(alpha: 0.05),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_rounded,
                              color: _kGold,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Next / Begin
                      Expanded(
                        child: GestureDetector(
                          onTap: _next,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFD4A017),
                                  Color(0xFFB8880F),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _kGold.withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLast
                                        ? context.tr('onb_get_started')
                                        : context.tr('next'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single slide content ──────────────────────────────────────────────────────

class _OnboardingPage extends StatefulWidget {
  final _SlideData slide;
  const _OnboardingPage({required this.slide});

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero icon + tag ────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Large emoji in gold ring
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _kGold.withValues(alpha: 0.18),
                          _kGold.withValues(alpha: 0.04),
                        ],
                      ),
                      border: Border.all(
                          color: _kGold.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        widget.slide.icon,
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: _kGold.withValues(alpha: 0.3),
                                width: 1),
                          ),
                          child: Text(
                            context.tr(widget.slide.tag).toUpperCase(),
                            style: const TextStyle(
                              color: _kGold,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Title
                        Text(
                          context.tr(widget.slide.titleKey),
                          style: const TextStyle(
                            color: _kText,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ── Gold divider ───────────────────────────────────────────
              Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _kGold.withValues(alpha: 0.6),
                      _kGold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Body text ──────────────────────────────────────────────
              Text(
                context.tr(widget.slide.bodyKey),
                style: const TextStyle(
                  color: _kText,
                  fontSize: 15,
                  height: 1.75,
                ),
              ),

              // ── Feature pills ──────────────────────────────────────────
              if (widget.slide.features.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _kBgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _kGold.withValues(alpha: 0.18), width: 1),
                  ),
                  child: Column(
                    children: widget.slide.features.map((f) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _kGold.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  f.icon,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                context.tr(f.labelKey),
                                style: const TextStyle(
                                  color: _kText,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
