import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class BenefitsPage extends StatelessWidget {
  const BenefitsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Benefits of Kundalini Sadhana',
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
            // Hero Image
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.saffron.withValues(alpha: 0.3),
                    AppTheme.gold.withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    AppConstants.meditationImageUrl,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Benefits of Kundalini Sadhana',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBrown,
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  _buildBenefit(
                    icon: Icons.bolt,
                    title: 'Enhanced Energy',
                    description: 'Experience unlimited cosmic energy flowing through your being.',
                  ),
                  
                  _buildBenefit(
                    icon: Icons.psychology,
                    title: 'Mental Clarity',
                    description: 'Achieve crystal clear focus and enhanced cognitive abilities.',
                  ),
                  
                  _buildBenefit(
                    icon: Icons.mood,
                    title: 'Emotional Balance',
                    description: 'Reduces stress, fear, and negativity, creating inner peace.',
                  ),
                  
                  _buildBenefit(
                    icon: Icons.circle,
                    title: 'Chakra Activation',
                    description: 'Aligns and energizes the body\'s subtle energy centers.',
                  ),
                  
                  _buildBenefit(
                    icon: Icons.auto_awesome,
                    title: 'Spiritual Awakening',
                    description: 'Expands consciousness and deepens connection with the Divine.',
                  ),
                  
                  _buildBenefit(
                    icon: Icons.transform,
                    title: 'Inner Transformation',
                    description: 'Brings self-realization and a purposeful, harmonious life.',
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Decorative bottom element
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.saffronGradient,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '✨ Transform Your Life ✨',
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
  
  Widget _buildBenefit({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.beige.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.saffron.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.saffronGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBrown,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
