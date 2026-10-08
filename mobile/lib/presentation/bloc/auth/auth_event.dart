import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String username;
  final String password;
  const LoginSubmitted({required this.username, required this.password});
  @override
  List<Object?> get props => [username, password];
}

class RegisterSubmitted extends AuthEvent {
  final String username;
  final String email;
  final String password;
  const RegisterSubmitted({
    required this.username,
    required this.email,
    required this.password,
  });
  @override
  List<Object?> get props => [username, email, password];
}

class LogoutRequested extends AuthEvent {}
