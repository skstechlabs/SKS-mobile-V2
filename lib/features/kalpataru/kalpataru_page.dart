import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/localization_service.dart';

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
  'kalpataru_manifest_para': 'కల్పతరు కేవలం రుగ్మతలను నయం చేయడం మాత్రమే కాదు — అది మీలో సహజంగా ఉన్న సంకల్ప సిద్ధి శక్తిని జాగృతం చేస్తుంది.\n\nఈ ప్రయాణం చిన్న చిన్న మేనిఫెస్టేషన్లతో మొదలవుతుంది. ఆ తర్వాత సరైన అవకాశాలు, వ్యక్తులు, స్పష్టత అన్నీ మీ జీవితంలోకి ప్రవహించడం మొదలవుతుంది.',
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
  'kalpataru_proof_highlight': 'ప్రపంచవ్యాప్తంగా వేలాది మందికి కల్పతరు ఒక సాధన కాదు — అదే వారి జీవన విధానం.',
  'kalpataru_cta_title': 'పరివర్తనకు మీరు సిద్ధమేనా?',
  'kalpataru_cta_sub': 'కల్పతరు మీ కోసం వేచి ఉంది',
  'kalpataru_cta_para': 'సమస్యను మూలం నుంచే నయం చేసుకోవడానికి మీరు సిద్ధంగా ఉన్నారా?\nమీ కర్మను అధిగమించడానికి మీరు సిద్ధంగా ఉన్నారా?\nమీలోని అత్యున్నత సామర్థ్యాన్ని సాకారం చేసుకోవడానికి మీరు సిద్ధంగా ఉన్నారా?\n\nమోక్ష గురు శ్రీ జీవేశ్వర యోగి అందించిన ఈ పవిత్ర సాధన ద్వారా మీ ప్రయాణాన్ని ఇప్పుడే ప్రారంభించండి.',
  'kalpataru_cta_highlight': 'కల్పతరు సాధన ద్వారా, శుద్ధమైన మనసుతో మీరు ఏ కోరికనైనా నెరవేర్చుకోవచ్చు. మీరు సాధించగలిగేదానికి — కేవలం మీ ఊహాశక్తే హద్దు!',
  'kalpataru_cta_button': '✨ మీ పరివర్తనను ప్రారంభించండి ✨',
};

class KalpataruPage extends StatefulWidget {
  const KalpataruPage({super.key});

  @override
  State<KalpataruPage> createState() => _KalpataruPageState();
}

class _KalpataruPageState extends State<KalpataruPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Inject kalpataru keys into the live localization service so
    // translate() finds them and never prints "Missing translation".
    // putIfAbsent means live bundle values always win once re-built.
    final lang = LocalizationService().currentLocale.languageCode;
    LocalizationService().patchStrings(lang == 'te' ? _teFb : _enFb);
  }

  /// Simple passthrough — now that patchStrings() has populated the service,
  /// context.tr() will find all keys. _tr() is kept as a safe wrapper.
  String _tr(String key) {
    return LocalizationService().translate(key);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8F0), Color(0xFFFFF4E0), Color(0xFFFFF8F0)],
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildHeroSection(context),
            _buildDivineIntroduction(context),
            _buildPrincipleSection(context),
            _buildHowItWorksSection(context),
            _buildTransformationSection(context),
            _buildManifestSection(context),
            _buildBenefitsGrid(context),
            _buildProofSection(context),
            _buildCallToAction(context),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────

  Widget _buildHeroSection(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: screenHeight * 0.65,
      width: screenWidth,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/kalpataru-bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.35),
                  ],
                  stops: const [0.0, 0.72, 1.0],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              height: screenHeight * 0.50,
              constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.saffron.withValues(alpha: 0.3),
                    blurRadius: 40, spreadRadius: 10, offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/images/guruji-kalpatharu.png', fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 1 · Divine Introduction ────────────────────────────────────────────────

  Widget _buildDivineIntroduction(BuildContext context) {
    final paras = _tr('kalpataru_intro_para')
        .split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
      child: Column(
        children: [
          // Headline
          Text(
            _tr('kalpataru_hero_headline'),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.grey[800], height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _tr('kalpataru_hero_sub'),
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppTheme.saffron, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          // Intro card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.saffron.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.07), blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  decoration: BoxDecoration(
                    color: AppTheme.saffron.withValues(alpha: 0.07),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(19), topRight: Radius.circular(19)),
                    border: Border(bottom: BorderSide(color: AppTheme.saffron.withValues(alpha: 0.15))),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.saffron.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.saffron.withValues(alpha: 0.3)),
                      ),
                      child: const Center(child: Text('🌳', style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _tr('kalpataru_intro_title'),
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.saffron),
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < paras.length; i++) ...[
                        if (i > 0) ...[
                          const SizedBox(height: 8),
                          _paraDivider(AppTheme.saffron),
                          const SizedBox(height: 10),
                        ],
                        Text(paras[i].trim(),
                            style: const TextStyle(fontSize: 14.5, height: 1.85, color: Color(0xFF4A3728), letterSpacing: 0.1),
                            textAlign: TextAlign.justify),
                      ],
                    ],
                  ),
                ),
                _highlightBox(_tr('kalpataru_intro_highlight'), AppTheme.saffron),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2 · Principle ──────────────────────────────────────────────────────────

  Widget _buildPrincipleSection(BuildContext context) {
    final pillars = [
      {'icon': '🌟', 'title': 'Energy & Consciousness', 'body': _tr('kalpataru_pillar_1')},
      {'icon': '🔄', 'title': 'Karmic Healing', 'body': _tr('kalpataru_pillar_2')},
      {'icon': '✨', 'title': 'Direct Experience', 'body': _tr('kalpataru_pillar_3')},
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppTheme.saffron.withValues(alpha: 0.08), AppTheme.gold.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.saffron.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.saffron.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('THE PRINCIPLE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.saffron, letterSpacing: 2)),
          ),
          const SizedBox(height: 10),
          Text(_tr('kalpataru_principle_title'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFBF360C)),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(_tr('kalpataru_principle_para'),
              style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.6),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          for (int i = 0; i < pillars.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _buildPrincipleItem(pillars[i]['icon']!, pillars[i]['title']!, pillars[i]['body']!),
          ],
        ],
      ),
    );
  }

  Widget _buildPrincipleItem(String icon, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey[800])),
            const SizedBox(height: 4),
            Text(body, style: TextStyle(fontSize: 13.5, height: 1.65, color: Colors.grey[600])),
          ]),
        ),
      ],
    );
  }

  // ── 3 · How It Works ──────────────────────────────────────────────────────

  Widget _buildHowItWorksSection(BuildContext context) {
    final paras = _tr('kalpataru_works_para')
        .split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    final steps = [
      {'num': '1', 'title': 'Identify the Challenge', 'body': _tr('kalpataru_step_1')},
      {'num': '2', 'title': 'Practice Kalpataru', 'body': _tr('kalpataru_step_2')},
      {'num': '3', 'title': 'Karmic Transformation', 'body': _tr('kalpataru_step_3')},
      {'num': '4', 'title': 'Natural Manifestation', 'body': _tr('kalpataru_step_4')},
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(_tr('kalpataru_works_title'),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.grey[800]),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(_tr('kalpataru_works_sub'),
                style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: AppTheme.saffron, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 20),
          // Body paras
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < paras.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: 8),
                    _paraDivider(AppTheme.saffron),
                    const SizedBox(height: 10),
                  ],
                  Text(paras[i].trim(),
                      style: const TextStyle(fontSize: 14.5, height: 1.85, color: Color(0xFF4A3728)),
                      textAlign: TextAlign.justify),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Steps
          for (int i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildProcessStep(steps[i]['num']!, steps[i]['title']!, steps[i]['body']!),
          ],
          const SizedBox(height: 16),
          _highlightBox(_tr('kalpataru_works_highlight'), AppTheme.saffron),
        ],
      ),
    );
  }

  Widget _buildProcessStep(String number, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.saffron, const Color(0xFFFFAA00)]),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(number, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey[800])),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(fontSize: 13.5, height: 1.6, color: Colors.grey[600])),
            ]),
          ),
        ],
      ),
    );
  }

  // ── 4 · Three-Level Transformation ────────────────────────────────────────

  Widget _buildTransformationSection(BuildContext context) {
    final levels = [
      {
        'title': _tr('kalpataru_level_1_title'),
        'body': _tr('kalpataru_level_1'),
        'color': const Color(0xFFE53935),
      },
      {
        'title': _tr('kalpataru_level_2_title'),
        'body': _tr('kalpataru_level_2'),
        'color': const Color(0xFF1565C0),
      },
      {
        'title': _tr('kalpataru_level_3_title'),
        'body': _tr('kalpataru_level_3'),
        'color': const Color(0xFF6A1B9A),
      },
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppTheme.saffron, const Color(0xFFFF9933)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.3), blurRadius: 28, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Icon(Icons.self_improvement, size: 48, color: Colors.white),
          const SizedBox(height: 16),
          Text(_tr('kalpataru_levels_title'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(_tr('kalpataru_levels_para'),
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9), height: 1.6),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          for (int i = 0; i < levels.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _buildTransformationLevel(
              levels[i]['title'] as String,
              levels[i]['body'] as String,
            ),
          ],
          const SizedBox(height: 16),
          // Closing para
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Text(
              _tr('kalpataru_levels_closing'),
              style: TextStyle(fontSize: 14, height: 1.75, color: Colors.white.withValues(alpha: 0.95)),
              textAlign: TextAlign.justify,
            ),
          ),
          const SizedBox(height: 14),
          // Highlight pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppTheme.saffron, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _tr('kalpataru_levels_highlight'),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.saffron),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransformationLevel(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
          ]),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text(body,
                style: TextStyle(fontSize: 13.5, height: 1.65, color: Colors.white.withValues(alpha: 0.9)),
                textAlign: TextAlign.justify),
          ),
        ],
      ),
    );
  }

  // ── 5 · Manifestation ─────────────────────────────────────────────────────

  Widget _buildManifestSection(BuildContext context) {
    final paras = _tr('kalpataru_manifest_para')
        .split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6A1B9A).withValues(alpha: 0.07), blurRadius: 18, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: BoxDecoration(
              color: const Color(0xFF6A1B9A).withValues(alpha: 0.07),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(19), topRight: Radius.circular(19)),
              border: Border(bottom: BorderSide(color: const Color(0xFF6A1B9A).withValues(alpha: 0.15))),
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.3)),
                ),
                child: const Center(child: Text('🌟', style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_tr('kalpataru_manifest_title'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A))),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (int i = 0; i < paras.length; i++) ...[
                if (i > 0) ...[
                  const SizedBox(height: 8),
                  _paraDivider(const Color(0xFF6A1B9A)),
                  const SizedBox(height: 10),
                ],
                Text(paras[i].trim(),
                    style: const TextStyle(fontSize: 14.5, height: 1.85, color: Color(0xFF4A3728)),
                    textAlign: TextAlign.justify),
              ],
            ]),
          ),
          _highlightBox(_tr('kalpataru_manifest_highlight'), const Color(0xFF6A1B9A)),
        ],
      ),
    );
  }

  // ── 6 · Benefits Grid ─────────────────────────────────────────────────────

  Widget _buildBenefitsGrid(BuildContext context) {
    final benefits = [
      {'icon': Icons.favorite, 'titleKey': 'kalpataru_brings_1_title', 'descKey': 'kalpataru_brings_1'},
      {'icon': Icons.psychology, 'titleKey': 'kalpataru_brings_2_title', 'descKey': 'kalpataru_brings_2'},
      {'icon': Icons.family_restroom, 'titleKey': 'kalpataru_brings_3_title', 'descKey': 'kalpataru_brings_3'},
      {'icon': Icons.spa, 'titleKey': 'kalpataru_brings_4_title', 'descKey': 'kalpataru_brings_4'},
      {'icon': Icons.trending_up, 'titleKey': 'kalpataru_brings_5_title', 'descKey': 'kalpataru_brings_5'},
      {'icon': Icons.auto_awesome, 'titleKey': 'kalpataru_brings_6_title', 'descKey': 'kalpataru_brings_6'},
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        children: [
          Text(_tr('kalpataru_brings_title'),
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.grey[800]),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.87,
              crossAxisSpacing: 14, mainAxisSpacing: 14,
            ),
            itemCount: benefits.length,
            itemBuilder: (context, index) {
              final b = benefits[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppTheme.saffron.withValues(alpha: 0.18),
                          AppTheme.gold.withValues(alpha: 0.12),
                        ]),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(b['icon'] as IconData, size: 28, color: AppTheme.saffron),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.tr(b['titleKey'] as String),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey[800]),
                      textAlign: TextAlign.center, maxLines: 2,
                    ),
                    const SizedBox(height: 5),
                    Flexible(
                      child: Text(
                        context.tr(b['descKey'] as String),
                        style: TextStyle(fontSize: 11.5, height: 1.4, color: Colors.grey[600]),
                        textAlign: TextAlign.center, maxLines: 3,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 7 · Social Proof ──────────────────────────────────────────────────────

  Widget _buildProofSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.saffron.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Text(_tr('kalpataru_proof_para'),
              style: TextStyle(fontSize: 14.5, height: 1.85, color: Colors.grey[700]),
              textAlign: TextAlign.justify),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildStatCard('5000+', 'Practitioners'),
            const SizedBox(width: 12),
            _buildStatCard('10K+', 'Sadhaks'),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildStatCard('40+', 'Countries'),
            const SizedBox(width: 12),
            _buildStatCard('4 hrs', 'One Miracle'),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.format_quote, color: AppTheme.saffron.withValues(alpha: 0.5), size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _tr('kalpataru_proof_highlight'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.saffron, fontStyle: FontStyle.italic, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.saffron)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // ── 8 · CTA ────────────────────────────────────────────────────────────────

  Widget _buildCallToAction(BuildContext context) {
    final ctaLines = _tr('kalpataru_cta_para')
        .split('\n').where((l) => l.trim().isNotEmpty).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [const Color(0xFFFFF8F0), AppTheme.gold.withValues(alpha: 0.15)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.saffron.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(_tr('kalpataru_cta_title'),
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.grey[800]),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(_tr('kalpataru_cta_sub'),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.saffron, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          // Rhetorical questions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))],
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
                        Icon(Icons.check_circle_outline, color: AppTheme.saffron, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(line.trim(),
                              style: TextStyle(fontSize: 14.5, height: 1.6, color: Colors.grey[700])),
                        ),
                      ],
                    ),
                  ),
                if (ctaLines.length > 3) ...[
                  _paraDivider(AppTheme.saffron),
                  const SizedBox(height: 10),
                  for (final line in ctaLines.skip(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(line.trim(),
                          style: TextStyle(fontSize: 14.5, height: 1.75, color: Colors.grey[700])),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _highlightBox(_tr('kalpataru_cta_highlight'), AppTheme.saffron),
          const SizedBox(height: 20),
          // CTA button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: AppTheme.saffronGradient,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: Center(
              child: Text(
                _tr('kalpataru_cta_button'),
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _highlightBox(String text, Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, height: 1.6),
      ),
    );
  }

  Widget _paraDivider(Color color) {
    return Row(children: [
      Container(width: 18, height: 1, color: color.withValues(alpha: 0.2)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Container(width: 4, height: 4,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.4), shape: BoxShape.circle)),
      ),
      Expanded(child: Container(height: 1, color: color.withValues(alpha: 0.08))),
    ]);
  }
}
