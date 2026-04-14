import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/localization_service.dart';

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
          context.tr('benefits_title'),
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
            // Hero Image
            Container(
              height: 300,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: AppConstants.meditationImageUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.softGray,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.saffron),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.softGray,
                  child: const Icon(Icons.image_not_supported, size: 48),
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
                    context.tr('benefits_title'),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildBenefit(
                    icon: Icons.bolt,
                    title: context.tr('benefit_enhanced_energy'),
                    description: context.tr('benefit_enhanced_energy_desc'),
                  ),
                  
                  _buildBenefit(
                    icon: Icons.psychology,
                    title: context.tr('benefit_mental_clarity'),
                    description: context.tr('benefit_mental_clarity_desc'),
                  ),
                  
                  _buildBenefit(
                    icon: Icons.mood,
                    title: context.tr('benefit_emotional_balance'),
                    description: context.tr('benefit_emotional_balance_desc'),
                  ),
                  
                  _buildBenefit(
                    icon: Icons.circle,
                    title: context.tr('benefit_chakra_activation'),
                    description: context.tr('benefit_chakra_activation_desc'),
                  ),
                  
                  _buildBenefit(
                    icon: Icons.auto_awesome,
                    title: context.tr('benefit_spiritual_awakening'),
                    description: context.tr('benefit_spiritual_awakening_desc'),
                  ),
                  
                  _buildBenefit(
                    icon: Icons.transform,
                    title: context.tr('benefit_inner_transformation'),
                    description: context.tr('benefit_inner_transformation_desc'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Decorative bottom element
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.saffronGradient,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        context.tr('transform_your_life'),
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
