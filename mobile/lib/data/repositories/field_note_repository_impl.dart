import '../../core/validation.dart';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/field_note.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/field_note_repository.dart';
import '../local/database_helper.dart';
import '../models/field_note_model.dart';
import '../remote/api_client.dart';
import '../local/settings_local_data_source.dart';

class FieldNoteRepositoryImpl implements FieldNoteRepository {
  final DatabaseHelper _dbHelper;
  final SettingsLocalDataSource _settingsDataSource;
  final Uuid _uuid = const Uuid();

  FieldNoteRepositoryImpl(
    this._dbHelper,
    ApiClient apiClient,
    this._settingsDataSource,
  );

  @override
  Future<List<FieldNote>> getNotes({
    String? query,
    String? siteId,
    String? status,
  }) async {
    final db = await _dbHelper.database;

    String sql = '''
      SELECT n.*, s.site_name, s.customer_id, c.name as customer_name
      FROM field_notes n
      JOIN sites s ON n.site_id = s.id
      JOIN customers c ON s.customer_id = c.id
      WHERE n.is_deleted = 0 AND s.is_deleted = 0 AND c.is_deleted = 0 AND c.user_id = ?
    ''';
    List<dynamic> args = [_settingsDataSource.requireUserId()];

    if (siteId != null && siteId.isNotEmpty) {
      sql += ' AND n.site_id = ?';
      args.add(siteId);
    }

    if (status != null && status.isNotEmpty && status != 'ALL') {
      sql += ' AND n.status = ?';
      args.add(status);
    }

    if (query != null && query.trim().isNotEmpty) {
      final cleanQuery = '%${query.trim()}%';
      sql += '''
        AND (
          n.title LIKE ? OR 
          n.description LIKE ? OR 
          s.site_name LIKE ? OR 
          c.name LIKE ?
        )
      ''';
      args.addAll([cleanQuery, cleanQuery, cleanQuery, cleanQuery]);
    }

    sql += ' ORDER BY n.updated_at DESC';

    final maps = await db.rawQuery(sql, args);
    return maps.map((m) => FieldNoteModel.fromDbMap(m)).toList();
  }

  @override
  Future<FieldNote?> getNoteById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT n.*, s.site_name, s.customer_id, c.name as customer_name
      FROM field_notes n
      JOIN sites s ON n.site_id = s.id
      JOIN customers c ON s.customer_id = c.id
      WHERE n.id = ? AND n.is_deleted = 0 AND s.is_deleted = 0 AND c.is_deleted = 0 AND c.user_id = ?
      LIMIT 1
    ''',
      [id, _settingsDataSource.requireUserId()],
    );

    if (maps.isNotEmpty) {
      return FieldNoteModel.fromDbMap(maps.first);
    }
    return null;
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
    RecordValidation.note(title, description, location, status, photo);
    RecordValidation.inspectionDate(dateTime);
    final db = await _dbHelper.database;
    final parent = await db.rawQuery(
      'SELECT s.id FROM sites s JOIN customers c ON c.id = s.customer_id WHERE s.id = ? AND c.user_id = ? AND s.is_deleted = 0 AND c.is_deleted = 0',
      [siteId, _settingsDataSource.requireUserId()],
    );
    if (parent.isEmpty) throw Exception('Parent record unavailable');
    final now = DateTime.now();
    final id = _uuid.v4();

    // Query site and customer info
    final siteMaps = await db.rawQuery(
      '''
      SELECT s.site_name, s.customer_id, c.name as customer_name
      FROM sites s
      JOIN customers c ON s.customer_id = c.id
      WHERE s.id = ?
      LIMIT 1
    ''',
      [siteId],
    );

    String? siteName;
    String? customerId;
    String? customerName;
    if (siteMaps.isNotEmpty) {
      siteName = siteMaps.first['site_name'] as String?;
      customerId = siteMaps.first['customer_id'] as String?;
      customerName = siteMaps.first['customer_name'] as String?;
    }

    FieldNoteModel model = FieldNoteModel(
      id: id,
      siteId: siteId,
      siteName: siteName,
      customerId: customerId,
      customerName: customerName,
      title: title,
      description: description,
      location: location,
      dateTime: dateTime ?? now,
      status: status,
      photo: photo,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
      syncStatus: SyncStatus.pendingCreate,
    );

    await db.insert(
      'field_notes',
      model.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    _dbHelper.notifyChange();

    return model;
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
    RecordValidation.note(title, description, location, status, photo);
    RecordValidation.inspectionDate(dateTime);
    final db = await _dbHelper.database;
    final parent = await db.rawQuery(
      'SELECT s.id FROM sites s JOIN customers c ON c.id = s.customer_id WHERE s.id = ? AND c.user_id = ? AND s.is_deleted = 0 AND c.is_deleted = 0',
      [siteId, _settingsDataSource.requireUserId()],
    );
    if (parent.isEmpty) throw Exception('Parent record unavailable');
    final now = DateTime.now();

    final existing = await getNoteById(id);
    if (existing == null) throw Exception('Field note not found');

    final newStatus = (existing.syncStatus == SyncStatus.pendingCreate)
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;

    FieldNoteModel updated = FieldNoteModel.fromEntity(
      existing.copyWith(
        siteId: siteId,
        title: title,
        description: description,
        clearDescription: description == null,
        location: location,
        clearLocation: location == null,
        dateTime: dateTime ?? existing.dateTime,
        status: status,
        photo: photo,
        clearPhoto: photo == null,
        updatedAt: now,
        syncStatus: newStatus,
      ),
    );

    await db.transaction((txn) async {
      await txn.update(
        'field_notes',
        updated.toDbMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.rawUpdate(
        'UPDATE field_notes SET local_revision = local_revision + 1 WHERE id = ?',
        [id],
      );
    });

    _dbHelper.notifyChange();

    return updated;
  }

  @override
  Future<void> deleteNote(String id) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final existing = await getNoteById(id);
    if (existing == null) return;

    await db.transaction((txn) async {
      await txn.rawUpdate(
        "UPDATE field_notes SET is_deleted = 1, sync_status = 'PENDING_DELETE', updated_at = ?, local_revision = local_revision + 1 WHERE id = ?",
        [now.toUtc().toIso8601String(), id],
      );
    });
    _dbHelper.notifyChange();
  }
}
