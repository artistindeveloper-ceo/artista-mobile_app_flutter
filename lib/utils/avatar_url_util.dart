import '../../../config/ApiConfig.dart';

/// Pure helper — koi Flutter widget dependency nahi, sirf URL banata hai.
class AvatarUrlUtil {
  static String? build(dynamic rawPath) {
    if (rawPath == null) return null;
    final path = rawPath.toString();
    if (path.startsWith('http')) return path;
    return '${ApiConfig.baseUrl}${path.startsWith('/') ? '' : '/'}$path';
  }
}
