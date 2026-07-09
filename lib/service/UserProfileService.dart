import 'dart:io';

import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import '../config/Session.dart';
import '../model/UserModel.dart';
import 'HelperService.dart';
import 'ApiClient.dart'; // ← NAYA IMPORT

class UserProfileService {
  // ─── UPLOAD PROFILE PHOTO (POST /api/v1/users/me/profile-photo) ─
  static Future<UserModel> uploadProfilePhoto(File imageFile) async {
    final uri = Uri.parse(ApiConfig.uploadProfilePhotoUrl);

    Future<http.Response> sendMultipart() async {
      final token = Session().token;
      if (token == null) throw ApiException('Not logged in.');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(sendMultipart);
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'Photo upload failed.');
    }

    final userJson = (body['data'] ?? body) as Map<String, dynamic>;
    return UserModel.fromJson(userJson);
  }

  // ─── UPLOAD COVER PHOTO (POST /api/v1/users/me/cover-photo) ─────
  static Future<UserModel> uploadCoverPhoto(File imageFile) async {
    final uri = Uri.parse(ApiConfig.uploadCoverPhotoUrl);

    Future<http.Response> sendMultipart() async {
      final token = Session().token;
      if (token == null) throw ApiException('Not logged in.');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(sendMultipart);
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'Cover photo upload failed.');
    }

    final userJson = (body['data'] ?? body) as Map<String, dynamic>;
    return UserModel.fromJson(userJson);
  }
}
