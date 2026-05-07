import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/localization_service.dart';

class KundaliniSciencePage extends StatelessWidget {
  const KundaliniSciencePage({super.key});

  // Chakra colours — root → crown
  static const List<Color> _chakraColors = [
    Color(0xFFB71C1C), // Muladhara  — deep red
    Color(0xFFE65100), // Svadhisthana — orange
    Color(0xFFF9A825), // Manipura   — golden yellow
    Color(0xFF2E7D32), // Anahata    — green
    Color(0xFF1565C0), // Vishuddha  — blue
    Color(0xFF4527A0), // Ajna       — indigo
    Color(0xFF6A1B9A), // Sahasrara  — violet
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5), // soft lavender-cream
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A148C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('kundalini_science_title'),
          style: const TextStyle(
            color: Color(0xFF4A148C),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image ─────────────────────────────────────────────────
            _buildHeroImage(),

            // ── Sacred header ───────────────────────────────────────────────
            _buildSacredHeader(context),

            // ── Chakra strip ────────────────────────────────────────────────
            _buildChakraStrip(),

            const SizedBox(height: 8),

            // ── Content sections ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSection(
                    context,
                    icon: '🐍',
                    accentColor: const Color(0xFFB71C1C),
                    title: context.tr('kundalini_section_1_title'),
                    body: context.tr('kundalini_science_para1'),
                    highlight: context.tr('kundalini_highlight_1'),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    context,
                    icon: '✨',
                    accentColor: const Color(0xFF4527A0),
                    title: context.tr('kundalini_section_2_title'),
                    body: context.tr('kundalini_science_para2'),
                    highlight: context.tr('kundalini_highlight_2'),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    context,
                    icon: '📿',
                    accentColor: const Color(0xFF1B5E20),
                    title: context.tr('kundalini_section_3_title'),
                    body: context.tr('kundalini_science_para3'),
                    highlight: context.tr('kundalini_highlight_3'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ── Closing ─────────────────────────────────────────────────
            _buildClosing(context),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Hero image ─────────────────────────────────────────────────────────────

  Widget _buildHeroImage() {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: AppConstants.kundaliniImageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: const Color(0xFF4A148C).withValues(alpha: 0.15),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.saffron),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: const Color(0xFF4A148C).withValues(alpha: 0.15),
              child: const Icon(Icons.image_not_supported,
                  size: 48, color: Colors.white54),
            ),
          ),
          // Gradient overlay — purple at bottom
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x994A148C),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sacred header ──────────────────────────────────────────────────────────

  Widget _buildSacredHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF3E5F5),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        children: [
          // Sanskrit symbol
          // Text(
          //   'कुण्डलिनी',
          //   style: TextStyle(
          //     fontSize: 32,
          //     fontWeight: FontWeight.bold,
          //     color: const Color(0xFF6A1B9A).withValues(alpha: 0.75),
          //     letterSpacing: 2,
          //     height: 1.2,
          //   ),
          // ),
          const SizedBox(height: 10),
          _decorativeLine(const Color(0xFF6A1B9A)),
          const SizedBox(height: 14),
          Text(
            context.tr('kundalini_science_title'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('kundalini_subtitle'),
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF6A1B9A).withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          _decorativeLine(const Color(0xFF6A1B9A)),
        ],
      ),
    );
  }

  // ── Chakra colour strip ────────────────────────────────────────────────────

  Widget _buildChakraStrip() {
    return SizedBox(
      height: 8,
      child: Row(
        children: _chakraColors
            .map((c) => Expanded(child: Container(color: c)))
            .toList(),
      ),
    );
  }

  // ── Content section card ───────────────────────────────────────────────────

  Widget _buildSection(
    BuildContext context, {
    required String icon,
    required Color accentColor,
    required String title,
    required String body,
    required String highlight,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body text
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Text(
              body,
              style: const TextStyle(
                fontSize: 14,
                height: 1.8,
                color: Color(0xFF4E342E),
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.justify,
            ),
          ),

          // Highlight box
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(color: accentColor, width: 3),
              ),
            ),
            child: Text(
              highlight,
              style: TextStyle(
                fontSize: 13,
                color: accentColor,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Closing ────────────────────────────────────────────────────────────────

  Widget _buildClosing(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          // Lotus divider
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _hLine(const Color(0xFF6A1B9A).withValues(alpha: 0.3), 60),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('🪷', style: TextStyle(fontSize: 22)),
              ),
              _hLine(const Color(0xFF6A1B9A).withValues(alpha: 0.3), 60),
            ],
          ),
          const SizedBox(height: 20),
          // CTA pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              context.tr('awaken_inner_energy'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Text(
          //   'ॐ कुण्डलिन्यै नमः',
          //   style: TextStyle(
          //     fontSize: 18,
          //     color: const Color(0xFF6A1B9A).withValues(alpha: 0.65),
          //     letterSpacing: 2,
          //     fontWeight: FontWeight.w500,
          //   ),
          // ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _decorativeLine(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(color.withValues(alpha: 0.3)),
        _hLine(color.withValues(alpha: 0.4), 40),
        _dot(color.withValues(alpha: 0.6)),
        _hLine(color.withValues(alpha: 0.4), 40),
        _dot(color.withValues(alpha: 0.3)),
      ],
    );
  }

  Widget _dot(Color color, {double size = 6}) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _hLine(Color color, double width) =>
      Container(width: width, height: 1.5, color: color);
}
