import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_env.dart';
import '../../../core/services/onesignal_service.dart';

/// AuthService — Google Sign-In using google_sign_in 7.x API.
///
/// Key changes from 6.x:
/// - GoogleSignIn.instance is a singleton (no constructor)
/// - Must call initialize() once before any other method
/// - authenticate() replaces signIn()
/// - GoogleSignInAuthentication only has idToken (no accessToken)
/// - accessToken is via authorizationClient (not needed for Firebase)
/// - GoogleSignInException has .code and .description (no .message)
/// - authentication is a synchronous getter (no await)
///
/// IMPORTANT: serverClientId MUST be passed explicitly to initialize().
/// Do NOT rely on the automatic google-services.json resource lookup —
/// it can fail on some devices when minification is enabled.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // The web OAuth client ID (client_type: 3) from google-services.json.
  // This is the SAME value as default_web_client_id in Android resources.
  // Hardcoded as fallback so it works even if AppEnv is not set.
  static const String _webClientId =
      '294856785598-qivhqf2ehn5p0rs1830dt9mt030ort9p.apps.googleusercontent.com';

  bool _initialized = false;
  bool _initializing = false;

  FirebaseAuth get _auth {
    try {
      Firebase.app();
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('⚠️ Firebase not initialized: $e');
      rethrow;
    }
  }

  /// Ensure Firebase is initialized before using auth
  Future<void> _ensureFirebaseInitialized() async {
    try {
      Firebase.app();
    } catch (e) {
      debugPrint('⚠️ Firebase not ready, initializing...');
      // Wait for Firebase - it should be initializing in main.dart
      for (int i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        try {
          Firebase.app();
          debugPrint('✅ Firebase ready after ${(i + 1) * 100}ms');
          return;
        } catch (_) {
          // Keep waiting
        }
      }
      debugPrint('❌ Firebase still not initialized after 5 seconds');
      throw Exception('Firebase not initialized. Please restart the app.');
    }
  }

  /// Initialize GoogleSignIn singleton. Safe to call multiple times.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    if (_initializing) {
      // Wait for the in-progress initialization with a safety timeout
      for (int i = 0; i < 100; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (_initialized) return;
        if (!_initializing) break; // init failed, fall through to retry
      }
      if (_initialized) return;
    }
    _initializing = true;
    try {
      final serverClientId = AppEnv.googleClientId.isNotEmpty
          ? AppEnv.googleClientId
          : _webClientId;

      debugPrint('🔑 GoogleSignIn.initialize() with serverClientId: $serverClientId');

      await GoogleSignIn.instance.initialize(
        serverClientId: serverClientId,
      );
      _initialized = true;
      debugPrint('✅ GoogleSignIn.instance initialized');
    } catch (e) {
      debugPrint('❌ GoogleSignIn.initialize() failed: $e');
      _initialized = false;
      rethrow;
    } finally {
      _initializing = false;
    }
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Ensure Firebase is ready before attempting sign-in
      await _ensureFirebaseInitialized();
      
      if (kIsWeb) {
        return await _signInWeb();
      } else {
        return await _signInMobile();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} — ${e.message}');
      return {'success': false, 'message': _friendlyFirebaseError(e.code)};
    } on GoogleSignInException catch (e) {
      debugPrint('❌ GoogleSignInException: ${e.code} — ${e.description}');
      return {'success': false, 'message': _friendlyGoogleError(e)};
    } catch (e) {
      debugPrint('❌ Google sign-in error: $e');
      return {'success': false, 'message': _friendlyGenericError(e.toString())};
    }
  }

  // ── Mobile (Android / iOS) ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> _signInMobile() async {
    await _ensureInitialized();

    // authenticate() shows the account picker.
    // Throws GoogleSignInException on failure/cancellation.
    final GoogleSignInAccount account =
        await GoogleSignIn.instance.authenticate();

    debugPrint('✅ GoogleSignIn account: ${account.email}');

    // In 7.x, authentication is a synchronous getter — no await needed.
    // It only contains idToken (accessToken moved to authorizationClient).
    // For Firebase we only need idToken.
    final GoogleSignInAuthentication googleAuth = account.authentication;

    debugPrint(
        '✅ idToken: ${googleAuth.idToken != null ? "present" : "null"}');

    if (googleAuth.idToken == null) {
      // On some devices the idToken can be null on first call.
      // Wait briefly and try again.
      await Future.delayed(const Duration(milliseconds: 400));
      final retryAuth = account.authentication;
      if (retryAuth.idToken == null) {
        debugPrint('❌ idToken still null after retry');
        return {
          'success': false,
          'message': 'Google sign-in failed. Please try again.',
        };
      }
      return await _signInWithFirebase(googleAuth: retryAuth);
    }

    return await _signInWithFirebase(googleAuth: googleAuth);
  }

  Future<Map<String, dynamic>> _signInWithFirebase({
    required GoogleSignInAuthentication googleAuth,
  }) async {
    // In 7.x, GoogleSignInAuthentication only has idToken.
    // Firebase credential only needs idToken for sign-in.
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      // accessToken is not available in 7.x authentication — omit it.
      // Firebase accepts idToken-only credentials.
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null) {
      return {
        'success': false,
        'message': 'Google sign-in failed. Please try again.'
      };
    }

    // Force-refresh the Firebase ID token — this is what we send to our backend
    String? freshIdToken;
    try {
      freshIdToken = await user.getIdToken(true);
    } catch (e) {
      debugPrint('⚠️ Force-refresh failed, using cached: $e');
      try {
        freshIdToken = await user.getIdToken(false);
      } catch (_) {}
    }

    debugPrint('✅ Firebase sign-in success: ${user.email}');
    return {
      'success': true,
      'uid': user.uid,
      'email': user.email ?? '',
      'name': user.displayName ?? '',
      'photo': user.photoURL ?? '',
      'mobile': user.phoneNumber ?? '',
      'idToken': freshIdToken,
      'message': 'Google sign-in successful',
    };
  }

  // ── Web ────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _signInWeb() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');

    try {
      final userCredential = await _auth.signInWithPopup(provider);
      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'message': 'Google sign-in failed.'};
      }
      final idToken = await user.getIdToken(true);
      return {
        'success': true,
        'uid': user.uid,
        'email': user.email ?? '',
        'name': user.displayName ?? '',
        'photo': user.photoURL ?? '',
        'mobile': user.phoneNumber ?? '',
        'idToken': idToken,
        'message': 'Google sign-in successful',
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-blocked') {
        await _auth.signInWithRedirect(provider);
        return {'success': false, 'pending': true, 'message': 'Redirecting...'};
      }
      rethrow;
    }
  }

  // ── Silent sign-in (for splash screen) ────────────────────────────────────
  /// Tries to restore a previous Google session without showing any UI.
  /// Returns the Firebase user if successful, null otherwise.
  Future<User?> attemptSilentSignIn() async {
    try {
      await _ensureInitialized();

      // attemptLightweightAuthentication() returns Future<GoogleSignInAccount?>?
      // The outer nullable means the platform may not support it.
      final Future<GoogleSignInAccount?>? lightweightFuture =
          GoogleSignIn.instance.attemptLightweightAuthentication();

      if (lightweightFuture == null) {
        debugPrint('ℹ️ Lightweight auth not supported on this platform');
        return null;
      }

      final GoogleSignInAccount? account = await lightweightFuture
          .timeout(const Duration(seconds: 8), onTimeout: () => null);

      if (account == null) {
        debugPrint('ℹ️ No lightweight Google session available');
        return null;
      }

      debugPrint('✅ Lightweight auth restored: ${account.email}');

      // authentication is a synchronous getter in 7.x
      final googleAuth = account.authentication;
      if (googleAuth.idToken == null) {
        debugPrint('⚠️ Lightweight auth: idToken null');
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint('⚠️ Silent sign-in failed (expected if no session): $e');
      return null;
    }
  }

  // ── Web redirect result ────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getRedirectResult() async {
    try {
      final result = await _auth.getRedirectResult();
      final user = result.user;
      if (user != null) {
        final idToken = await user.getIdToken(true);
        return {
          'success': true,
          'uid': user.uid,
          'email': user.email ?? '',
          'name': user.displayName ?? '',
          'photo': user.photoURL ?? '',
          'mobile': user.phoneNumber ?? '',
          'idToken': idToken,
          'message': 'Google sign-in successful',
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await OneSignalService().removeExternalUserId();
    } catch (_) {}
    try {
      if (_initialized) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (e) {
      debugPrint('⚠️ GoogleSignIn signOut error: $e');
    }
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('⚠️ Firebase signOut error: $e');
    }
  }

  // ── Error helpers ──────────────────────────────────────────────────────────
  String _friendlyFirebaseError(String code) {
    switch (code) {
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'web-context-cancelled':
        return 'Sign-in cancelled. Please try again.';
      case 'popup-blocked':
        return 'Popup blocked. Please allow popups and try again.';
      case 'account-exists-with-different-credential':
        return 'Account already exists with a different sign-in method.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled. Contact support.';
      case 'user-disabled':
        return 'Your account has been disabled. Contact support.';
      default:
        return 'Authentication failed ($code). Please try again.';
    }
  }

  String _friendlyGoogleError(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Sign-in cancelled.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Sign-in was interrupted. Please try again.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        // This usually means SHA-1 mismatch or wrong package name
        return 'Sign-in configuration error. Please contact support.';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Sign-in provider error. Please contact support.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Sign-in UI unavailable. Please try again.';
      default:
        return 'Google sign-in failed. Please try again.';
    }
  }

  String _friendlyGenericError(String msg) {
    if (msg.contains('network_error') || msg.contains('NetworkException')) {
      return 'Network error. Check your internet connection.';
    }
    if (msg.contains('canceled') || msg.contains('cancelled')) {
      return 'Sign-in cancelled.';
    }
    return 'Google sign-in failed. Please try again.';
  }
}
