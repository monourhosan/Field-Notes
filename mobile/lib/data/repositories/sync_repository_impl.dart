import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/sync_repository.dart';
import '../local/database_helper.dart';
import '../local/settings_local_data_source.dart';
import '../models/customer_model.dart';
import '../models/site_model.dart';
import '../models/field_note_model.dart';
import '../remote/api_client.dart';

class SyncRepositoryImpl implements SyncRepository {
  final DatabaseHelper _dbHelper;
  final ApiClient _apiClient;
  final SettingsLocalDataSource _settingsDataSource;

  SyncRepositoryImpl(this._dbHelper, this._apiClient, this._settingsDataSource);

  @override
  Future<int> getPendingSyncCount() async {
    final db = await _dbHelper.database;
    final pendingStates = [
      SyncStatus.pendingCreate.toDbString(),
      SyncStatus.pendingUpdate.toDbString(),
      SyncStatus.pendingDelete.toDbString(),
    ];

    final custCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM customers WHERE sync_status IN (?, ?, ?)',
      pendingStates,
    )) ?? 0;

    final siteCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM sites WHERE sync_status IN (?, ?, ?)',
      pendingStates,
    )) ?? 0;

    final noteCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM field_notes WHERE sync_status IN (?, ?, ?)',
      pendingStates,
    )) ?? 0;

    return custCount + siteCount + noteCount;
  }

  @override
  Future<void> syncAll() async {
    final db = await _dbHelper.database;

    // 1. Gather all pending local changes
    final pendingCustomers = await db.query(
      'customers',
      where: 'sync_status != ?',
      whereArgs: [SyncStatus.synced.toDbString()],
    );
    final pendingSites = await db.query(
      'sites',
      where: 'sync_status != ?',
      whereArgs: [SyncStatus.synced.toDbString()],
    );
    final pendingNotes = await db.query(
      'field_notes',
      where: 'sync_status != ?',
      whereArgs: [SyncStatus.synced.toDbString()],
    );

    // 2. Build Push payload
    final pushBody = {
      'customers': pendingCustomers.map((m) {
        return {
          'id': m['id'],
          'name': m['name'],
          'contactInformation': m['contact_information'],
          'deleted': (m['is_deleted'] as int) == 1,
          'updatedAt': DateTime.parse(m['updated_at'] as String).millisecondsSinceEpoch,
        };
      }).toList(),
      'sites': pendingSites.map((m) {
        return {
          'id': m['id'],
          'customerId': m['customer_id'],
          'siteName': m['site_name'],
          'address': m['address'],
          'deleted': (m['is_deleted'] as int) == 1,
          'updatedAt': DateTime.parse(m['updated_at'] as String).millisecondsSinceEpoch,
        };
      }).toList(),
      'notes': pendingNotes.map((m) {
        return {
          'id': m['id'],
          'siteId': m['site_id'],
          'title': m['title'],
          'description': m['description'],
          'location': m['location'],
          'dateTime': DateTime.parse(m['date_time'] as String).millisecondsSinceEpoch,
          'status': m['status'],
          'photo': m['photo'],
          'deleted': (m['is_deleted'] as int) == 1,
          'updatedAt': DateTime.parse(m['updated_at'] as String).millisecondsSinceEpoch,
        };
      }).toList(),
    };

    // 3. Push to Server
    if (pendingCustomers.isNotEmpty || pendingSites.isNotEmpty || pendingNotes.isNotEmpty) {
      final pushResponse = await _apiClient.post(ApiConstants.syncPush, body: pushBody);
      if (pushResponse.statusCode == 200) {
        final pushData = jsonDecode(pushResponse.body);
        final syncedCustIds = List<String>.from(pushData['syncedCustomerIds'] ?? []);
        final syncedSiteIds = List<String>.from(pushData['syncedSiteIds'] ?? []);
        final syncedNoteIds = List<String>.from(pushData['syncedNoteIds'] ?? []);

        // Mark synced or clean up soft-deleted items
        for (var id in syncedCustIds) {
          await db.delete('customers', where: 'id = ? AND is_deleted = 1', whereArgs: [id]);
          await db.update('customers', {'sync_status': SyncStatus.synced.toDbString()}, where: 'id = ?', whereArgs: [id]);
        }
        for (var id in syncedSiteIds) {
          await db.delete('sites', where: 'id = ? AND is_deleted = 1', whereArgs: [id]);
          await db.update('sites', {'sync_status': SyncStatus.synced.toDbString()}, where: 'id = ?', whereArgs: [id]);
        }
        for (var id in syncedNoteIds) {
          await db.delete('field_notes', where: 'id = ? AND is_deleted = 1', whereArgs: [id]);
          await db.update('field_notes', {'sync_status': SyncStatus.synced.toDbString()}, where: 'id = ?', whereArgs: [id]);
        }
      }
    }

    // 4. Pull server updates since last sync timestamp
    final lastSync = _settingsDataSource.getLastSyncTime();
    final pullResponse = await _apiClient.get(
      ApiConstants.syncPull,
      queryParameters: {'since': lastSync > 0 ? lastSync : null},
    );

    if (pullResponse.statusCode == 200) {
      final pullData = jsonDecode(pullResponse.body);
      final serverTimestamp = pullData['serverTimestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

      final serverCustomers = (pullData['customers'] as List? ?? []).map((j) => CustomerModel.fromJson(j)).toList();
      final serverSites = (pullData['sites'] as List? ?? []).map((j) => SiteModel.fromJson(j)).toList();
      final serverNotes = (pullData['notes'] as List? ?? []).map((j) => FieldNoteModel.fromJson(j)).toList();

      for (var c in serverCustomers) {
        if (c.isDeleted) {
          await db.delete('customers', where: 'id = ?', whereArgs: [c.id]);
        } else {
          await db.insert('customers', c.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      for (var s in serverSites) {
        if (s.isDeleted) {
          await db.delete('sites', where: 'id = ?', whereArgs: [s.id]);
        } else {
          await db.insert('sites', s.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      for (var n in serverNotes) {
        if (n.isDeleted) {
          await db.delete('field_notes', where: 'id = ?', whereArgs: [n.id]);
        } else {
          await db.insert('field_notes', n.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      await _settingsDataSource.setLastSyncTime(serverTimestamp);
    }
  }
}
