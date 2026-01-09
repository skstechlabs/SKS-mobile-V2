import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class ChakraDetailPage extends StatefulWidget {
  final int initialIndex;

  const ChakraDetailPage({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<ChakraDetailPage> createState() => _ChakraDetailPageState();
}

class _ChakraDetailPageState extends State<ChakraDetailPage> {
  late PageController _pageController;
  late int _currentIndex;

  final List<Map<String, dynamic>> chakras = [
    {
      'name': 'Root Chakra',
      'sanskritName': 'Mooladhara',
      'image': AppConstants.rootChakraImageUrl,
      'location': 'Base of spine',
      'color': 'Red',
      'element': 'Earth',
      'mantra': 'LAM',
      'description': 'The Root Chakra represents our foundation and feeling of being grounded. It affects our survival instincts, security, and basic needs. When balanced, you feel safe, stable, and confident in facing life\'s challenges.',
      'backgroundColor': Color(0xFFB85C5C),
    },
    {
      'name': 'Sacral Chakra',
      'sanskritName': 'Swadhisthana',
      'image': AppConstants.sacralChakraImageUrl,
      'location': 'Lower abdomen',
      'color': 'Orange',
      'element': 'Water',
      'mantra': 'VAM',
      'description': 'The Sacral Chakra governs creativity, sexuality, and emotions. It represents pleasure, joy, and passion. When balanced, you experience healthy relationships, creativity flows naturally, and you embrace change with ease.',
      'backgroundColor': Color(0xFFD17842),
    },
    {
      'name': 'Solar Plexus Chakra',
      'sanskritName': 'Manipura',
      'image': AppConstants.solarPlexusChakraImageUrl,
      'location': 'Upper abdomen',
      'color': 'Yellow',
      'element': 'Fire',
      'mantra': 'RAM',
      'description': 'The Solar Plexus Chakra is your power center, governing self-esteem, confidence, and personal power. It influences your sense of control and willpower. When balanced, you feel confident, motivated, and have a strong sense of purpose.',
      'backgroundColor': Color(0xFFE8B84D),
    },
    {
      'name': 'Heart Chakra',
      'sanskritName': 'Anahata',
      'image': AppConstants.heartChakraImageUrl,
      'location': 'Center of chest',
      'color': 'Green',
      'element': 'Air',
      'mantra': 'YAM',
      'description': 'The Heart Chakra represents love, compassion, and connection. It bridges physical and spiritual realms. When balanced, you experience unconditional love, forgiveness, empathy, and deep connections with others.',
      'backgroundColor': Color(0xFF5FA777),
    },
    {
      'name': 'Throat Chakra',
      'sanskritName': 'Vishuddha',
      'image': AppConstants.throatChakraImageUrl,
      'location': 'Throat',
      'color': 'Blue',
      'element': 'Ether',
      'mantra': 'HAM',
      'description': 'The Throat Chakra governs communication, self-expression, and truth. It allows you to speak your authentic truth. When balanced, you communicate clearly, listen actively, and express yourself confidently.',
      'backgroundColor': Color(0xFF5B9BD5),
    },
    {
      'name': 'Third Eye Chakra',
      'sanskritName': 'Ajna',
      'image': AppConstants.thirdEyeChakraImageUrl,
      'location': 'Between eyebrows',
      'color': 'Indigo',
      'element': 'Light',
      'mantra': 'OM',
      'description': 'The Third Eye Chakra represents intuition, wisdom, and inner vision. It governs insight and spiritual awareness. When balanced, you trust your intuition, see beyond the physical, and have clarity of thought.',
      'backgroundColor': Color(0xFF4B5D8F),
    },
    {
      'name': 'Crown Chakra',
      'sanskritName': 'Sahasrara',
      'image': AppConstants.crownChakraImageUrl,
      'location': 'Top of head',
      'color': 'Violet/White',
      'element': 'Cosmic Energy',
      'mantra': 'AH',
      'description': 'The Crown Chakra connects you to divine consciousness and universal energy. It represents enlightenment and spiritual connection. When balanced, you experience inner peace, wisdom, and a sense of oneness with all.',
      'backgroundColor': Color(0xFF9B59B6),
    },
  ];

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
          return _buildChakraPage(chakras[index]);
        },
      ),
    );
  }

  Widget _buildChakraPage(Map<String, dynamic> chakra) {
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
          child: Image.network(
            chakra['image'],
            fit: BoxFit.contain,
            width: double.infinity,
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
                child: _buildInfoCard('LOCATION', chakra['location']),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard('COLOR', chakra['color']),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard('ELEMENT', chakra['element']),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard('MANTRA', chakra['mantra']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
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
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About ${chakra['name']}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 16),
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
