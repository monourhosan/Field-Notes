import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/entities/site.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/site_repository.dart';
import '../local/database_helper.dart';
import '../models/site_model.dart';
import '../remote/api_client.dart';

class SiteRepositoryImpl implements SiteRepository {
  final DatabaseHelper _dbHelper;
  final ApiClient _apiClient;
  final Uuid _uuid = const Uuid();

  SiteRepositoryImpl(this._dbHelper, this._apiClient);

  @override
  Future<List<Site>> getSites({String? customerId}) async {
    final db = await _dbHelper.database;

    String query = '''
      SELECT s.*, c.name as customer_name 
      FROM sites s 
      JOIN customers c ON s.customer_id = c.id 
      WHERE s.is_deleted = 0
    ''';
    List<dynamic> args = [];

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
    final maps = await db.rawQuery('''
      SELECT s.*, c.name as customer_name 
      FROM sites s 
      JOIN customers c ON s.customer_id = c.id 
      WHERE s.id = ? AND s.is_deleted = 0
      LIMIT 1
    ''', [id]);

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
    final db = await _dbHelper.database;
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
    final customerName = customerMaps.isNotEmpty ? customerMaps.first['name'] as String? : null;

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

    await db.insert('sites', model.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    // Try online sync
    try {
      final response = await _apiClient.post(
        ApiConstants.sites,
        body: {
          'id': id,
          'customerId': customerId,
          'siteName': siteName,
          'address': address,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        model = SiteModel.fromEntity(model.copyWith(syncStatus: SyncStatus.synced));
        await db.update(
          'sites',
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
  Future<Site> updateSite({
    required String id,
    required String customerId,
    required String siteName,
    String? address,
  }) async {
    final db = await _dbHelper.database;
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
        updatedAt: now,
        syncStatus: newStatus,
      ),
    );

    await db.update('sites', updated.toDbMap(), where: 'id = ?', whereArgs: [id]);

    // Try online sync
    try {
      final response = await _apiClient.put(
        '${ApiConstants.sites}/$id',
        body: {
          'customerId': customerId,
          'siteName': siteName,
          'address': address,
        },
      );
      if (response.statusCode == 200) {
        updated = SiteModel.fromEntity(updated.copyWith(syncStatus: SyncStatus.synced));
        await db.update(
          'sites',
          {'sync_status': SyncStatus.synced.toDbString()},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (_) {
      // Offline
    }

    return updated;
  }

  @override
  Future<void> deleteSite(String id) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final existing = await getSiteById(id);
    if (existing == null) return;

    if (existing.syncStatus == SyncStatus.pendingCreate) {
      await db.delete('sites', where: 'id = ?', whereArgs: [id]);
      return;
    }

    await db.update(
      'sites',
      {
        'is_deleted': 1,
        'sync_status': SyncStatus.pendingDelete.toDbString(),
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    try {
      final response = await _apiClient.delete('${ApiConstants.sites}/$id');
      if (response.statusCode == 204 || response.statusCode == 200) {
        await db.delete('sites', where: 'id = ?', whereArgs: [id]);
      }
    } catch (_) {
      // Offline
    }
  }
}
