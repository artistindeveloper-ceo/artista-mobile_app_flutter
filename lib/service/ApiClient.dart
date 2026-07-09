import 'package:http/http.dart' as http;
import '../config/Session.dart';
import 'AuthService.dart';

class ApiClient {
  static Future<http.Response> authorizedRequest(
    Future<http.Response> Function() requestFn,
  ) async {
    http.Response response = await requestFn();

    if (response.statusCode == 401) {
      final refreshed = await AuthService.refreshAccessToken();

      if (refreshed) {
        response = await requestFn();
      } else {
        await Session().clear();
        throw Exception('SESSION_EXPIRED');
      }
    }

    return response;
  }
}
