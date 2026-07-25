import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/ApiConfig.dart';
import '../dto/CityDto.dart';
import 'ApiClient.dart';
import 'HelperService.dart';

class LocationService {
  /// GET /api/locations/cities/search?q=...
  static Future<List<CityDto>> searchCities(String query) async {
    final response = await ApiClient.authorizedRequest(
      () async => http.get(
        Uri.parse(ApiConfig.searchCitiesUrl(query)),
        headers: HelperService.authHeaders(),
      ),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CityDto.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search cities: ${response.statusCode}');
    }
  }

  /// GET /api/locations/cities/{cityId}
  static Future<CityDto> getCityById(int cityId) async {
    final response = await ApiClient.authorizedRequest(
      () async => http.get(
        Uri.parse(ApiConfig.cityByIdUrl(cityId)),
        headers: HelperService.authHeaders(),
      ),
    );

    if (response.statusCode == 200) {
      return CityDto.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch city: ${response.statusCode}');
    }
  }
}
