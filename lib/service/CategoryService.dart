// lib/service/CategoryService.dart
//
// Create Account screen ke dropdowns yahan se DB-driven category list
// fetch karte hain — koi hardcoded list nahi.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import '../model/CategoryModel.dart';
import 'HelperService.dart';

class CategoryService {
  // Individual account type ke liye — MUSICIAN, PHOTOGRAPHER, EVENT_MANAGER...
  static Future<List<CategoryModel>> getProfileCategories() async {
    final uri = Uri.parse(ApiConfig.profileCategoriesUrl);

    http.Response response;
    try {
      response =
          await http.get(uri, headers: {'Content-Type': 'application/json'});
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    if (response.statusCode != 200) {
      final body = HelperService.safeDecode(response.body);
      throw ApiException(body['message'] ?? 'Could not load profession types.');
    }

    final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Business account type ke liye — SHOP, ACADEMY, SCHOOL, INSTITUTE...
  static Future<List<CategoryModel>> getBusinessCategories() async {
    final uri = Uri.parse(ApiConfig.businessCategoriesUrl);

    http.Response response;
    try {
      response =
          await http.get(uri, headers: {'Content-Type': 'application/json'});
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    if (response.statusCode != 200) {
      final body = HelperService.safeDecode(response.body);
      throw ApiException(body['message'] ?? 'Could not load business types.');
    }

    final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
