import 'package:flutter_test/flutter_test.dart';
import 'package:field_notes_app/domain/entities/field_note.dart';
import 'package:field_notes_app/domain/entities/sync_status.dart';
import 'package:field_notes_app/domain/repositories/field_note_repository.dart';
import 'package:field_notes_app/presentation/bloc/note/field_note_bloc.dart';
import 'package:field_notes_app/presentation/bloc/note/field_note_event.dart';
import 'package:field_notes_app/presentation/bloc/note/field_note_state.dart';

class MockFieldNoteRepository implements FieldNoteRepository {
  List<FieldNote> notes = [];

  @override
  Future<List<FieldNote>> getNotes({
    String? query,
    String? siteId,
    String? status,
  }) async {
    return notes.where((n) {
      if (siteId != null && n.siteId != siteId) return false;
      if (status != null &&
          status.isNotEmpty &&
          status != 'ALL' &&
          n.status != status) {
        return false;
      }
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        return n.title.toLowerCase().contains(q) ||
            (n.description?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();
  }

  @override
  Future<FieldNote?> getNoteById(String id) async {
    try {
      return notes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<FieldNote> createNote({
    required String siteId,
    required String title,
    String? description,
    String? location,
    DateTime? dateTime,
    required String status,
    String? photo,
  }) async {
    final note = FieldNote(
      id: 'note-1',
      siteId: siteId,
      title: title,
      description: description,
      location: location,
      dateTime: dateTime ?? DateTime.now(),
      status: status,
      photo: photo,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );
    notes.add(note);
    return note;
  }

  @override
  Future<FieldNote> updateNote({
    required String id,
    required String siteId,
    required String title,
    String? description,
    String? location,
    DateTime? dateTime,
    required String status,
    String? photo,
  }) async {
    final idx = notes.indexWhere((n) => n.id == id);
    final updated = notes[idx].copyWith(title: title, status: status);
    notes[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteNote(String id) async {
    notes.removeWhere((n) => n.id == id);
  }
}

void main() {
  group('FieldNoteBloc', () {
    late FieldNoteBloc bloc;
    late MockFieldNoteRepository repository;

    setUp(() {
      repository = MockFieldNoteRepository();
      bloc = FieldNoteBloc(repository);
    });

    tearDown(() {
      bloc.close();
    });

    test('filters and searches notes correctly', () async {
      repository.notes = [
        FieldNote(
          id: '1',
          siteId: 'site-1',
          title: 'Transformer Check',
          description: 'High voltage readings',
          dateTime: DateTime.now(),
          status: 'COMPLETED',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        FieldNote(
          id: '2',
          siteId: 'site-2',
          title: 'Foundation Inspection',
          description: 'Concrete curing normal',
          dateTime: DateTime.now(),
          status: 'IN_PROGRESS',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Test Search
      bloc.add(const LoadFieldNotes(query: 'voltage'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<FieldNoteLoaded>().having(
            (s) => s.notes.length,
            'notes count',
            1,
          ),
        ),
      );

      // Test Filter by status
      bloc.add(const LoadFieldNotes(status: 'IN_PROGRESS'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<FieldNoteLoaded>().having(
            (s) => s.notes.first.status,
            'status',
            'IN_PROGRESS',
          ),
        ),
      );
    });
  });
}
