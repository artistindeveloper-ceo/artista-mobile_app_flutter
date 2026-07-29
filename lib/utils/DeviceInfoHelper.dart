import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoHelper {
  static const _deviceIdKey = 'app_device_id';

  /// App-generated UUID — stable jab tak app uninstall na ho.
  /// OS-level IDs (Android ID / identifierForVendor) kabhi-kabhi
  /// reset ho jate hain, isliye ye zyada reliable hai.
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_deviceIdKey);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_deviceIdKey, id);
    }
    return id;
  }

  static Future<Map<String, String>> getDeviceDetails() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await deviceInfoPlugin.androidInfo;
        return {
          'deviceType': 'ANDROID',
          'deviceModel': info.model,
          'deviceOs': 'Android ${info.version.release}',
        };
      } else if (Platform.isIOS) {
        final info = await deviceInfoPlugin.iosInfo;
        return {
          'deviceType': 'IOS',
          'deviceModel': info.utsname.machine,
          'deviceOs': 'iOS ${info.systemVersion}',
        };
      }
    } catch (e) {
      // device info fetch fail ho sakta hai kabhi kabhi — safe fallback
    }
    return {
      'deviceType': 'UNKNOWN',
      'deviceModel': 'Unknown',
      'deviceOs': 'Unknown',
    };
  }
}
