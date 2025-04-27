import 'package:uuid/uuid.dart';
import 'dart:math';

String generateUID() {
  const uuid = Uuid();
  final random = Random();

  // Generate base UUID and remove hyphens
  String baseId = uuid.v4().replaceAll('-', '');

  // Convert to list of characters for manipulation
  List<String> chars = baseId.split('');

  // Randomly convert some characters to uppercase
  for (int i = 0; i < chars.length; i++) {
    if (random.nextBool()) {
      chars[i] = chars[i].toUpperCase();
    }
  }

  // Join and take first 24 characters
  return chars.join('').substring(0, 24);
}
