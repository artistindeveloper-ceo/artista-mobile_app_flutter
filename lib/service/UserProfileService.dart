import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import '../config/Session.dart';
import '../model/UserModel.dart';
import 'HelperService.dart';
import 'ApiClient.dart';
import 'MediaUploadService.dart'; // ← NAYA IMPORT

class UserProfileService {
  // ─── UPLOAD PROFILE PHOTO (presigned S3) ─────────────────────
  static Future<UserModel> uploadProfilePhoto(File imageFile) async {
    final result = await MediaUploadService.uploadFile(
      imageFile,
      mediaType: 'profile',
      isVideo: false,
    );

    final uri = Uri.parse(ApiConfig.uploadProfilePhotoUrl);
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(() => http.post(
            uri,
            headers: {
              ...HelperService.authHeaders(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'mediaKey': result.key}),
          ));
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

  // ─── UPLOAD COVER PHOTO (presigned S3) ───────────────────────
  static Future<UserModel> uploadCoverPhoto(File imageFile) async {
    final result = await MediaUploadService.uploadFile(
      imageFile,
      mediaType: 'cover',
      isVideo: false,
    );

    final uri = Uri.parse(ApiConfig.uploadCoverPhotoUrl);
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(() => http.post(
            uri,
            headers: {
              ...HelperService.authHeaders(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'mediaKey': result.key}),
          ));
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
