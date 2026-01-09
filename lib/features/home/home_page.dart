import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/shimmer_loading.dart';

import '../audio/playlist_screen.dart';
import '../video/youtube_player.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool _showFullAbout = false;
  int _currentQuoteIndex = 0;
  late AnimationController _glowController;
  late PageController _pageController;
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
    
    // Initialize page controller for wisdom cards
    _pageController = PageController();
    
    // Start auto-scroll timer for wisdom cards (2 seconds interval)
    if (AppConstants.dailyQuotes.isNotEmpty) {
      _autoScrollTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted && _pageController.hasClients) {
          int nextPage = (_currentQuoteIndex + 1) % AppConstants.dailyQuotes.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pageController.dispose();
    if (AppConstants.dailyQuotes.isNotEmpty) {
      _autoScrollTimer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGurujiSection(),
          _buildAboutSection(),
          _buildDailyQuotes(),
          _buildMeditationMusic(),
          _buildBhajans(),
          _buildExperienceVideos(),
          _buildRecommendedSection(),
          _buildUpcomingPrograms(),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGurujiSection() {
    return Container(
      height: MediaQuery.of(context).size.height > 700 ? 400 : 
              MediaQuery.of(context).size.height * 0.4,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gold.withValues(alpha: 0.2 + _glowController.value * 0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Image.asset(
              AppConstants.gurujiImageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppTheme.beige,
                child: Center(
                  child: Icon(Icons.person, size: 100, color: AppTheme.saffron),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.white.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Text(
              'Parama Pujya Sri Jeeveswara Yogi',
              style: Theme.of(context).textTheme.displayLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About Guruji',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 12),
              Text(
                _showFullAbout
                    ? AppConstants.aboutGuruji
                    : AppConstants.aboutGuruji.substring(0, 120) + '...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: () => setState(() => _showFullAbout = !_showFullAbout),
                child: Text(_showFullAbout ? 'Read less' : 'Read more'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyQuotes() {
    if (AppConstants.dailyQuotes.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Column(
      children: [
        const SectionHeader(title: 'Daily Wisdom'),
        Container(
          height: MediaQuery.of(context).size.width > 600 ? 200 : 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: AppConstants.dailyQuotes.length,
            onPageChanged: (index) => setState(() => _currentQuoteIndex = index),
            itemBuilder: (context, index) {
              final quote = AppConstants.dailyQuotes[index];
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: AppTheme.saffronGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [AppTheme.softShadow],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.format_quote, 
                        color: Colors.white.withValues(alpha: 0.4), 
                        size: 20,
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: Center(
                          child: Text(
                            quote,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                              fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: MediaQuery.of(context).size.width > 600 ? 4 : 3,
                            overflow: TextOverflow.ellipsis,
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
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AppConstants.dailyQuotes.asMap().entries.map((entry) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: _currentQuoteIndex == entry.key ? 16 : 6,
              height: 6,
              margin: EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: _currentQuoteIndex == entry.key
                    ? AppTheme.saffron
                    : AppTheme.softGray,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMeditationMusic() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlaylistScreen(
                        title: 'Meditation Music',
                        songs: AppConstants.meditationMusic,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Meditation Music',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                icon: Icon(Icons.repeat, color: AppTheme.gold, size: 20),
                label: Text('Loop All', style: TextStyle(color: AppTheme.gold)),
                onPressed: () async {
                  await _audioService.playWithLoop(AppConstants.meditationMusic, 0, loopMode: LoopMode.all);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Playing Meditation Music in loop')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.width > 600 ? 120 : 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: AppConstants.meditationMusic.length,
            itemBuilder: (context, index) {
              final music = AppConstants.meditationMusic[index];
              final screenWidth = MediaQuery.of(context).size.width;
              final isLargeScreen = screenWidth > 600;
              
              return Container(
                width: isLargeScreen ? 300 : (screenWidth * 0.75).clamp(250.0, 280.0),
                margin: EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () async {
                    await _audioService.playSong(AppConstants.meditationMusic, index);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Playing "${music['title']}"')),
                      );
                    }
                  },
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Container(
                            width: isLargeScreen ? 60 : 45,
                            height: isLargeScreen ? 60 : 45,
                            decoration: BoxDecoration(
                              gradient: AppTheme.saffronGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: isLargeScreen ? 30 : 22,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  music['title']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: isLargeScreen ? 14 : 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 10, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        music['duration']!,
                                        style: TextStyle(fontSize: 10, color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '• Song',
                                      style: TextStyle(fontSize: 10, color: AppTheme.saffron),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.play_arrow,
                            color: AppTheme.saffron,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBhajans() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlaylistScreen(
                        title: 'Songs & Bhajans',
                        songs: AppConstants.bhajans,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Songs & Bhajans',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                icon: Icon(Icons.repeat, color: AppTheme.gold, size: 20),
                label: Text('Loop All', style: TextStyle(color: AppTheme.gold)),
                onPressed: () async {
                  await _audioService.playWithLoop(AppConstants.bhajans, 0, loopMode: LoopMode.all);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Playing Songs & Bhajans in loop')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: AppConstants.bhajans.length,
            itemBuilder: (context, index) {
              final bhajan = AppConstants.bhajans[index];
              return Container(
                width: 160,
                margin: EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () async {
                    await _audioService.playSong(AppConstants.bhajans, index);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Playing "${bhajan['title']}"')),
                      );
                    }
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Image.asset(
                              bhajan['imageUrl']!,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 100,
                                color: AppTheme.beige,
                                child: Icon(Icons.music_note, size: 40, color: AppTheme.saffron),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.music_note, size: 14, color: AppTheme.saffron),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        bhajan['title']!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${bhajan['artist']!} • Song',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.saffron,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tap to play',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceVideos() {
    return Column(
      children: [
        const SectionHeader(title: 'Experience Videos'),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: AppConstants.experienceVideos.length,
            itemBuilder: (context, index) {
              final video = AppConstants.experienceVideos[index];
              return Container(
                width: 280,
                margin: EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => YouTubeVideoPlayer(
                          videoId: video['youtubeId']!,
                          title: video['title']!,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: video['thumbnail']!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => ShimmerLoading(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.width > 600 ? 180 : 160,
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.play_arrow, size: 40, color: AppTheme.saffron),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video['title']!,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              video['duration']!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      children: [
        const SectionHeader(title: 'Recommended for You'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppTheme.gold, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Personalized content coming soon based on your spiritual journey',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingPrograms() {
    if (AppConstants.upcomingEvents.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Column(
      children: [
        SectionHeader(title: 'Upcoming Programs', onSeeAll: () {}),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: AppConstants.upcomingEvents.length,
          itemBuilder: (context, index) {
            final event = AppConstants.upcomingEvents[index];
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CachedNetworkImage(
                    imageUrl: event['imageUrl']!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => ShimmerLoading(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.width > 600 ? 150 : 130,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title']!,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: AppTheme.saffron),
                            SizedBox(width: 8),
                            Text(event['date']!),
                            SizedBox(width: 16),
                            Icon(Icons.location_on, size: 16, color: AppTheme.saffron),
                            SizedBox(width: 8),
                            Text(event['location']!),
                          ],
                        ),
                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {},
                          child: Text('Learn More'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
