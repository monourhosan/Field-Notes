import 'package:equatable/equatable.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final String defaultNoteStatus;
  final String baseUrl;

  const SettingsLoaded({
    required this.defaultNoteStatus,
    required this.baseUrl,
  });

  @override
  List<Object?> get props => [defaultNoteStatus, baseUrl];
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
  @override
  List<Object?> get props => [message];
}
