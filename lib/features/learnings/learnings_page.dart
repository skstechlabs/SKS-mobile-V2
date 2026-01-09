import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LearningsPage extends StatelessWidget {
  const LearningsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    final availableHeight = screenHeight - 
        kBottomNavigationBarHeight - 
        MediaQuery.of(context).padding.top - 
        MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: availableHeight,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 32 : 16,
            vertical: 16,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isLargeScreen ? 120 : 80,
                height: isLargeScreen ? 120 : 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.saffronGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school,
                  size: isLargeScreen ? 60 : 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isLargeScreen ? 24 : 16),
              Text(
                'Learnings',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: isLargeScreen ? null : 28,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isLargeScreen ? 12 : 8),
              Text(
                'Coming Soon',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.saffron,
                  fontSize: isLargeScreen ? null : 20,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isLargeScreen ? 16 : 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 0 : 8),
                child: Text(
                  'Spiritual courses, audio lessons, video teachings, and sacred texts will be available here soon.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: isLargeScreen ? null : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: isLargeScreen ? 32 : 20),
              Container(
                constraints: BoxConstraints(
                  maxWidth: isLargeScreen ? 500 : double.infinity,
                ),
                padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
                decoration: BoxDecoration(
                  color: AppTheme.beige,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(context, Icons.video_library, 'Video Courses', isLargeScreen),
                    _buildFeatureItem(context, Icons.headphones, 'Audio Lessons', isLargeScreen),
                    _buildFeatureItem(context, Icons.picture_as_pdf, 'Sacred Texts', isLargeScreen),
                    _buildFeatureItem(context, Icons.quiz, 'Interactive Quizzes', isLargeScreen),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text, bool isLargeScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 10 : 6),
      child: Row(
        children: [
          Icon(
            icon, 
            color: AppTheme.saffron, 
            size: isLargeScreen ? 24 : 20,
          ),
          SizedBox(width: isLargeScreen ? 12 : 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: isLargeScreen ? null : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
