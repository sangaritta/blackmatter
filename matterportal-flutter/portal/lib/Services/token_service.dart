import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

class TokenService {
  TokenService();
  Future<void> storeToken(String token) async {
    await storage.write(key: 'token', value: token);
  }

  Future<String?> readToken() async {
    return await storage.read(key: 'token');
  }

  Future<void> deleteToken() async {
    await storage.delete(key: 'token');
  }
}

TokenService tks = TokenService();
