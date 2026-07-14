import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_env.dart';
import '../../../core/services/onesignal_service.dart';
import '../../../firebase_options.dart';

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

  // Access FirebaseAuth directly — never through Firebase.app() which can throw.
  // FirebaseAuth.instance works as long as Firebase.initializeApp() was called,
  // which _ensureFirebaseInitialized() guarantees before any auth operation.
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Ensure Firebase is initialized and FirebaseAuth is accessible.
  Future<void> _ensureFirebaseInitialized() async {
    // Fast path — if FirebaseAuth is already accessible, we're done.
    if (_isFirebaseAuthReady()) return;

    debugPrint('⚠️ Firebase not ready, initializing...');

    // Retry initializeApp up to 5 times with increasing backoff.
    // Handles: first-launch race, warm-restart, storage-clear scenarios.
    for (int attempt = 1; attempt <= 5; attempt++) {
      try {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
        debugPrint('✅ Firebase.initializeApp() succeeded (attempt $attempt)');
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('duplicate') || msg.contains('already')) {
          // Already initialized — this is success, not failure.
          debugPrint('✅ Firebase already initialized (attempt $attempt)');
        } else {
          debugPrint('⚠️ Firebase init attempt $attempt failed: $e');
          if (attempt < 5) {
            await Future.delayed(Duration(milliseconds: 300 * attempt));
            continue;
          }
        }
      }

      // After each initializeApp attempt, poll for FirebaseAuth readiness
      // (platform channel registration takes a few ms after initializeApp).
      for (int poll = 0; poll < 30; poll++) {
        if (_isFirebaseAuthReady()) {
          debugPrint('✅ FirebaseAuth ready');
          return;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // If still not ready, one final check before throwing
    if (_isFirebaseAuthReady()) return;

    throw Exception(
        'Google Sign-In is temporarily unavailable. '
        'Please check your internet connection and try again.');
  }

  /// Returns true if FirebaseAuth.instance is accessible without throwing.
  bool _isFirebaseAuthReady() {
    try {
      FirebaseAuth.instance.currentUser; // throws [core/no-app] if not ready
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Initialize GoogleSignIn singleton. Safe to call multiple times.
  /// Resets and retries if storage was cleared (handles clear-cache scenario).
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    if (_initializing) {
      for (int i = 0; i < 100; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (_initialized) return;
        if (!_initializing) break;
      }
      if (_initialized) return;
    }
    _initializing = true;
    try {
      final serverClientId = AppEnv.googleClientId.isNotEmpty
          ? AppEnv.googleClientId
          : _webClientId;

      debugPrint('🔑 GoogleSignIn.initialize() with serverClientId: $serverClientId');

      // On Android, after clearing app storage, GoogleSignIn.instance may be
      // in a stale state. Calling initialize() again always works — it's
      // idempotent in google_sign_in 7.x and re-registers the client.
      await GoogleSignIn.instance.initialize(
        serverClientId: serverClientId,
      );
      _initialized = true;
      debugPrint('✅ GoogleSignIn.instance initialized');
    } catch (e) {
      debugPrint('⚠️ GoogleSignIn.initialize() attempt failed: $e — retrying once');
      // Reset flag so we retry fresh next call
      _initialized = false;
      // Wait briefly then retry once — handles transient Play Services state
      await Future.delayed(const Duration(milliseconds: 600));
      try {
        final serverClientId = AppEnv.googleClientId.isNotEmpty
            ? AppEnv.googleClientId
            : _webClientId;
        await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
        _initialized = true;
        debugPrint('✅ GoogleSignIn.instance initialized on retry');
      } catch (e2) {
        debugPrint('❌ GoogleSignIn.initialize() failed after retry: $e2');
        rethrow;
      }
    } finally {
      _initializing = false;
    }
  }

  User? get currentUser {
    try { return FirebaseAuth.instance.currentUser; } catch (_) { return null; }
  }

  Stream<User?> get authStateChanges {
    try { return FirebaseAuth.instance.authStateChanges(); }
    catch (_) { return const Stream.empty(); }
  }

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
    // Always reset initialization state before a fresh sign-in attempt.
    // After clear cache/storage, the singleton's internal state may be stale.
    _initialized = false;
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
    // Re-verify Firebase is ready immediately before using it.
    // GoogleSignIn can take several seconds (account picker, network),
    // during which the Firebase SDK state may change.
    await _ensureFirebaseInitialized();

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
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
