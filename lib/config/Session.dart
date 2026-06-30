import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static final Session _instance = Session._internal();

  factory Session() => _instance;

  Session._internal();

  String? token;
  int? userId;
  String? profilePhotoUrl; // ← already hai
  String? displayName;

  bool get isLoggedIn => token != null && userId != null;
  Future<String?> getDisplayName() async => displayName;
  Future<String?> getProfilePhotoUrl() async => profilePhotoUrl;
  // REPLACE load():
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    userId = prefs.getInt('userId');
    profilePhotoUrl = prefs.getString('profilePhotoUrl');
    displayName = prefs.getString('displayName');
  }

  // REPLACE save():
  Future<void> save({
    required String token,
    required int userId,
    String? profilePhotoUrl,
    String? displayName, // ← parameter
  }) async {
    this.token = token;
    this.userId = userId;
    this.displayName = displayName ?? this.displayName;
    if (profilePhotoUrl != null) {
      this.profilePhotoUrl = profilePhotoUrl; // ← ADD
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setInt('userId', userId);
    await prefs.setString('displayName', displayName ?? '');
    if (profilePhotoUrl != null) {
      await prefs.setString('profilePhotoUrl', profilePhotoUrl); // ← ADD
    }
  }

  // Profile update hone pe call karo
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
    userId = null;
    displayName = null;
    profilePhotoUrl = null; // ← ADD
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('profilePhotoUrl');
    await prefs.remove('displayName');
  }
}
