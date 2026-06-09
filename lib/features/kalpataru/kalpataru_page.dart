import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class KalpataruPage extends StatefulWidget {
  const KalpataruPage({super.key});

  @override
  State<KalpataruPage> createState() => _KalpataruPageState();
}

class _KalpataruPageState extends State<KalpataruPage> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFFFF8E7), Color(0xFFFFF4D6)],
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildHeroSection(),
            _buildDivineIntroduction(),
            _buildPrincipleSection(),
            _buildHowItWorksSection(),
            _buildTransformationSection(),
            _buildBenefitsGrid(),
            _buildTestimonialsSection(),
            _buildCallToAction(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFFFF8E7), const Color(0xFFFFE5B4).withValues(alpha: 0.6)],
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.saffron.withValues(alpha: 0.1 + (_animationController.value * 0.2)),
                      AppTheme.saffron.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: child,
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFFFF9933), Color(0xFFFF6600)]),
                boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5)],
              ),
              child: const Center(child: Icon(Icons.spa_outlined, color: Colors.white, size: 40)),
            ),
          ),
          const SizedBox(height: 32),
          Text('ॐ', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w300, color: AppTheme.saffron.withValues(alpha: 0.8))),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFCC6600), Color(0xFFFF9933), Color(0xFFFFCC00)]).createShader(bounds),
            child: const Text('Kalpataru', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2, height: 1.2), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 8),
          Text('The Wish-Fulfilling Tree', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.grey[700], fontStyle: FontStyle.italic, letterSpacing: 1), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Container(width: 80, height: 3, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, AppTheme.saffron, Colors.transparent]))),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 4))]),
            child: Column(
              children: [
                Text('A Divine Technique', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600], letterSpacing: 2)),
                const SizedBox(height: 8),
                Text('Revealed by Sri Jeeveswara', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.saffron, letterSpacing: 0.5), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('Moksha Guru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700], fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivineIntroduction() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Text('What if you could manifest your deepest desires naturally?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.grey[800], height: 1.4), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 10))]),
            child: Column(
              children: [
                Icon(Icons.auto_awesome, size: 40, color: AppTheme.saffron),
                const SizedBox(height: 16),
                Text('Kalpataru is a sacred manifestation and healing technique revealed by Moksha Guru Sri Jeeveswara. Like the mythical wish-fulfilling tree, this divine practice helps you manifest health, relationships, abundance, and spiritual growth.', style: TextStyle(fontSize: 16, height: 1.8, color: Colors.grey[700], fontWeight: FontWeight.w400), textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrincipleSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.saffron.withValues(alpha: 0.08), const Color(0xFFFFE5B4).withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.saffron.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: AppTheme.saffron.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('THE PRINCIPLE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.saffron, letterSpacing: 2)),
          ),
          const SizedBox(height: 24),
          _buildPrincipleItem('🌟', 'Energy & Consciousness', 'Everything is Shakti (Energy) and Shiva (Consciousness)'),
          const SizedBox(height: 16),
          _buildPrincipleItem('🔄', 'Karmic Healing', 'Heals at the causal level - Sthula, Sukshma, and Karana bodies'),
          const SizedBox(height: 16),
          _buildPrincipleItem('✨', 'Direct Experience', 'Not belief or imagination - experience transformation directly'),
        ],
      ),
    );
  }

  Widget _buildPrincipleItem(String icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey[800])),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorksSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Text('How Kalpataru Works', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.grey[800]), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('Heals the Root Cause', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: AppTheme.saffron, fontWeight: FontWeight.w500)),
          const SizedBox(height: 40),
          _buildProcessStep('1', 'Identify the Challenge', 'Recognize what you want to heal or manifest'),
          const SizedBox(height: 12),
          _buildProcessStep('2', 'Practice Kalpataru', 'Connect with the divine energy through the sacred technique'),
          const SizedBox(height: 12),
          _buildProcessStep('3', 'Karmic Transformation', 'Healing occurs at the causal body - the root of all karma'),
          const SizedBox(height: 12),
          _buildProcessStep('4', 'Natural Manifestation', 'Your desire manifests effortlessly as consciousness shifts'),
        ],
      ),
    );
  }

  Widget _buildProcessStep(String number, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.saffron, const Color(0xFFFFAA00)]), shape: BoxShape.circle),
            child: Center(child: Text(number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey[800])),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 13, height: 1.5, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransformationSection() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.saffron, const Color(0xFFFF9933)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10))]),
      child: Column(
        children: [
          const Icon(Icons.self_improvement, size: 48, color: Colors.white),
          const SizedBox(height: 20),
          const Text('Three-Level Transformation', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _buildTransformationLevel('Sthula Sharira', 'Physical Body', 'Healing of physical ailments and manifestation in the material world'),
          const SizedBox(height: 16),
          _buildTransformationLevel('Sukshma Sharira', 'Subtle Body', 'Transformation of mind, emotions, and energy patterns'),
          const SizedBox(height: 16),
          _buildTransformationLevel('Karana Sharira', 'Causal Body', 'Dissolution of karmic imprints at the deepest level'),
        ],
      ),
    );
  }

  Widget _buildTransformationLevel(String sanskrit, String english, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text(sanskrit, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 4),
          Padding(padding: const EdgeInsets.only(left: 20), child: Text(english, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9)))),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.only(left: 20), child: Text(description, style: TextStyle(fontSize: 13, height: 1.5, color: Colors.white.withValues(alpha: 0.85)))),
        ],
      ),
    );
  }

  Widget _buildBenefitsGrid() {
    final benefits = [
      {'icon': Icons.favorite, 'title': 'Deep Healing', 'desc': 'Heal physical and emotional pain at the root'},
      {'icon': Icons.psychology, 'title': 'Mental Clarity', 'desc': 'Clear mind and focused consciousness'},
      {'icon': Icons.family_restroom, 'title': 'Harmonious Relations', 'desc': 'Transform relationships naturally'},
      {'icon': Icons.spa, 'title': 'Inner Peace', 'desc': 'Experience profound spiritual calm'},
      {'icon': Icons.trending_up, 'title': 'Abundance', 'desc': 'Manifest wealth and prosperity'},
      {'icon': Icons.auto_awesome, 'title': 'Spiritual Growth', 'desc': 'Accelerate your path to enlightenment'},
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Text('What Kalpataru Brings', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.grey[800]), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.87, // Adjusted for better fit
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: benefits.length,
                itemBuilder: (context, index) {
                  final benefit = benefits[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppTheme.saffron.withValues(alpha: 0.2), const Color(0xFFFFE5B4).withValues(alpha: 0.3)]),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(benefit['icon'] as IconData, size: 28, color: AppTheme.saffron),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          benefit['title'] as String,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey[800]),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Flexible(
                          child: Text(
                            benefit['desc'] as String,
                            style: TextStyle(fontSize: 11, height: 1.3, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: const Color(0xFFFFF8E7), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.saffron.withValues(alpha: 0.2), width: 1.5)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildStatCard('5000+', 'Practitioners'), const SizedBox(width: 20), _buildStatCard('10K+', 'Sadhaks')]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildStatCard('40+', 'Countries'), const SizedBox(width: 20), _buildStatCard('4 hrs', 'One Miracle')]),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Text('"The problem does NOT return"', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.saffron, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 2))]),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.saffron)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[600]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildCallToAction() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFFFFF8E7), const Color(0xFFFFE5B4).withValues(alpha: 0.6)]), borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Text('Are You Ready to Transform?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.grey[800]), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Text('Kalpataru is waiting for you', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600], fontStyle: FontStyle.italic), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 8))]),
            child: Column(
              children: [
                Icon(Icons.emoji_objects_outlined, size: 48, color: AppTheme.saffron),
                const SizedBox(height: 16),
                Text('Begin your journey of healing and manifestation through this sacred practice revealed by Moksha Guru', style: TextStyle(fontSize: 15, height: 1.7, color: Colors.grey[700]), textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
