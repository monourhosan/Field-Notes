import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;

  SettingsBloc(this._settingsRepository) : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateDefaultNoteStatus>(_onUpdateDefaultNoteStatus);
    on<UpdateBaseUrl>(_onUpdateBaseUrl);
  }

  Future<void> _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    final status = await _settingsRepository.getDefaultNoteStatus();
    final url = await _settingsRepository.getBaseUrl();
    emit(SettingsLoaded(defaultNoteStatus: status, baseUrl: url));
  }

  Future<void> _onUpdateDefaultNoteStatus(UpdateDefaultNoteStatus event, Emitter<SettingsState> emit) async {
    await _settingsRepository.setDefaultNoteStatus(event.status);
    final url = await _settingsRepository.getBaseUrl();
    emit(SettingsLoaded(defaultNoteStatus: event.status, baseUrl: url));
  }

  Future<void> _onUpdateBaseUrl(UpdateBaseUrl event, Emitter<SettingsState> emit) async {
    await _settingsRepository.setBaseUrl(event.url);
    final status = await _settingsRepository.getDefaultNoteStatus();
    emit(SettingsLoaded(defaultNoteStatus: status, baseUrl: event.url));
  }
}
