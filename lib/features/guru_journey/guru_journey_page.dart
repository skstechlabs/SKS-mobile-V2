import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

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
        title: const Text(
          'Journey of our Guru',
          style: TextStyle(
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Tap to watch on YouTube',
                                style: TextStyle(
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
                    'Parama Pujya SriJeeveswara Yogi',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBrown,
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  _buildParagraph(
                    'Parama Pujya SriJeeveswara Yogi was born with an awakened Kundalini. At the tender age of 8, during a meditation class at school, he naturally entered into a deep state of Samadhi for four hours. From that moment onward, his heart was filled with a burning curiosity to explore the mysteries of meditation.',
                  ),
                  
                  SizedBox(height: 16),
                  
                  _buildParagraph(
                    'At the age of 13, guided by his spiritual quest, he traveled to the sacred land of Srisailam, a powerful abode of Lord Shiva. There, in a miraculous turn, he encountered his Guru — none other than Lord Shiva Himself. In the divine presence of his Guru, he spent three days and received profound, intense meditation techniques.',
                  ),
                  
                  SizedBox(height: 16),
                  
                  _buildParagraph(
                    'Through years of dedicated practice, he eventually attained Enlightenment. Choosing to renounce worldly pursuits, he initially intended to enter Jeeva Samadhi, but on the divine guidance of his Guru, he redirected his life towards serving humanity. Leaving behind a flourishing professional career, he resolved to dedicate his entire life to spreading the sacred knowledge of Kundalini Sadhana.',
                  ),
                  
                  SizedBox(height: 16),
                  
                  _buildParagraph(
                    'In 2017, he founded Siva Kundalini Sadhana, a non-profit spiritual organization with the mission of offering this divine practice freely to all seekers. Gurudev strongly believes that Salvation is the birthright of every human being, and thus he shares these teachings without any barriers or prerequisites.',
                  ),
                  
                  SizedBox(height: 16),
                  
                  _buildParagraph(
                    'SriJeeveswara Yogi Gurudev is among the rarest of masters who bestow Shaktipatham (the direct transmission of energy from Guru to disciple) and Shivapatham, guiding seekers on the path to ultimate realization.',
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Decorative bottom element
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.saffronGradient,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '🙏 Jai Gurudev 🙏',
                        style: TextStyle(
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
