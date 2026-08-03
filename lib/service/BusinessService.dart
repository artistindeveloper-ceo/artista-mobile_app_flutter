import 'dart:convert';

import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import '../model/BusinessModel.dart';
import '../model/PostModel.dart';
import 'ApiClient.dart';
import 'HelperService.dart';

class BusinessService {
  // ─── GET BUSINESS PROFILE ─────────────────────────────────
  static Future<BusinessModel> getById(int businessId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/businesses/$businessId');
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
        () => http.get(uri, headers: HelperService.authHeaders()),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load business profile.');
    }
    return BusinessModel.fromJson(body);
  }

  // ─── UPDATE BUSINESS PROFILE ───────────────────────────────
  static Future<BusinessModel> update({
    required int businessId,
    String? name,
    String? description,
    int? cityId,
    String? contactEmail,
    String? contactPhone,
    Map<String, dynamic>? details,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/businesses/$businessId');
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
        () => http.put(
          uri,
          headers: HelperService.authHeaders(),
          body: jsonEncode({
            if (name != null) 'name': name,
            if (description != null) 'description': description,
            if (cityId != null) 'cityId': cityId,
            if (contactEmail != null) 'contactEmail': contactEmail,
            if (contactPhone != null) 'contactPhone': contactPhone,
            if (details != null) 'details': details,
          }),
        ),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(
          body['message'] ?? 'Could not update business profile.');
    }
    return BusinessModel.fromJson(body);
  }

  // ─── MESSAGE BUSINESS (routes to the owner's DM thread) ───────────
  static Future<Map<String, dynamic>?> messageBusiness(
      int businessId, String content) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/businesses/$businessId/message');
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
        () => http.post(
          uri,
          headers: HelperService.authHeaders(),
          body: jsonEncode({'content': content}),
        ),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 201) {
      throw ApiException(body['message'] ?? 'Could not send message.');
    }

    final conversationId = body['conversationId'];
    final otherUserId = body['otherUserId'];
    if (conversationId == null || otherUserId == null) return null;

    return {
      'conversationId': conversationId is int
          ? conversationId
          : int.tryParse('$conversationId'),
      'otherUserId':
          otherUserId is int ? otherUserId : int.tryParse('$otherUserId'),
    };
  }

  // ─── GET BUSINESS POSTS ───────────────────────────────────
  static Future<List<PostModel>> getPosts(int businessId,
      {int page = 0, int size = 20}) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/posts/user/$businessId?page=$page&size=$size');

    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
        () => http.get(uri, headers: HelperService.authHeaders()),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Could not reach server.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load posts.');
    }

    final List<dynamic> list = body['content'] ?? [];
    return list
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
