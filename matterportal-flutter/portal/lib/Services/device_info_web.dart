// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

Future<Map<String, dynamic>> getDeviceInfo() async {
  return {
    'platform': 'web',
    'browser': window.navigator.userAgent,
  };
}
