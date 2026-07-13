import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/ApiConfig.dart';
import '../config/Session.dart';
import '../model/InstrumentModel.dart';
import '../model/CategoryModel.dart';
import '../model/InstrumentTypeModel.dart';

class InstrumentService {
  static Map<String, String> _headers() => {
        'Authorization': 'Bearer ${Session().token}',
        'Content-Type': 'application/json',
      };

  /// GET /api/instruments — full catalog (specific models, used by search)
  static Future<List<InstrumentModel>> getAllInstruments() async {
    final response = await http.get(
      Uri.parse(ApiConfig.allInstrumentsUrl),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => InstrumentModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load instruments (${response.statusCode})');
  }

  /// GET /api/instruments/{id}
  static Future<InstrumentModel> getInstrumentById(int id) async {
    final response = await http.get(
      Uri.parse(ApiConfig.instrumentByIdUrl(id)),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return InstrumentModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load instrument (${response.statusCode})');
  }

  /// GET /api/instruments/user/{userId} — this user's instruments, each with
  /// userInstrumentDetails.isPrimary telling you Primary vs Secondary
  static Future<List<InstrumentModel>> getUserInstruments(int userId) async {
    final response = await http.get(
      Uri.parse(ApiConfig.userInstrumentsUrl(userId)),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => InstrumentModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load user instruments (${response.statusCode})');
  }

  /// GET /api/instruments/search?query=... — used while typing in Add Instrument
  static Future<List<InstrumentModel>> searchInstruments(String query) async {
    final response = await http.get(
      Uri.parse(ApiConfig.searchInstrumentsUrl(query)),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => InstrumentModel.fromJson(e)).toList();
    }
    throw Exception('Search failed (${response.statusCode})');
  }

  /// POST /api/instruments/user/add — link an existing catalog instrument
  /// (by id) to the logged-in user, matching UserInstrumentDTO fields.
  static Future<void> addUserInstrument({
    required int instrumentId,
    required bool isPrimary,
    String? proficiencyLevel,
    double? yearsExperience,
    String? purchaseDate,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.addUserInstrumentUrl),
      headers: _headers(),
      body: jsonEncode({
        'instrumentId': instrumentId,
        'isPrimary': isPrimary,
        if (proficiencyLevel != null) 'proficiencyLevel': proficiencyLevel,
        if (yearsExperience != null) 'yearsExperience': yearsExperience,
        if (purchaseDate != null) 'purchaseDate': purchaseDate,
      }),
    );
    print("🔍 STATUS: ${response.statusCode}");
    print("🔍 BODY: ${response.body}"); // ← YE LINE ADD KARO
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Failed to add instrument (${response.statusCode}): ${response.body}');
    }
  }

  /// GET /api/categories
  static Future<List<CategoryModel>> getAllCategories() async {
    final response = await http.get(
      Uri.parse(ApiConfig.allCategoriesUrl),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load categories (${response.statusCode})');
  }

  /// GET /api/instrument-types?categoryId=
  static Future<List<InstrumentTypeModel>> getTypesByCategory(
      int categoryId) async {
    final response = await http.get(
      Uri.parse(ApiConfig.instrumentTypesByCategoryUrl(categoryId)),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => InstrumentTypeModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load instrument types (${response.statusCode})');
  }

  /// GET /api/instruments/by-type?typeId=  (paginated — Spring Page response)
  static Future<List<InstrumentModel>> getInstrumentsByType(int typeId,
      {int page = 0}) async {
    final response = await http.get(
      Uri.parse(ApiConfig.instrumentsByTypeUrl(typeId, page: page)),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final List<dynamic> content =
          body['content']; // Spring Page wraps list in "content"
      return content.map((e) => InstrumentModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load instruments (${response.statusCode})');
  }
}
