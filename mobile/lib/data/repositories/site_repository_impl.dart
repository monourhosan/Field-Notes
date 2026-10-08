import '../../core/validation.dart';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/site.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/site_repository.dart';
import '../local/database_helper.dart';
import '../models/site_model.dart';
import '../remote/api_client.dart';
import '../local/settings_local_data_source.dart';

class SiteRepositoryImpl implements SiteRepository {
  final DatabaseHelper _dbHelper;
  final SettingsLocalDataSource _settingsDataSource;
  final Uuid _uuid = const Uuid();

  SiteRepositoryImpl(
    this._dbHelper,
    ApiClient apiClient,
    this._settingsDataSource,
  );

  @override
  Future<List<Site>> getSites({String? customerId}) async {
    final db = await _dbHelper.database;

    String query = '''
      SELECT s.*, c.name as customer_name 
      FROM sites s 
      JOIN customers c ON s.customer_id = c.id 
      WHERE s.is_deleted = 0 AND c.is_deleted = 0 AND c.user_id = ?
    ''';
    List<dynamic> args = [_settingsDataSource.requireUserId()];

    if (customerId != null && customerId.isNotEmpty) {
      query += ' AND s.customer_id = ?';
      args.add(customerId);
    }

    query += ' ORDER BY s.updated_at DESC';

    final maps = await db.rawQuery(query, args);
    return maps.map((m) => SiteModel.fromDbMap(m)).toList();
  }

  @override
  Future<Site?> getSiteById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT s.*, c.name as customer_name 
      FROM sites s 
      JOIN customers c ON s.customer_id = c.id 
      WHERE s.id = ? AND s.is_deleted = 0 AND c.is_deleted = 0 AND c.user_id = ?
      LIMIT 1
    ''',
      [id, _settingsDataSource.requireUserId()],
    );

    if (maps.isNotEmpty) {
      return SiteModel.fromDbMap(maps.first);
    }
    return null;
  }

  @override
  Future<Site> createSite({
    required String customerId,
    required String siteName,
    String? address,
  }) async {
    RecordValidation.text(siteName, 'Site name', 255, required: true);
    RecordValidation.text(address, 'Address', 16000);
    final db = await _dbHelper.database;
    final parent = await db.rawQuery(
      'SELECT id FROM customers WHERE id = ? AND user_id = ? AND is_deleted = 0',
      [customerId, _settingsDataSource.requireUserId()],
    );
    if (parent.isEmpty) throw Exception('Parent record unavailable');
    final now = DateTime.now();
    final id = _uuid.v4();

    // Query customer name
    final customerMaps = await db.query(
      'customers',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    final customerName = customerMaps.isNotEmpty
        ? customerMaps.first['name'] as String?
        : null;

    SiteModel model = SiteModel(
      id: id,
      customerId: customerId,
      customerName: customerName,
      siteName: siteName,
      address: address,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
      syncStatus: SyncStatus.pendingCreate,
    );

    await db.insert(
      'sites',
      model.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    _dbHelper.notifyChange();

    return model;
  }

  @override
  Future<Site> updateSite({
    required String id,
    required String customerId,
    required String siteName,
    String? address,
  }) async {
    RecordValidation.text(siteName, 'Site name', 255, required: true);
    RecordValidation.text(address, 'Address', 16000);
    final db = await _dbHelper.database;
    final parent = await db.rawQuery(
      'SELECT id FROM customers WHERE id = ? AND user_id = ? AND is_deleted = 0',
      [customerId, _settingsDataSource.requireUserId()],
    );
    if (parent.isEmpty) throw Exception('Parent record unavailable');
    final now = DateTime.now();

    final existing = await getSiteById(id);
    if (existing == null) throw Exception('Site not found');

    final newStatus = (existing.syncStatus == SyncStatus.pendingCreate)
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;

    SiteModel updated = SiteModel.fromEntity(
      existing.copyWith(
        customerId: customerId,
        siteName: siteName,
        address: address,
        clearAddress: address == null,
        updatedAt: now,
        syncStatus: newStatus,
      ),
    );

    await db.transaction((txn) async {
      await txn.update(
        'sites',
        updated.toDbMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.rawUpdate(
        'UPDATE sites SET local_revision = local_revision + 1 WHERE id = ?',
        [id],
      );
    });

    _dbHelper.notifyChange();

    return updated;
  }

  @override
  Future<void> deleteSite(String id) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final existing = await getSiteById(id);
    if (existing == null) return;

    await db.transaction((txn) async {
      await txn.rawUpdate(
        "UPDATE field_notes SET is_deleted = 1, sync_status = 'SYNCED' WHERE site_id = ?",
        [id],
      );
      await txn.rawUpdate(
        "UPDATE sites SET is_deleted = 1, sync_status = 'PENDING_DELETE', updated_at = ?, local_revision = local_revision + 1 WHERE id = ?",
        [now.toUtc().toIso8601String(), id],
      );
    });
    _dbHelper.notifyChange();
  }
}
