import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../domain/repositories/field_note_repository.dart';
import 'field_note_event.dart';
import 'field_note_state.dart';

class FieldNoteBloc extends Bloc<FieldNoteEvent, FieldNoteState> {
  final FieldNoteRepository _fieldNoteRepository;
  LoadFieldNotes _lastLoad = const LoadFieldNotes();

  FieldNoteBloc(this._fieldNoteRepository) : super(FieldNoteInitial()) {
    on<LoadFieldNotes>(_onLoadFieldNotes, transformer: restartable());
    on<RefreshFieldNotes>((event, emit) => add(_lastLoad));
    on<CreateFieldNoteEvent>(_onCreateFieldNote, transformer: sequential());
    on<UpdateFieldNoteEvent>(_onUpdateFieldNote, transformer: sequential());
    on<DeleteFieldNoteEvent>(_onDeleteFieldNote, transformer: sequential());
  }

  Future<void> _onLoadFieldNotes(
    LoadFieldNotes event,
    Emitter<FieldNoteState> emit,
  ) async {
    if (event.reset) {
      _lastLoad = const LoadFieldNotes();
      emit(FieldNoteInitial());
      return;
    }
    _lastLoad = event;
    emit(FieldNoteLoading());
    try {
      final notes = await _fieldNoteRepository.getNotes(
        query: event.query,
        siteId: event.siteId,
        status: event.status,
      );
      emit(
        FieldNoteLoaded(
          notes,
          currentQuery: event.query,
          currentSiteId: event.siteId,
          currentStatus: event.status,
        ),
      );
    } catch (e) {
      emit(FieldNoteError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateFieldNote(
    CreateFieldNoteEvent event,
    Emitter<FieldNoteState> emit,
  ) async {
    emit(FieldNoteSaving());
    try {
      await _fieldNoteRepository.createNote(
        siteId: event.siteId,
        title: event.title,
        description: event.description,
        location: event.location,
        dateTime: event.dateTime,
        status: event.status,
        photo: event.photo,
      );
      emit(FieldNoteSaved());
      add(_lastLoad);
    } catch (e) {
      emit(FieldNoteError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateFieldNote(
    UpdateFieldNoteEvent event,
    Emitter<FieldNoteState> emit,
  ) async {
    emit(FieldNoteSaving());
    try {
      await _fieldNoteRepository.updateNote(
        id: event.id,
        siteId: event.siteId,
        title: event.title,
        description: event.description,
        location: event.location,
        dateTime: event.dateTime,
        status: event.status,
        photo: event.photo,
      );
      emit(FieldNoteSaved());
      add(_lastLoad);
    } catch (e) {
      emit(FieldNoteError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteFieldNote(
    DeleteFieldNoteEvent event,
    Emitter<FieldNoteState> emit,
  ) async {
    emit(FieldNoteSaving());
    try {
      await _fieldNoteRepository.deleteNote(event.id);
      emit(FieldNoteSaved());
      add(_lastLoad);
    } catch (e) {
      emit(FieldNoteError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
