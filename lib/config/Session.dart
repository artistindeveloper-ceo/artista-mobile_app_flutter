import 'package:shared_preferences/shared_preferences.dart';

import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static final Session _instance = Session._internal();

  factory Session() => _instance;

  Session._internal();

  String? token;
  String? refreshToken; // ← ADD
  int? userId;
  String? profilePhotoUrl;
  String? displayName;

  bool get isLoggedIn => token != null && userId != null;

  Future<String?> getDisplayName() async => displayName;

  Future<String?> getProfilePhotoUrl() async => profilePhotoUrl;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    refreshToken = prefs.getString('refreshToken'); // ← ADD
    userId = prefs.getInt('userId');
    profilePhotoUrl = prefs.getString('profilePhotoUrl');
    displayName = prefs.getString('displayName');
  }

  Future<void> save({
    required String token,
    String? refreshToken, // ← ADD
    required int userId,
    String? profilePhotoUrl,
    String? displayName,
  }) async {
    this.token = token;
    if (refreshToken != null) this.refreshToken = refreshToken; // ← ADD
    this.userId = userId;
    this.displayName = displayName ?? this.displayName;
    if (profilePhotoUrl != null) {
      this.profilePhotoUrl = profilePhotoUrl;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    if (refreshToken != null) {
      await prefs.setString('refreshToken', refreshToken); // ← ADD
    }
    await prefs.setInt('userId', userId);
    await prefs.setString('displayName', displayName ?? '');
    if (profilePhotoUrl != null) {
      await prefs.setString('profilePhotoUrl', profilePhotoUrl);
    }
  }

  // Refresh hone ke baad sirf naya access token update karne ke liye
  Future<void> updateAccessToken(String newToken,
      {String? newRefreshToken}) async {
    token = newToken;
    if (newRefreshToken != null) refreshToken = newRefreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', newToken);
    if (newRefreshToken != null) {
      await prefs.setString('refreshToken', newRefreshToken);
    }
  }

  Future<void> updateProfilePhoto(String? url) async {
    profilePhotoUrl = url;
    final prefs = await SharedPreferences.getInstance();
    if (url != null) {
      await prefs.setString('profilePhotoUrl', url);
    } else {
      await prefs.remove('profilePhotoUrl');
    }
  }

  Future<void> clear() async {
    token = null;
    refreshToken = null; // ← ADD
    userId = null;
    displayName = null;
    profilePhotoUrl = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refreshToken'); // ← ADD
    await prefs.remove('userId');
    await prefs.remove('profilePhotoUrl');
    await prefs.remove('displayName');
  }
}
