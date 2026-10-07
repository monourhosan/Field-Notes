import '../../domain/repositories/settings_repository.dart';
import '../local/settings_local_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _localDataSource;

  SettingsRepositoryImpl(this._localDataSource);

  @override
  Future<String> getDefaultNoteStatus() async {
    return _localDataSource.getDefaultNoteStatus();
  }

  @override
  Future<void> setDefaultNoteStatus(String status) async {
    await _localDataSource.setDefaultNoteStatus(status);
  }

  @override
  Future<String> getBaseUrl() async {
    return _localDataSource.getBaseUrl();
  }

  @override
  Future<void> setBaseUrl(String url) async {
    await _localDataSource.setBaseUrl(url);
  }
}
