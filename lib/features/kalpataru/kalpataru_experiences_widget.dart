import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

// CDN base for the experience images
const _cdnBase =
    'https://pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev/sadhaks/kalpatharu_experience/';

// Static fallback — images we know exist in the folder.
// These show instantly while the API call is in-flight or offline.
const _fallbackImages = [
  '${_cdnBase}kalpataru-1.jpeg',
  '${_cdnBase}kalpataru-2.jpeg',
  '${_cdnBase}kalpataru-3.jpeg',
  '${_cdnBase}kalpataru-4.jpeg',
  '${_cdnBase}kalpataru-5.jpeg',
];

class KalpataruExperiencesWidget extends StatefulWidget {
  const KalpataruExperiencesWidget({super.key});

  @override
  State<KalpataruExperiencesWidget> createState() =>
      _KalpataruExperiencesWidgetState();
}

class _KalpataruExperiencesWidgetState
    extends State<KalpataruExperiencesWidget> {
  late Future<List<String>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadImages();
  }

  Future<List<String>> _loadImages() async {
    try {
      final response = await ApiService().getKalpataruExperiences();
      if (response['success'] == true) {
        final raw = response['images'] as List<dynamic>? ?? [];
        if (raw.isNotEmpty) {
          return raw.map((e) {
            final name = e.toString();
            // Backend may return full URL or just filename
            if (name.startsWith('http')) return name;
            return '$_cdnBase$name';
          }).toList();
        }
      }
    } catch (_) {}
    // Fall back to static list
    return _fallbackImages;
  }

  void _openFullImage(BuildContext context, List<String> images, int index) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) =>
            _FullImageViewer(images: images, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _future,
      builder: (context, snapshot) {
        final images =
            snapshot.data ?? _fallbackImages;

        if (images.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Saffron accent bar
                  Container(
                    width: 4, height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.saffron,
                          AppTheme.saffron.withValues(alpha: 0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('📜', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kalpataru Experiences',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          'Real healing & manifestation stories',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tap count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.saffron.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.saffron.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${images.length} stories',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.saffron),
                    ),
                  ),
                ],
              ),
            ),

            // ── Horizontal scroll of experience cards ──────────────────
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16, right: 4),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return _ExperienceCard(
                    imageUrl: images[index],
                    index: index,
                    onTap: () => _openFullImage(context, images, index),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Individual card ────────────────────────────────────────────────────────

class _ExperienceCard extends StatelessWidget {
  final String imageUrl;
  final int index;
  final VoidCallback onTap;

  const _ExperienceCard({
    required this.imageUrl,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.saffron.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Saffron gradient background — always visible
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.saffron.withValues(alpha: 0.7),
                      AppTheme.gold.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
              // Network image
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, prog) =>
                    prog == null ? child : const SizedBox.shrink(),
                errorBuilder: (_, __, ___) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_stories,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 36),
                      const SizedBox(height: 6),
                      Text(
                        'Experience ${index + 1}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom gradient + tap hint
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to read',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Full-screen image viewer with swipe ───────────────────────────────────

class _FullImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<_FullImageViewer> {
  late PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.92),
      body: SafeArea(
        child: Stack(
          children: [
            // Full-screen page view
            PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _current = i),
              itemCount: widget.images.length,
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.images[i],
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, prog) => prog == null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.saffron)),
                    errorBuilder: (_, __, ___) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image,
                            color: Colors.white54, size: 64),
                        const SizedBox(height: 12),
                        const Text('Image not available',
                            style:
                                TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Top bar — close button + counter
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${_current + 1} / ${widget.images.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom dot indicators
            Positioned(
              bottom: 16, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _current == i ? 20 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _current == i
                          ? AppTheme.saffron
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
