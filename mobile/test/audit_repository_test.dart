import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:field_notes_app/data/local/database_helper.dart';
import 'package:field_notes_app/data/local/settings_local_data_source.dart';
import 'package:field_notes_app/data/remote/api_client.dart';
import 'package:field_notes_app/data/repositories/customer_repository_impl.dart';
import 'package:field_notes_app/data/repositories/site_repository_impl.dart';
import 'package:field_notes_app/data/repositories/field_note_repository_impl.dart';
import 'package:field_notes_app/data/repositories/sync_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Database db;
  late DatabaseHelper helper;
  late SettingsLocalDataSource settings;
  late ApiClient api;
  late CustomerRepositoryImpl customers;
  late SiteRepositoryImpl sites;
  late FieldNoteRepositoryImpl notes;
  late Future<http.Response> Function(http.Request) handler;
  final timestamp = DateTime.utc(2026).toIso8601String();
  Map<String, dynamic> serverCustomer(String id, String name, int version) => {
    'id': id,
    'userId': 1,
    'name': name,
    'version': version,
    'deleted': false,
    'createdAt': timestamp,
    'updatedAt': timestamp,
  };
  http.Response pull(List<dynamic> rows) => http.Response(
    jsonEncode({
      'customers': rows,
      'sites': [],
      'notes': [],
      'serverTimestamp': 1,
    }),
    200,
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    settings = SettingsLocalDataSource(await SharedPreferences.getInstance());
    await settings.initialize();
    await settings.saveAuthData(
      token: 'token',
      userId: 1,
      username: 'owner',
      email: 'owner@example.com',
    );
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
        onCreate: DatabaseHelper.createSchema,
      ),
    );
    helper = DatabaseHelper.forTesting(db);
    handler = (_) async => http.Response('failure', 500);
    api = ApiClient(settings, MockClient((request) => handler(request)));
    customers = CustomerRepositoryImpl(helper, api, settings);
    sites = SiteRepositoryImpl(helper, api, settings);
    notes = FieldNoteRepositoryImpl(helper, api, settings);
  });

  test(
    'v1 migration preserves valid pending rows and recovers orphaned rows',
    () async {
      final legacy = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await legacy.execute(
        'CREATE TABLE customers (id TEXT PRIMARY KEY,user_id INTEGER,name TEXT,contact_information TEXT,created_at TEXT,updated_at TEXT,is_deleted INTEGER,sync_status TEXT)',
      );
      await legacy.execute(
        'CREATE TABLE sites (id TEXT PRIMARY KEY,customer_id TEXT,site_name TEXT,address TEXT,created_at TEXT,updated_at TEXT,is_deleted INTEGER,sync_status TEXT)',
      );
      await legacy.execute(
        'CREATE TABLE field_notes (id TEXT PRIMARY KEY,site_id TEXT,title TEXT,description TEXT,location TEXT,date_time TEXT,status TEXT,photo TEXT,created_at TEXT,updated_at TEXT,is_deleted INTEGER,sync_status TEXT)',
      );
      await legacy.insert('customers', {
        'id': 'c',
        'user_id': 1,
        'name': 'Pending',
        'created_at': timestamp,
        'updated_at': timestamp,
        'is_deleted': 0,
        'sync_status': 'PENDING_CREATE',
      });
      for (final parent in ['c', 'missing']) {
        await legacy.insert('sites', {
          'id': 's$parent',
          'customer_id': parent,
          'site_name': 'Site',
          'created_at': timestamp,
          'updated_at': timestamp,
          'is_deleted': 0,
          'sync_status': 'PENDING_CREATE',
        });
      }
      await legacy.transaction((_) async {});
      await DatabaseHelper.migrateSchema(legacy, 1, 2);
      await legacy.execute('PRAGMA foreign_keys=ON');
      expect(
        (await legacy.query('customers')).single['sync_status'],
        'PENDING_CREATE',
      );
      expect((await legacy.query('sites')).length, 1);
      expect((await legacy.query('recovered_records')).length, 1);
      expect(await legacy.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      await legacy.delete('customers');
      expect(await legacy.query('sites'), isEmpty);
      await legacy.close();
    },
  );
  tearDown(() async {
    api.close();
    await helper.close();
  });
  test('offline hierarchy writes never use HTTP; reads and outbox isolate accounts', () async {
    var calls = 0;
    handler = (_) async {
      calls++;
      return http.Response('', 500);
    };
    final c = await customers.createCustomer(name: 'Customer');
    final s = await sites.createSite(customerId: c.id, siteName: 'Site');
    final n = await notes.createNote(
      siteId: s.id,
      title: 'Inspection',
      status: 'DRAFT',
    );
    expect((await notes.getNotes()).single.id, n.id);
    expect(calls, 0);
    expect(
      await SyncRepositoryImpl(helper, api, settings).getPendingSyncCount(),
      3,
    );
    await settings.saveAuthData(
      token: 'other',
      userId: 2,
      username: 'other',
      email: 'other@example.com',
    );
    expect(await customers.getCustomers(), isEmpty);
    expect(await sites.getSites(), isEmpty);
    expect(await notes.getNotes(), isEmpty);
    expect(await notes.getNoteById(n.id), isNull);
    expect(
      await SyncRepositoryImpl(helper, api, settings).getPendingSyncCount(),
      0,
    );
    expect(
      () => sites.createSite(customerId: c.id, siteName: 'Attack'),
      throwsException,
    );
  });
  test('photo removal persists and combined filters work', () async {
    final c = await customers.createCustomer(name: 'Energy');
    final s = await sites.createSite(customerId: c.id, siteName: 'Solar');
    final n = await notes.createNote(
      siteId: s.id,
      title: 'Inspect',
      description: 'Voltage',
      status: 'DRAFT',
      photo: 'photo',
    );
    await notes.updateNote(
      id: n.id,
      siteId: s.id,
      title: 'Inspect',
      description: 'Voltage',
      status: 'COMPLETED',
      photo: null,
    );
    expect((await notes.getNoteById(n.id))!.photo, isNull);
    for (final query in ['Inspect', 'Voltage', 'Solar', 'Energy']) {
      expect(
        (await notes.getNotes(
          query: query,
          siteId: s.id,
          status: 'COMPLETED',
        )).length,
        1,
        reason: 'Search title, description, site and customer offline',
      );
    }
    expect(await notes.getNotes(query: 'Voltage', status: 'DRAFT'), isEmpty);
  });
  test(
    'deleting pending creation leaves tombstone and hides descendants',
    () async {
      final c = await customers.createCustomer(name: 'Customer');
      final s = await sites.createSite(customerId: c.id, siteName: 'Site');
      await notes.createNote(siteId: s.id, title: 'Note', status: 'DRAFT');
      await customers.deleteCustomer(c.id);
      expect(await sites.getSites(), isEmpty);
      expect(await notes.getNotes(), isEmpty);
      expect(
        (await db.query('customers')).single['sync_status'],
        'PENDING_DELETE',
      );
      expect(
        await SyncRepositoryImpl(helper, api, settings).getPendingSyncCount(),
        1,
      );
      await db.delete('customers');
      expect(await db.query('sites'), isEmpty);
      expect(await db.query('field_notes'), isEmpty);
    },
  );
  for (final status in [401, 500]) {
    test('HTTP $status preserves pending records', () async {
      final c = await customers.createCustomer(name: 'Customer');
      handler = (_) async => http.Response('{}', status);
      await expectLater(
        SyncRepositoryImpl(helper, api, settings).syncAll(),
        throwsA(isA<ApiException>()),
      );
      expect(
        (await db.query(
          'customers',
          where: 'id=?',
          whereArgs: [c.id],
        )).single['sync_status'],
        'PENDING_CREATE',
      );
    });
  }
  test('successful acknowledgement applies server version, then upload retry is harmless', () async {
    final c = await customers.createCustomer(name: 'Customer');
    handler = (request) async => request.method == 'POST'
        ? http.Response(
            jsonEncode({
              'syncedCustomerIds': [c.id],
              'customerVersions': {c.id: 0},
              'syncedSiteIds': [],
              'syncedNoteIds': [],
              'conflicts': [],
            }),
            200,
          )
        : pull([serverCustomer(c.id, 'Customer', 0)]);
    final sync = SyncRepositoryImpl(helper, api, settings);
    await sync.syncAll();
    expect(await sync.getPendingSyncCount(), 0);
    expect((await customers.getCustomerById(c.id))!.serverVersion, 0);
  });
  test(
    'editing during upload preserves the newer edit and rebases its version',
    () async {
      final c = await customers.createCustomer(name: 'First');
      handler = (request) async {
        if (request.method == 'POST') {
          await customers.updateCustomer(id: c.id, name: 'Second');
          return http.Response(
            jsonEncode({
              'syncedCustomerIds': [c.id],
              'customerVersions': {c.id: 0},
              'conflicts': [],
            }),
            200,
          );
        }
        return pull([serverCustomer(c.id, 'First', 0)]);
      };
      final sync = SyncRepositoryImpl(helper, api, settings);
      await sync.syncAll();
      expect((await customers.getCustomerById(c.id))!.name, 'Second');
      expect((await customers.getCustomerById(c.id))!.serverVersion, 0);
      expect(await sync.getPendingSyncCount(), 1);
    },
  );
  test('deleting during first upload does not resurrect creation', () async {
    final c = await customers.createCustomer(name: 'First');
    handler = (request) async {
      if (request.method == 'POST') {
        await customers.deleteCustomer(c.id);
        return http.Response(
          jsonEncode({
            'syncedCustomerIds': [c.id],
            'customerVersions': {c.id: 0},
            'conflicts': [],
          }),
          200,
        );
      }
      return pull([serverCustomer(c.id, 'First', 0)]);
    };
    final sync = SyncRepositoryImpl(helper, api, settings);
    await sync.syncAll();
    expect(await customers.getCustomers(), isEmpty);
    expect(await sync.getPendingSyncCount(), 1);
  });
  test(
    'server conflicts preserve local content and can be resolved explicitly',
    () async {
      final c = await customers.createCustomer(name: 'My edit');
      handler = (request) async => request.method == 'POST'
          ? http.Response(
              jsonEncode({
                'syncedCustomerIds': [],
                'conflicts': ['Customer ${c.id}: newer server version'],
              }),
              200,
            )
          : pull([serverCustomer(c.id, 'Their edit', 4)]);
      final sync = SyncRepositoryImpl(helper, api, settings);
      await expectLater(sync.syncAll(), throwsStateError);
      expect((await customers.getCustomerById(c.id))!.name, 'My edit');
      expect((await sync.getConflicts()).length, 1);
      await sync.resolveConflict(c.id, keepLocal: true);
      expect((await customers.getCustomerById(c.id))!.serverVersion, 4);
      expect(await sync.getConflicts(), isEmpty);
    },
  );
  test('an intervening server edit after push is never silently overwritten by a newer local edit', () async {
    final c = await customers.createCustomer(name: 'Sent');
    handler = (request) async {
      if (request.method == 'POST') {
        await customers.updateCustomer(id: c.id, name: 'New local edit');
        return http.Response(
          jsonEncode({
            'syncedCustomerIds': [c.id],
            'customerVersions': {c.id: 0},
            'conflicts': [],
          }),
          200,
        );
      }
      return pull([serverCustomer(c.id, 'Other device edit', 1)]);
    };
    final sync = SyncRepositoryImpl(helper, api, settings);
    await expectLater(sync.syncAll(), throwsStateError);
    expect((await customers.getCustomerById(c.id))!.name, 'New local edit');
    expect((await customers.getCustomerById(c.id))!.serverVersion, isNull);
    expect((await sync.getConflicts()).length, 1);
  });
  test('nullable customer, site and note text can be removed', () async {
    final c = await customers.createCustomer(
      name: 'Customer',
      contactInformation: 'Old contact',
    );
    final s = await sites.createSite(
      customerId: c.id,
      siteName: 'Site',
      address: 'Old address',
    );
    final n = await notes.createNote(
      siteId: s.id,
      title: 'Note',
      description: 'Old description',
      location: 'Old location',
      status: 'DRAFT',
    );
    await customers.updateCustomer(
      id: c.id,
      name: 'Customer',
      contactInformation: null,
    );
    await sites.updateSite(
      id: s.id,
      customerId: c.id,
      siteName: 'Site',
      address: null,
    );
    await notes.updateNote(
      id: n.id,
      siteId: s.id,
      title: 'Note',
      description: null,
      location: null,
      status: 'DRAFT',
    );
    expect((await customers.getCustomerById(c.id))!.contactInformation, isNull);
    expect((await sites.getSiteById(s.id))!.address, isNull);
    expect((await notes.getNoteById(n.id))!.description, isNull);
    expect((await notes.getNoteById(n.id))!.location, isNull);
  });
  test('large offline outbox drains in bounded batches', () async {
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < 205; i++) {
      final c = await customers.createCustomer(name: 'Customer $i');
      rows.add(serverCustomer(c.id, c.name, 0));
    }
    var pushes = 0;
    handler = (request) async {
      if (request.method == 'GET') return pull(rows);
      final data = jsonDecode(request.body) as Map<String, dynamic>;
      final batch = data['customers'] as List;
      expect(batch.length, lessThanOrEqualTo(200));
      pushes++;
      return http.Response(
        jsonEncode({
          'syncedCustomerIds': batch.map((c) => c['id']).toList(),
          'customerVersions': {for (final c in batch) c['id']: 0},
          'conflicts': [],
        }),
        200,
      );
    };
    final sync = SyncRepositoryImpl(helper, api, settings);
    await sync.syncAll();
    expect(pushes, 2);
    expect(await sync.getPendingSyncCount(), 0);
  });
  test('logout during push prevents a pull with a different account', () async {
    await customers.createCustomer(name: 'Customer');
    var calls = 0;
    handler = (request) async {
      calls++;
      await settings.clearAuthData();
      return http.Response('{"conflicts":[]}', 200);
    };
    await expectLater(
      SyncRepositoryImpl(helper, api, settings).syncAll(),
      throwsStateError,
    );
    expect(calls, 1);
  });
  test(
    'token migrates out of preferences and defaults survive restart',
    () async {
      await settings.setDefaultNoteStatus('COMPLETED');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', 'legacy');
      await prefs.setInt('auth_user_id', 1);
      await prefs.setString('auth_username', 'owner');
      await prefs.setString('auth_email', 'owner@example.com');
      FlutterSecureStorage.setMockInitialValues({});
      final restarted = SettingsLocalDataSource(prefs);
      await restarted.initialize();
      expect(restarted.getToken(), 'legacy');
      expect(prefs.containsKey('auth_user_id'), false);
      final again = SettingsLocalDataSource(prefs);
      await again.initialize();
      expect(again.getUserId(), 1);
      expect(again.getToken(), 'legacy');
      expect(prefs.containsKey('auth_token'), false);
      expect(restarted.getDefaultNoteStatus(), 'COMPLETED');
      await expectLater(
        restarted.setBaseUrl('http://other.example'),
        throwsStateError,
      );
      await restarted.clearAuthData();
      await restarted.setBaseUrl('http://other.example');
      expect(restarted.getBaseUrl(), 'http://other.example');
    },
  );
  test('repeated edits during upload preserve monotonic revisions and newest content', () async {
    final c = await customers.createCustomer(name: 'Created');
    await customers.updateCustomer(id: c.id, name: 'Sent');
    handler = (request) async {
      if (request.method == 'POST') {
        await customers.updateCustomer(id: c.id, name: 'Second');
        await customers.updateCustomer(id: c.id, name: 'Third');
        return http.Response(
          jsonEncode({
            'syncedCustomerIds': [c.id],
            'customerVersions': {c.id: 0},
            'conflicts': [],
          }),
          200,
        );
      }
      return pull([serverCustomer(c.id, 'Sent', 0)]);
    };
    await SyncRepositoryImpl(helper, api, settings).syncAll();
    expect((await customers.getCustomerById(c.id))!.name, 'Third');
    expect((await db.query('customers')).single['local_revision'], 3);
    expect(
      (await db.query('customers')).single['sync_status'],
      'PENDING_UPDATE',
    );
  });
  test(
    'conditional pull caches its tag with the committed database snapshot',
    () async {
      var calls = 0;
      handler = (request) async {
        expect(request.method, 'GET');
        calls++;
        if (calls == 1) {
          expect(request.headers['if-none-match'], isNull);
          return http.Response(
            jsonEncode({
              'customers': [serverCustomer('c', 'Remote', 0)],
              'sites': [],
              'notes': [],
              'serverTimestamp': 1,
            }),
            200,
            headers: {'etag': '"tag"'},
          );
        }
        expect(request.headers['if-none-match'], '"tag"');
        return http.Response('', 304);
      };
      final sync = SyncRepositoryImpl(helper, api, settings);
      await sync.syncAll();
      await sync.syncAll();
      expect(calls, 2);
      expect((await customers.getCustomers()).single.name, 'Remote');
      expect((await db.query('sync_metadata')).single['snapshot_tag'], '"tag"');
    },
  );
  test(
    'stale conflict review cannot discard a subsequent local edit',
    () async {
      final c = await customers.createCustomer(name: 'Reviewed');
      handler = (request) async => request.method == 'POST'
          ? http.Response(
              jsonEncode({
                'conflicts': ['Customer ${c.id}: stale'],
              }),
              200,
            )
          : pull([serverCustomer(c.id, 'Server', 1)]);
      final sync = SyncRepositoryImpl(helper, api, settings);
      await expectLater(sync.syncAll(), throwsStateError);
      final reviewed = (await sync.getConflicts()).single;
      final revision =
          (jsonDecode(reviewed['local_data'] as String)
                  as Map)['local_revision']
              as int;
      await customers.updateCustomer(id: c.id, name: 'Newer');
      await expectLater(
        sync.resolveConflict(
          c.id,
          keepLocal: false,
          entityType: 'customers',
          expectedRevision: revision,
        ),
        throwsStateError,
      );
      expect((await customers.getCustomerById(c.id))!.name, 'Newer');
      expect((await sync.getConflicts()).length, 1);
    },
  );
  test('conflict keys include entity type and account', () async {
    for (final type in ['customers', 'sites']) {
      await db.insert('sync_conflicts', {
        'id': 'same',
        'user_id': 1,
        'entity_type': type,
        'local_data': '{}',
        'message': 'Conflict',
        'created_at': timestamp,
      });
    }
    final sync = SyncRepositoryImpl(helper, api, settings);
    expect((await sync.getConflicts()).length, 2);
    await expectLater(
      sync.resolveConflict('same', keepLocal: false),
      throwsStateError,
    );
    await sync.resolveConflict('same', keepLocal: false, entityType: 'sites');
    expect((await sync.getConflicts()).single['entity_type'], 'customers');
  });
  test(
    'secure session writes expose a complete identity only after success',
    () async {
      final storage = ControlledSecureStorage();
      final local = SettingsLocalDataSource(
        await SharedPreferences.getInstance(),
        secureStorage: storage,
      );
      await local.initialize();
      await local.saveAuthData(
        token: 'one',
        userId: 1,
        username: 'one',
        email: 'one@example.com',
      );
      storage.gate = Completer<void>();
      final saving = local.saveAuthData(
        token: 'two',
        userId: 2,
        username: 'two',
        email: 'two@example.com',
      );
      await Future<void>.delayed(Duration.zero);
      expect(local.getToken(), 'one');
      expect(local.getUserId(), 1);
      storage.gate!.complete();
      await saving;
      expect(local.getToken(), 'two');
      expect(local.getUserId(), 2);
      storage.gate = null;
      storage.fail = true;
      await expectLater(
        local.saveAuthData(
          token: 'three',
          userId: 3,
          username: 'three',
          email: 'three@example.com',
        ),
        throwsStateError,
      );
      expect(local.getToken(), 'two');
      expect(local.getUserId(), 2);
    },
  );
  test('v2 conflict journal upgrade preserves rows and permits matching IDs across types', () async {
    await db.execute('DROP TABLE sync_metadata');
    await db.execute('DROP TABLE sync_conflicts');
    await db.execute(
      'CREATE TABLE sync_conflicts (id TEXT PRIMARY KEY,user_id INTEGER NOT NULL,entity_type TEXT NOT NULL,local_data TEXT NOT NULL,server_data TEXT,message TEXT NOT NULL,created_at TEXT NOT NULL)',
    );
    final row = {
      'id': 'same',
      'user_id': 1,
      'entity_type': 'customers',
      'local_data': '{}',
      'message': 'Preserved',
      'created_at': timestamp,
    };
    await db.insert('sync_conflicts', row);
    await DatabaseHelper.migrateSchema(db, 2, 3);
    await db.insert('sync_conflicts', {...row, 'entity_type': 'sites'});
    expect((await db.query('sync_conflicts')).length, 2);
    expect(await db.query('sync_metadata'), isEmpty);
  });
}

class ControlledSecureStorage extends FlutterSecureStorage {
  Completer<void>? gate;
  bool fail = false;
  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    await gate?.future;
    if (fail) throw StateError('Storage unavailable');
    await super.write(key: key, value: value);
  }
}
