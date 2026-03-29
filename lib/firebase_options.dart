// File generated based on google-services.json and GoogleService-Info.plist
// DO NOT edit manually — re-run `flutterfire configure` to regenerate

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBXUN42KBq3eGoMgib4ZWDbYYFFc0Ft458',
    appId: '1:294856785598:web:placeholder', // replace after running: flutterfire configure
    messagingSenderId: '294856785598',
    projectId: 'sks-login-mobile',
    authDomain: 'sks-login-mobile.firebaseapp.com',
    storageBucket: 'sks-login-mobile.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBXUN42KBq3eGoMgib4ZWDbYYFFc0Ft458',
    appId: '1:294856785598:android:c5a6e5f6685abcef9da8ef',
    messagingSenderId: '294856785598',
    projectId: 'sks-login-mobile',
    storageBucket: 'sks-login-mobile.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDUHxriv0aZbMXrx4-NIdXdHp3AgwzBxYE',
    appId: '1:294856785598:ios:0205f6cf47bea0d39da8ef',
    messagingSenderId: '294856785598',
    projectId: 'sks-login-mobile',
    storageBucket: 'sks-login-mobile.firebasestorage.app',
    iosBundleId: 'org.sks',
  );
}
