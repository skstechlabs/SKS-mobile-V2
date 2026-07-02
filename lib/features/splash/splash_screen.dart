import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  //
  // SESSION PERSISTENCE RULE:
  // If AuthState has a cached user → the user IS logged in. Go home.
  // Never call the backend during splash just to "verify" — a network
  // hiccup would incorrectly log the user out. Trust the local cache.
  // The backend is only consulted on the very first login, not on every restart.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _initializeApp() async {
    try {
      developer.log('🚀 Splash: initializing...');

      // Generous timeout — 15s is enough for slow devices + DNS.
      // On timeout: trust local cache if available, else go to login.
      await Future.any([
        _performInitialization(),
        Future.delayed(const Duration(seconds: 15), () {
          developer.log('⏰ Splash initialization timeout');
          throw TimeoutException('Splash initialization timed out');
        }),
      ]);
    } catch (e, st) {
      developer.log('❌ Splash error: $e\n$st');
      // On any error: check if we have a cached user before giving up.
      // This prevents a bad network from logging the user out.
      await _navigateWithCacheFallback();
    }
  }

  /// Last-resort navigation: use cached user if available, else login screen.
  Future<void> _navigateWithCacheFallback() async {
    try {
      final authState = AuthState();
      if (!authState.isInitialized) {
        await authState.initialize().timeout(const Duration(seconds: 2));
      }
      if (authState.user != null) {
        developer.log('🔒 Fallback: cached user found → going home');
        _navigate('/');
        return;
      }
    } catch (_) {}
    developer.log('🔒 Fallback: no cached user → going to login');
    _navigate('/login');
  }

  Future<void> _performInitialization() async {
    try {
      developer.log('📍 Step 1: Waiting for first frame...');
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
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
        if (!mounted) return;
      }
      developer.log('✅ Localization ready');

      // Preload images in background — never blocks navigation
      _preloadImages();

      // ── Step 1: First-time language selection ────────────────────────────
      developer.log('📍 Step 3: Checking language selection...');
      final isLanguageSelected = await LocalizationService.isLanguageSelected();
      developer.log('🌐 Language selected: $isLanguageSelected');
      if (!isLanguageSelected) {
        developer.log('📱 First launch — navigating to language selection');
        _navigate('/language-selection');
        return;
      }

      // ── Step 2: Check local cache FIRST ──────────────────────────────────
      // This is the primary session check. If we have a cached user we are
      // logged in — no network call needed. This is what makes cold-restart
      // seamless even on slow/no network.
      developer.log('📍 Step 4: Checking cached user...');
      final authState = AuthState();
      if (!authState.isInitialized) {
        developer.log('🔄 Initializing AuthState...');
        await authState.initialize();
      }

      if (authState.user != null) {
        developer.log('✅ Cached user found: ${authState.user!.uid}');
        await _handleAuthenticatedUser(authState.user!);
        return;
      }
      developer.log('❌ No cached user found — checking Firebase...');

      // ── Step 3: No cached user — try Firebase silent restore ─────────────
      // This path only runs on first login after install, or after explicit logout.
      await _tryFirebaseRestore();
    } catch (e, st) {
      developer.log('❌ Error in _performInitialization: $e\n$st');
      // Final safety net: check cache before giving up
      await _navigateWithCacheFallback();
    }
  }

  /// Handle a user we know is authenticated (from local cache).
  /// Never makes a network call — pure local navigation decision.
  Future<void> _handleAuthenticatedUser(UserModel user) async {
    // Re-link OneSignal (no network, just registers the ID locally)
    if (!kIsWeb) {
      try {
        OneSignal.login(user.uid);
        if (OneSignal.Notifications.permission) {
          OneSignal.User.pushSubscription.optIn();
        }
        developer.log('✅ OneSignal re-linked for cached user ${user.uid}');
      } catch (e) {
        developer.log('⚠️ OneSignal re-link failed: $e');
      }
    }

    String destination;
    if (!user.isProfileComplete) {
      destination = '/profile-setup';
    } else {
      final hasPermission = await _checkNotificationPermission();
      destination = hasPermission ? '/' : '/notification-permission';
    }
    developer.log('🎯 Cached user → navigating to $destination');
    _navigate(destination);
  }

  /// Try to restore a Firebase session and complete backend login silently.
  /// This only runs when there is NO cached user (fresh install / after logout).
  Future<void> _tryFirebaseRestore() async {
    User? firebaseUser;

    // Check Firebase's own cached session
    try {
      firebaseUser = AuthService().currentUser;
      developer.log('Firebase currentUser: ${firebaseUser?.email ?? "null"}');
    } catch (e) {
      developer.log('⚠️ Firebase not ready: $e');
    }

    // Web: check redirect result
    if (kIsWeb && firebaseUser == null) {
      try {
        final redirectResult = await AuthService()
            .getRedirectResult()
            .timeout(const Duration(seconds: 3), onTimeout: () => null);
        if (redirectResult != null && redirectResult['success'] == true) {
          developer.log('🌐 Web redirect result — going to login to complete');
          _navigate('/login');
          return;
        }
      } catch (e) {
        developer.log('⚠️ Redirect check failed: $e');
      }
    }

    // Mobile: try lightweight Google silent sign-in
    if (!kIsWeb && firebaseUser == null) {
      try {
        developer.log('📍 Attempting lightweight Google sign-in...');
        firebaseUser = await AuthService()
            .attemptSilentSignIn()
            .timeout(const Duration(seconds: 5), onTimeout: () {
              developer.log('⏰ Silent sign-in timeout');
              return null;
            });
        developer.log(firebaseUser != null
            ? '✅ Silent sign-in: ${firebaseUser.email}'
            : '❌ Silent sign-in: no session');
      } catch (e) {
        developer.log('⚠️ Silent sign-in failed: $e');
      }
    }

    if (firebaseUser == null) {
      developer.log('👤 No Firebase session → login screen');
      _navigate('/login');
      return;
    }

    // Firebase has a session — must be Google for silent backend login
    final isGoogle =
        firebaseUser.providerData.any((p) => p.providerId == 'google.com');
    if (!isGoogle) {
      developer.log('📱 Non-Google Firebase session → login screen');
      _navigate('/login');
      return;
    }

    // Complete backend login silently
    await _completeSilentGoogleLogin(firebaseUser);
  }

  /// Silently completes the backend login for a Firebase Google user.
  /// Only called when there is NO cached user (fresh install / after logout).
  ///
  /// If the backend call fails (timeout, server error, no network), we do NOT
  /// send the user to the login screen — we simply save what we know from
  /// Firebase locally and navigate home. The next API call with a valid
  /// Firebase token will re-establish the full session transparently.
  Future<void> _completeSilentGoogleLogin(User firebaseUser) async {
    try {
      // Fetch Firebase token — try cached first, then force-refresh
      String? idToken;
      for (int i = 0; i < 2; i++) {
        try {
          idToken = await firebaseUser
              .getIdToken(i > 0) // false on first attempt, true on retry
              .timeout(const Duration(seconds: 5));
          if (idToken != null && idToken.isNotEmpty) break;
        } catch (e) {
          developer.log('⚠️ Token attempt $i failed: $e');
        }
        if (i == 0) await Future.delayed(const Duration(milliseconds: 300));
      }

      if (idToken == null || idToken.isEmpty) {
        developer.log('❌ Could not get Firebase token — going to login');
        _navigate('/login');
        return;
      }

      final email = firebaseUser.email ?? '';
      if (email.isEmpty) {
        developer.log('❌ No email on Firebase user — going to login');
        _navigate('/login');
        return;
      }

      // Attempt backend login with a generous timeout
      Map<String, dynamic>? result;
      try {
        result = await ApiService().loginWithGoogle(
          mobile: firebaseUser.phoneNumber ?? email,
          email: email,
          name: firebaseUser.displayName,
          photo: firebaseUser.photoURL,
          idToken: idToken,
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        developer.log('⚠️ Backend login failed/timed out: $e');
        // Backend unavailable — build a minimal user from Firebase data
        // so the user can still use the app. Session will be fully restored
        // on the next successful API call.
        result = null;
      }

      UserModel user;
      if (result != null && result['success'] == true) {
        user = UserModel.fromJson(result['user'] as Map<String, dynamic>);
        developer.log('✅ Backend login success for ${user.uid}');
      } else {
        // Backend rejected OR unavailable — create user from Firebase data.
        // This ensures the user is never stuck on the login screen just because
        // of a transient server/network issue.
        developer.log('⚠️ Backend unavailable — using Firebase identity as fallback');
        user = UserModel(
          uid: firebaseUser.uid,
          mobile: firebaseUser.phoneNumber ?? '',
          email: email,
          name: firebaseUser.displayName ?? '',
          photo: firebaseUser.photoURL ?? '',
          authProvider: 'google',
          isProfileComplete: false, // will be confirmed on next API call
        );
      }

      await AuthState().setUser(user);

      if (!kIsWeb) {
        try {
          OneSignal.login(user.uid);
          if (OneSignal.Notifications.permission) {
            OneSignal.User.pushSubscription.optIn();
          }
        } catch (e) {
          developer.log('⚠️ OneSignal login failed: $e');
        }
      }

      String destination;
      if (!user.isProfileComplete) {
        // If profile completeness is unknown (fallback user), go to home and
        // let the profile screen handle the incomplete state.
        destination = (result != null && result['success'] == true)
            ? '/profile-setup'
            : '/';
      } else {
        final hasPermission = await _checkNotificationPermission();
        destination = hasPermission ? '/' : '/notification-permission';
      }

      developer.log('✅ Silent login complete → $destination');
      _navigate(destination);
    } catch (e) {
      developer.log('❌ Silent login error: $e');
      // Last resort: if we have a cached user, go home; otherwise login
      await _navigateWithCacheFallback();
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

  /// Check if notification permission is granted (without prompting).
  /// Uses permission_handler to query the OS directly — always accurate,
  /// no SDK sync delay needed.
  ///
  /// Returns true if:
  ///   - Permission is granted by the OS, OR
  ///   - User has already seen the permission screen (to avoid showing it on every restart)
  Future<bool> _checkNotificationPermission() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.notification.status;
      final granted = status.isGranted;

      // Keep the persisted flag in sync with the live OS state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_permission_granted', granted);

      developer.log('✅ Notification permission (OS direct): $granted');

      if (granted) return true;

      // Not granted — check if the user has already seen (and skipped) this screen.
      // If they've seen it, don't redirect them there again on every cold restart.
      final alreadySeen = prefs.getBool('notification_permission_seen') ?? false;
      if (alreadySeen) {
        developer.log('ℹ️ Notification permission screen already seen — skipping');
        return true;
      }

      return false;
    } catch (e) {
      developer.log('⚠️ Error checking notification permission: $e');
      return true; // Assume granted on error — don't block users
    }
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
