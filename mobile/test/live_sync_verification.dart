// Run explicitly against a disposable/local backend:
// flutter test test/live_sync_verification.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'package:field_notes_app/data/local/database_helper.dart';
import 'package:field_notes_app/data/local/settings_local_data_source.dart';
import 'package:field_notes_app/data/remote/api_client.dart';
import 'package:field_notes_app/data/repositories/auth_repository_impl.dart';
import 'package:field_notes_app/data/repositories/customer_repository_impl.dart';
import 'package:field_notes_app/data/repositories/site_repository_impl.dart';
import 'package:field_notes_app/data/repositories/field_note_repository_impl.dart';
import 'package:field_notes_app/data/repositories/sync_repository_impl.dart';

class DisconnectableClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  bool offline = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (offline) throw http.ClientException('Simulated disconnected device');
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  sqfliteFfiInit();

  test('real backend: offline restart, upload, second device, conflict and cascade', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final settings = SettingsLocalDataSource(
      await SharedPreferences.getInstance(),
    );
    await settings.initialize();
    await settings.setBaseUrl(
      const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8080',
      ),
    );
    final network = DisconnectableClient();
    final api = ApiClient(settings, network);
    final suffix = const Uuid().v4().replaceAll('-', '');
    await AuthRepositoryImpl(
      api,
      settings,
    ).register('ready$suffix', 'ready$suffix@example.com', suffix);
    final directory = await Directory.systemTemp.createTemp(
      'field-notes-ready-',
    );
    final databases = <Database>[];
    Future<DatabaseHelper> open(String name) async {
      final database = await databaseFactoryFfi.openDatabase(
        '${directory.path}/$name.db',
        options: OpenDatabaseOptions(
          version: 3,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
          onCreate: DatabaseHelper.createSchema,
          onUpgrade: DatabaseHelper.migrateSchema,
        ),
      );
      databases.add(database);
      return DatabaseHelper.forTesting(database);
    }

    String? customerId;
    try {
      var first = await open('first');
      var customers = CustomerRepositoryImpl(first, api, settings);
      var sites = SiteRepositoryImpl(first, api, settings);
      var notes = FieldNoteRepositoryImpl(first, api, settings);
      network.offline = true;
      final customer = await customers.createCustomer(
        name: 'Readiness customer',
        contactInformation: 'Contact details',
      );
      customerId = customer.id;
      final site = await sites.createSite(
        customerId: customer.id,
        siteName: 'Readiness site',
        address: 'Site address',
      );
      final note = await notes.createNote(
        siteId: site.id,
        title: 'Offline inspection',
        status: 'DRAFT',
        description: 'Inspection description',
        location: '23.700000, 90.400000',
        dateTime: DateTime.utc(2040, 1, 2),
        photo: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+sH7sAAAAASUVORK5CYII=',
      );
      await first.close();
      first = await open('first');
      customers = CustomerRepositoryImpl(first, api, settings);
      notes = FieldNoteRepositoryImpl(first, api, settings);
      final sync = SyncRepositoryImpl(first, api, settings);
      expect((await notes.getNotes()).single.title, 'Offline inspection');
      expect(await sync.getPendingSyncCount(), 3);
      await expectLater(sync.syncAll(), throwsA(isA<http.ClientException>()));
      expect(await sync.getPendingSyncCount(), 3);

      network.offline = false;
      await sync.syncAll();
      expect(await sync.getPendingSyncCount(), 0);
      final response = await api.get('/api/notes/${note.id}');
      api.requireSuccess(response);
      final remote = jsonDecode(response.body) as Map<String, dynamic>;
      expect(remote['title'], 'Offline inspection');
      expect(remote['dateTime'], '2040-01-02T00:00:00Z');
      expect(remote['photo'], note.photo);

      // Simulate reinstall: empty preferences, no token, fresh local database, then log in again.
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final restored = SettingsLocalDataSource(
        await SharedPreferences.getInstance(),
      );
      await restored.initialize();
      await restored.setBaseUrl(settings.getBaseUrl());
      final restoredApi = ApiClient(restored);
      addTearDown(restoredApi.close);
      expect(restored.getToken(), isNull);
      await AuthRepositoryImpl(
        restoredApi,
        restored,
      ).login('ready$suffix', suffix);
      final second = await open('second');
      final otherNotes = FieldNoteRepositoryImpl(second, restoredApi, restored);
      final otherSync = SyncRepositoryImpl(second, restoredApi, restored);
      await otherSync.syncAll();
      expect((await otherNotes.getNotes()).single.id, note.id);
      expect((await otherNotes.getNotes()).single.photo, note.photo);
      expect(
        (await CustomerRepositoryImpl(
          second,
          restoredApi,
          restored,
        ).getCustomers()).single.contactInformation,
        'Contact details',
      );
      expect(
        (await SiteRepositoryImpl(
          second,
          restoredApi,
          restored,
        ).getSites()).single.address,
        'Site address',
      );
      await notes.updateNote(
        id: note.id,
        siteId: site.id,
        title: 'First device edit',
        status: 'COMPLETED',
      );
      await sync.syncAll();
      await otherNotes.updateNote(
        id: note.id,
        siteId: site.id,
        title: 'Second device offline edit',
        status: 'DRAFT',
      );
      await expectLater(otherSync.syncAll(), throwsStateError);
      expect(
        (await otherNotes.getNoteById(note.id))!.title,
        'Second device offline edit',
      );
      expect((await otherSync.getConflicts()).length, 1);
      await otherSync.resolveConflict(
        note.id,
        keepLocal: false,
        entityType: 'field_notes',
      );
      expect(
        (await otherNotes.getNoteById(note.id))!.title,
        'First device edit',
      );
      expect(await otherSync.getPendingSyncCount(), 0);

      network.offline = true;
      await customers.deleteCustomer(customer.id);
      expect(await notes.getNotes(), isEmpty);
      expect(await sync.getPendingSyncCount(), 1);
      network.offline = false;
      await sync.syncAll();
      await otherSync.syncAll();
      expect(await otherNotes.getNotes(), isEmpty);
      expect(await sync.getPendingSyncCount(), 0);
      expect(await otherSync.getPendingSyncCount(), 0);
    } finally {
      network.offline = false;
      if (customerId != null) {
        await api.delete('/api/customers/$customerId');
      }
      api.close();
      for (final db in databases) {
        if (db.isOpen) await db.close();
      }
      final root = Directory.systemTemp.absolute.path;
      if (directory.absolute.path.startsWith(
        '$root${Platform.pathSeparator}',
      )) {
        await directory.delete(recursive: true);
      }
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
