import 'package:shared_preferences/shared_preferences.dart';

import 'ApiConfig.dart';

class Session {
  static final Session _instance = Session._internal();

  factory Session() => _instance;

  Session._internal();

  String? token;
  String? refreshToken;
  int? userId;
  String? profilePhotoUrl;
  String? displayName;
  String? accountType; // "INDIVIDUAL" or "BUSINESS" — routing ke liye chahiye

  bool get isLoggedIn => token != null && userId != null;

  bool get isBusinessAccount => accountType?.toUpperCase() == 'BUSINESS';

  Future<String?> getDisplayName() async => displayName;

  Future<String?> getProfilePhotoUrl() async => profilePhotoUrl;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    refreshToken = prefs.getString('refreshToken');
    userId = prefs.getInt('userId');
    profilePhotoUrl = prefs.getString('profilePhotoUrl');
    displayName = prefs.getString('displayName');
    accountType = prefs.getString('accountType');
  }

  Future<void> save({
    required String token,
    String? refreshToken,
    required int userId,
    String? profilePhotoUrl,
    String? displayName,
    String? accountType,
  }) async {
    this.token = token;
    if (refreshToken != null) this.refreshToken = refreshToken;
    this.userId = userId;
    this.displayName = displayName ?? this.displayName;
    if (profilePhotoUrl != null) {
      this.profilePhotoUrl = profilePhotoUrl;
    }
    if (accountType != null) this.accountType = accountType;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    if (refreshToken != null) {
      await prefs.setString('refreshToken', refreshToken);
    }
    await prefs.setInt('userId', userId);
    await prefs.setString('displayName', displayName ?? '');
    if (profilePhotoUrl != null) {
      await prefs.setString('profilePhotoUrl', profilePhotoUrl);
    }
    if (accountType != null) {
      await prefs.setString('accountType', accountType);
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
    refreshToken = null;
    userId = null;
    displayName = null;
    profilePhotoUrl = null;
    accountType = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('profilePhotoUrl');
    await prefs.remove('displayName');
    await prefs.remove('accountType');
  }

  // Home screen par jo upar Post ka laga he vaha profile ke leay use ho rahah he
  String? get resolvedProfilePhotoUrl {
    if (profilePhotoUrl == null || profilePhotoUrl!.isEmpty) return null;
    if (profilePhotoUrl!.startsWith('http')) return profilePhotoUrl;
    return '${ApiConfig.baseUrl}$profilePhotoUrl';
  }
}
