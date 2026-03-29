import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_env.dart';
import '../../../core/services/onesignal_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // On web: clientId must be passed explicitly
  // On Android/iOS: clientId is read from google-services.json / GoogleService-Info.plist
  GoogleSignIn get _googleSignIn => GoogleSignIn(
    clientId: kIsWeb && AppEnv.googleClientId.isNotEmpty
        ? AppEnv.googleClientId
        : null,
    scopes: ['email', 'profile'],
  );

  String? _verificationId;
  int? _resendToken;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Step 1: Send OTP via Firebase ─────────────────────────────────────────
  Future<Map<String, dynamic>> sendOtp(
    String phoneNumber, {
    required void Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        timeout: const Duration(seconds: 60),

        // Auto-retrieval on Android (SMS auto-read)
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },

        verificationFailed: (FirebaseAuthException e) {
          onError(_friendlyFirebaseError(e.code));
        },

        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken    = resendToken;
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },

        forceResendingToken: _resendToken,
      );

      return {'success': true, 'message': 'OTP sent successfully'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _friendlyFirebaseError(e.code)};
    } catch (_) {
      return {'success': false, 'message': 'Failed to send OTP. Please try again.'};
    }
  }

  // ── Step 2: Verify OTP entered by user ────────────────────────────────────
  Future<Map<String, dynamic>> verifyOtp(String otp) async {
    if (_verificationId == null) {
      return {'success': false, 'message': 'Session expired. Please request OTP again.'};
    }
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        return {
          'success': true,
          'mobile': user.phoneNumber ?? '',
          'uid': user.uid,
          'message': 'OTP verified successfully',
        };
      }
      return {'success': false, 'message': 'Verification failed. Please try again.'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _friendlyFirebaseError(e.code)};
    } catch (_) {
      return {'success': false, 'message': 'Verification failed. Please try again.'};
    }
  }

  // ── Resend OTP ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> resendOtp(
    String phoneNumber, {
    required void Function(String error) onError,
  }) async {
    return sendOtp(phoneNumber, onError: onError);
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    // Remove OneSignal external user ID
    await OneSignalService().removeExternalUserId();
    
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  // On web: uses Firebase signInWithRedirect (more reliable than popup on localhost)
  // On mobile: uses google_sign_in package
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');

        // Use redirect — avoids popup issues on localhost / OAuth restrictions
        await _auth.signInWithRedirect(provider);

        // getRedirectResult picks up the result after page reloads
        userCredential = await _auth.getRedirectResult();

        // If no user yet (redirect hasn't completed), return pending
        if (userCredential.user == null) {
          return {'success': false, 'pending': true, 'message': 'Redirecting...'};
        }
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return {'success': false, 'message': 'Google sign-in cancelled.'};
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user != null) {
        return {
          'success': true,
          'uid':    user.uid,
          'email':  user.email ?? '',
          'name':   user.displayName ?? '',
          'photo':  user.photoURL ?? '',
          'mobile': user.phoneNumber ?? '',
          'message': 'Google sign-in successful',
        };
      }
      return {'success': false, 'message': 'Google sign-in failed. Please try again.'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _friendlyFirebaseError(e.code)};
    } catch (e) {
      // ignore: avoid_print
      print('Google sign-in error: $e');
      return {'success': false, 'message': 'Google sign-in failed. Please try again.'};
    }
  }

  // Called on app start to pick up redirect result after Google sign-in
  Future<Map<String, dynamic>?> getRedirectResult() async {
    try {
      final result = await _auth.getRedirectResult();
      final user = result.user;
      if (user != null) {
        return {
          'success': true,
          'uid':    user.uid,
          'email':  user.email ?? '',
          'name':   user.displayName ?? '',
          'photo':  user.photoURL ?? '',
          'mobile': user.phoneNumber ?? '',
          'message': 'Google sign-in successful',
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void clearSession() {
    _verificationId = null;
    _resendToken    = null;
  }

  // ── Firebase error code → user-friendly message ───────────────────────────
  String _friendlyFirebaseError(String code) {
    switch (code) {
      case 'invalid-phone-number':       return 'Invalid phone number. Please check and try again.';
      case 'too-many-requests':          return 'Too many attempts. Please try again later.';
      case 'invalid-verification-code':  return 'Incorrect OTP. Please try again.';
      case 'session-expired':            return 'OTP expired. Please request a new one.';
      case 'quota-exceeded':             return 'SMS quota exceeded. Please try again later.';
      case 'network-request-failed':     return 'Network error. Check your connection.';
      case 'app-not-authorized':         return 'App not authorized. Contact support.';
      case 'popup-closed-by-user':       return 'Sign-in popup was closed. Please try again.';
      case 'popup-blocked':              return 'Popup was blocked by browser. Please allow popups.';
      case 'cancelled-popup-request':    return 'Sign-in cancelled.';
      case 'account-exists-with-different-credential': return 'Account already exists with a different sign-in method.';
      default:                           return 'Something went wrong. Please try again.';
    }
  }
}
