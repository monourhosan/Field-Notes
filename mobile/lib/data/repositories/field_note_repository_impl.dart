import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/entities/field_note.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/field_note_repository.dart';
import '../local/database_helper.dart';
import '../models/field_note_model.dart';
import '../remote/api_client.dart';

class FieldNoteRepositoryImpl implements FieldNoteRepository {
  final DatabaseHelper _dbHelper;
  final ApiClient _apiClient;
  final Uuid _uuid = const Uuid();

  FieldNoteRepositoryImpl(this._dbHelper, this._apiClient);

  @override
  Future<List<FieldNote>> getNotes({String? query, String? siteId, String? status}) async {
    final db = await _dbHelper.database;

    String sql = '''
      SELECT n.*, s.site_name, s.customer_id, c.name as customer_name
      FROM field_notes n
      JOIN sites s ON n.site_id = s.id
      JOIN customers c ON s.customer_id = c.id
      WHERE n.is_deleted = 0
    ''';
    List<dynamic> args = [];

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
    final maps = await db.rawQuery('''
      SELECT n.*, s.site_name, s.customer_id, c.name as customer_name
      FROM field_notes n
      JOIN sites s ON n.site_id = s.id
      JOIN customers c ON s.customer_id = c.id
      WHERE n.id = ? AND n.is_deleted = 0
      LIMIT 1
    ''', [id]);

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
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final id = _uuid.v4();

    // Query site and customer info
    final siteMaps = await db.rawQuery('''
      SELECT s.site_name, s.customer_id, c.name as customer_name
      FROM sites s
      JOIN customers c ON s.customer_id = c.id
      WHERE s.id = ?
      LIMIT 1
    ''', [siteId]);

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

    await db.insert('field_notes', model.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    // Try online sync
    try {
      final response = await _apiClient.post(
        ApiConstants.notes,
        body: {
          'id': id,
          'siteId': siteId,
          'title': title,
          'description': description,
          'location': location,
          'dateTime': (dateTime ?? now).toIso8601String(),
          'status': status,
          'photo': photo,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        model = FieldNoteModel.fromEntity(model.copyWith(syncStatus: SyncStatus.synced));
        await db.update(
          'field_notes',
          {'sync_status': SyncStatus.synced.toDbString()},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (_) {
      // Offline: keep as PENDING_CREATE
    }

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
    final db = await _dbHelper.database;
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
        location: location,
        dateTime: dateTime ?? existing.dateTime,
        status: status,
        photo: photo ?? existing.photo,
        updatedAt: now,
        syncStatus: newStatus,
      ),
    );

    await db.update('field_notes', updated.toDbMap(), where: 'id = ?', whereArgs: [id]);

    // Try online sync
    try {
      final response = await _apiClient.put(
        '${ApiConstants.notes}/$id',
        body: {
          'siteId': siteId,
          'title': title,
          'description': description,
          'location': location,
          'dateTime': updated.dateTime.toIso8601String(),
          'status': status,
          'photo': updated.photo,
        },
      );
      if (response.statusCode == 200) {
        updated = FieldNoteModel.fromEntity(updated.copyWith(syncStatus: SyncStatus.synced));
        await db.update(
          'field_notes',
          {'sync_status': SyncStatus.synced.toDbString()},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (_) {
      // Offline: keep pending
    }

    return updated;
  }

  @override
  Future<void> deleteNote(String id) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final existing = await getNoteById(id);
    if (existing == null) return;

    if (existing.syncStatus == SyncStatus.pendingCreate) {
      await db.delete('field_notes', where: 'id = ?', whereArgs: [id]);
      return;
    }

    await db.update(
      'field_notes',
      {
        'is_deleted': 1,
        'sync_status': SyncStatus.pendingDelete.toDbString(),
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    try {
      final response = await _apiClient.delete('${ApiConstants.notes}/$id');
      if (response.statusCode == 204 || response.statusCode == 200) {
        await db.delete('field_notes', where: 'id = ?', whereArgs: [id]);
      }
    } catch (_) {
      // Offline
    }
  }
}
