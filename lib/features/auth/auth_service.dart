import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_env.dart';
import '../../../core/services/onesignal_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth? _authInstance;
  
  FirebaseAuth get _auth {
    // Lazy initialization - only access Firebase when needed
    if (_authInstance == null) {
      try {
        // Check if Firebase is initialized
        Firebase.app();
        _authInstance = FirebaseAuth.instance;
      } catch (e) {
        debugPrint('⚠️  Firebase not initialized yet: $e');
        rethrow;
      }
    }
    return _authInstance!;
  }

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
      debugPrint('📱 Sending OTP to +91$phoneNumber');
      
      // Clear any existing session
      _verificationId = null;
      _resendToken = null;
      
      // Use Completer to wait for callbacks
      final completer = Completer<Map<String, dynamic>>();
      bool isCompleted = false;
      
      // Set a timeout to prevent hanging forever
      Timer(const Duration(seconds: 60), () {
        if (!isCompleted && !completer.isCompleted) {
          isCompleted = true;
          debugPrint('⏱️ OTP request timeout after 60 seconds');
          completer.complete({
            'success': false,
            'message': 'Request timeout. Please check your connection and try again.'
          });
        }
      });
      
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        timeout: const Duration(seconds: 120),
        
        // Auto-retrieval on Android (SMS auto-read)
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ Auto-verification completed');
          try {
            await _auth.signInWithCredential(credential);
            if (!isCompleted && !completer.isCompleted) {
              isCompleted = true;
              completer.complete({
                'success': true,
                'message': 'Auto-verified successfully',
                'auto_verified': true,
              });
            }
          } catch (e) {
            debugPrint('❌ Auto sign-in failed: $e');
          }
        },

        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Verification failed: ${e.code} - ${e.message}');
          if (!isCompleted && !completer.isCompleted) {
            isCompleted = true;
            final errorMsg = _friendlyFirebaseError(e.code);
            onError(errorMsg);
            completer.complete({
              'success': false,
              'message': errorMsg,
            });
          }
        },

        codeSent: (String verificationId, int? resendToken) {
          debugPrint('✅ Code sent successfully, verification ID: ${verificationId.substring(0, 10)}...');
          _verificationId = verificationId;
          _resendToken = resendToken;
          
          if (!isCompleted && !completer.isCompleted) {
            isCompleted = true;
            completer.complete({
              'success': true,
              'message': 'OTP sent successfully',
            });
          }
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏱️ Auto-retrieval timeout');
          _verificationId = verificationId;
          // This is called after codeSent, so don't complete here
        },

        forceResendingToken: _resendToken,
      );

      // Wait for one of the callbacks to complete
      final result = await completer.future;
      debugPrint('📱 OTP send result: ${result['success']}');
      return result;
      
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase exception: ${e.code} - ${e.message}');
      return {'success': false, 'message': _friendlyFirebaseError(e.code)};
    } catch (e, stackTrace) {
      debugPrint('❌ Unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {'success': false, 'message': 'Failed to send OTP. Please check your connection and try again.'};
    }
  }

  // ── Step 2: Verify OTP entered by user ────────────────────────────────────
  Future<Map<String, dynamic>> verifyOtp(String otp) async {
    debugPrint('🔐 Verifying OTP: $otp');
    
    if (_verificationId == null || _verificationId!.isEmpty) {
      debugPrint('❌ No verification ID found');
      return {'success': false, 'message': 'Session expired. Please request OTP again.'};
    }
    
    if (otp.length != 6) {
      return {'success': false, 'message': 'Please enter a valid 6-digit OTP.'};
    }
    
    try {
      debugPrint('🔐 Creating credential with verification ID: ${_verificationId!.substring(0, 10)}...');
      
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      debugPrint('🔐 Signing in with credential...');
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        debugPrint('✅ OTP verified successfully for user: ${user.uid}');
        
        // Clear session after successful verification
        _verificationId = null;
        _resendToken = null;
        
        return {
          'success': true,
          'mobile': user.phoneNumber ?? '',
          'uid': user.uid,
          'message': 'OTP verified successfully',
        };
      }
      
      debugPrint('❌ No user returned after sign-in');
      return {'success': false, 'message': 'Verification failed. Please try again.'};
      
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase exception during verification: ${e.code} - ${e.message}');
      
      // Don't clear verification ID on invalid code - allow retry
      if (e.code != 'invalid-verification-code') {
        _verificationId = null;
        _resendToken = null;
      }
      
      return {'success': false, 'message': _friendlyFirebaseError(e.code)};
    } catch (e, stackTrace) {
      debugPrint('❌ Unexpected error during verification: $e');
      debugPrint('Stack trace: $stackTrace');
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
    debugPrint('🔥 Firebase error code: $code');
    switch (code) {
      case 'invalid-phone-number':       return 'Invalid phone number. Please check and try again.';
      case 'too-many-requests':          return 'Too many attempts. Please try again after 1 hour.';
      case 'invalid-verification-code':  return 'Incorrect OTP. Please check and try again.';
      case 'session-expired':            return 'OTP expired. Please request a new one.';
      case 'quota-exceeded':             return 'SMS quota exceeded. Please try again tomorrow.';
      case 'network-request-failed':     return 'Network error. Check your internet connection.';
      case 'app-not-authorized':         return 'App not authorized. Please update the app.';
      case 'popup-closed-by-user':       return 'Sign-in cancelled. Please try again.';
      case 'popup-blocked':              return 'Popup blocked. Please allow popups and try again.';
      case 'cancelled-popup-request':    return 'Sign-in cancelled.';
      case 'account-exists-with-different-credential': return 'Account already exists with a different sign-in method.';
      case 'invalid-verification-id':    return 'Session expired. Please request OTP again.';
      case 'missing-verification-code':  return 'Please enter the OTP code.';
      case 'missing-phone-number':       return 'Please enter your phone number.';
      case 'credential-already-in-use':  return 'This credential is already associated with another account.';
      case 'operation-not-allowed':      return 'This sign-in method is not enabled. Contact support.';
      case 'user-disabled':              return 'Your account has been disabled. Contact support.';
      case 'web-context-cancelled':      return 'Sign-in cancelled.';
      default:                           return 'Authentication failed: $code. Please try again.';
    }
  }
}
