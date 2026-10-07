import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class UpdateDefaultNoteStatus extends SettingsEvent {
  final String status;
  const UpdateDefaultNoteStatus(this.status);
  @override
  List<Object?> get props => [status];
}

class UpdateBaseUrl extends SettingsEvent {
  final String url;
  const UpdateBaseUrl(this.url);
  @override
  List<Object?> get props => [url];
}
