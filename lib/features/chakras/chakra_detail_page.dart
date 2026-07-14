import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/localization_service.dart';

class ChakraDetailPage extends StatefulWidget {
  final int initialIndex;
  const ChakraDetailPage({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<ChakraDetailPage> createState() => _ChakraDetailPageState();
}

class _ChakraDetailPageState extends State<ChakraDetailPage> {
  late PageController _pageController;
  late int _currentIndex;

  // Root → Crown
  static const List<Color> _bgColors = [
    Color(0xFF8B1A1A), // Root
    Color(0xFFBF5000), // Sacral
    Color(0xFFA87800), // Solar
    Color(0xFF1A6635), // Heart
    Color(0xFF1A4A8A), // Throat
    Color(0xFF2E2E7A), // Third Eye
    Color(0xFF4A1070), // Crown
  ];
  static const List<Color> _accentColors = [
    Color(0xFFE53935),
    Color(0xFFE65100),
    Color(0xFFF9A825),
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFF4527A0),
    Color(0xFF6A1B9A),
  ];
  static const List<String> _symbols = ['🔴', '🟠', '🟡', '🟢', '🔵', '🟣', '🔮'];

  List<Map<String, dynamic>> _getChakras(BuildContext context) => [
    {
      'name': context.tr('chakra_root'), 'sanskrit': context.tr('chakra_mooladhara'),
      'image': AppConstants.rootChakraImageUrl,
      'location': context.tr('chakra_root_location'), 'color': context.tr('chakra_root_color'),
      'element': context.tr('chakra_root_element'), 'mantra': context.tr('chakra_root_mantra'),
      'petals': context.tr('chakra_root_petals'), 'deity': context.tr('chakra_root_deity'),
      'archetype': context.tr('chakra_root_archetype'), 'age': context.tr('chakra_root_age'),
      'desc': context.tr('chakra_root_desc'),
    },
    {
      'name': context.tr('chakra_sacral'), 'sanskrit': context.tr('chakra_swadhisthana'),
      'image': AppConstants.sacralChakraImageUrl,
      'location': context.tr('chakra_sacral_location'), 'color': context.tr('chakra_sacral_color'),
      'element': context.tr('chakra_sacral_element'), 'mantra': context.tr('chakra_sacral_mantra'),
      'petals': context.tr('chakra_sacral_petals'), 'deity': context.tr('chakra_sacral_deity'),
      'archetype': context.tr('chakra_sacral_archetype'), 'age': context.tr('chakra_sacral_age'),
      'desc': context.tr('chakra_sacral_desc'),
    },
    {
      'name': context.tr('chakra_solar_plexus'), 'sanskrit': context.tr('chakra_manipura'),
      'image': AppConstants.solarPlexusChakraImageUrl,
      'location': context.tr('chakra_solar_plexus_location'), 'color': context.tr('chakra_solar_plexus_color'),
      'element': context.tr('chakra_solar_plexus_element'), 'mantra': context.tr('chakra_solar_plexus_mantra'),
      'petals': context.tr('chakra_solar_plexus_petals'), 'deity': context.tr('chakra_solar_plexus_deity'),
      'archetype': context.tr('chakra_solar_plexus_archetype'), 'age': context.tr('chakra_solar_plexus_age'),
      'desc': context.tr('chakra_solar_plexus_desc'),
    },
    {
      'name': context.tr('chakra_heart'), 'sanskrit': context.tr('chakra_anahata'),
      'image': AppConstants.heartChakraImageUrl,
      'location': context.tr('chakra_heart_location'), 'color': context.tr('chakra_heart_color'),
      'element': context.tr('chakra_heart_element'), 'mantra': context.tr('chakra_heart_mantra'),
      'petals': context.tr('chakra_heart_petals'), 'deity': context.tr('chakra_heart_deity'),
      'archetype': context.tr('chakra_heart_archetype'), 'age': context.tr('chakra_heart_age'),
      'desc': context.tr('chakra_heart_desc'),
    },
    {
      'name': context.tr('chakra_throat'), 'sanskrit': context.tr('chakra_vishuddha'),
      'image': AppConstants.throatChakraImageUrl,
      'location': context.tr('chakra_throat_location'), 'color': context.tr('chakra_throat_color'),
      'element': context.tr('chakra_throat_element'), 'mantra': context.tr('chakra_throat_mantra'),
      'petals': context.tr('chakra_throat_petals'), 'deity': context.tr('chakra_throat_deity'),
      'archetype': context.tr('chakra_throat_archetype'), 'age': context.tr('chakra_throat_age'),
      'desc': context.tr('chakra_throat_desc'),
    },
    {
      'name': context.tr('chakra_third_eye'), 'sanskrit': context.tr('chakra_ajna'),
      'image': AppConstants.thirdEyeChakraImageUrl,
      'location': context.tr('chakra_third_eye_location'), 'color': context.tr('chakra_third_eye_color'),
      'element': context.tr('chakra_third_eye_element'), 'mantra': context.tr('chakra_third_eye_mantra'),
      'petals': context.tr('chakra_third_eye_petals'), 'deity': context.tr('chakra_third_eye_deity'),
      'archetype': context.tr('chakra_third_eye_archetype'), 'age': context.tr('chakra_third_eye_age'),
      'desc': context.tr('chakra_third_eye_desc'),
    },
    {
      'name': context.tr('chakra_crown'), 'sanskrit': context.tr('chakra_sahasrara'),
      'image': AppConstants.crownChakraImageUrl,
      'location': context.tr('chakra_crown_location'), 'color': context.tr('chakra_crown_color'),
      'element': context.tr('chakra_crown_element'), 'mantra': context.tr('chakra_crown_mantra'),
      'petals': context.tr('chakra_crown_petals'), 'deity': context.tr('chakra_crown_deity'),
      'archetype': context.tr('chakra_crown_archetype'), 'age': context.tr('chakra_crown_age'),
      'desc': context.tr('chakra_crown_desc'),
    },
  ];

  @override
  void initState() {
    super.initState();
    // No intro slide — this page is purely 7 chakra detail slides.
    // initialIndex directly maps to the chakra (0 = Root, 6 = Crown).
    _currentIndex = widget.initialIndex.clamp(0, 6);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chakras = _getChakras(context);
    final total = chakras.length; // 7 chakras only, no intro
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemCount: total,
        itemBuilder: (ctx, i) => _buildPage(ctx, chakras[i], i, total),
      ),
    );
  }

  Widget _buildPage(BuildContext context, Map<String, dynamic> chakra, int idx, int total) {
    final bg = _bgColors[idx];
    final accent = _accentColors[idx];
    final symbol = _symbols[idx];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [bg, bg.withValues(alpha: 0.85)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, bg),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildChakraHero(context, chakra, accent, symbol),
                    _buildMetaGrid(context, chakra, accent),
                    _buildDescSection(context, chakra, accent),
                    _buildNavDots(context, total),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, Color bg) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            ),
          ),
          const Spacer(),
          Text(
            context.tr('seven_chakras'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ── Hero: image + name ─────────────────────────────────────────────────────

  Widget _buildChakraHero(BuildContext context, Map<String, dynamic> chakra, Color accent, String symbol) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          // Chakra image
          Container(
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CachedNetworkImage(
                imageUrl: chakra['image'],
                fit: BoxFit.contain, width: double.infinity,
                placeholder: (_, __) => Container(
                  color: Colors.white.withValues(alpha: 0.15),
                  child: Center(child: Text(symbol, style: const TextStyle(fontSize: 80))),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.white.withValues(alpha: 0.15),
                  child: Center(child: Text(symbol, style: const TextStyle(fontSize: 80))),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Name
          Text(
            chakra['name'],
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            chakra['sanskrit'],
            style: TextStyle(
              fontSize: 17, color: Colors.white.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic, letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          // Mantra badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${context.tr('chakra_mantra')}: ${chakra['mantra']}',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2×3 meta grid ─────────────────────────────────────────────────────────

  Widget _buildMetaGrid(BuildContext context, Map<String, dynamic> chakra, Color accent) {
    final items = [
      [context.tr('chakra_location'), chakra['location'], '📍'],
      [context.tr('chakra_element'), chakra['element'], '🌿'],
      [context.tr('chakra_color'), chakra['color'], '🎨'],
      [context.tr('chakra_petals'), chakra['petals'], '🪷'],
      [context.tr('chakra_deity'), chakra['deity'], '🙏'],
      [context.tr('chakra_archetype'), chakra['archetype'], '✨'],
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          for (int r = 0; r < 3; r++) ...[
            Row(
              children: [
                Expanded(child: _metaCard(items[r * 2][0], items[r * 2][1], items[r * 2][2])),
                const SizedBox(width: 12),
                Expanded(child: _metaCard(items[r * 2 + 1][0], items[r * 2 + 1][1], items[r * 2 + 1][2])),
              ],
            ),
            if (r < 2) const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          // Age/stage — full width
          _metaCardWide('⏳', chakra['age']),
        ],
      ),
    );
  }

  Widget _metaCard(String label, String value, String icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              style: TextStyle(fontSize: 9, color: Colors.grey[600], fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center, maxLines: 2),
        ],
      ),
    );
  }

  Widget _metaCardWide(String icon, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  // ── Description section ────────────────────────────────────────────────────

  Widget _buildDescSection(BuildContext context, Map<String, dynamic> chakra, Color accent) {
    final paragraphs = (chakra['desc'] as String)
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: accent.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12), shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Icon(Icons.auto_stories_outlined, color: accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${context.tr('chakra_about')} ${chakra['name']}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accent),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < paragraphs.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(width: 20, height: 1, color: accent.withValues(alpha: 0.25)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Container(width: 4, height: 4,
                            decoration: BoxDecoration(color: accent.withValues(alpha: 0.4), shape: BoxShape.circle)),
                      ),
                      Expanded(child: Container(height: 1, color: accent.withValues(alpha: 0.1))),
                    ]),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    paragraphs[i].trim(),
                    style: const TextStyle(fontSize: 14.5, height: 1.85, color: Color(0xFF3A2A2A), letterSpacing: 0.1),
                    textAlign: TextAlign.justify,
                  ),
                ],
                const SizedBox(height: 14),
                Container(height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [accent.withValues(alpha: 0.4), Colors.transparent]),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigation dots ────────────────────────────────────────────────────────

  Widget _buildNavDots(BuildContext context, int total) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_currentIndex > 0)
            GestureDetector(
              onTap: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
              child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.arrow_back_ios, color: Colors.black54, size: 18)),
            )
          else
            const SizedBox(width: 34),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(total, (i) {
                // Each dot uses its chakra accent colour directly (no intro offset)
                final dotColor = _accentColors[i];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: _currentIndex == i ? 24 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _currentIndex == i ? dotColor : Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 4),
          if (_currentIndex < total - 1)
            GestureDetector(
              onTap: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accentColors[_currentIndex],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ),
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }
}
