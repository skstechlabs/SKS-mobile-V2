import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_env.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/localization_service.dart';
import '../../core/widgets/cached_image.dart';
import '../home/widgets/youtube_playlist_section.dart';
import 'kalpataru_experiences_widget.dart';

// ---------------------------------------------------------------------------
// Kalpataru Experiences — fetched live from CDN.
// Silently hidden on any network / parse failure (no error shown to user).
// ---------------------------------------------------------------------------

class _ExperienceImage {
  final String url;
  final String filename;
  const _ExperienceImage({required this.url, required this.filename});

  factory _ExperienceImage.fromJson(Map<String, dynamic> j) =>
      _ExperienceImage(
        url: j['url'] as String? ?? '',
        filename: j['filename'] as String? ?? '',
      );
}

class _KalpataruExperiencesSection extends StatefulWidget {
  const _KalpataruExperiencesSection();

  @override
  State<_KalpataruExperiencesSection> createState() =>
      _KalpataruExperiencesSectionState();
}

class _KalpataruExperiencesSectionState
    extends State<_KalpataruExperiencesSection> {
  // null  = still loading
  // []    = loaded but empty (hide section)
  // [..] = show section
  List<_ExperienceImage>? _images;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final baseUrl = AppEnv.apiBaseUrl.isNotEmpty
          ? AppEnv.apiBaseUrl
          : 'https://app.sivakundalini.org';

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response =
          await dio.get('$baseUrl/api/kalpataru/experiences');

      final data = response.data;
      if (data is Map && data['success'] == true) {
        final raw = data['images'] as List? ?? [];
        final images = raw
            .whereType<Map<String, dynamic>>()
            .map(_ExperienceImage.fromJson)
            .where((e) => e.url.isNotEmpty)
            .toList();

        if (mounted) setState(() => _images = images);
      } else {
        if (mounted) setState(() => _images = []);
      }
    } catch (_) {
      if (mounted) setState(() => _images = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_images == null) return const SizedBox.shrink();
    if (_images!.isEmpty) return const SizedBox.shrink();
    return _ExperiencesGallery(images: _images!);
  }
}

// ---------------------------------------------------------------------------
// Gallery + fullscreen lightbox
// ---------------------------------------------------------------------------

class _ExperiencesGallery extends StatefulWidget {
  final List<_ExperienceImage> images;
  const _ExperiencesGallery({required this.images});

  @override
  State<_ExperiencesGallery> createState() => _ExperiencesGalleryState();
}

class _ExperiencesGalleryState extends State<_ExperiencesGallery> {
  void _openLightbox(int startIndex) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      pageBuilder: (_, __, ___) => _LightboxScreen(
        images: widget.images,
        initialIndex: startIndex,
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 28, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.saffron, const Color(0xFFFF9933)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.saffron.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🙏', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kalpataru Experiences',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Real transformations from our practitioners',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.saffron.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.saffron.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${widget.images.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.saffron,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: widget.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final img = widget.images[index];
                return GestureDetector(
                  onTap: () => _openLightbox(index),
                  child: Container(
                    width: 170,
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF6EC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.saffron.withValues(alpha: 0.18),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CachedNetworkImage(
                        imageUrl: img.url,
                        width: 170,
                        height: 220,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: const Color(0xFFF5EDE0),
                          highlightColor: const Color(0xFFFFF8F0),
                          child: Container(
                            width: 170,
                            height: 220,
                            color: const Color(0xFFFDF6EC),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 24),
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_outlined,
                      size: 13, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to view full screen',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen lightbox with swipe navigation
// ---------------------------------------------------------------------------

class _LightboxScreen extends StatefulWidget {
  final List<_ExperienceImage> images;
  final int initialIndex;

  const _LightboxScreen({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_LightboxScreen> createState() => _LightboxScreenState();
}

class _LightboxScreenState extends State<_LightboxScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _prev() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _next() {
    if (_currentIndex < widget.images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1208),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 80),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF6EC),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: widget.images[index].url,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const SizedBox(
                            width: 200,
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFF6F00)),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: Colors.white30, size: 64),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_currentIndex > 0)
            Positioned(
              left: 8, top: 0, bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _prev,
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left,
                        color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          if (_currentIndex < widget.images.length - 1)
            Positioned(
              right: 8, top: 0, bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _next,
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right,
                        color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 24, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  final active = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? AppTheme.saffron
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inline fallbacks — exact copies of en.json / te.json values.
// Used when rootBundle cache hasn't picked up the new keys yet.
// ---------------------------------------------------------------------------
const Map<String, String> _enFb = {
  'kalpataru_hero_headline': 'What if you could manifest your deepest desires naturally?',
  'kalpataru_hero_sub': 'The world\'s easiest and fastest healing and manifestation technique — bestowed upon humanity, completely free, by Moksha Guru Sri Jeeveswara Yogi.',
  'kalpataru_intro_title': 'Welcome to Kalpataru',
  'kalpataru_intro_para': 'What if the life you are living today is only a fraction of what is truly possible? What if deep healing need not take years, and manifestation need not be a struggle — but could unfold naturally, through pure inner harmony?\n\nKalpataru is the sacred bridge between the reality you are living and the extraordinary life you were always meant to live. Named after the celestial wish-fulfilling tree, this rare and profound practice was once a closely guarded secret within the highest spiritual traditions. Out of pure compassion, Moksha Guru Sri Jeeveswara Yogi has revealed it to the world as a divine blessing — offered through Siva Kundalini Sadhana entirely free of cost. Kalpataru is not merely a technique; it is a direct, living experience that begins, at once, to transform every dimension of your existence.',
  'kalpataru_intro_highlight': 'Kalpataru is not something you believe in — it is something you experience.',
  'kalpataru_principle_title': 'Shiva and Shakti — The Foundation',
  'kalpataru_principle_para': 'At the heart of the universe lies one absolute truth: everything is Energy (Shakti), and everything is Consciousness (Shiva). Kalpataru aligns them both.',
  'kalpataru_pillar_1': 'Everything is Shakti (Energy) and Shiva (Consciousness) — and Kalpataru brings the two into perfect harmony.',
  'kalpataru_pillar_2': 'It heals at the causal level, working across the Sthula, Sukshma, and Karana bodies — so the root itself dissolves.',
  'kalpataru_pillar_3': 'Not belief, not imagination — transformation you witness for yourself, in your own life.',
  'kalpataru_works_title': 'Shift Your Frequency, Transform Your Reality',
  'kalpataru_works_sub': 'Heals the root cause',
  'kalpataru_works_para': 'Conventional methods ask you to struggle endlessly against your outer circumstances. Kalpataru takes a beautifully different path — it elevates the consciousness of the one who is experiencing life.\n\nThink of the health, abundance, and peace you long for as a high-frequency station, and your present struggles as a low-frequency one. Through Kalpataru and Gurudev\'s divine energy, your inner frequency is gently tuned away from the low vibration of lack and suffering, and raised to the frequency of healing and fulfilment. As your thought waves sync with this higher state, outer limitations dissolve of their own accord. You need not fight your circumstances at all — when your inner world shifts, your outer reality shifts with it.',
  'kalpataru_step_1': 'Recognise what you wish to heal or manifest.',
  'kalpataru_step_2': 'Connect with the divine energy through the sacred technique.',
  'kalpataru_step_3': 'Healing occurs at the causal body — the root of all karma.',
  'kalpataru_step_4': 'As your consciousness shifts, your desire manifests effortlessly.',
  'kalpataru_works_highlight': 'The outer world is simply a reflection of the inner. Change the frequency within, and reality reshapes itself.',
  'kalpataru_levels_title': 'Healing at the Absolute Root',
  'kalpataru_levels_para': 'Most methods treat only the surface symptom, and so the same suffering returns. Kalpataru works far deeper — across all three layers of your being.',
  'kalpataru_level_1_title': 'Sthula Sharira — Physical Body',
  'kalpataru_level_1': 'Healing of physical ailments and manifestation in the material world. Practitioners often witness something extraordinary: pain moving through the body from one place to another, before dissolving entirely into nothingness — revealing that the origin of pain is rarely where it appears.',
  'kalpataru_level_2_title': 'Sukshma Sharira — Subtle Body',
  'kalpataru_level_2': 'Transformation of the mind, emotions, and energy patterns, restoring you to profound inner peace.',
  'kalpataru_level_3_title': 'Karana Sharira — Causal Body',
  'kalpataru_level_3': 'Dissolution of karmic imprints at the deepest level — the very root of all recurring struggle.',
  'kalpataru_levels_closing': 'By clearing these karmic imprints at the causal level, Kalpataru breaks the cycle of suffering itself. Whether it is health, relationships, finances, success, or inner peace, the transformation is complete and lasting — and the same challenges do not come back.',
  'kalpataru_levels_highlight': 'The problem does NOT return.',
  'kalpataru_manifest_title': 'Become the Conscious Creator of Your Destiny',
  'kalpataru_manifest_para': 'Kalpataru does more than heal — it awakens the power of manifestation that already lives within you. You do not merely manifest a single desire; you awaken your whole potential to become the conscious creator of your own life.\n\nThe journey begins with small, immediate manifestations. Then, step by step, that ability multiplies — until the right opportunities, the right people, deep emotional freedom, and absolute clarity begin flowing into your life of their own accord. You stop merely reacting to life, and begin consciously creating it.',
  'kalpataru_manifest_highlight': 'When your consciousness, your energy, and your desire align in one frequency — manifestation becomes effortless.',
  'kalpataru_brings_title': 'What Kalpataru Brings',
  'kalpataru_brings_1_title': 'Deep Healing',
  'kalpataru_brings_1': 'Heal physical and emotional pain at its very root.',
  'kalpataru_brings_2_title': 'Mental Clarity',
  'kalpataru_brings_2': 'Clear thinking, steady focus, and confident decisions.',
  'kalpataru_brings_3_title': 'Harmonious Relations',
  'kalpataru_brings_3': 'Relationships restored through love, trust, and understanding.',
  'kalpataru_brings_4_title': 'Inner Peace',
  'kalpataru_brings_4': 'Freedom from fear, trauma, and repeating emotional patterns.',
  'kalpataru_brings_5_title': 'Abundance',
  'kalpataru_brings_5': 'Prosperity, success, and fulfilment flowing in naturally.',
  'kalpataru_brings_6_title': 'Spiritual Growth',
  'kalpataru_brings_6': 'An ever-deepening connection with your true Self.',
  'kalpataru_proof_para': 'Across the world, thousands of practitioners have already stepped onto this sacred path — and for them, Kalpataru is no longer a technique they practise, but a way of living. From the healing of chronic, life-altering conditions to the fulfilment of lifelong dreams, the miraculous has quietly become their everyday reality.',
  'kalpataru_proof_heading': 'Transforming Lives Across the World',
  'kalpataru_proof_highlight': 'For thousands across the world, Kalpataru is no longer a practice they follow — it has become the way they live.',
  'kalpataru_cta_title': 'Are You Ready to Transform?',
  'kalpataru_cta_sub': 'Kalpataru is waiting for you',
  'kalpataru_cta_para': 'Are you ready to heal at the absolute root?\nAre you ready to rise above your karma?\nAre you ready to manifest your highest potential — effortlessly?\n\nBegin your journey of healing and manifestation through this sacred practice revealed by Moksha Guru Sri Jeeveswara Yogi. The doorway to your highest potential stands open, and Gurudev\'s gift is waiting for you.',
  'kalpataru_cta_highlight': 'With a pure heart, this sacred Kalpataru technique can fulfil any desire. The only limit to what you may attain is your own imagination.',
  'kalpataru_cta_button': '✨ Begin Your Transformation ✨',
};

const Map<String, String> _teFb = {
  'kalpataru_hero_headline': 'మీలోని ప్రగాఢమైన కోరికలను సహజ సిద్ధంగా నెరవేర్చుకోగలిగితే ఎలా ఉంటుంది?',
  'kalpataru_hero_sub': 'మోక్షగురు శ్రీ జీవేశ్వర యోగి వారు మానవాళికి సంపూర్ణ ఉచితంగా ప్రసాదించిన, ప్రపంచంలోనే అత్యంత సులువైన మరియు వేగవంతమైన హీలింగ్ మరియు మ్యానిఫెస్టేషన్ ప్రక్రియ.',
  'kalpataru_intro_title': 'కల్పతరుకు స్వాగతం',
  'kalpataru_intro_para': 'ప్రస్తుతం మీరు జీవిస్తున్న జీవితం, మీ అసలు పరిధిలో ఒక చిన్న భాగం మాత్రమే అయితే? లోతైన స్వస్థత కోసం సంవత్సరాల సమయం అవసరం లేకపోతే? మీ కోరికలు సాకారం కావడానికి తీవ్రమైన పోరాటం అక్కర్లేకుండా, కేవలం అంతరంగ సమతుల్యత ద్వారానే అవి సహజంగా మీ జీవితంలోకి ప్రవహిస్తే?\n\nమీరు ప్రస్తుతం అనుభవిస్తున్న వాస్తవికతకు మరియు మీరు జీవించాల్సిన అద్భుతమైన జీవితానికి మధ్య ఉన్న పవిత్రమైన వారధే ఈ కల్పతరు. కోరిన కోరికలు తీర్చే దివ్య వృక్షం పేరుతో పిలువబడే ఈ అత్యున్నత, అరుదైన సాధన, యుగయుగాలుగా అత్యున్నత ఆధ్యాత్మిక సంప్రదాయాలలో ఒక రహస్యంగా దాగి ఉండేది. కల్పతరు కేవలం ఒక ప్రక్రియ కాదు; అది మీ జీవితంలోని ప్రతి కోణాన్నీ తక్షణమే మార్చివేసే ప్రారంభించే ఒక ప్రత్యక్ష జీవన అనుభవం.',
  'kalpataru_intro_highlight': 'కల్పతరు నమ్మవలసినది కాదు — మీ జీవితంలో స్వయంగా అనుభవించవలసినది.',
  'kalpataru_principle_title': 'శివ శక్తి — మూల సూత్రం',
  'kalpataru_principle_para': 'ఈ విశ్వం మొత్తం ఒకే ఒక్క సత్యంపై నిలిచి ఉంది: ప్రతిదీ శక్తి (Energy), ప్రతిదీ చైతన్యం (Consciousness). ఈ రెండింటినీ కల్పతరు ఏకం చేస్తుంది.',
  'kalpataru_pillar_1': 'విశ్వంలో ప్రతిదీ శక్తియే, ప్రతిదీ చైతన్యమే — ఈ రెండింటినీ కల్పతరు పరిపూర్ణ సమన్వయంలోకి తెస్తుంది.',
  'kalpataru_pillar_2': 'ఇది స్థూల, సూక్ష్మ, కారణ శరీరాల స్థాయిలో పనిచేస్తూ, సమస్యను మూలాలను సైతం కరిగించివేస్తుంది.',
  'kalpataru_pillar_3': 'ఇది కేవలం నమ్మకాలు, ఊహలు కావు — మీ జీవితంలో మీరు స్వయంగా వీక్షించే ప్రత్యక్ష మార్పు.',
  'kalpataru_works_title': 'మీ ఫ్రీక్వెన్సీ మారితే, మీ జీవితమే మారుతుంది',
  'kalpataru_works_sub': 'సమస్యను మూలం నుంచే నయం చేస్తుంది',
  'kalpataru_works_para': 'సాధారణ పద్ధతులు బయటి పరిస్థితులతో నిరంతరం పోరాడమని చెబుతాయి. కల్పతరు మార్గం పూర్తిగా భిన్నమైనది — అది వ్యక్తి యొక్క చైతన్యాన్నే ఉన్నత స్థాయికి తీసుకువెళ్తుంది.\n\nమీరు కోరుకునే ఆరోగ్యం, సమృద్ధి, ప్రశాంతతను ఒక ఉన్నత ఫ్రీక్వెన్సీ స్టేషన్‌గా, మీ ప్రస్తుత కష్టాలను తక్కువ ఫ్రీక్వెన్సీ స్టేషన్‌గా భావించండి. కల్పతరు ద్వారా, మీ అంతరంగ ఫ్రీక్వెన్సీ ఆరోగ్యం, విజయం, పరిపూర్ణత వైపు చేరుతుంది. మీ అంతర్గత ప్రపంచం మారినప్పుడు, బాహ్య ప్రపంచం కూడా మారిపోతుంది.',
  'kalpataru_step_1': 'మీరు దేని నుండి నివారణ పొందాలనుకుంటున్నారో స్పష్టంగా గుర్తించండి.',
  'kalpataru_step_2': 'ఈ పవిత్ర సాధన ద్వారా దివ్య శక్తితో అనుసంధానం అవ్వండి.',
  'kalpataru_step_3': 'సమస్త కర్మలకూ మూలమైన కారణ శరీర స్థాయిలో నివారణ జరుగుతుంది.',
  'kalpataru_step_4': 'మీ చైతన్యం ఉన్నత స్థితికి మారగానే, మీ కోరిక అప్రయత్నంగా సాకారమవుతుంది.',
  'kalpataru_works_highlight': 'బాహ్య ప్రపంచం అనేది మీ అంతరంగ ప్రపంచానికి ప్రతిబింబం. లోపలి ఫ్రీక్వెన్సీ మార్చండి — బాహ్య జీవితం రూపాంతరం చెందుతుంది.',
  'kalpataru_levels_title': 'సమస్యను మూలం నుంచే నయం చేయడం',
  'kalpataru_levels_para': 'చాలా పద్ధతులు పైపైన ఉన్న లక్షణాలకు మాత్రమే చికిత్స చేస్తాయి. కల్పతరు మన అస్తిత్వంలోని మూడు లోతైన స్థాయిలలోనూ పనిచేస్తుంది.',
  'kalpataru_level_1_title': 'స్థూల శరీరం',
  'kalpataru_level_1': 'శారీరక వ్యాధుల నివారణ. నొప్పి ఒక చోటి నుంచి మరో చోటికి కదులుతూ, చివరకు పూర్తిగా శూన్యంలో కలిసిపోతుంది.',
  'kalpataru_level_2_title': 'సూక్ష్మ శరీరం',
  'kalpataru_level_2': 'మనసు, భావోద్వేగాలు, శక్తి ప్రవాహాలలోని అసమతుల్యతలు తొలగి, లోతైన అంతరంగ ప్రశాంతత చేకూరుతుంది.',
  'kalpataru_level_3_title': 'కారణ శరీరం',
  'kalpataru_level_3': 'మీ పునరావృత సమస్యలకూ మూలమైన కర్మ ముద్రలు అత్యంత లోతైన స్థాయిలో కరిగిపోతాయి.',
  'kalpataru_levels_closing': 'కారణ శరీర స్థాయిలోని కర్మ ముద్రలను తొలగించడం ద్వారా, కల్పతరు బాధల చక్రాన్నే పూర్తిగా ఛేదిస్తుంది. ఈ పరివర్తన సంపూర్ణమైనది, శాశ్వతమైనది.',
  'kalpataru_levels_highlight': 'ఆ సమస్య మీ జీవితంలోకి మళ్లీ ఎప్పటికీ తిరిగి రాదు.',
  'kalpataru_manifest_title': 'మీ తలరాతను మీరే మార్చుకునే సృష్టికర్తగా మారండి',
  'kalpataru_manifest_para': 'కల్పతరు కేవలం రుగ్మతలను నయం చేయడం మాత్రమే కాదు — అది మీలో సహజంగా ఉన్న సంకల్ప సిద్ధి శక్తిని జాగృతం చేస్తుంది.\n\nఈ ప్రయాణం చిన్న చిన్న మేనిఫెస్టేషన్లతో మొదలవుతుంది. అప్పటి నుంచి, అడుగడుగునా ఆ శక్తి రెట్టింపవుతూ — సరైన అవకాశాలు, సరైన వ్యక్తులు, లోతైన భావోద్వేగ స్వేచ్ఛ, సంపూర్ణ స్పష్టత మీ జీవితంలోకి సహజంగా ప్రవహించడం మొదలవుతాయి.',
  'kalpataru_manifest_highlight': 'మీ చైతన్యం, శక్తి మరియు కోరిక ఒకే ఫ్రీక్వెన్స లో ఏకమైనప్పుడు — సాకారం అప్రయత్నంగా జరిగిపోతుంది.',
  'kalpataru_brings_title': 'కల్పతరువు మీ జీవితంలోకి తీసుకువచ్చే మార్పులు',
  'kalpataru_brings_1_title': 'లోతైన స్వస్థత',
  'kalpataru_brings_1': 'శారీరక, భావోద్వేగ బాధలు మూలం నుంచే నయమవుతాయి.',
  'kalpataru_brings_2_title': 'మానసిక స్పష్టత',
  'kalpataru_brings_2': 'స్పష్టమైన ఆలోచన, స్థిరమైన ఏకాగ్రత, ఆత్మవిశ్వాసంతో కూడిన నిర్ణయాలు.',
  'kalpataru_brings_3_title': 'సామరస్య సంబంధాలు',
  'kalpataru_brings_3': 'ప్రేమ, నమ్మకం, పరస్పర అవగాహనతో సంబంధాలు చక్కబడతాయి.',
  'kalpataru_brings_4_title': 'అంతరంగ ప్రశాంతత',
  'kalpataru_brings_4': 'భయం, బాధాకర జ్ఞాపకాలు, పునరావృత నమూనాల నుంచి విముక్తి.',
  'kalpataru_brings_5_title': 'సమృద్ధి',
  'kalpataru_brings_5': 'సంపద, విజయం, పరిపూర్ణత సహజంగానే మీ జీవితంలోకి ప్రవహిస్తాయి.',
  'kalpataru_brings_6_title': 'ఆధ్యాత్మిక వికాసం',
  'kalpataru_brings_6': 'మీ నిజ స్వరూపంతో నానాటికీ లోతైన అనుసంధానం.',
  'kalpataru_proof_para': 'ప్రపంచవ్యాప్తంగా వేలాది మంది సాధకులు ఈ దివ్య మార్గంలో అడుగుపెట్టారు. వారికి కల్పతరు ఒక జీవన విధానంగా మారిపోయింది.',
  'kalpataru_proof_heading': 'ప్రపంచవ్యాప్తంగా జీవితాలను మారుస్తున్న కల్పతరు',
  'kalpataru_proof_highlight': 'ప్రపంచవ్యాప్తంగా వేలాది మందికి కల్పతరు ఒక సాధన కాదు — అదే వారి జీవన విధానం.',
  'kalpataru_cta_title': 'పరివర్తనకు మీరు సిద్ధమేనా?',
  'kalpataru_cta_sub': 'కల్పతరు మీ కోసం వేచి ఉంది',
  'kalpataru_cta_para': 'సమస్యను మూలం నుంచే నయం చేసుకోవడానికి మీరు సిద్ధంగా ఉన్నారా?\nమీ కర్మను అధిగమించడానికి మీరు సిద్ధంగా ఉన్నారా?\nమీలోని అత్యున్నత సామర్థ్యాన్ని సాకారం చేసుకోవడానికి మీరు సిద్ధంగా ఉన్నారా?\n\nమోక్ష గురు శ్రీ జీవేశ్వర యోగి అందించిన ఈ పవిత్ర సాధన ద్వారా మీ ప్రయాణాన్ని ఇప్పుడే ప్రారంభించండి.',
  'kalpataru_cta_highlight': 'కల్పతరు సాధన ద్వారా, శుద్ధమైన మనసుతో మీరు ఏ కోరికనైనా నెరవేర్చుకోవచ్చు. మీరు సాధించగలిగేదానికి — కేవలం మీ ఊహాశక్తే హద్దు!',
  'kalpataru_cta_button': '✨ మీ పరివర్తనను ప్రారంభించండి ✨',
};

// Chapter accent colours — one per chapter slide (slides 1–7)
const List<Color> _accentColors = [
  Color(0xFFC4622D), // 1 Introduction
  Color(0xFFBF360C), // 2 Principle
  Color(0xFFE65100), // 3 How It Works
  Color(0xFFFF6F00), // 4 Transformation
  Color(0xFF6A1B9A), // 5 Manifestation
  Color(0xFFD84315), // 6 Benefits
  Color(0xFF4E342E), // 7 Proof & Experiences
];

class KalpataruPage extends StatefulWidget {
  const KalpataruPage({super.key});

  @override
  State<KalpataruPage> createState() => _KalpataruPageState();
}

class _KalpataruPageState extends State<KalpataruPage>
    with TickerProviderStateMixin {

  static const int _totalSlides = 9;
  late PageController _pageController;
  late AnimationController _bounceCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _bounceAnim;
  int _currentPage = 0;
  bool _hintDismissed = false;

  String _tr(String key) {
    final live = LocalizationService().translate(key);
    if (live != key) return live;
    final lang = LocalizationService().currentLocale.languageCode;
    return (lang == 'te' ? _teFb : _enFb)[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    final lang = LocalizationService().currentLocale.languageCode;
    LocalizationService().patchStrings(lang == 'te' ? _teFb : _enFb);

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
              onPressed: () => context.go('/'),
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
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
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
              if (i == 1) return _buildClosingSlide(ctx);
              return _buildChapterSlide(ctx, i - 2); // chapters 0–6
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

  // ── Slide 0: Cover ────────────────────────────────────────────────────────

  Widget _buildCoverSlide(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedImage(
          imageUrl: AppConstants.kalpataruSlide1,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        // Top vignette
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
        // Bottom dark gradient band
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 110),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF1A0A00).withValues(alpha: 0.97),
                  const Color(0xFF3E1A00).withValues(alpha: 0.80),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // _ornamentalRule(AppTheme.gold),
                const SizedBox(height: 14),
                // Text(
                //   'MOKSHA GURU',
                //   style: TextStyle(
                //     color: AppTheme.gold,
                //     fontSize: 11,
                //     fontWeight: FontWeight.w700,
                //     letterSpacing: 4,
                //   ),
                //   textAlign: TextAlign.center,
                // ),
                const SizedBox(height: 8),
                // const Text(
                //   'Sri Jeeveswara Yogi',
                //   style: TextStyle(
                //     color: Colors.white,
                //     fontSize: 30,
                //     fontWeight: FontWeight.bold,
                //     letterSpacing: 0.5,
                //     height: 1.2,
                //   ),
                //   textAlign: TextAlign.center,
                // ),
                const SizedBox(height: 6),
                Text(
                  _tr('kalpataru_hero_sub'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 13,
                    letterSpacing: 0.5,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                // const SizedBox(height: 18),
                // _ornamentalRule(AppTheme.gold),
                // const SizedBox(height: 18),
                // Stats row
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     _buildCoverStat('1,00,000+', 'Lives Transformed'),
                //     Container(width: 1, height: 36,
                //         color: Colors.white.withValues(alpha: 0.25),
                //         margin: const EdgeInsets.symmetric(horizontal: 14)),
                //     _buildCoverStat('2,316', 'Shaktipatham\nIn a Single Night'),
                //     Container(width: 1, height: 36,
                //         color: Colors.white.withValues(alpha: 0.25),
                //         margin: const EdgeInsets.symmetric(horizontal: 14)),
                //     _buildCoverStat('Asia', 'Book of Records'),
                //   ],
                // ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
        // Gold top accent line
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                AppTheme.gold.withValues(alpha: 0.9),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: AppTheme.gold,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 10,
                height: 1.3),
            textAlign: TextAlign.center),
      ],
    );
  }

  // ── Chapter image header (slides 1–7) ─────────────────────────────────────

  Widget _buildChapterImage(Color accent, String imageUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedImage(
          imageUrl: imageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
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
          child: Container(
            height: 3,
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

  // ── Slides 1–7: Chapter slides ─────────────────────────────────────────────

  Widget _buildChapterSlide(BuildContext context, int idx) {
    final accent = _accentColors[idx];
    // CDN image per chapter slide (slides 1–7 map to kalpataruSlide3–9,
    // since slide1=cover, slide2=CTA)
    final cdnImages = [
      AppConstants.kalpataruSlide3, // idx 0 · Introduction
      AppConstants.kalpataruSlide4, // idx 1 · Principle
      AppConstants.kalpataruSlide5, // idx 2 · How It Works
      AppConstants.kalpataruSlide6, // idx 3 · Transformation
      AppConstants.kalpataruSlide7, // idx 4 · Manifestation
      AppConstants.kalpataruSlide8, // idx 5 · Benefits
      AppConstants.kalpataruSlide9, // idx 6 · Proof & Experiences
    ];

    return Container(
      color: const Color(0xFFF8F2EC),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            expandedHeight: 310,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildChapterImage(accent, cdnImages[idx]),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildChapterContent(context, idx, accent),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterContent(BuildContext context, int idx, Color accent) {
    switch (idx) {
      case 0:
        return _buildSlide1Introduction(context, accent);
      case 1:
        return _buildSlide2Principle(context, accent);
      case 2:
        return _buildSlide3HowItWorks(context, accent);
      case 3:
        return _buildSlide4Transformation(context, accent);
      case 4:
        return _buildSlide5Manifestation(context, accent);
      case 5:
        return _buildSlide6Benefits(context, accent);
      case 6:
        return _buildSlide7Proof(context, accent);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Slide 1: Introduction ─────────────────────────────────────────────────

  Widget _buildSlide1Introduction(BuildContext context, Color accent) {
    final paras = _tr('kalpataru_intro_para')
        .split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    return Column(
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
              child: Text('INTRODUCTION',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: accent, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 10),
            Text(_tr('kalpataru_intro_title'),
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold,
                    color: accent, height: 1.25)),
            const SizedBox(height: 6),
            Text(_tr('kalpataru_hero_headline'),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: Colors.grey[700], height: 1.4)),
            const SizedBox(height: 10),
            Container(height: 2, width: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, Colors.transparent]),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ]),
        ),
        // Hero sub
        Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Text(_tr('kalpataru_hero_sub'),
              style: TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic,
                  color: accent, height: 1.6),
              textAlign: TextAlign.center),
        ),
        // Body paragraphs
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
            for (int i = 0; i < paras.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: 10),
                _paraDivider(accent),
                const SizedBox(height: 10),
              ],
              Text(paras[i].trim(),
                  style: const TextStyle(fontSize: 15, height: 1.85,
                      color: Color(0xFF4A3728), letterSpacing: 0.1),
                  textAlign: TextAlign.justify),
            ],
          ]),
        ),
        _highlightBox(_tr('kalpataru_intro_highlight'), accent),
        const SizedBox(height: 100),
      ],
    );
  }

  // ── Slide 2: Principle ────────────────────────────────────────────────────

  Widget _buildSlide2Principle(BuildContext context, Color accent) {
    final pillars = [
      {'icon': '🌟', 'body': _tr('kalpataru_pillar_1')},
      {'icon': '🔄', 'body': _tr('kalpataru_pillar_2')},
      {'icon': '✨', 'body': _tr('kalpataru_pillar_3')},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              child: Text('THE PRINCIPLE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: accent, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 10),
            Text(_tr('kalpataru_principle_title'),
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold,
                    color: accent, height: 1.25)),
            const SizedBox(height: 10),
            Container(height: 2, width: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, Colors.transparent]),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ]),
        ),
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
          child: Column(children: [
            Text(_tr('kalpataru_principle_para'),
                style: TextStyle(fontSize: 15, height: 1.8,
                    color: const Color(0xFF4A3728), letterSpacing: 0.1),
                textAlign: TextAlign.justify),
            const SizedBox(height: 20),
            for (int i = 0; i < pillars.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: 16),
                _paraDivider(accent),
                const SizedBox(height: 16),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                    ),
                    child: Center(child: Text(pillars[i]['icon']!,
                        style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(pillars[i]['body']!,
                        style: TextStyle(fontSize: 14, height: 1.7,
                            color: const Color(0xFF4A3728))),
                  ),
                ],
              ),
            ],
          ]),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  // ── Slide 3: How It Works ─────────────────────────────────────────────────

  Widget _buildSlide3HowItWorks(BuildContext context, Color accent) {
    final paras = _tr('kalpataru_works_para')
        .split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    final steps = [
      {'num': '1', 'title': 'Identify', 'body': _tr('kalpataru_step_1')},
      {'num': '2', 'title': 'Connect', 'body': _tr('kalpataru_step_2')},
      {'num': '3', 'title': 'Heal', 'body': _tr('kalpataru_step_3')},
      {'num': '4', 'title': 'Manifest', 'body': _tr('kalpataru_step_4')},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              child: Text('HOW IT WORKS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: accent, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 10),
            Text(_tr('kalpataru_works_title'),
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold,
                    color: accent, height: 1.25)),
            const SizedBox(height: 4),
            Text(_tr('kalpataru_works_sub'),
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic,
                    color: accent.withValues(alpha: 0.8))),
            const SizedBox(height: 10),
            Container(height: 2, width: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, Colors.transparent]),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ]),
        ),
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
            for (int i = 0; i < paras.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: 10),
                _paraDivider(accent),
                const SizedBox(height: 10),
              ],
              Text(paras[i].trim(),
                  style: const TextStyle(fontSize: 15, height: 1.85,
                      color: Color(0xFF4A3728), letterSpacing: 0.1),
                  textAlign: TextAlign.justify),
            ],
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _buildProcessStep(steps[i]['num']!, steps[i]['title']!,
                    steps[i]['body']!, accent),
              ],
            ],
          ),
        ),
        _highlightBox(_tr('kalpataru_works_highlight'), accent),
        const SizedBox(height: 100),
      ],
    );
  }

  // ── Slide 4: Transformation ───────────────────────────────────────────────

  Widget _buildSlide4Transformation(BuildContext context, Color accent) {
    final levels = [
      {
        'title': _tr('kalpataru_level_1_title'),
        'body': _tr('kalpataru_level_1'),
      },
      {
        'title': _tr('kalpataru_level_2_title'),
        'body': _tr('kalpataru_level_2'),
      },
      {
        'title': _tr('kalpataru_level_3_title'),
        'body': _tr('kalpataru_level_3'),
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              child: Text('TRANSFORMATION',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: accent, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 10),
            Text(_tr('kalpataru_levels_title'),
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold,
                    color: accent, height: 1.25)),
            const SizedBox(height: 10),
            Container(height: 2, width: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, Colors.transparent]),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ]),
        ),
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
          child: Column(children: [
            Text(_tr('kalpataru_levels_para'),
                style: const TextStyle(fontSize: 15, height: 1.8,
                    color: Color(0xFF4A3728)),
                textAlign: TextAlign.justify),
            const SizedBox(height: 20),
            for (int i = 0; i < levels.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.2)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 8, height: 8,
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(levels[i]['title']!,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                            color: accent))),
                  ]),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Text(levels[i]['body']!,
                        style: const TextStyle(fontSize: 13.5, height: 1.65,
                            color: Color(0xFF4A3728)),
                        textAlign: TextAlign.justify),
                  ),
                ]),
              ),
            ],
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.15)),
          ),
          child: Text(_tr('kalpataru_levels_closing'),
              style: const TextStyle(fontSize: 14.5, height: 1.75,
                  color: Color(0xFF4A3728)),
              textAlign: TextAlign.justify),
        ),
        _highlightBox(_tr('kalpataru_levels_highlight'), accent),
        const SizedBox(height: 100),
      ],
    );
  }

  // ── Slide 5: Manifestation ────────────────────────────────────────────────

  Widget _buildSlide5Manifestation(BuildContext context, Color accent) {
    final paras = _tr('kalpataru_manifest_para')
        .split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              child: Text('MANIFESTATION',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: accent, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 10),
            Text(_tr('kalpataru_manifest_title'),
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold,
                    color: accent, height: 1.25)),
            const SizedBox(height: 10),
            Container(height: 2, width: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, Colors.transparent]),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ]),
        ),
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
            for (int i = 0; i < paras.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: 10),
                _paraDivider(accent),
                const SizedBox(height: 10),
              ],
              Text(paras[i].trim(),
                  style: const TextStyle(fontSize: 15, height: 1.85,
                      color: Color(0xFF4A3728), letterSpacing: 0.1),
                  textAlign: TextAlign.justify),
            ],
          ]),
        ),
        _highlightBox(_tr('kalpataru_manifest_highlight'), accent),
        const SizedBox(height: 100),
      ],
    );
  }

  // ── Slide 6: Benefits ─────────────────────────────────────────────────────

  Widget _buildSlide6Benefits(BuildContext context, Color accent) {
    final benefits = [
      {'icon': Icons.favorite, 'titleKey': 'kalpataru_brings_1_title', 'descKey': 'kalpataru_brings_1'},
      {'icon': Icons.psychology, 'titleKey': 'kalpataru_brings_2_title', 'descKey': 'kalpataru_brings_2'},
      {'icon': Icons.family_restroom, 'titleKey': 'kalpataru_brings_3_title', 'descKey': 'kalpataru_brings_3'},
      {'icon': Icons.spa, 'titleKey': 'kalpataru_brings_4_title', 'descKey': 'kalpataru_brings_4'},
      {'icon': Icons.trending_up, 'titleKey': 'kalpataru_brings_5_title', 'descKey': 'kalpataru_brings_5'},
      {'icon': Icons.auto_awesome, 'titleKey': 'kalpataru_brings_6_title', 'descKey': 'kalpataru_brings_6'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              child: Text('BENEFITS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: accent, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 10),
            Text(_tr('kalpataru_brings_title'),
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold,
                    color: accent, height: 1.25)),
            const SizedBox(height: 10),
            Container(height: 2, width: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, Colors.transparent]),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.87,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: benefits.length,
            itemBuilder: (context, index) {
              final b = benefits[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          accent.withValues(alpha: 0.18),
                          AppTheme.gold.withValues(alpha: 0.12),
                        ]),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(b['icon'] as IconData, size: 28, color: accent),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _tr(b['titleKey'] as String),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: Colors.grey[800]),
                      textAlign: TextAlign.center, maxLines: 2,
                    ),
                    const SizedBox(height: 5),
                    Flexible(
                      child: Text(
                        _tr(b['descKey'] as String),
                        style: TextStyle(fontSize: 11.5, height: 1.4,
                            color: Colors.grey[600]),
                        textAlign: TextAlign.center, maxLines: 3,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  // ── Slide 7: Social Proof + Experiences ──────────────────────────────────

  Widget _buildSlide7Proof(BuildContext context, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              child: Text('SOCIAL PROOF',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: accent, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 10),
            Text(_tr('kalpataru_proof_heading'),
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold,
                    color: accent, height: 1.25)),
            const SizedBox(height: 10),
            Container(height: 2, width: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, Colors.transparent]),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.1)),
          ),
          child: Column(children: [
            Text(_tr('kalpataru_proof_para'),
                style: const TextStyle(fontSize: 14.5, height: 1.85,
                    color: Color(0xFF4A3728)),
                textAlign: TextAlign.justify),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _buildStatCard('5000+', 'Practitioners')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('10K+', 'Sadhaks')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildStatCard('40+', 'Countries')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('4 hrs', 'One Miracle')),
            ]),
          ]),
        ),
        _highlightBox(_tr('kalpataru_proof_highlight'), accent),
        const SizedBox(height: 28),
        const KalpataruExperiencesWidget(),
        const SizedBox(height: 36),
        YouTubePlaylistSection(
          config: const PlaylistConfig(
            title: 'Healing & Manifestation Experiences',
            subtitle: 'Real stories using Kalpataru Technique',
            playlistId: 'PL5n5gvsTFZLwrGFrtAa3sLgq5BVOpL7K_',
            accentColor: Color(0xFFC4622D),
            bgColor: Color(0xFFFFF3EE),
            emoji: '🙏',
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EE),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.08),
            blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
                color: AppTheme.saffron)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: Colors.grey[600]),
            textAlign: TextAlign.center),
      ]),
    );
  }

  // ── Slide 8: Closing / CTA ────────────────────────────────────────────────

  Widget _buildClosingSlide(BuildContext context) {
    const accent = Color(0xFFC4622D);
    final ctaLines = _tr('kalpataru_cta_para')
        .split('\n').where((l) => l.trim().isNotEmpty).toList();

    return Stack(
      fit: StackFit.expand,
      children: [
        CachedImage(
          imageUrl: AppConstants.kalpataruSlide2,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF3E1A00).withValues(alpha: 0.7),
                const Color(0xFF1A0A00).withValues(alpha: 0.97),
              ],
              stops: const [0.2, 1.0],
            ),
          ),
        ),
        // Gold top accent line
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                AppTheme.gold.withValues(alpha: 0.9),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        // Content
        SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, MediaQuery.of(context).padding.top + 80, 24, 110),
          child: Column(
            children: [
              _ornamentalRule(accent),
              const SizedBox(height: 20),
              Text(
                _tr('kalpataru_cta_title'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    height: 1.2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _tr('kalpataru_cta_sub'),
                style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // White card with rhetorical questions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in ctaLines.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: accent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(line.trim(),
                                  style: TextStyle(fontSize: 14.5, height: 1.6,
                                      color: Colors.grey[700])),
                            ),
                          ],
                        ),
                      ),
                    if (ctaLines.length > 3) ...[
                      _paraDivider(accent),
                      const SizedBox(height: 10),
                      for (final line in ctaLines.skip(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(line.trim(),
                              style: TextStyle(fontSize: 14.5, height: 1.75,
                                  color: Colors.grey[700])),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Highlight box
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A0E00).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border(left: BorderSide(color: accent, width: 4)),
                ),
                child: Text(
                  _tr('kalpataru_cta_highlight'),
                  style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      height: 1.6),
                ),
              ),
              const SizedBox(height: 20),
              // Gradient CTA button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppTheme.saffronGradient,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(
                      color: accent.withValues(alpha: 0.5),
                      blurRadius: 18, offset: const Offset(0, 6))],
                ),
                child: Center(
                  child: Text(
                    _tr('kalpataru_cta_button'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Jai Gurudev pill
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              //   decoration: BoxDecoration(
              //     color: Colors.white.withValues(alpha: 0.1),
              //     borderRadius: BorderRadius.circular(24),
              //     border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
              //   ),
              //   child: Text(
              //     '🙏  Jai Gurudev  🙏',
              //     style: TextStyle(
              //         color: AppTheme.gold,
              //         fontSize: 14,
              //         fontWeight: FontWeight.w600,
              //         letterSpacing: 0.5),
              //   ),
              // ),
            ],
          ),
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
                      Icon(Icons.swipe_left_rounded, color: AppTheme.gold, size: 16),
                      const SizedBox(width: 6),
                      const Text('Swipe to Explore',
                          style: TextStyle(color: Colors.white, fontSize: 12,
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

  // ── Bottom dot nav ─────────────────────────────────────────────────────────

  Widget _buildDotNav() {
    Color dotColorFor(int i) {
      if (i == 0) return AppTheme.gold;
      if (i == 1) return AppTheme.saffron;
      return _accentColors[i - 2];
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
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 15),
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
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: dotColorFor(_currentPage),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: dotColorFor(_currentPage).withValues(alpha: 0.45),
                      blurRadius: 8)],
                ),
                child: const Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 15),
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

  Widget _highlightBox(String text, Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.07),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            height: 1.6),
      ),
    );
  }

  Widget _paraDivider(Color color) {
    return Row(children: [
      Container(width: 18, height: 1, color: color.withValues(alpha: 0.2)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Container(
            width: 4, height: 4,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.4), shape: BoxShape.circle)),
      ),
      Expanded(child: Container(height: 1, color: color.withValues(alpha: 0.08))),
    ]);
  }

  Widget _buildProcessStep(
      String number, String title, String description, Color accent) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.08),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.7)]),
              shape: BoxShape.circle,
            ),
            child: Center(
                child: Text(number,
                    style: const TextStyle(fontSize: 17,
                        fontWeight: FontWeight.w800, color: Colors.white))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: Colors.grey[800])),
              const SizedBox(height: 4),
              Text(description,
                  style: TextStyle(fontSize: 13.5, height: 1.6,
                      color: Colors.grey[600])),
            ]),
          ),
        ],
      ),
    );
  }
}
