import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';

class SettingsLocalDataSource {
  static const String _keyDefaultNoteStatus = 'default_note_status';
  static const String _keyBaseUrl = 'base_url';
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUsername = 'auth_username';
  static const String _keyEmail = 'auth_email';
  static const String _keyLastSyncTime = 'last_sync_timestamp';

  final SharedPreferences _prefs;

  SettingsLocalDataSource(this._prefs);

  static Future<SettingsLocalDataSource> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsLocalDataSource(prefs);
  }

  // Default note status (locally persisted, does not sync with backend)
  String getDefaultNoteStatus() {
    return _prefs.getString(_keyDefaultNoteStatus) ?? 'DRAFT';
  }

  Future<void> setDefaultNoteStatus(String status) async {
    await _prefs.setString(_keyDefaultNoteStatus, status);
  }

  // Base URL
  String getBaseUrl() {
    return _prefs.getString(_keyBaseUrl) ?? ApiConstants.defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    await _prefs.setString(_keyBaseUrl, url);
  }

  // Auth credentials
  String? getToken() => _prefs.getString(_keyToken);
  int? getUserId() => _prefs.getInt(_keyUserId);
  String? getUsername() => _prefs.getString(_keyUsername);
  String? getEmail() => _prefs.getString(_keyEmail);

  Future<void> saveAuthData({
    required String token,
    required int userId,
    required String username,
    required String email,
  }) async {
    await _prefs.setString(_keyToken, token);
    await _prefs.setInt(_keyUserId, userId);
    await _prefs.setString(_keyUsername, username);
    await _prefs.setString(_keyEmail, email);
  }

  Future<void> clearAuthData() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUsername);
    await _prefs.remove(_keyEmail);
  }

  // Sync timestamps
  int getLastSyncTime() => _prefs.getInt(_keyLastSyncTime) ?? 0;
  Future<void> setLastSyncTime(int timestamp) async {
    await _prefs.setInt(_keyLastSyncTime, timestamp);
  }
}
