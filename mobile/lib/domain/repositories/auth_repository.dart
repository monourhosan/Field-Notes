import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> register(String username, String email, String password);
  Future<User> login(String username, String password);
  Future<User?> getCurrentUser();
  Future<void> logout();
}
