import 'package:http/http.dart' as http;
import '../config/Session.dart';
import 'AuthService.dart';

class ApiClient {
  static Future<http.Response> authorizedRequest(
    Future<http.Response> Function() requestFn,
  ) async {
    http.Response response = await requestFn();
    print('🔍 First attempt status: ${response.statusCode}');

    if (response.statusCode == 401) {
      print('🔄 401 detected, trying refresh...');
      final refreshed = await AuthService.refreshAccessToken();
      print('🔄 Refresh result: $refreshed');

      if (refreshed) {
        response = await requestFn();
        print('🔍 Retry status: ${response.statusCode}');
      } else {
        print('❌ Refresh failed, logging out');
        await Session().clear();
        throw Exception('SESSION_EXPIRED');
      }
    }

    return response;
  }
}
