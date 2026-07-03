import 'dart:io';

import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import '../config/Session.dart';
import '../model/UserModel.dart';
import 'HelperService.dart';

class UserProfileService {
  // ─── UPLOAD PROFILE PHOTO (POST /api/v1/users/me/profile-photo) ─
  static Future<UserModel> uploadProfilePhoto(File imageFile) async {
    final token = Session().token;
    if (token == null) throw ApiException('Not logged in.');

    final uri = Uri.parse(ApiConfig.uploadProfilePhotoUrl);
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    http.StreamedResponse streamed;
    try {
      streamed = await request.send();
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final response = await http.Response.fromStream(streamed);
    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'Photo upload failed.');
    }

    final userJson = (body['data'] ?? body) as Map<String, dynamic>;
    return UserModel.fromJson(userJson);
  }

  // ─── UPLOAD COVER PHOTO (POST /api/v1/users/me/cover-photo) ─────
  static Future<UserModel> uploadCoverPhoto(File imageFile) async {
    final token = Session().token;
    if (token == null) throw ApiException('Not logged in.');

    final uri = Uri.parse(ApiConfig.uploadCoverPhotoUrl);
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    http.StreamedResponse streamed;
    try {
      streamed = await request.send();
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final response = await http.Response.fromStream(streamed);
    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'Cover photo upload failed.');
    }

    final userJson = (body['data'] ?? body) as Map<String, dynamic>;
    return UserModel.fromJson(userJson);
  }
}
