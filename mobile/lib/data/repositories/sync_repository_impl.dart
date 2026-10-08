import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../core/constants/api_constants.dart';
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
  final SettingsLocalDataSource _settings;
  Future<void>? _running;
  SyncRepositoryImpl(this._dbHelper, this._apiClient, this._settings);

  Future<Map<String, List<Map<String, Object?>>>> _pending(
    DatabaseExecutor db,
    int user,
  ) async => {
    'customers': await db.rawQuery(
      "SELECT id, local_revision FROM customers WHERE user_id = ? AND sync_status != 'SYNCED'",
      [user],
    ),
    'sites': await db.rawQuery(
      "SELECT s.id, s.local_revision FROM sites s JOIN customers c ON c.id = s.customer_id WHERE c.user_id = ? AND s.sync_status != 'SYNCED' AND c.is_deleted = 0",
      [user],
    ),
    'field_notes': await db.rawQuery(
      "SELECT n.id, n.local_revision FROM field_notes n JOIN sites s ON s.id = n.site_id JOIN customers c ON c.id = s.customer_id WHERE c.user_id = ? AND n.sync_status != 'SYNCED' AND c.is_deleted = 0 AND s.is_deleted = 0",
      [user],
    ),
  };
  @override
  Future<int> getPendingSyncCount() async {
    if (_settings.getUserId() == null) return 0;
    final db = await _dbHelper.database;
    final user = _settings.requireUserId();
    final counts = await db.rawQuery(
      """
      SELECT (SELECT COUNT(*) FROM customers WHERE user_id=? AND sync_status!='SYNCED') +
      (SELECT COUNT(*) FROM sites s JOIN customers c ON c.id=s.customer_id WHERE c.user_id=? AND c.is_deleted=0 AND s.sync_status!='SYNCED') +
      (SELECT COUNT(*) FROM field_notes n JOIN sites s ON s.id=n.site_id JOIN customers c ON c.id=s.customer_id WHERE c.user_id=? AND c.is_deleted=0 AND s.is_deleted=0 AND n.sync_status!='SYNCED') AS total
    """,
      [user, user, user],
    );
    return counts.single['total'] as int;
  }

  @override
  Future<void> syncAll() =>
      _running ??= _run().whenComplete(() => _running = null);
  Future<void> _run() async {
    final user = _settings.requireUserId();
    final account = _settings.accountKey;
    final db = await _dbHelper.database;
    final pending = await db.transaction((txn) => _pending(txn, user));
    final acknowledged = <String, Set<String>>{
      for (final table in pending.keys) table: <String>{},
    };
    final acknowledgedVersions = <String, Map<String, int>>{
      for (final table in pending.keys) table: {},
    };
    List<String> conflicts = [];
    // Send parents first in bounded batches, so large offline outboxes can drain.
    for (final kind in ['customers', 'sites', 'notes']) {
      final table = kind == 'notes' ? 'field_notes' : kind;
      final items = pending[table]!;
      final sent = <Map<String, Object?>>[];
      var offset = 0;
      while (offset < items.length) {
        final batch = <Map<String, dynamic>>[];
        var bytes = 100;
        while (offset < items.length && batch.length < 200) {
          final metadata = items[offset];
          final rows = await db.query(
            table,
            where: 'id=?',
            whereArgs: [metadata['id']],
          );
          if (rows.isEmpty || rows.single['sync_status'] == 'SYNCED') {
            offset++;
            continue;
          }
          final row = rows.single;
          final item = table == 'customers'
              ? CustomerModel.fromDbMap(row).toJson()
              : table == 'sites'
              ? SiteModel.fromDbMap(row).toJson()
              : FieldNoteModel.fromDbMap(row).toJson();
          final size = utf8.encode(jsonEncode(item)).length + 1;
          if (batch.isNotEmpty && bytes + size > 4 * 1024 * 1024) break;
          if (size > 4 * 1024 * 1024) {
            throw StateError('A record exceeds the upload limit');
          }
          sent.add({'id': row['id'], 'local_revision': row['local_revision']});
          batch.add(item);
          bytes += size;
          offset++;
        }
        if (batch.isEmpty) continue;
        if (_settings.getUserId() != user || _settings.accountKey != account) {
          throw StateError('Account changed during sync');
        }
        final response = await _apiClient.post(
          ApiConstants.syncPush,
          body: {
            'customers': kind == 'customers' ? batch : [],
            'sites': kind == 'sites' ? batch : [],
            'notes': kind == 'notes' ? batch : [],
          },
        );
        _apiClient.requireSuccess(response);
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        for (final entry in {
          'customers': 'syncedCustomerIds',
          'sites': 'syncedSiteIds',
          'field_notes': 'syncedNoteIds',
        }.entries) {
          acknowledged[entry.key]!.addAll(
            List<String>.from(data[entry.value] as List? ?? []),
          );
        }
        for (final entry in {
          'customers': 'customerVersions',
          'sites': 'siteVersions',
          'field_notes': 'noteVersions',
        }.entries) {
          final versions = data[entry.value] as Map? ?? {};
          acknowledgedVersions[entry.key]!.addAll(
            versions.map(
              (id, version) => MapEntry(id as String, (version as num).toInt()),
            ),
          );
        }
        conflicts.addAll(List<String>.from(data['conflicts'] as List? ?? []));
      }
      pending[table] = sent;
    }
    // Pull before acknowledging locally: a lost response leaves the outbox available for an idempotent retry.
    if (_settings.getUserId() != user || _settings.accountKey != account) {
      throw StateError('Account changed during sync');
    }
    final hasPending = pending.values.any((rows) => rows.isNotEmpty);
    final snapshots = await db.query(
      'sync_metadata',
      where: 'user_id=?',
      whereArgs: [user],
    );
    final cachedTag = snapshots.isEmpty
        ? null
        : snapshots.single['snapshot_tag'] as String;
    final response = await _apiClient.get(
      ApiConstants.syncPull,
      ifNoneMatch: hasPending ? null : cachedTag,
    );
    if (response.statusCode == 304) {
      if (hasPending || cachedTag == null) {
        throw StateError('Unexpected unchanged response from server');
      }
      if (_settings.getUserId() != user || _settings.accountKey != account) {
        throw StateError('Account changed during sync');
      }
      return;
    }
    _apiClient.requireSuccess(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (_settings.getUserId() != user || _settings.accountKey != account) {
      throw StateError('Account changed during sync');
    }
    final server = <String, List<Map<String, Object?>>>{
      'customers': (data['customers'] as List)
          .map((m) => CustomerModel.fromJson(m).toDbMap())
          .toList(),
      'sites': (data['sites'] as List)
          .map((m) => SiteModel.fromJson(m).toDbMap())
          .toList(),
      'field_notes': (data['notes'] as List)
          .map((m) => FieldNoteModel.fromJson(m).toDbMap())
          .toList(),
    };
    await db.transaction((txn) async {
      for (final table in ['customers', 'sites', 'field_notes']) {
        final sent = {for (final row in pending[table]!) row['id']: row};
        for (final row in server[table]!) {
          if (table == 'customers' && row['user_id'] != user) {
            throw StateError('Invalid server ownership');
          }
          final localRows = await txn.query(
            table,
            where: 'id = ?',
            whereArgs: [row['id']],
          );
          final local = localRows.isEmpty ? null : localRows.first;
          final wasAcknowledged = acknowledged[table]!.contains(row['id']);
          final unchanged =
              local != null &&
              sent[row['id']] != null &&
              local['local_revision'] == sent[row['id']]!['local_revision'];
          if (local != null &&
              local['sync_status'] != 'SYNCED' &&
              !(wasAcknowledged && unchanged)) {
            if (wasAcknowledged &&
                acknowledgedVersions[table]![row['id']] ==
                    row['server_version']) {
              // The user edited during the upload: rebase that edit on the acknowledged server revision.
              await txn.update(
                table,
                {
                  'server_version': row['server_version'],
                  'sync_status': local['is_deleted'] == 1
                      ? 'PENDING_DELETE'
                      : 'PENDING_UPDATE',
                },
                where: 'id = ?',
                whereArgs: [row['id']],
              );
            } else if (wasAcknowledged ||
                conflicts.any(
                  (message) => message.contains(row['id'] as String),
                )) {
              await txn.insert('sync_conflicts', {
                'id': row['id'],
                'user_id': user,
                'entity_type': table,
                'local_data': jsonEncode(local),
                'server_data': jsonEncode(row),
                'message': wasAcknowledged
                    ? '${row['id']}: server changed after upload'
                    : conflicts.firstWhere(
                        (message) => message.contains(row['id'] as String),
                      ),
                'created_at': DateTime.now().toUtc().toIso8601String(),
              }, conflictAlgorithm: ConflictAlgorithm.replace);
              if (wasAcknowledged) {
                conflicts.add('${row['id']}: server changed after upload');
              }
            }
            continue;
          }
          // Keep tombstones to preserve parent relationships and safely reconcile child rows.
          if (local == null) {
            await txn.insert(table, row);
          } else {
            await txn.update(
              table,
              row,
              where: 'id = ?',
              whereArgs: [row['id']],
            );
          }
          await txn.delete(
            'sync_conflicts',
            where: 'id = ? AND user_id = ? AND entity_type=?',
            whereArgs: [row['id'], user, table],
          );
        }
        // Also preserve conflicts for records missing from the server (e.g. an invalid parent).
        for (final row in pending[table]!) {
          final matching = conflicts.where(
            (message) => message.contains(row['id'] as String),
          );
          if (matching.isNotEmpty &&
              !server[table]!.any((r) => r['id'] == row['id'])) {
            final currentRows = await txn.query(
              table,
              where: 'id=?',
              whereArgs: [row['id']],
            );
            if (currentRows.isEmpty) continue;
            await txn.insert('sync_conflicts', {
              'id': row['id'],
              'user_id': user,
              'entity_type': table,
              'local_data': jsonEncode(currentRows.single),
              'message': matching.first,
              'created_at': DateTime.now().toUtc().toIso8601String(),
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }
      final tag = response.headers['etag'];
      if (tag != null) {
        await txn.insert('sync_metadata', {
          'user_id': user,
          'snapshot_tag': tag,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    await _settings.setLastSyncTime(data['serverTimestamp'] as int);

    if (conflicts.isNotEmpty) {
      throw StateError(
        '${conflicts.length} conflict(s) require review in Settings; your edits are preserved',
      );
    }
  }

  Future<List<Map<String, Object?>>> getConflicts() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'sync_conflicts',
      where: 'user_id=?',
      whereArgs: [_settings.requireUserId()],
    );
    final result = <Map<String, Object?>>[];
    for (final row in rows) {
      final table = row['entity_type'] as String;
      if (!['customers', 'sites', 'field_notes'].contains(table)) {
        throw StateError('Invalid conflict');
      }
      final current = await db.query(
        table,
        where: 'id=?',
        whereArgs: [row['id']],
      );
      result.add({
        ...row,
        if (current.isNotEmpty) 'local_data': jsonEncode(current.single),
      });
    }
    return result;
  }

  Future<void> resolveConflict(
    String id, {
    required bool keepLocal,
    String? entityType,
    int? expectedRevision,
  }) async {
    try {
      await _running;
    } catch (_) {}
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'sync_conflicts',
        where:
            'id=? AND user_id=?${entityType == null ? '' : ' AND entity_type=?'}',
        whereArgs: [id, _settings.requireUserId(), ?entityType],
      );
      if (rows.length > 1) throw StateError('Choose a specific record type');
      if (rows.isEmpty) return;
      final conflict = rows.first;
      final table = conflict['entity_type'] as String;
      if (!['customers', 'sites', 'field_notes'].contains(table)) {
        throw StateError('Invalid conflict');
      }
      final currentRows = await txn.query(
        table,
        where: 'id=?',
        whereArgs: [id],
      );
      if (expectedRevision != null &&
          currentRows.isNotEmpty &&
          currentRows.single['local_revision'] != expectedRevision) {
        throw StateError(
          'Your record changed. Reload conflicts before choosing a version.',
        );
      }
      final serverJson = conflict['server_data'] as String?;
      if (serverJson == null && keepLocal) {
        throw StateError(
          'Parent or record unavailable; fix its relationship first',
        );
      }
      final server = serverJson == null
          ? null
          : jsonDecode(serverJson) as Map<String, dynamic>;
      if (keepLocal) {
        if (server!['is_deleted'] == 1) {
          throw StateError(
            'The record was deleted on the server. Copy your edit to a new record.',
          );
        }
        await txn.update(
          table,
          {'server_version': server['server_version']},
          where: 'id = ?',
          whereArgs: [id],
        );
        await txn.rawUpdate(
          'UPDATE $table SET local_revision = local_revision + 1 WHERE id = ?',
          [id],
        );
      } else if (server != null) {
        await txn.update(table, server, where: 'id = ?', whereArgs: [id]);
      } else {
        await txn.delete(table, where: 'id = ?', whereArgs: [id]);
      }
      await txn.delete(
        'sync_conflicts',
        where: 'id = ? AND entity_type=? AND user_id=?',
        whereArgs: [id, table, _settings.requireUserId()],
      );
    });
    _dbHelper.notifyChange();
  }
}
