import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/ApiConfig.dart';
import '../Exception/ApiException.dart';
import 'ApiClient.dart';
import 'HelperService.dart';

class ProfileService {
  // ---------- Categories (public, no auth needed for a catalog list) ----------
  static Future<List<CategoryDto>> getCategories() async {
    http.Response res;
    try {
      res = await ApiClient.authorizedRequest(
        () => http.get(
          Uri.parse(ApiConfig.allCategoriesUrl),
          headers: HelperService.authHeaders(),
        ),
      );
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }
    if (res.statusCode != 200) {
      throw ApiException('Failed to load categories');
    }
    final List<dynamic> data = jsonDecode(res.body);
    return data.map((e) => CategoryDto.fromJson(e)).toList();
  }

  // ---------- Instrument types by category (public) ----------
  static Future<List<InstrumentTypeDto>> getInstrumentTypes(
      int categoryId) async {
    http.Response res;
    try {
      res = await ApiClient.authorizedRequest(
        () => http.get(
          Uri.parse(ApiConfig.instrumentTypesByCategoryUrl(categoryId)),
          headers: HelperService.authHeaders(),
        ),
      );
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }
    if (res.statusCode != 200) {
      throw ApiException('Failed to load instrument types');
    }
    final List<dynamic> data = jsonDecode(res.body);
    return data.map((e) => InstrumentTypeDto.fromJson(e)).toList();
  }

  // ---------- Get profile (auth required) ----------
  static Future<ProfileDto?> getProfile(int userId) async {
    final uri = Uri.parse(ApiConfig.profileByUserIdUrl(userId));
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    if (response.statusCode == 404) return null;

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'Could not load profile.');
    }

    final profileJson = (body['data'] ?? body) as Map<String, dynamic>;
    return ProfileDto.fromJson(profileJson);
  }

  // ---------- Create / Update profile (auth required) ----------
  // professionalType and cityId are query params on the backend;
  // details (role-specific JSON) goes in the request body.
  //
  // NOTE: city/state/country strings are gone. Only cityId travels now —
  // the backend resolves state/country from the City -> State -> Country
  // relation, so there is no risk of them going out of sync.
  static Future<ProfileDto> saveProfile({
    required int userId,
    required String professionalType,
    required int cityId,
    required Map<String, dynamic> details,
  }) async {
    final query = {
      'professionalType': professionalType,
      'cityId': cityId.toString(),
    };
    final uri = Uri.parse(ApiConfig.saveProfileUrl(userId))
        .replace(queryParameters: query);

    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(() => http.post(
            uri,
            headers: HelperService.authHeaders(),
            body: jsonEncode(details),
          ));
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'Profile save failed.');
    }

    final profileJson = (body['data'] ?? body) as Map<String, dynamic>;

// Fix: backend save response me user/id nested nahi aata to fallback use karo
    if (profileJson['id'] == null &&
        (profileJson['user'] == null || profileJson['user']['id'] == null)) {
      profileJson['id'] = userId;
    }

    return ProfileDto.fromJson(profileJson);
  }
}

class CategoryDto {
  final int id;
  final String name;
  final String? icon;

  CategoryDto({required this.id, required this.name, this.icon});

  factory CategoryDto.fromJson(Map<String, dynamic> json) => CategoryDto(
        id: json['id'],
        name: json['name'] ?? '',
        icon: json['icon'],
      );

  // THIS is what was breaking the dropdown: DropdownButtonFormField matches
  // its `value` against `items` using ==. Without this override, Dart falls
  // back to identity equality, so a CategoryDto fetched in one API call
  // never == a "same" CategoryDto fetched in another call, and the dropdown
  // can't find/keep the selection.
  @override
  bool operator ==(Object other) => other is CategoryDto && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class InstrumentTypeDto {
  final int id;
  final String name;
  final String? icon;
  final String? description;
  final int? categoryId;

  InstrumentTypeDto({
    required this.id,
    required this.name,
    this.icon,
    this.description,
    this.categoryId,
  });

  factory InstrumentTypeDto.fromJson(Map<String, dynamic> json) =>
      InstrumentTypeDto(
        id: json['id'],
        name: json['name'] ?? '',
        icon: json['icon'],
        description: json['description'],
        categoryId: json['categoryId'],
      );

  // Same fix as CategoryDto — id-based equality so DropdownButtonFormField
  // can match `value` against `items` correctly.
  @override
  bool operator ==(Object other) =>
      other is InstrumentTypeDto && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class ProfileDto {
  final int userId;
  final String professionalType;
  final int? cityId;
  final String? cityName;
  final String? stateName;
  final String? countryName;
  final Map<String, dynamic> details;

  ProfileDto({
    required this.userId,
    required this.professionalType,
    this.cityId,
    this.cityName,
    this.stateName,
    this.countryName,
    required this.details,
  });


  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    final city = json['city'] as Map<String, dynamic>?;
    final state = city?['state'] as Map<String, dynamic>?;
    final country = state?['country'] as Map<String, dynamic>?;

    return ProfileDto(
      userId: json['user']?['id'] ?? json['id'] ?? 0,
      // ← fallback 0 add kiya
      professionalType: json['professionalType'] ?? '',
      cityId: city?['id'],
      cityName: city?['name'],
      stateName: state?['name'],
      countryName: country?['name'],
      details: (json['details'] as Map<String, dynamic>?) ?? {},
    );
  }
}
