import 'package:flutter/foundation.dart';
import '../constants/app_env.dart';

class EnvironmentChecker {
  static void checkEnvironment() {
    debugPrint('========================================');
    debugPrint('ENVIRONMENT CONFIGURATION CHECK');
    debugPrint('========================================');
    
    debugPrint('API_BASE_URL: "${AppEnv.apiBaseUrl}"');
    debugPrint('API_BASE_URL isEmpty: ${AppEnv.apiBaseUrl.isEmpty}');
    debugPrint('API_BASE_URL length: ${AppEnv.apiBaseUrl.length}');
    
    debugPrint('MSG91_WIDGET_ID: "${AppEnv.msg91WidgetId}"');
    debugPrint('MSG91_WIDGET_ID isEmpty: ${AppEnv.msg91WidgetId.isEmpty}');
    
    debugPrint('ONESIGNAL_APP_ID: "${AppEnv.oneSignalAppId}"');
    debugPrint('ONESIGNAL_APP_ID isEmpty: ${AppEnv.oneSignalAppId.isEmpty}');
    
    debugPrint('GOOGLE_CLIENT_ID: "${AppEnv.googleClientId}"');
    debugPrint('GOOGLE_CLIENT_ID isEmpty: ${AppEnv.googleClientId.isEmpty}');
    
    debugPrint('========================================');
    
    if (AppEnv.apiBaseUrl.isEmpty) {
      debugPrint('❌ CRITICAL: API_BASE_URL is EMPTY!');
  
      debugPrint('❌ APK was built WITHOUT --dart-define-from-file flag!');
      debugPrint('❌ App will try to connect to localhost and fail!');
      debugPrint('');
      debugPrint('FIX: Rebuild APK with:');
      debugPrint('  flutter build apk --release --dart-define-from-file=.env.prod.json');
      debugPrint('');
    } else {
      debugPrint('✅ API_BASE_URL is configured: ${AppEnv.apiBaseUrl}');
    }
    
    debugPrint('========================================');
  }
  
  static bool isConfigured() {
    return AppEnv.apiBaseUrl.isNotEmpty;
  }
  
  static String getEffectiveApiUrl() {
    if (AppEnv.apiBaseUrl.isNotEmpty) {
      return AppEnv.apiBaseUrl;
    }
    // Fallback for development
    return 'https://sivakundalini.org';
  }
}
