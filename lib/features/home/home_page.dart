import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/audio_player_service.dart';

import '../chakras/chakra_detail_page.dart';
import '../songs/all_songs_page.dart';
import '../guru_journey/guru_journey_page.dart';
import '../kundalini_science/kundalini_science_page.dart';
import '../benefits/benefits_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _currentQuoteIndex = 0;
  late AnimationController _glowController;
  late Timer _autoScrollTimer;
  final AudioPlayerService _audioService = AudioPlayerService();

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _audioService.initialize();
    _audioService.addListener(_onAudioStateChanged);

    // Initialize quote index
    _currentQuoteIndex = 0;

    // Start timer for quote rotation (3 seconds interval)
    if (AppConstants.dailyQuotes.isNotEmpty) {
      _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted) {
          setState(() {
            _currentQuoteIndex =
                (_currentQuoteIndex + 1) % AppConstants.dailyQuotes.length;
          });
        }
      });
    }
  }

  void _onAudioStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _audioService.removeListener(_onAudioStateChanged);
    if (AppConstants.dailyQuotes.isNotEmpty) {
      _autoScrollTimer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Performance optimizations
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildDailyQuotes(),
          _buildMeditationMusic(),
          _buildBhajans(),
          _buildGuruJourney(),
          _buildKundaliniScience(),
          _buildBenefits(),
          _build7Chakras(),
          _buildRecentGatherings(),
          _buildUpcomingPrograms(),
          _buildVisionMission(),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox.shrink();
  }

  Widget _buildDailyQuotes() {
    if (AppConstants.dailyQuotes.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed single image container
        Container(
          height: 300,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.saffron.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppConstants
                      .dailyWisdomImages[0]), // Fixed to first image
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: 30),

        // Guruji name section with enhanced styling
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parama Pujya',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF97316),
                  letterSpacing: 1.2,
                  height: 1.4,
                ),
              ),
              Text(
                'Sri Jeeveswara Yogi',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF97316),
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 30),
// Beautiful static quotation with top icon and fixed height for 3 rows
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 140, // Fixed height for exactly 3 rows
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF97316).withOpacity(0.08),
                  Color(0xFFFF6B35).withOpacity(0.12),
                  Color(0xFFFFAB40).withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Color(0xFFF97316).withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFF97316).withOpacity(0.15),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top icon
                Icon(
                  Icons.format_quote,
                  color: Color(0xFFF97316),
                  size: 20,
                ),
                SizedBox(height: 8),
                // Quote text with fixed height for 3 lines
                Expanded(
                  child: Center(
                    child: Text(
                      AppConstants.dailyQuotes[
                          _currentQuoteIndex], // Rotating quote without animation
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Color(0xFF2D3748),
                                fontSize: 16,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 0.3,
                              ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildVisionMission() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.saffron.withOpacity(0.1),
            AppTheme.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.saffron.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Vision Card
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.saffron,
                            AppTheme.saffron.withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.saffron.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.visibility,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Our Vision',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.saffron,
                                letterSpacing: 0.5,
                              ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  AppConstants.vision,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),

          // Decorative Divider
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.saffron.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppTheme.saffron.withOpacity(0.5),
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.saffron.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mission Card
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary,
                            AppTheme.primary.withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.explore,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Our Mission',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                                letterSpacing: 0.5,
                              ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  AppConstants.mission,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeditationMusic() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Meditation',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              if (AppConstants.meditationMusic.isNotEmpty) {
                // Check if this meditation is currently playing
                final isCurrentlyPlaying =
                    _audioService.playlist == AppConstants.meditationMusic &&
                        _audioService.currentIndex == 0 &&
                        _audioService.isPlaying;

                if (isCurrentlyPlaying) {
                  // If playing, pause it
                  await _audioService.pause();
                } else {
                  // If not playing or different song, play it
                  await _audioService.playSong(AppConstants.meditationMusic, 0);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Playing "${AppConstants.meditationMusic[0]['title']}"'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height - 100,
                          left: 10,
                          right: 10,
                        ),
                      ),
                    );
                  }
                }
              }
            },
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border:
                    (_audioService.playlist == AppConstants.meditationMusic &&
                            _audioService.currentIndex == 0 &&
                            _audioService.isPlaying)
                        ? Border.all(color: AppTheme.primary, width: 3)
                        : null,
                image: DecorationImage(
                  image: AssetImage(AppConstants.gurujiTeachingImageUrl),
                  fit: BoxFit.contain,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          (_audioService.playlist ==
                                      AppConstants.meditationMusic &&
                                  _audioService.currentIndex == 0 &&
                                  _audioService.isPlaying)
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Guided Meditation',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                        ),
                        Text(
                          '15:00',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBhajans() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Songs & Bhajans',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Icon(Icons.repeat, color: AppTheme.softGray, size: 24),
            ],
          ),
          SizedBox(height: 16),
          ...AppConstants.bhajans
              .take(3)
              .map((bhajan) => _buildBhajanCard(bhajan))
              .toList(),
          SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllSongsPage(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primary, width: 2),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View All Songs',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: AppTheme.primary, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBhajanCard(Map<String, dynamic> bhajan) {
    final isCurrentSong =
        _audioService.currentSong?['title'] == bhajan['title'];
    final isPlaying = isCurrentSong && _audioService.isPlaying;

    return GestureDetector(
      onTap: () async {
        final index = AppConstants.bhajans
            .indexWhere((b) => b['title'] == bhajan['title']);
        if (index != -1) {
          if (isCurrentSong && _audioService.isPlaying) {
            await _audioService.pause();
          } else {
            await _audioService.playSong(AppConstants.bhajans, index);
          }
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentSong
              ? AppTheme.saffron.withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: isCurrentSong
              ? Border.all(color: AppTheme.saffron, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(bhajan['imageUrl']!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (isCurrentSong)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bhajan['title']!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isCurrentSong ? AppTheme.saffron : null,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    bhajan['artist'] ?? 'Divine Chants',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  bhajan['duration'] ?? '5:30',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                ),
                SizedBox(height: 4),
                Icon(
                  isCurrentSong && isPlaying ? Icons.pause : Icons.play_arrow,
                  color:
                      isCurrentSong ? AppTheme.saffron : AppTheme.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuruJourney() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuruJourneyPage(),
            ),
          );
        },
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: AssetImage(AppConstants.guruJourneyImageUrl),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.saffron.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF6B4A).withValues(alpha: 0.88),
                  Color(0xFFFF8A65).withValues(alpha: 0.85),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Journey of\nour Guru',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Discover the life and teachings of\nParama Pujya Sri Jeeveswara Yogi',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Know More',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKundaliniScience() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KundaliniSciencePage(),
            ),
          );
        },
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: AssetImage(AppConstants.kundaliniScienceImageUrl),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gold.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF00897B).withValues(alpha: 0.88),
                  Color(0xFF26A69A).withValues(alpha: 0.85),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'The Science of\nKundalini Awakening',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Unlock the primordial cosmic energy\nwithin you',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Learn More',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefits() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BenefitsPage(),
            ),
          );
        },
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: AssetImage(AppConstants.benefitsImageUrl),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.saffron.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE91E63).withValues(alpha: 0.88),
                  Color(0xFFEC407A).withValues(alpha: 0.85),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Benefits of\nKundalini Sadhana',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Transform your life through enhanced\nenergy, clarity, and spiritual growth',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Explore Benefits',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build7Chakras() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChakraDetailPage(initialIndex: 0),
            ),
          );
        },
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: AssetImage(AppConstants.chakrasImageUrl),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.saffron.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.withValues(alpha: 0.85),
                  Colors.deepPurple.withValues(alpha: 0.75),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Explore the\n7 Chakras',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Journey through your body\'s\nenergy centers',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Swipe to Explore',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentGatherings() {
    if (AppConstants.recentGatherings.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Recent Gatherings',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 340,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: AppConstants.recentGatherings.length,
            itemBuilder: (context, index) {
              final gathering = AppConstants.recentGatherings[index];
              return InkWell(
                onTap: () async {
                  final videoUrl = gathering['videoUrl'] as String?;
                  if (videoUrl != null && videoUrl.isNotEmpty) {
                    try {
                      // Open YouTube video
                      final uri = Uri.parse(videoUrl);
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } catch (e) {
                      debugPrint('Error launching URL: $e');
                    }
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 300,
                  margin: EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 180,
                            width: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                              image: DecorationImage(
                                image: AssetImage(gathering['image']!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Play button overlay
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.saffron.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gathering['title']!,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: AppTheme.primary,
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      gathering['date']!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              if (gathering['participants'] != null) ...[
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        gathering['participants']!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  gathering['description']!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildUpcomingPrograms() {
    if (AppConstants.upcomingEvents.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Events',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 16),
          ...AppConstants.upcomingEvents.map((event) {
            return InkWell(
              onTap: () {
                // Navigate to events tab
                context.go('/events');
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                        image: DecorationImage(
                          image: AssetImage(event['imageUrl']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['title']!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppTheme.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                event['date']!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  event['location']!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
