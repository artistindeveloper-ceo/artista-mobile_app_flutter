import '../config/ApiConfig.dart';

class UrlHelper {
  /// Backend kabhi absolute CDN URL bhejta hai (CloudFront), kabhi relative path.
  /// Ye function dono cases handle karta hai — safe hai har jagah use karne ke liye.
  static String? resolveMediaUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    return '${ApiConfig.baseUrl}$rawUrl';
  }
}
