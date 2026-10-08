import '../../core/validation.dart';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/customer.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/customer_repository.dart';
import '../local/database_helper.dart';
import '../local/settings_local_data_source.dart';
import '../models/customer_model.dart';
import '../remote/api_client.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final DatabaseHelper _dbHelper;
  final SettingsLocalDataSource _settingsDataSource;
  final Uuid _uuid = const Uuid();

  CustomerRepositoryImpl(
    this._dbHelper,
    ApiClient apiClient,
    this._settingsDataSource,
  );

  @override
  Future<List<Customer>> getCustomers() async {
    final db = await _dbHelper.database;
    final userId = _settingsDataSource.requireUserId();

    final maps = await db.query(
      'customers',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );

    return maps.map((m) => CustomerModel.fromDbMap(m)).toList();
  }

  @override
  Future<Customer?> getCustomerById(String id) async {
    final db = await _dbHelper.database;
    final userId = _settingsDataSource.requireUserId();

    final maps = await db.query(
      'customers',
      where: 'id = ? AND user_id = ? AND is_deleted = 0',
      whereArgs: [id, userId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return CustomerModel.fromDbMap(maps.first);
    }
    return null;
  }

  @override
  Future<Customer> createCustomer({
    required String name,
    String? contactInformation,
  }) async {
    RecordValidation.text(name, 'Name', 255, required: true);
    RecordValidation.text(contactInformation, 'Contact information', 16000);
    final db = await _dbHelper.database;
    final userId = _settingsDataSource.requireUserId();
    final now = DateTime.now();
    final id = _uuid.v4();

    CustomerModel model = CustomerModel(
      id: id,
      userId: userId,
      name: name,
      contactInformation: contactInformation,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
      syncStatus: SyncStatus.pendingCreate,
    );

    await db.insert(
      'customers',
      model.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    _dbHelper.notifyChange();

    return model;
  }

  @override
  Future<Customer> updateCustomer({
    required String id,
    required String name,
    String? contactInformation,
  }) async {
    RecordValidation.text(name, 'Name', 255, required: true);
    RecordValidation.text(contactInformation, 'Contact information', 16000);
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final existing = await getCustomerById(id);
    if (existing == null) throw Exception('Customer not found');

    final newStatus = (existing.syncStatus == SyncStatus.pendingCreate)
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;

    CustomerModel updated = CustomerModel.fromEntity(
      existing.copyWith(
        name: name,
        contactInformation: contactInformation,
        clearContactInformation: contactInformation == null,
        updatedAt: now,
        syncStatus: newStatus,
      ),
    );

    await db.transaction((txn) async {
      await txn.update(
        'customers',
        updated.toDbMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.rawUpdate(
        'UPDATE customers SET local_revision = local_revision + 1 WHERE id = ?',
        [id],
      );
    });

    _dbHelper.notifyChange();

    return updated;
  }

  @override
  Future<void> deleteCustomer(String id) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final existing = await getCustomerById(id);
    if (existing == null) return;

    await db.transaction((txn) async {
      await txn.rawUpdate(
        "UPDATE field_notes SET is_deleted = 1, sync_status = 'SYNCED' WHERE site_id IN (SELECT id FROM sites WHERE customer_id = ?)",
        [id],
      );
      await txn.rawUpdate(
        "UPDATE sites SET is_deleted = 1, sync_status = 'SYNCED' WHERE customer_id = ?",
        [id],
      );
      await txn.rawUpdate(
        "UPDATE customers SET is_deleted = 1, sync_status = 'PENDING_DELETE', updated_at = ?, local_revision = local_revision + 1 WHERE id = ?",
        [now.toUtc().toIso8601String(), id],
      );
    });
    _dbHelper.notifyChange();
  }
}
