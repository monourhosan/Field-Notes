abstract class SettingsRepository {
  Future<String> getDefaultNoteStatus();
  Future<void> setDefaultNoteStatus(String status);
  Future<String> getBaseUrl();
  Future<void> setBaseUrl(String url);
}
