// ignore: avoid_web_libraries_in_flutter

import 'package:universal_html/html.dart';

Future<Map<String, dynamic>> getDeviceInfo() async {
  return {'platform': 'web', 'browser': window.navigator.userAgent};
}
