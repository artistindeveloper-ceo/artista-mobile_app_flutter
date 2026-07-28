import 'dart:convert';

import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import '../model/BusinessModel.dart';
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
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load business profile.');
    }
    return BusinessModel.fromJson(body);
  }

  // ─── FOLLOW ─────────────────────────────────────────────
  static Future<void> follow(int businessId) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/businesses/$businessId/follow');
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
            () => http.post(uri, headers: HelperService.authHeaders()),
      );
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not follow this business.');
    }
  }

  // ─── UNFOLLOW ───────────────────────────────────────────
  static Future<void> unfollow(int businessId) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/businesses/$businessId/follow');
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
            () => http.delete(uri, headers: HelperService.authHeaders()),
      );
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(
          body['message'] ?? 'Could not unfollow this business.');
    }
  }

  // ─── MESSAGE BUSINESS (routes to the owner's DM thread) ───────────
  // Returns the conversationId from the created message, so the caller can
  // navigate straight into the existing chat screen.
  static Future<int?> messageBusiness(int businessId, String content) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/businesses/$businessId/message');
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
            () =>
            http.post(
              uri,
              headers: HelperService.authHeaders(),
              body: jsonEncode({'content': content}),
            ),
      );
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 201) {
      throw ApiException(body['message'] ?? 'Could not send message.');
    }
    final conversationId = body['conversationId'];
    return conversationId is int ? conversationId : int.tryParse(
        '$conversationId');
  }
}