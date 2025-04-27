import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _notificationsKey = 'notifications_enabled';
  static const String _underConstructionKey = 'under_construction_overlay';

  static final SettingsService _instance = SettingsService._internal();
  late SharedPreferences _prefs;
  bool _initialized = false;

  // Singleton factory
  factory SettingsService() {
    return _instance;
  }

  SettingsService._internal();

  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // Notifications
  Future<bool> getNotificationsEnabled() async {
    await _ensureInitialized();
    return _prefs.getBool(_notificationsKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _ensureInitialized();
    await _prefs.setBool(_notificationsKey, value);
  }

  // Under Construction Overlay
  Future<bool> getUnderConstructionOverlay() async {
    await _ensureInitialized();
    return _prefs.getBool(_underConstructionKey) ?? true;
  }

  Future<void> setUnderConstructionOverlay(bool value) async {
    await _ensureInitialized();
    await _prefs.setBool(_underConstructionKey, value);
  }

  // Helper method to ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }
}

final settingsService = SettingsService();
