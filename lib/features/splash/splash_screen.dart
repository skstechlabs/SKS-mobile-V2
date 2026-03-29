import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_service.dart';
import '../../core/services/image_preloader_service.dart';
import 'dart:developer' as developer;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    _controller.forward();

    // Initialize app and navigate
    _initializeApp();
  }

  /// Initialize app: preload images and navigate
  Future<void> _initializeApp() async {
    try {
      developer.log('🚀 Initializing app from splash screen...');
      
      // Wait for first frame to ensure context is ready
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      
      // Start animation and preloading in parallel
      await Future.wait([
        // Minimum splash duration for smooth animation
        Future.delayed(const Duration(milliseconds: 2000)),
        // Preload critical images (don't block if it fails)
        _preloadImages().catchError((e) {
          developer.log('⚠️  Image preload error (non-blocking): $e');
          return null;
        }),
      ]);
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      // Small delay to show loaded state
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      // Navigate based on platform
      if (kIsWeb) {
        final result = await AuthService().getRedirectResult();
        if (!mounted) return;
        if (result != null && result['success'] == true) {
          context.go('/login');
          return;
        }
      }

      context.go('/login');
    } catch (e) {
      developer.log('❌ Splash initialization error: $e');
      // Navigate anyway on error
      if (mounted) context.go('/login');
    }
  }

  /// Preload critical images for faster loading
  Future<void> _preloadImages() async {
    developer.log('🖼️  Starting image preload...');
    await ImagePreloaderService().preloadCriticalImages(context);
    developer.log('✅ Critical images preloaded');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.white,
              AppTheme.beige.withValues(alpha: 0.3),
              AppTheme.white,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Guruji Logo with Glow Effect
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.saffron.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/Guruji_logo.JPG',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.beige,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: AppTheme.primary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Guruji Name - Matching home screen style
                      Column(
                        children: [
                          Text(
                            'Parama Pujya',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.saffron.withValues(alpha: 0.8),
                              letterSpacing: 1.5,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sri Jeeveswara Yogi',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.saffron,
                              letterSpacing: 0.5,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Loading indicator
                      SizedBox(
                        height: 40,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.saffron,
                                ),
                                strokeWidth: 2.5,
                              )
                            : const Icon(
                                Icons.check_circle,
                                color: AppTheme.saffron,
                                size: 32,
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}