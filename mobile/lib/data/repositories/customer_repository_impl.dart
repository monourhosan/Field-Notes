import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/customer_repository.dart';
import '../local/database_helper.dart';
import '../local/settings_local_data_source.dart';
import '../models/customer_model.dart';
import '../remote/api_client.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final DatabaseHelper _dbHelper;
  final ApiClient _apiClient;
  final SettingsLocalDataSource _settingsDataSource;
  final Uuid _uuid = const Uuid();

  CustomerRepositoryImpl(this._dbHelper, this._apiClient, this._settingsDataSource);

  @override
  Future<List<Customer>> getCustomers() async {
    final db = await _dbHelper.database;
    final userId = _settingsDataSource.getUserId() ?? 0;

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
    final userId = _settingsDataSource.getUserId() ?? 0;

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
  Future<Customer> createCustomer({required String name, String? contactInformation}) async {
    final db = await _dbHelper.database;
    final userId = _settingsDataSource.getUserId() ?? 0;
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

    await db.insert('customers', model.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    // Try online sync immediately
    try {
      final response = await _apiClient.post(
        ApiConstants.customers,
        body: {
          'id': id,
          'name': name,
          'contactInformation': contactInformation,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        model = CustomerModel.fromEntity(model.copyWith(syncStatus: SyncStatus.synced));
        await db.update(
          'customers',
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
  Future<Customer> updateCustomer({required String id, required String name, String? contactInformation}) async {
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
        updatedAt: now,
        syncStatus: newStatus,
      ),
    );

    await db.update('customers', updated.toDbMap(), where: 'id = ?', whereArgs: [id]);

    // Try online sync
    try {
      final response = await _apiClient.put(
        '${ApiConstants.customers}/$id',
        body: {
          'name': name,
          'contactInformation': contactInformation,
        },
      );
      if (response.statusCode == 200) {
        updated = CustomerModel.fromEntity(updated.copyWith(syncStatus: SyncStatus.synced));
        await db.update(
          'customers',
          {'sync_status': SyncStatus.synced.toDbString()},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (_) {
      // Offline: keep pending status
    }

    return updated;
  }

  @override
  Future<void> deleteCustomer(String id) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final existing = await getCustomerById(id);
    if (existing == null) return;

    if (existing.syncStatus == SyncStatus.pendingCreate) {
      // Not yet on server, can be completely deleted locally
      await db.delete('customers', where: 'id = ?', whereArgs: [id]);
      return;
    }

    // Mark as pending delete
    await db.update(
      'customers',
      {
        'is_deleted': 1,
        'sync_status': SyncStatus.pendingDelete.toDbString(),
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    // Try online delete
    try {
      final response = await _apiClient.delete('${ApiConstants.customers}/$id');
      if (response.statusCode == 204 || response.statusCode == 200) {
        await db.delete('customers', where: 'id = ?', whereArgs: [id]);
      }
    } catch (_) {
      // Offline: keep soft-deleted and pendingDelete
    }
  }
}
