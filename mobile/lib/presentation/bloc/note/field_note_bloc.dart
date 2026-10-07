import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/field_note_repository.dart';
import 'field_note_event.dart';
import 'field_note_state.dart';

class FieldNoteBloc extends Bloc<FieldNoteEvent, FieldNoteState> {
  final FieldNoteRepository _fieldNoteRepository;

  FieldNoteBloc(this._fieldNoteRepository) : super(FieldNoteInitial()) {
    on<LoadFieldNotes>(_onLoadFieldNotes);
    on<CreateFieldNoteEvent>(_onCreateFieldNote);
    on<UpdateFieldNoteEvent>(_onUpdateFieldNote);
    on<DeleteFieldNoteEvent>(_onDeleteFieldNote);
  }

  Future<void> _onLoadFieldNotes(LoadFieldNotes event, Emitter<FieldNoteState> emit) async {
    emit(FieldNoteLoading());
    try {
      final notes = await _fieldNoteRepository.getNotes(
        query: event.query,
        siteId: event.siteId,
        status: event.status,
      );
      emit(FieldNoteLoaded(
        notes,
        currentQuery: event.query,
        currentSiteId: event.siteId,
        currentStatus: event.status,
      ));
    } catch (e) {
      emit(FieldNoteError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateFieldNote(CreateFieldNoteEvent event, Emitter<FieldNoteState> emit) async {
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
      add(const LoadFieldNotes());
    } catch (e) {
      emit(FieldNoteError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateFieldNote(UpdateFieldNoteEvent event, Emitter<FieldNoteState> emit) async {
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
      add(const LoadFieldNotes());
    } catch (e) {
      emit(FieldNoteError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteFieldNote(DeleteFieldNoteEvent event, Emitter<FieldNoteState> emit) async {
    try {
      await _fieldNoteRepository.deleteNote(event.id);
      add(const LoadFieldNotes());
    } catch (e) {
      emit(FieldNoteError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
