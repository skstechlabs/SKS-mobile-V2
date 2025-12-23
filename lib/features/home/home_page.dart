import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/shimmer_loading.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool _showFullAbout = false;
  int _currentQuoteIndex = 0;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
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
      height: 400,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gold.withOpacity(0.2 + _glowController.value * 0.2),
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
                  AppTheme.white.withOpacity(0.9),
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
    return Column(
      children: [
        SectionHeader(title: 'Daily Wisdom'),
        CarouselSlider(
          options: CarouselOptions(
            height: 200,
            autoPlay: true,
            autoPlayInterval: Duration(seconds: 5),
            enlargeCenterPage: true,
            onPageChanged: (index, reason) {
              setState(() => _currentQuoteIndex = index);
            },
          ),
          items: AppConstants.dailyQuotes.map((quote) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.saffronGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [AppTheme.softShadow],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.format_quote, color: Colors.white.withOpacity(0.3), size: 40),
                            SizedBox(height: 12),
                            Text(
                              quote,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(Icons.share, color: Colors.white),
                          onPressed: () => Share.share(quote),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AppConstants.dailyQuotes.asMap().entries.map((entry) {
            return Container(
              width: 8,
              height: 8,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
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
        SectionHeader(title: 'Meditation Music'),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: AppConstants.meditationMusic.length,
            itemBuilder: (context, index) {
              final music = AppConstants.meditationMusic[index];
              return Container(
                width: 280,
                margin: EdgeInsets.only(right: 12),
                child: Card(
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppTheme.saffronGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.music_note, color: Colors.white),
                    ),
                    title: Text(music['title']!),
                    subtitle: Text(music['duration']!),
                    trailing: IconButton(
                      icon: Icon(Icons.play_arrow, color: AppTheme.saffron),
                      onPressed: () {},
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
        SectionHeader(title: 'Songs & Bhajans'),
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
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        bhajan['imageUrl']!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 120,
                          color: AppTheme.beige,
                          child: Icon(Icons.music_note, size: 40, color: AppTheme.saffron),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bhajan['title']!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              bhajan['artist']!,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
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
        SectionHeader(title: 'Experience Videos'),
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
                          height: 180,
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
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
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
        SectionHeader(title: 'Recommended for You'),
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
    return Column(
      children: [
        SectionHeader(title: 'Upcoming Programs', onSeeAll: () {}),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: 2,
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
                      height: 150,
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
