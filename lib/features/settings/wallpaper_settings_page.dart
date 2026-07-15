import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/wallpaper_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/widgets/cached_image.dart';

class WallpaperSettingsPage extends StatefulWidget {
  const WallpaperSettingsPage({Key? key}) : super(key: key);

  @override
  State<WallpaperSettingsPage> createState() => _WallpaperSettingsPageState();
}

class _WallpaperSettingsPageState extends State<WallpaperSettingsPage> {
  final WallpaperService _wallpaperService = WallpaperService();
  
  bool _isLoading = true;
  List<String> _availableWallpapers = [];
  // Tracks which index was explicitly set by the user — null means none yet
  int? _currentIndex;
  // URLs that failed with a fatal error (corrupt, undecodable) — hidden from grid
  final Set<String> _brokenUrls = {};

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);

    try {
      // Always force-refresh the wallpaper list when the page loads so that
      // any new wallpapers added to the CDN appear immediately.
      final wallpapers = await _wallpaperService.getAvailableWallpapers(
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          _availableWallpapers = wallpapers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading wallpaper status: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setSpecificWallpaper(int index) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.wallpaper, color: AppTheme.primary),
            SizedBox(width: 10),
            Text('Set Wallpaper?'),
          ],
        ),
        content: const Text(
          'This image will be set as your device wallpaper.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Set Wallpaper'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _wallpaperService.setWallpaperByIndex(index);
      await _loadStatus();
      // Mark this index as current after successful set
      if (mounted) setState(() => _currentIndex = index);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Wallpaper set successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error setting wallpaper: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        if (e.toString().contains('not supported on web')) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(child: Text('Mobile Only Feature')),
                ],
              ),
              content: const Text(
                'Wallpaper setting is only available on mobile devices (Android/iOS).\n\n'
                'Please use the mobile app to set wisdom wallpapers on your device.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(context.tr('wisdom_wallpapers_title')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ───────────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [AppTheme.glowShadow],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.wallpaper,
                                color: Colors.white, size: 32),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            context.tr('wisdom_wallpapers_title'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr('tap_to_set_wallpaper'),
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // ── Section heading ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('available_wallpapers'),
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap an image to set it as your wallpaper',
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),

                    // ── Wallpaper grid ───────────────────────────────────────
                    if (_availableWallpapers.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            context.tr('no_wallpapers_available'),
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.7,
                          ),
                          // Only show wallpapers that haven't failed with a fatal error
                          itemCount: _availableWallpapers
                              .where((url) => !_brokenUrls.contains(url))
                              .length,
                          itemBuilder: (context, index) {
                            // Build against the filtered list
                            final filtered = _availableWallpapers
                                .where((url) => !_brokenUrls.contains(url))
                                .toList();
                            return _buildWallpaperCard(
                              _availableWallpapers.indexOf(filtered[index]),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWallpaperCard(int index) {
    final imageUrl = _availableWallpapers[index];
    // Only show "Current" badge if user has explicitly set this image
    final isCurrent = _currentIndex == index;

    return GestureDetector(
      onTap: () => _setSpecificWallpaper(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent ? AppTheme.primary : AppTheme.softGray,
            width: isCurrent ? 3 : 1,
          ),
          boxShadow: isCurrent
              ? [BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                // When image fails fatally (EncodingError, corrupt), hide it from grid
                errorWidget: Builder(builder: (_) {
                  // Schedule removal after the current frame — can't call setState in build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_brokenUrls.contains(imageUrl) && mounted) {
                      debugPrint('🗑️ Removing broken wallpaper from grid: $imageUrl');
                      setState(() => _brokenUrls.add(imageUrl));
                    }
                  });
                  return const SizedBox.shrink();
                }),
              ),
              if (isCurrent)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 13),
                        SizedBox(width: 4),
                        Text('Current',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              // Bottom label
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                  child: Text(
                    'Image ${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
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

