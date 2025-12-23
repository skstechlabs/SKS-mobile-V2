import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GurujiConnectPage extends StatelessWidget {
  const GurujiConnectPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.saffronGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.connect_without_contact,
                size: 60,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Guruji\'s Connect',
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Coming Soon',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.saffron,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Connect directly with Guruji through messages, live sessions, and community features.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.beige,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildFeatureItem(context, Icons.message, 'Direct Messages'),
                  _buildFeatureItem(context, Icons.video_call, 'Live Sessions'),
                  _buildFeatureItem(context, Icons.campaign, 'Announcements'),
                  _buildFeatureItem(context, Icons.people, 'Community Forum'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.saffron, size: 24),
          SizedBox(width: 12),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
