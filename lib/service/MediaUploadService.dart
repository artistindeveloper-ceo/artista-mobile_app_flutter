import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import 'HelperService.dart';
import 'ApiClient.dart';

class MediaUploadResult {
  final String key;
  final String cdnUrl;

  MediaUploadResult({required this.key, required this.cdnUrl});
}

class MediaUploadService {
  /// mediaType: "post" | "profile" | "cover" | "chat"
  /// isVideo: true agar video hai (backend async processing karega)
  static Future<MediaUploadResult> uploadFile(
    File file, {
    required String mediaType,
    required bool isVideo,
  }) async {
    final contentType = _resolveContentType(file.path, isVideo);

    // Step 1: backend se presigned URL maango (auth token ke saath)
    final presignUri = Uri.parse(ApiConfig.presignUrl).replace(
      queryParameters: {
        'mediaType': mediaType,
        'contentType': contentType,
        'isVideo': isVideo.toString(),
      },
    );

    http.Response presignResponse;
    try {
      presignResponse = await ApiClient.authorizedRequest(
        () => http.post(presignUri, headers: HelperService.authHeaders()),
      );
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final presignBody = HelperService.safeDecode(presignResponse.body);
    if (presignResponse.statusCode != 200) {
      throw ApiException(presignBody['message'] ?? 'Failed to get upload URL.');
    }

    final uploadUrl = presignBody['uploadUrl'] as String;
    final key = presignBody['key'] as String;
    final cdnUrl = presignBody['cdnUrl'] as String;

    // Step 2: file seedha S3 pe upload karo (auth headers ki zarurat nahi, presigned URL hi permission hai)
    final bytes = await file.readAsBytes();
    final putResponse = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );

    if (putResponse.statusCode != 200) {
      throw ApiException('Upload to storage failed. Please try again.');
    }

    return MediaUploadResult(key: key, cdnUrl: cdnUrl);
  }

  static String _resolveContentType(String path, bool isVideo) {
    final ext = path.split('.').last.toLowerCase();
    if (isVideo) {
      if (ext == 'mov') return 'video/quicktime';
      return 'video/mp4';
    }
    if (ext == 'png') return 'image/png';
    if (ext == 'webp') return 'image/webp';
    return 'image/jpeg';
  }
}
