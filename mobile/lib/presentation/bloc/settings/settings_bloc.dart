import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../domain/repositories/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;

  SettingsBloc(
    this._settingsRepository, {
    String initialDefaultStatus = 'DRAFT',
  }) : super(
         SettingsLoaded(defaultNoteStatus: initialDefaultStatus, baseUrl: ''),
       ) {
    on<LoadSettings>(_onLoadSettings, transformer: restartable());
    on<UpdateDefaultNoteStatus>(
      _onUpdateDefaultNoteStatus,
      transformer: sequential(),
    );
    on<UpdateBaseUrl>(_onUpdateBaseUrl, transformer: sequential());
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final status = await _settingsRepository.getDefaultNoteStatus();
    final url = await _settingsRepository.getBaseUrl();
    emit(SettingsLoaded(defaultNoteStatus: status, baseUrl: url));
  }

  Future<void> _onUpdateDefaultNoteStatus(
    UpdateDefaultNoteStatus event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.setDefaultNoteStatus(event.status);
    final url = await _settingsRepository.getBaseUrl();
    emit(SettingsLoaded(defaultNoteStatus: event.status, baseUrl: url));
  }

  Future<void> _onUpdateBaseUrl(
    UpdateBaseUrl event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsRepository.setBaseUrl(event.url);
    } catch (e) {
      emit(SettingsError(e.toString()));
      add(LoadSettings());
      return;
    }
    final status = await _settingsRepository.getDefaultNoteStatus();
    emit(SettingsLoaded(defaultNoteStatus: status, baseUrl: event.url));
  }
}
