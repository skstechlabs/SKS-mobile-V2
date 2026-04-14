import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/localization_service.dart';

class ChakraDetailPage extends StatefulWidget {
  final int initialIndex;

  const ChakraDetailPage({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<ChakraDetailPage> createState() => _ChakraDetailPageState();
}

class _ChakraDetailPageState extends State<ChakraDetailPage> {
  late PageController _pageController;
  late int _currentIndex;

  List<Map<String, dynamic>> _getChakras(BuildContext context) {
    return [
      {
        'name': context.tr('chakra_root'),
        'sanskritName': context.tr('chakra_mooladhara'),
        'image': AppConstants.rootChakraImageUrl,
        'location': context.tr('chakra_root_location'),
        'color': context.tr('chakra_root_color'),
        'element': context.tr('chakra_root_element'),
        'mantra': context.tr('chakra_root_mantra'),
        'description': context.tr('chakra_root_desc'),
        'backgroundColor': const Color(0xFFB85C5C),
      },
      {
        'name': context.tr('chakra_sacral'),
        'sanskritName': context.tr('chakra_swadhisthana'),
        'image': AppConstants.sacralChakraImageUrl,
        'location': context.tr('chakra_sacral_location'),
        'color': context.tr('chakra_sacral_color'),
        'element': context.tr('chakra_sacral_element'),
        'mantra': context.tr('chakra_sacral_mantra'),
        'description': context.tr('chakra_sacral_desc'),
        'backgroundColor': const Color(0xFFD17842),
      },
      {
        'name': context.tr('chakra_solar_plexus'),
        'sanskritName': context.tr('chakra_manipura'),
        'image': AppConstants.solarPlexusChakraImageUrl,
        'location': context.tr('chakra_solar_plexus_location'),
        'color': context.tr('chakra_solar_plexus_color'),
        'element': context.tr('chakra_solar_plexus_element'),
        'mantra': context.tr('chakra_solar_plexus_mantra'),
        'description': context.tr('chakra_solar_plexus_desc'),
        'backgroundColor': const Color(0xFFE8B84D),
      },
      {
        'name': context.tr('chakra_heart'),
        'sanskritName': context.tr('chakra_anahata'),
        'image': AppConstants.heartChakraImageUrl,
        'location': context.tr('chakra_heart_location'),
        'color': context.tr('chakra_heart_color'),
        'element': context.tr('chakra_heart_element'),
        'mantra': context.tr('chakra_heart_mantra'),
        'description': context.tr('chakra_heart_desc'),
        'backgroundColor': const Color(0xFF5FA777),
      },
      {
        'name': context.tr('chakra_throat'),
        'sanskritName': context.tr('chakra_vishuddha'),
        'image': AppConstants.throatChakraImageUrl,
        'location': context.tr('chakra_throat_location'),
        'color': context.tr('chakra_throat_color'),
        'element': context.tr('chakra_throat_element'),
        'mantra': context.tr('chakra_throat_mantra'),
        'description': context.tr('chakra_throat_desc'),
        'backgroundColor': const Color(0xFF5B9BD5),
      },
      {
        'name': context.tr('chakra_third_eye'),
        'sanskritName': context.tr('chakra_ajna'),
        'image': AppConstants.thirdEyeChakraImageUrl,
        'location': context.tr('chakra_third_eye_location'),
        'color': context.tr('chakra_third_eye_color'),
        'element': context.tr('chakra_third_eye_element'),
        'mantra': context.tr('chakra_third_eye_mantra'),
        'description': context.tr('chakra_third_eye_desc'),
        'backgroundColor': const Color(0xFF4B5D8F),
      },
      {
        'name': context.tr('chakra_crown'),
        'sanskritName': context.tr('chakra_sahasrara'),
        'image': AppConstants.crownChakraImageUrl,
        'location': context.tr('chakra_crown_location'),
        'color': context.tr('chakra_crown_color'),
        'element': context.tr('chakra_crown_element'),
        'mantra': context.tr('chakra_crown_mantra'),
        'description': context.tr('chakra_crown_desc'),
        'backgroundColor': const Color(0xFF9B59B6),
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chakras = _getChakras(context);
    
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: chakras.length,
        itemBuilder: (context, index) {
          return _buildChakraPage(chakras[index], chakras.length);
        },
      ),
    );
  }

  Widget _buildChakraPage(Map<String, dynamic> chakra, int totalChakras) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            chakra['backgroundColor'],
            chakra['backgroundColor'].withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    _buildChakraImage(chakra),
                    SizedBox(height: 24),
                    _buildChakraName(chakra),
                    SizedBox(height: 24),
                    _buildInfoCards(chakra),
                    SizedBox(height: 24),
                    _buildAboutSection(chakra),
                    SizedBox(height: 24),
                    _buildNavigationDots(),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }

  Widget _buildChakraImage(Map<String, dynamic> chakra) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: CachedNetworkImage(
            imageUrl: chakra['image'],
            fit: BoxFit.contain,
            width: double.infinity,
            placeholder: (context, url) => Container(
              color: Colors.white.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.white.withValues(alpha: 0.3),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Image not available',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChakraName(Map<String, dynamic> chakra) {
    return Column(
      children: [
        Text(
          chakra['name'],
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Text(
          chakra['sanskritName'],
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black.withOpacity(0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards(Map<String, dynamic> chakra) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoCard('location', chakra['location'], context),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard('color', chakra['color'], context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard('element', chakra['element'], context),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard('mantra', chakra['mantra'], context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            context.tr('chakra_$label'),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(Map<String, dynamic> chakra) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${context.tr('chakra_about')} ${chakra['name']}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              chakra['description'],
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationDots() {
    final chakras = _getChakras(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_currentIndex > 0)
            GestureDetector(
              onTap: () {
                _pageController.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.arrow_back_ios, color: Colors.black54, size: 18),
              ),
            )
          else
            SizedBox(width: 34),
          SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                chakras.length,
                (index) => Container(
                  width: _currentIndex == index ? 28 : 8,
                  height: 8,
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? AppTheme.primary
                        : Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          if (_currentIndex < chakras.length - 1)
            GestureDetector(
              onTap: () {
                _pageController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ),
            )
          else
            SizedBox(width: 44),
        ],
      ),
    );
  }
}
