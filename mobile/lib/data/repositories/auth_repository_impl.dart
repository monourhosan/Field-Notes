import 'dart:convert';

import '../../core/constants/api_constants.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../local/settings_local_data_source.dart';
import '../models/user_model.dart';
import '../remote/api_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final SettingsLocalDataSource _settingsDataSource;

  AuthRepositoryImpl(this._apiClient, this._settingsDataSource);

  @override
  Future<User> register(String username, String email, String password) async {
    final server = _settingsDataSource.getBaseUrl();
    final response = await _apiClient.post(
      ApiConstants.register,
      body: {'username': username, 'email': email, 'password': password},
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (_settingsDataSource.getBaseUrl() != server) {
        throw StateError('Server changed during sign in; try again');
      }
      final json = jsonDecode(response.body);
      final user = UserModel.fromJson(json);
      await _settingsDataSource.saveAuthData(
        token: user.token,
        userId: user.id,
        username: user.username,
        email: user.email,
      );
      return user;
    } else {
      _apiClient.requireSuccess(response);
      throw StateError('Unexpected registration response');
    }
  }

  @override
  Future<User> login(String username, String password) async {
    final server = _settingsDataSource.getBaseUrl();
    final response = await _apiClient.post(
      ApiConstants.login,
      body: {'username': username, 'password': password},
    );

    if (response.statusCode == 200) {
      if (_settingsDataSource.getBaseUrl() != server) {
        throw StateError('Server changed during sign in; try again');
      }
      final json = jsonDecode(response.body);
      final user = UserModel.fromJson(json);
      await _settingsDataSource.saveAuthData(
        token: user.token,
        userId: user.id,
        username: user.username,
        email: user.email,
      );
      return user;
    } else {
      _apiClient.requireSuccess(response);
      throw StateError('Unexpected login response');
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = _settingsDataSource.getToken();
    final userId = _settingsDataSource.getUserId();
    final username = _settingsDataSource.getUsername();
    final email = _settingsDataSource.getEmail();

    if (token != null && userId != null && username != null && email != null) {
      return User(id: userId, username: username, email: email, token: token);
    }
    return null;
  }

  @override
  Future<void> logout() async {
    await _settingsDataSource.clearAuthData();
  }
}
