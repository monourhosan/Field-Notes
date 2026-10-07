import 'dart:convert';
import 'package:http/http.dart' as http;
import '../local/settings_local_data_source.dart';

class ApiClient {
  final SettingsLocalDataSource _settingsDataSource;
  final http.Client _client;

  ApiClient(this._settingsDataSource, [http.Client? client])
      : _client = client ?? http.Client();

  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = _settingsDataSource.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final baseUrl = _settingsDataSource.getBaseUrl().replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$baseUrl$cleanPath';

    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams = queryParameters.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      )..removeWhere((key, value) => value.isEmpty);
      return Uri.parse(fullUrl).replace(queryParameters: stringParams);
    }
    return Uri.parse(fullUrl);
  }

  Future<http.Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final uri = _buildUri(path, queryParameters);
    return await _client.get(uri, headers: _buildHeaders());
  }

  Future<http.Response> post(String path, {dynamic body}) async {
    final uri = _buildUri(path);
    final encodedBody = body is String ? body : (body != null ? jsonEncode(body) : null);
    return await _client.post(uri, headers: _buildHeaders(), body: encodedBody);
  }

  Future<http.Response> put(String path, {dynamic body}) async {
    final uri = _buildUri(path);
    final encodedBody = body is String ? body : (body != null ? jsonEncode(body) : null);
    return await _client.put(uri, headers: _buildHeaders(), body: encodedBody);
  }

  Future<http.Response> delete(String path) async {
    final uri = _buildUri(path);
    return await _client.delete(uri, headers: _buildHeaders());
  }
}
