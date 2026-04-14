import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/localization_service.dart';

class GuruJourneyPage extends StatefulWidget {
  const GuruJourneyPage({super.key});

  @override
  State<GuruJourneyPage> createState() => _GuruJourneyPageState();
}

class _GuruJourneyPageState extends State<GuruJourneyPage> {
  Future<void> _openYouTubeVideo() async {
    final Uri youtubeUrl = Uri.parse('https://www.youtube.com/watch?v=6mf3Rmykov4');
    
    try {
      if (await canLaunchUrl(youtubeUrl)) {
        await launchUrl(
          youtubeUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open YouTube video'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('guru_journey_title'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // YouTube Video Thumbnail with Play Button
            GestureDetector(
              onTap: _openYouTubeVideo,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.black,
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://img.youtube.com/vi/6mf3Rmykov4/maxresdefault.jpg',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // Dark overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                    // Play button
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                    // "Tap to watch on YouTube" text
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.play_circle_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('guru_journey_watch_youtube'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('parama_pujya') + ' ' + context.tr('sri_jeeveswara_yogi'),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildParagraph(context.tr('guru_journey_para1')),
                  
                  const SizedBox(height: 16),
                  
                  _buildParagraph(context.tr('guru_journey_para2')),
                  
                  const SizedBox(height: 16),
                  
                  _buildParagraph(context.tr('guru_journey_para3')),
                  
                  const SizedBox(height: 16),
                  
                  _buildParagraph(context.tr('guru_journey_para4')),
                  
                  const SizedBox(height: 16),
                  
                  _buildParagraph(context.tr('guru_journey_para5')),
                  
                  const SizedBox(height: 32),
                  
                  // Decorative bottom element
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.saffronGradient,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        context.tr('jai_gurudev'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        height: 1.8,
        color: AppTheme.textPrimary,
        letterSpacing: 0.3,
      ),
      textAlign: TextAlign.justify,
    );
  }
}
