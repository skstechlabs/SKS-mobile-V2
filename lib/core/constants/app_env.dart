// All values are injected at build time via --dart-define flags.
// No package dependency needed — uses native Dart String.fromEnvironment.
//
// Run commands:
//   Dev:  flutter run --dart-define-from-file=.env.json
//   Prod: flutter run --dart-define-from-file=.env.prod.json
//
// Or pass individually:
//   flutter run \
//     --dart-define=MSG91_WIDGET_ID=xxx \
//     --dart-define=MSG91_AUTH_TOKEN=xxx \
//     --dart-define=API_BASE_URL=http://localhost:3011

class AppEnv {
  AppEnv._();

  static const String msg91WidgetId  = String.fromEnvironment('MSG91_WIDGET_ID');
  static const String msg91AuthToken = String.fromEnvironment('MSG91_AUTH_TOKEN');
  static const String apiBaseUrl     = String.fromEnvironment('API_BASE_URL');
  static const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const String oneSignalAppId = String.fromEnvironment('ONESIGNAL_APP_ID');
}
