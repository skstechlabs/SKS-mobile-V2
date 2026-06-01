import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/localization_service.dart';

class KalpataruPage extends StatefulWidget {
  const KalpataruPage({Key? key}) : super(key: key);

  @override
  State<KalpataruPage> createState() => _KalpataruPageState();
}

class _KalpataruPageState extends State<KalpataruPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/meditation.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.darken,
          ),
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildHeroSection(),
            _buildStatsSection(),
            _buildWhatIsSection(),
            _buildSecretSection(),
            _buildHowItWorksSection(),
            _buildKarmaSection(),
            _buildEnergySection(),
            _buildManifestationSection(),
            _buildBenefitsSection(),
            _buildReadySection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.saffron.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/Guruji_Meditation.PNG',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Color(0xFFd4a843),
                Color(0xFFf5e6a3),
                Color(0xFFd4a843),
              ],
            ).createShader(bounds),
            child: Text(
              'Sri Jeeveswara\'s Kalpataru',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            'The Impact of Kalpataru',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFfbbf24),
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildStatCard('✨', '4', 'hrs', 'One Miracle')),
              Expanded(child: _buildStatCard('🙏', '10K+', '', 'Sadhaks')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('🌍', '40+', '', 'Countries')),
              Expanded(child: _buildStatCard('🧘', '5000+', '', 'Practitioners')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String suffix, String label) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            '$value$suffix',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFfbbf24).withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWhatIsSection() {
    return _buildSection(
      title: 'What is Kalpataru?',
      children: [
        _buildGlassCard(
          child: Column(
            children: [
              _buildItalicText('What if the life you are living is only a fraction of what is truly possible?'),
              const SizedBox(height: 12),
              _buildItalicText('What if healing happens when you shift within?'),
              const SizedBox(height: 12),
              _buildItalicText('What if manifestation unfolds through inner harmony?'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildHighlightCard(
          title: 'Kalpataru is the Answer!',
          content: 'A divine revelation — a sacred practice designed by Moksha Guru to transform human lives.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: ['Health', 'Relationships', 'Finances', 'Success', 'Inner Peace', 'Any Desire']
              .map((item) => _buildChip(item))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSecretSection() {
    return _buildSection(
      icon: '🔐',
      title: 'A Sacred Secret Revealed',
      children: [
        _buildGlassCard(
          child: Column(
            children: [
              Text(
                'For ages, the deeper laws of healing and manifestation remained hidden. Kalpataru is one such rare technique, revealed by Gurudev — not for a few, but for all who are ready to transform.',
                style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.95), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildItalicText('Not belief', fontSize: 14),
                  Text(' • ', style: TextStyle(color: Color(0xFFfbbf24).withOpacity(0.4))),
                  _buildItalicText('Not imagination', fontSize: 14),
                  Text(' • ', style: TextStyle(color: Color(0xFFfbbf24).withOpacity(0.4))),
                  Text('Direct experience', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Color(0xFFfbbf24), fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorksSection() {
    return _buildSection(
      icon: '🌿',
      title: 'How Kalpataru Works',
      subtitle: 'Heals the Root of the Pain',
      children: [
        _buildGlassCard(
          child: _buildItalicText('"The problem is not where it appears. The root lies deeper."', fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Text(
          'Pain dissolves through three layers:',
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        _buildLayerCard('Sthula', 'Physical Body'),
        _buildLayerCard('Sukshma', 'Subtle Body — mind, energy, emotions'),
        _buildLayerCard('Karana', 'Causal Body — karmic blueprint'),
        const SizedBox(height: 12),
        _buildItalicText('Not partial healing — total transformation.', color: Color(0xFFfbbf24)),
      ],
    );
  }

  Widget _buildKarmaSection() {
    return _buildSection(
      icon: '🔥',
      title: 'The Karma Connection',
      children: [
        _buildGlassCard(
          child: Column(
            children: [
              Text(
                'Every challenge in life arises from karma.',
                style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Kalpataru heals the karmic imprint. The cycle dissolves.',
                style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'The problem does NOT return.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFfbbf24),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnergySection() {
    return _buildSection(
      title: 'Energy & Consciousness',
      children: [
        Row(
          children: [
            Expanded(
              child: _buildGlassCard(
                child: Column(
                  children: [
                    Text(
                      'Everything is Energy',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFfbbf24)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    _buildItalicText('(Shakthi)', fontSize: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGlassCard(
                child: Column(
                  children: [
                    Text(
                      'Everything is Consciousness',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFfbbf24)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    _buildItalicText('(Siva)', fontSize: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildGlassCard(
          child: Column(
            children: [
              Text(
                'Kalpataru aligns both. When you practice:',
                style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ...[
                'Your consciousness shifts',
                'Your inner state transforms',
                'The external problem dissolves naturally'
              ].map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text('✦ ', style: TextStyle(color: Color(0xFFfbbf24))),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.95)),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManifestationSection() {
    return _buildSection(
      title: 'The Secret of Manifestation',
      children: [
        ...[
          'You become deeply connected to your desire',
          'Your energy aligns with it',
          'The manifestation unfolds — effortlessly'
        ].asMap().entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildGlassCard(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(0xFFd4a843).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFe8d48b),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value,
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.95)),
                  ),
                ),
              ],
            ),
          ),
        )),
        const SizedBox(height: 16),
        _buildHighlightCard(
          title: 'Manifestation Multiplied',
          content: 'Kalpataru awakens your manifestation power itself. You become a creator of your reality.',
        ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    return _buildSection(
      title: 'What Kalpataru Brings',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            {'icon': '❤️‍🩹', 'text': 'Deep healing'},
            {'icon': '🙏', 'text': 'Harmonious relationships'},
            {'icon': '🕊️', 'text': 'Emotional freedom'},
            {'icon': '🧘', 'text': 'Clarity and focus'},
            {'icon': '🌱', 'text': 'Spiritual growth'},
            {'icon': '✨', 'text': 'Effortless manifestation'},
          ].map((item) => _buildBenefitChip(item['icon']!, item['text']!)).toList(),
        ),
        const SizedBox(height: 16),
        _buildHighlightCard(
          content: '5000+ practitioners on this sacred path — Kalpataru is now their daily reality.',
        ),
      ],
    );
  }

  Widget _buildReadySection() {
    return _buildSection(
      title: 'Are You Ready?',
      children: [
        ...[
          'heal at the root',
          'go beyond karma',
          'manifest consciously',
          'transform completely'
        ].map((text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildGlassCard(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.95)),
                children: [
                  TextSpan(text: 'Are you ready to '),
                  TextSpan(
                    text: text,
                    style: TextStyle(color: Color(0xFFfbbf24), fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: '?'),
                ],
              ),
            ),
          ),
        )),
        const SizedBox(height: 16),
        _buildHighlightCard(
          content: 'Then this sacred path is for you. 🙏',
          highlight: true,
        ),
      ],
    );
  }

  // Helper widgets
  Widget _buildSection({
    String? icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          if (icon != null)
            Text(icon, style: TextStyle(fontSize: 32)),
          if (icon != null) const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Color(0xFFd4a843), Color(0xFFf5e6a3), Color(0xFFd4a843)],
            ).createShader(bounds),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Color(0xFFfbbf24).withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: child,
    );
  }

  Widget _buildHighlightCard({String? title, required String content, bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: highlight
            ? LinearGradient(colors: [Color(0xFFf59e0b), Color(0xFFfbbf24)])
            : null,
        color: highlight ? null : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFd4a843).withOpacity(0.3)),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: Color(0xFFfbbf24).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          if (title != null) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: highlight ? Colors.black : Color(0xFFfbbf24),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: highlight ? Colors.black : Colors.white.withOpacity(0.95),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLayerCard(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFd4a843).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFfbbf24),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
      ),
    );
  }

  Widget _buildBenefitChip(String icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.95)),
          ),
        ],
      ),
    );
  }

  Widget _buildItalicText(String text, {double fontSize = 16, FontWeight? fontWeight, Color? color}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontStyle: FontStyle.italic,
        fontWeight: fontWeight,
        color: color ?? Colors.white.withOpacity(0.9),
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }
}
