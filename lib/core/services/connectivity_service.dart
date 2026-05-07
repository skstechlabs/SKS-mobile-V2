import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Singleton that tracks online/offline state.
/// Listen to [onConnectivityChanged] or read [isOnline] synchronously.
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  bool _isOnline = true; // optimistic default
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  /// Call once from main() before runApp.
  Future<void> initialize() async {
    try {
      // Check current state
      final results = await Connectivity().checkConnectivity();
      _isOnline = _hasConnection(results);
      debugPrint('🌐 ConnectivityService: initial state = ${_isOnline ? "online" : "offline"}');

      // Subscribe to changes
      _subscription = Connectivity()
          .onConnectivityChanged
          .listen((List<ConnectivityResult> results) {
        final wasOnline = _isOnline;
        _isOnline = _hasConnection(results);
        if (wasOnline != _isOnline) {
          debugPrint('🌐 Connectivity changed: ${_isOnline ? "online" : "offline"}');
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('❌ ConnectivityService init error: $e');
      _isOnline = true; // assume online on error
    }
  }

  /// Re-check connectivity right now (e.g. when user taps Retry).
  Future<bool> recheck() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final wasOnline = _isOnline;
      _isOnline = _hasConnection(results);
      if (wasOnline != _isOnline) {
        notifyListeners();
      }
      return _isOnline;
    } catch (e) {
      return _isOnline;
    }
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
