import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/localization_service.dart';
import '../../core/services/api_service.dart';
import '../auth/auth_service.dart';
import '../auth/auth_state.dart';
import '../auth/user_model.dart';
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
      
      // IMPORTANT: Wait for localization to initialize
      developer.log('⏳ Waiting for localization service...');
      while (!LocalizationService().isInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      }
      developer.log('✅ Localization service ready');
      
      // Preload critical images (don't block navigation)
      _preloadImages().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          developer.log('⚠️  Image preload timeout (non-blocking)');
          return null;
        },
      ).catchError((e) {
        developer.log('⚠️  Image preload error (non-blocking): $e');
        return null;
      });
      
      if (!mounted) return;

      // Check if language is selected (first-time setup)
      final isLanguageSelected = await LocalizationService.isLanguageSelected();
      developer.log('📱 Language selected: $isLanguageSelected');
      
      if (!isLanguageSelected) {
        developer.log('✅ First time user, navigating to language selection');
        if (mounted) context.go('/language-selection');
        return;
      }

      // Check if user is already logged in
      // First check Firebase Auth, then check cached user data
      User? firebaseUser;
      try {
        firebaseUser = AuthService().currentUser;
      } catch (e) {
        developer.log('⚠️  Firebase not ready yet: $e');
        firebaseUser = null;
      }
      
      // Wait for AuthState to initialize
      final authState = AuthState();
      if (!authState.isInitialized) {
        developer.log('⏳ Waiting for AuthState to initialize...');
        await authState.initialize();
      }
      
      // Check if we have cached user data
      final cachedUser = authState.user;
      
      if (firebaseUser != null || cachedUser != null) {
        // User is logged in (either Firebase or cached)
        developer.log('✅ User logged in (Firebase: ${firebaseUser != null}, Cached: ${cachedUser != null})');
        
        // If we have Firebase user but no cached data, fetch from backend
        if (firebaseUser != null && cachedUser == null) {
          developer.log('🔄 Fetching user profile from backend...');
          try {
            final apiService = ApiService();
            final result = await apiService.getProfile();
            if (result['success'] == true && mounted) {
              final userData = result['user'] as Map<String, dynamic>;
              final userModel = UserModel.fromJson(userData);
              await authState.setUser(userModel);
              developer.log('✅ User profile loaded and cached');
            }
          } catch (e) {
            developer.log('⚠️  Failed to fetch user profile: $e');
            // Continue anyway with Firebase user
          }
        }
        
        if (mounted) context.go('/');
        return;
      }

      // Navigate based on platform
      if (kIsWeb) {
        try {
          final result = await AuthService().getRedirectResult().timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
          if (!mounted) return;
          if (result != null && result['success'] == true) {
            context.go('/login');
            return;
          }
        } catch (e) {
          developer.log('⚠️  Redirect result check failed (non-blocking): $e');
        }
      }

      if (!mounted) return;
      developer.log('✅ Navigating to login screen');
      context.go('/login');
    } catch (e, stackTrace) {
      developer.log('❌ Splash initialization error: $e');
      developer.log('Stack trace: $stackTrace');
      // Navigate anyway on error - don't leave user stuck on splash
      if (mounted) {
        try {
          context.go('/login');
        } catch (navError) {
          developer.log('❌ Navigation error: $navError');
        }
      }
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