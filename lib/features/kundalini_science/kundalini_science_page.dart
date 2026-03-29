import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class KundaliniSciencePage extends StatelessWidget {
  const KundaliniSciencePage({Key? key}) : super(key: key);

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
          'The Science of Kundalini Awakening',
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
              child: CachedNetworkImage(
                imageUrl: AppConstants.kundaliniImageUrl,
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
                    'The Science of Kundalini Awakening',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBrown,
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  _buildParagraph(
                    'Kundalini is the primordial cosmic energy that lies dormant at the base of the spine. Often depicted as a coiled serpent, this divine feminine energy represents the creative force of the universe.',
                  ),
                  
                  SizedBox(height: 16),
                  
                  _buildParagraph(
                    'When awakened through proper Sadhana (spiritual practice), Kundalini rises through the seven chakras, activating higher states of consciousness and ultimately leading to self-realization and unity with the divine.',
                  ),
                  
                  SizedBox(height: 16),
                  
                  _buildParagraph(
                    'This ancient science, preserved in Vedic traditions for millennia, offers a systematic path to spiritual evolution, healing, and the fulfillment of human potential.',
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Decorative bottom element
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.gold, AppTheme.saffron],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '🌟 Awaken Your Inner Energy 🌟',
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
