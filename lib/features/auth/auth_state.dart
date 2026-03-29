import 'package:flutter/foundation.dart';
import 'user_model.dart';

class AuthState extends ChangeNotifier {
  static final AuthState _instance = AuthState._internal();
  factory AuthState() => _instance;
  AuthState._internal();

  UserModel? _user;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  String? get uid => _user?.uid;
  String? get mobile => _user?.mobile;
  bool get isProfileComplete => _user?.isProfileComplete ?? false;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void updateProfile(UserModel updated) {
    _user = updated;
    notifyListeners();
  }

  // Keep for backward compat
  void loginWithMobile(String mobile) {
    _user = UserModel(uid: '', mobile: mobile, authProvider: 'phone');
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
