import '../entities/field_note.dart';

abstract class FieldNoteRepository {
  Future<List<FieldNote>> getNotes({String? query, String? siteId, String? status});
  Future<FieldNote?> getNoteById(String id);
  Future<FieldNote> createNote({
    required String siteId,
    required String title,
    String? description,
    String? location,
    DateTime? dateTime,
    required String status,
    String? photo,
  });
  Future<FieldNote> updateNote({
    required String id,
    required String siteId,
    required String title,
    String? description,
    String? location,
    DateTime? dateTime,
    required String status,
    String? photo,
  });
  Future<void> deleteNote(String id);
}
