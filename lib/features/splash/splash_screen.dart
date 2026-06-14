import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
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
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 1.0, curve: Curves.easeIn)),
    );

    _controller.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SINGLE entry point for all navigation decisions.
  // This is the ONLY place that decides where to go after launch.
  // The login screen only shows the login UI — no auto-login logic there.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _initializeApp() async {
    try {
      developer.log('🚀 Splash: initializing...');

      // Add overall timeout to prevent infinite loading
      await Future.any([
        _performInitialization(),
        Future.delayed(const Duration(seconds: 10), () {
          developer.log('⏰ Splash initialization timeout - going to login');
          throw TimeoutException('Splash initialization timed out');
        }),
      ]);
    } catch (e, st) {
      developer.log('❌ Splash error: $e\n$st');
      _navigate('/login');
    }
  }

  Future<void> _performInitialization() async {
    try {
      developer.log('📍 Step 1: Waiting for first frame...');
      // Wait for first frame
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        developer.log('⚠️ Widget unmounted after first frame');
        return;
      }
      developer.log('✅ First frame rendered');

      // Wait for localization with timeout
      developer.log('📍 Step 2: Checking localization...');
      final localizationTimeout = DateTime.now().add(const Duration(seconds: 3));
      while (!LocalizationService().isInitialized) {
        if (DateTime.now().isAfter(localizationTimeout)) {
          developer.log('⏰ Localization timeout - continuing anyway');
          break;
        }
        await Future.delayed(const Duration(milliseconds: 50));
        if (!mounted) {
          developer.log('⚠️ Widget unmounted during localization check');
          return;
        }
      }
      developer.log('✅ Localization ready');

      // Preload images in background — don't block navigation
      developer.log('📍 Step 3: Starting image preload (background)...');
      _preloadImages();

      // ── Step 1: First-time language selection ──────────────────────────────
      developer.log('📍 Step 4: Checking language selection...');
      final isLanguageSelected = await LocalizationService.isLanguageSelected();
      developer.log('🌐 Language selected: $isLanguageSelected');
      
      if (!isLanguageSelected) {
        developer.log('📱 First launch — navigating to language selection');
        _navigate('/language-selection');
        return;
      }

      // ── Step 2: Check our own cached user (set after successful backend login)
      developer.log('📍 Step 5: Checking cached user...');
      final authState = AuthState();
      if (!authState.isInitialized) {
        developer.log('🔄 Initializing AuthState...');
        await authState.initialize();
      }

      if (authState.user != null) {
        developer.log('✅ Cached user found: ${authState.user!.uid}');
        developer.log('📱 Profile complete: ${authState.user!.isProfileComplete}');
        final destination = authState.user!.isProfileComplete ? '/' : '/profile-setup';
        developer.log('🎯 Navigating to: $destination');
        _navigate(destination);
        return;
      }
      developer.log('❌ No cached user found');

      // ── Step 3: No cached user — check Firebase Auth ───────────────────────
      // Try silent/lightweight Google sign-in first (restores previous session
      // without showing any UI). Falls back to Firebase currentUser check.
      developer.log('📍 Step 6: Checking Firebase auth...');
      User? firebaseUser;
      try {
        // First check Firebase's own cached session
        firebaseUser = AuthService().currentUser;
        developer.log('Firebase currentUser: ${firebaseUser?.email ?? "null"}');
      } catch (e) {
        developer.log('⚠️ Firebase not ready: $e');
      }

      // Web: check redirect result first
      if (kIsWeb && firebaseUser == null) {
        try {
          developer.log('📍 Step 7: Checking web redirect result...');
          final redirectResult = await AuthService()
              .getRedirectResult()
              .timeout(const Duration(seconds: 3), onTimeout: () => null);
          if (redirectResult != null && redirectResult['success'] == true) {
            developer.log('🌐 Web redirect result — completing login');
            _navigate('/login');
            return;
          }
        } catch (e) {
          developer.log('⚠️ Redirect check failed: $e');
        }
      }

      if (firebaseUser == null) {
        // No Firebase session — try lightweight Google sign-in
        // This restores a previous Google session silently on Android
        if (!kIsWeb) {
          try {
            developer.log('📍 Step 8: Attempting lightweight Google sign-in...');
            firebaseUser = await AuthService()
                .attemptSilentSignIn()
                .timeout(const Duration(seconds: 3), onTimeout: () {
                  developer.log('⏰ Silent sign-in timeout');
                  return null;
                });
            if (firebaseUser != null) {
              developer.log('✅ Lightweight sign-in restored: ${firebaseUser.email}');
            } else {
              developer.log('❌ Lightweight sign-in returned null');
            }
          } catch (e) {
            developer.log('⚠️ Lightweight sign-in failed: $e');
          }
        }
      }

      if (firebaseUser == null) {
        developer.log('👤 No Firebase session found → login screen');
        _navigate('/login');
        return;
      }

      // Firebase has a session — check if it's a Google account
      developer.log('📍 Step 9: Validating Firebase provider...');
      final isGoogle = firebaseUser.providerData
          .any((p) => p.providerId == 'google.com');
      developer.log('Is Google provider: $isGoogle');

      if (!isGoogle) {
        developer.log('📱 Non-Google Firebase session, no cache → login');
        _navigate('/login');
        return;
      }

      // Google user — silently complete backend login with timeout
      developer.log('📍 Step 10: Completing backend login silently...');
      await _completeSilentGoogleLogin(firebaseUser);
    } catch (e, st) {
      developer.log('❌ Error in _performInitialization: $e\n$st');
      // On any error, go to login screen
      _navigate('/login');
    }
  }

  /// Silently completes the backend login for a Firebase Google user.
  /// Called from splash — no UI shown, user goes straight to home or profile setup.
  Future<void> _completeSilentGoogleLogin(User firebaseUser) async {
    try {
      // Get a fresh token with overall timeout
      String? idToken;
      try {
        for (int i = 0; i < 2; i++) {
          try {
            idToken = await firebaseUser.getIdToken(i == 0)
                .timeout(const Duration(seconds: 3));
            if (idToken != null && idToken.isNotEmpty) break;
          } catch (e) {
            developer.log('⚠️ Token attempt $i failed: $e');
          }
          await Future.delayed(const Duration(milliseconds: 300));
        }
      } catch (e) {
        developer.log('⏰ Token fetch timeout: $e');
      }

      if (idToken == null || idToken.isEmpty) {
        developer.log('❌ Could not get Firebase token → login screen');
        _navigate('/login');
        return;
      }

      final email = firebaseUser.email ?? '';
      if (email.isEmpty) {
        developer.log('❌ No email on Firebase user → login screen');
        _navigate('/login');
        return;
      }

      final result = await ApiService().loginWithGoogle(
        mobile: firebaseUser.phoneNumber ?? email,
        email: email,
        name: firebaseUser.displayName,
        photo: firebaseUser.photoURL,
        idToken: idToken,
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        developer.log('⏰ Backend login timeout');
        return {'success': false, 'message': 'Login timeout'};
      });

      if (result['success'] == true) {
        final user = UserModel.fromJson(result['user'] as Map<String, dynamic>);
        await AuthState().setUser(user);
        developer.log('✅ Silent login success → ${user.isProfileComplete ? "home" : "profile-setup"}');
        _navigate(user.isProfileComplete ? '/' : '/profile-setup');
      } else {
        // Backend rejected — could be blocked, server error, etc.
        // Send to login screen so user can see the error and retry.
        developer.log('❌ Backend rejected silent login: ${result['message']}');
        _navigate('/login');
      }
    } catch (e) {
      developer.log('❌ Silent login error: $e → login screen');
      _navigate('/login');
    }
  }

  void _navigate(String path) {
    developer.log('🚀 _navigate called with path: $path, mounted: $mounted');
    if (!mounted) {
      developer.log('⚠️ Cannot navigate - widget not mounted');
      return;
    }
    
    try {
      developer.log('🎯 Setting _isLoading = false');
      setState(() => _isLoading = false);
      
      developer.log('🎯 Calling context.go($path)');
      context.go(path);
      developer.log('✅ Navigation initiated to: $path');
    } catch (e, st) {
      developer.log('❌ Navigation error: $e\n$st');
    }
  }

  Future<void> _preloadImages() async {
    try {
      await ImagePreloaderService()
          .preloadCriticalImages(context)
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
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
            builder: (context, _) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
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
                            errorBuilder: (_, __, ___) => const DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.beige,
                              ),
                              child: Icon(Icons.person,
                                  size: 80, color: AppTheme.primary),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      Text(
                        'Moksha Guru',
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

                      const SizedBox(height: 40),

                      SizedBox(
                        height: 40,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.saffron),
                                strokeWidth: 2.5,
                              )
                            : const Icon(Icons.check_circle,
                                color: AppTheme.saffron, size: 32),
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
