import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

Future<Map<String, dynamic>> getDeviceInfo() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  if (kIsWeb) {
    WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
    return {
      'platform': 'web',
      'model': '${webInfo.browserName} ${webInfo.platform}',
      'version': webInfo.appVersion ?? 'unknown',
    };
  } else {
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return {
        'platform': 'android',
        'model': androidInfo.model,
        'version': androidInfo.version.release,
      };
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return {
        'platform': 'ios',
        'model': iosInfo.utsname.machine,
        'version': iosInfo.systemVersion,
      };
    } else {
      return {
        'platform': 'unknown',
      };
    }
  }
}
