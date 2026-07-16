import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/localization_service.dart';
import '../../core/widgets/cached_image.dart';

// Inline fallbacks for new keys stale in rootBundle cache
const Map<String, String> _enFallbacks = {
  'kundalini_section_tech_title': 'A Sacred Science and Inner Technology',
  'kundalini_tech_para':
      'Kundalini Yoga is not mere mysticism — it is the most ancient technology known to humanity, a precise inner science through which we realise our fullest potential. Just as we harness modern technology in daily life, this timeless technology is meant to be used, carrying human consciousness to its ultimate completeness. It is also known as Laya Yoga, the path of dissolution: as the awakened energy rises to the crown chakra, the individual self merges — laya — into Shiva, the infinite. This is the very meaning of yoga: the union of the individual soul with the Supreme.',
  'kundalini_highlight_tech':
      'Kundalini is not superstition — it is the most ancient and precise technology known to humanity.',
  'kundalini_section_steps_title': 'The Path of Awakening, Step by Step',
  'kundalini_steps_intro':
      'Siva Kundalini Sadhana unfolds this journey as a clear, systematic progression — taught as graded levels and known not through belief, but through each seeker\'s own direct experience. Gurudev first opens the seeker\'s Brahmarandra, the subtle aperture at the crown, so that pure cosmic energy may descend from above and gently awaken the dormant Kundalini — making the awakening remarkably safe and effortless. From there, the path unfolds stage by stage:\n\n1. Awakening — the Kundalini, the Sushumna nadi, and the chakras are awakened from their dormant state.\n2. Purification — the awakened energy centres are cleansed, making the path of Kundalini energy ahead clear.\n3. Control — the seeker gains steady command over these inner energies.\n4. Opening of Petals — each chakra is opened completely, petal by petal, to its full radiance.\n5. The Point of No Return — as the energy reaches the Ajna (third eye), the Kundalini can no longer slip back into the lower chakras.\n6. Completeness — the Kundalini reaches the Sahasrara, and the seeker attains completeness.\n\nBecause Gurudev awakens this energy directly through Shaktipatham, his grace works uniquely for each seeker — for one the Kundalini may awaken fully on the very first day, for another over days or weeks — always unfolding exactly as is best for them.',
  'kundalini_highlight_steps':
      'You need not believe blindly — do the practice, and the truth reveals itself in your own experience.',
};
const Map<String, String> _teFallbacks = {
  'kundalini_section_tech_title': 'ఒక పవిత్ర విజ్ఞానం - అంతర్గత సాంకేతికత',
  'kundalini_tech_para':
      'కుండలిని యోగం కేవలం ఒక ఆధ్యాత్మిక భావన కాదు — అది మానవాళికి తెలిసిన అత్యంత ప్రాచీనమైన సాంకేతికత; మన సంపూర్ణత్వాన్ని సాధించడానికి ఉపయోగపడే ఒక సూక్ష్మమైన అంతర్గత శాస్త్రం. దీన్నే లయ యోగము అని కూడా అంటారు — జాగృతమైన కుండలిని శక్తి మూలాధారం నుంచి సహస్రారానికి చేరి, ఆ శక్తి శివుడిలో లయమైపోతుంది. ఇదే యోగము యొక్క అసలు అర్థం: జీవాత్మను పరమాత్మలో ఐక్యం చేయడమే.',
  'kundalini_highlight_tech':
      'కుండలిని ఒక మూఢనమ్మకం కాదు — ఇది మానవాళికి తెలిసిన అత్యంత ప్రాచీనమైన, సూక్ష్మమైన సాంకేతికత.',
  'kundalini_section_steps_title': 'దశలవారీగా సాగే జాగృతి మార్గం',
  'kundalini_steps_intro':
      'శివ కుండలిని సాధన ఈ ప్రయాణాన్ని ఒక స్పష్టమైన, క్రమబద్ధమైన దశల వరుసగా నేర్పించబడుతుంది. గురుదేవులు ముందుగా సాధకుని బ్రహ్మ రంధ్రాన్ని తెరుస్తారు; తద్వారా పైనుంచి స్వచ్ఛమైన విశ్వశక్తి లోపలికి దిగివచ్చి, నిద్రావస్థలో ఉన్న కుండలినిని సున్నితంగా జాగృతం చేస్తుంది.',
  'kundalini_highlight_steps':
      'గుడ్డిగా నమ్మాల్సిన అవసరం లేదు — సాధన చేయండి, సత్యం మీ స్వానుభవంలోనే మీకు గోచరిస్తుంది.',
};

// Chapter accent colours — one per section slide
const List<Color> _accentColors = [
  Color(0xFFB71C1C), // 1 Primordial Energy
  Color(0xFF4527A0), // 2 Inner Technology
  Color(0xFF1565C0), // 3 Seven Chakras
  Color(0xFF2E7D32), // 4 Path of Awakening
  Color(0xFF6A1B9A), // 5 Safe for Every Seeker
];

// Chakra rainbow colours for strip
const List<Color> _chakraColors = [
  Color(0xFFB71C1C), Color(0xFFE65100), Color(0xFFF9A825),
  Color(0xFF2E7D32), Color(0xFF1565C0), Color(0xFF4527A0), Color(0xFF6A1B9A),
];

class KundaliniSciencePage extends StatefulWidget {
  const KundaliniSciencePage({super.key});
  @override
  State<KundaliniSciencePage> createState() => _KundaliniSciencePageState();
}

class _KundaliniSciencePageState extends State<KundaliniSciencePage>
    with TickerProviderStateMixin {

  late PageController _pageController;
  late AnimationController _bounceCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _bounceAnim;
  int _currentPage = 0;
  bool _hintDismissed = false;

  // 7 slides: 1 cover + 5 chapters + 1 closing
  static const int _totalSlides = 7;

  String _tr(String key) {
    final live = LocalizationService().translate(key);
    if (live != key) return live;
    final lang = LocalizationService().currentLocale.languageCode;
    return (lang == 'te' ? _teFallbacks : _enFallbacks)[key] ?? key;
  }

  String _trc(BuildContext context, String key) => context.tr(key);

  @override
  void initState() {
    super.initState();
    final lang = LocalizationService().currentLocale.languageCode;
    LocalizationService().patchStrings(lang == 'te' ? _teFallbacks : _enFallbacks);

    _pageController = PageController();

    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: 16).animate(
        CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

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
              if (i == _totalSlides - 1) return _buildClosingSlide(ctx);
              return _buildChapterSlide(ctx, i - 1);
            },
          ),
          if (!_hintDismissed && _currentPage == 0)
            _buildSwipeHint(context),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildDotNav(),
          ),
        ],
      ),
    );
  }

  // ── Slide 0: Cover ────────────────────────────────────────────────────────

  Widget _buildCoverSlide(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen CDN image
        CachedImage(
          imageUrl: AppConstants.kundaliniSlide1,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        // Top vignette
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: const Alignment(0, 0.2),
              colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
            ),
          ),
        ),
        // Bottom gradient band
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 110),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [
                  const Color(0xFF0D0028).withValues(alpha: 0.96),
                  const Color(0xFF1A0040).withValues(alpha: 0.75),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ornamentalRule(const Color(0xFF9C27B0)),
                const SizedBox(height: 14),
                Text(
                  _trc(context, 'vedic_tradition').toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFCE93D8), fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _trc(context, 'kundalini_science_title'),
                  style: const TextStyle(
                    color: Colors.white, fontSize: 28,
                    fontWeight: FontWeight.bold, letterSpacing: 0.5, height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _trc(context, 'kundalini_subtitle'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13, letterSpacing: 1.5, fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                _ornamentalRule(const Color(0xFF9C27B0)),
                const SizedBox(height: 18),
                // Chakra rainbow strip
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(colors: _chakraColors),
                  ),
                ),
                const SizedBox(height: 16),
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

  // ── Slides 1–5: Chapter slides ─────────────────────────────────────────────

  Widget _buildChapterSlide(BuildContext context, int idx) {
    final accent = _accentColors[idx];
    final cdnImages = [
      AppConstants.kundaliniSlide2,
      AppConstants.kundaliniSlide3,
      AppConstants.kundaliniSlide4,
      AppConstants.kundaliniSlide5,
      AppConstants.kundaliniSlide6,
    ];
    final symbols = ['🐍', '⚡', '✨', '🪷', '🙏'];
    final numbers = ['01', '02', '03', '04', '05'];

    final eras = [
      _tr('kundalini_section_1_title'),
      _tr('kundalini_section_tech_title'),
      _trc(context, 'kundalini_section_2_title'),
      _tr('kundalini_section_steps_title'),
      _trc(context, 'kundalini_section_3_title'),
    ];
    final titles = [
      _trc(context, 'kundalini_science_title'),
      _tr('kundalini_section_tech_title'),
      _trc(context, 'kundalini_section_2_title'),
      _tr('kundalini_section_steps_title'),
      _trc(context, 'kundalini_section_3_title'),
    ];
    final bodies = [
      _trc(context, 'kundalini_science_para1'),
      _tr('kundalini_tech_para'),
      _trc(context, 'kundalini_science_para2'),
      _tr('kundalini_steps_intro'),
      _trc(context, 'kundalini_science_para3'),
    ];
    final highlights = [
      _trc(context, 'kundalini_highlight_1'),
      _tr('kundalini_highlight_tech'),
      _trc(context, 'kundalini_highlight_2'),
      _tr('kundalini_highlight_steps'),
      _trc(context, 'kundalini_highlight_3'),
    ];
    final isSteps = idx == 3;
    final paragraphs = bodies[idx].split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    final bgColor = [
      const Color(0xFFFFF3F3),
      const Color(0xFFF5F0FF),
      const Color(0xFFF0F5FF),
      const Color(0xFFF0FAF0),
      const Color(0xFFFAF4FF),
    ][idx];

    return Container(
      color: const Color(0xFFF8F4FF),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            expandedHeight: 310,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildChapterImage(
                cdnImages[idx], accent, numbers[idx], symbols[idx]),
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
                      child: Text(eras[idx],
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                              color: accent, letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 10),
                    Text(titles[idx],
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
                // Body
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                      if (isSteps && paragraphs[i].contains('\n') &&
                          (paragraphs[i].startsWith('1.') || paragraphs[i].contains('\n1.')))
                        _buildStepsList(paragraphs[i], accent)
                      else
                        Text(paragraphs[i].trim(),
                            style: const TextStyle(fontSize: 15, height: 1.85,
                                color: Color(0xFF3A2A5C), letterSpacing: 0.1),
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
                // Highlight box
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border(left: BorderSide(color: accent, width: 4)),
                    boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.07),
                        blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: Text(highlights[idx],
                      style: TextStyle(fontSize: 14, color: accent,
                          fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, height: 1.6)),
                ),
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
          top: 90, right: 16,
          child: Text(number,
              style: TextStyle(fontSize: 110, fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.07), height: 1)),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                const Color(0xFF9C27B0).withValues(alpha: 0.7),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // Renders numbered steps
  Widget _buildStepsList(String text, Color accentColor) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final match = RegExp(r'^(\d+)\.\s*\*\*(.+?)\*\*\s*(.*)$').firstMatch(line.trim());
        if (match != null) {
          final num = match.group(1)!;
          final bold = match.group(2)!;
          final rest = match.group(3) ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 24, height: 24,
                margin: const EdgeInsets.only(right: 10, top: 1),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12), shape: BoxShape.circle,
                  border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                ),
                child: Center(child: Text(num,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor))),
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, height: 1.7, color: Color(0xFF3A2A5C)),
                    children: [
                      TextSpan(text: bold, style: TextStyle(fontWeight: FontWeight.bold, color: accentColor)),
                      if (rest.isNotEmpty) TextSpan(text: ' — $rest'),
                    ],
                  ),
                ),
              ),
            ]),
          );
        }
        // Plain numbered line like "1. Awakening — ..."
        final plainMatch = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(line.trim());
        if (plainMatch != null) {
          final num = plainMatch.group(1)!;
          final content = plainMatch.group(2)!;
          final dashIdx = content.indexOf(' — ');
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 24, height: 24,
                margin: const EdgeInsets.only(right: 10, top: 1),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12), shape: BoxShape.circle,
                  border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                ),
                child: Center(child: Text(num,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor))),
              ),
              Expanded(
                child: dashIdx >= 0
                    ? RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14, height: 1.7, color: Color(0xFF3A2A5C)),
                          children: [
                            TextSpan(text: content.substring(0, dashIdx),
                                style: TextStyle(fontWeight: FontWeight.bold, color: accentColor)),
                            TextSpan(text: content.substring(dashIdx)),
                          ],
                        ),
                      )
                    : Text(content, style: const TextStyle(
                        fontSize: 14, height: 1.7, color: Color(0xFF3A2A5C))),
              ),
            ]),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(line.trim(),
              style: const TextStyle(fontSize: 15, height: 1.8, color: Color(0xFF3A2A5C)),
              textAlign: TextAlign.justify),
        );
      }).toList(),
    );
  }

  // ── Last slide: Closing ────────────────────────────────────────────────────

  Widget _buildClosingSlide(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedImage(
          imageUrl: AppConstants.kundaliniSlide1,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0D0028).withValues(alpha: 0.6),
                const Color(0xFF1A0040).withValues(alpha: 0.95),
              ],
              stops: const [0.2, 1.0],
            ),
          ),
        ),
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
        Positioned(
          bottom: 100, left: 24, right: 24,
          child: Column(children: [
            _ornamentalRule(const Color(0xFF9C27B0)),
            const SizedBox(height: 20),
            // Pull quote card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1A0033), Color(0xFF3A0066)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.45), width: 1.5),
                boxShadow: [BoxShadow(
                    color: const Color(0xFF6A1B9A).withValues(alpha: 0.4),
                    blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Stack(children: [
                Positioned(right: 12, top: 8,
                    child: Text('ॐ', style: TextStyle(fontSize: 72,
                        color: Colors.white.withValues(alpha: 0.04), height: 1))),
                Column(children: [
                  Icon(Icons.format_quote, size: 28,
                      color: const Color(0xFFCE93D8).withValues(alpha: 0.7)),
                  const SizedBox(height: 12),
                  Text(
                    _trc(context, 'kundalini_quote'),
                    style: const TextStyle(fontSize: 15, height: 1.8, color: Colors.white,
                        fontStyle: FontStyle.italic, letterSpacing: 0.3),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Container(width: 46, height: 1.5,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [
                        Colors.transparent,
                        const Color(0xFFCE93D8).withValues(alpha: 0.7),
                        Colors.transparent,
                      ]))),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 5, height: 5,
                        decoration: const BoxDecoration(color: Color(0xFFCE93D8), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('— ${_trc(context, 'sri_jeeveswara_yogi')}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFCE93D8),
                            fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    const SizedBox(width: 8),
                    Container(width: 5, height: 5,
                        decoration: const BoxDecoration(color: Color(0xFFCE93D8), shape: BoxShape.circle)),
                  ]),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            // Lotus divider
            Row(children: [
              Expanded(child: Container(height: 1, color: const Color(0xFF9C27B0).withValues(alpha: 0.3))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text('🪷', style: TextStyle(fontSize: 22))),
              Expanded(child: Container(height: 1, color: const Color(0xFF9C27B0).withValues(alpha: 0.3))),
            ]),
            const SizedBox(height: 18),
            // CTA button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)]),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(
                    color: const Color(0xFF6A1B9A).withValues(alpha: 0.45),
                    blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: Text(
                _trc(context, 'awaken_inner_energy'),
                style: const TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.bold, letterSpacing: 0.8),
                textAlign: TextAlign.center,
              ),
            ),
          ]),
        ),
      ],
    );
  }

  // ── Swipe Hint ─────────────────────────────────────────────────────────────

  Widget _buildSwipeHint(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.62,
      left: 0, right: 0,
      child: Column(children: [
        AnimatedBuilder(
          animation: _bounceAnim,
          builder: (_, __) => Transform.translate(
            offset: Offset(_bounceAnim.value, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: const Color(0xFF6A1B9A).withValues(alpha: 0.55),
                    blurRadius: 20, spreadRadius: 4)],
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Opacity(
            opacity: 0.7 + (_pulseCtrl.value * 0.3),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.swipe_right, color: const Color(0xFFCE93D8), size: 18),
                const SizedBox(width: 8),
                Text(_trc(context, 'swipe_to_explore'),
                    style: const TextStyle(color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Bottom dot nav ─────────────────────────────────────────────────────────

  Widget _buildDotNav() {
    Color dotColorFor(int i) {
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
          if (_currentPage < _totalSlides - 1)
            GestureDetector(
              onTap: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 350), curve: Curves.easeInOut),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: dotColorFor(_currentPage), shape: BoxShape.circle,
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _ornamentalRule(Color color) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _dot(color.withValues(alpha: 0.3), size: 5),
      const SizedBox(width: 4),
      Container(width: 28, height: 1, color: color.withValues(alpha: 0.4)),
      const SizedBox(width: 4),
      _dot(color.withValues(alpha: 0.7), size: 7),
      const SizedBox(width: 4),
      Container(width: 28, height: 1, color: color.withValues(alpha: 0.4)),
      const SizedBox(width: 4),
      _dot(color.withValues(alpha: 0.3), size: 5),
    ]);
  }

  Widget _dot(Color color, {double size = 6}) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
