import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  Database? _database;
  Future<Database>? _opening;
  String _filename = 'field_notes.db';
  bool _importLegacy = false;
  Future<void> useServer(String origin) async {
    final prefs = await SharedPreferences.getInstance();
    final previousOrigin = prefs.getString('legacy_database_origin');
    _importLegacy = previousOrigin == null || previousOrigin == origin;
    if (previousOrigin == null) {
      await prefs.setString('legacy_database_origin', origin);
    }
    final next = 'field_notes_${sha256.convert(utf8.encode(origin))}.db';
    if (_filename == next) return;
    await close();
    _filename = next;
  }

  final _changes = StreamController<void>.broadcast();
  Stream<void> get changes => _changes.stream;
  void notifyChange() => _changes.add(null);
  DatabaseHelper._init();
  DatabaseHelper.forTesting(Database database) : _database = database;
  Future<Database> get database async =>
      _database ??= await (_opening ??= _initDB());

  Future<Database> _initDB() async {
    String filePath;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      filePath = _filename;
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      filePath = join((await getApplicationSupportDirectory()).path, _filename);
    } else {
      filePath = join(await getDatabasesPath(), _filename);
    }
    // Import the old database into exactly one server namespace, preserving its outbox.
    if (_importLegacy && !await databaseExists(filePath)) {
      final candidates = <String>[
        kIsWeb ? 'field_notes.db' : join(dirname(filePath), 'field_notes.db'),
      ];
      if (!kIsWeb) {
        candidates.add(
          join(
            (await getApplicationDocumentsDirectory()).path,
            'field_notes.db',
          ),
        );
      }
      for (final legacy in candidates) {
        if (await databaseExists(legacy)) {
          final bytes = await databaseFactory.readDatabaseBytes(legacy);
          await databaseFactory.writeDatabaseBytes(filePath, bytes);
          break;
        }
      }
    }
    return openDatabase(
      filePath,
      version: 3,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: createSchema,
      onUpgrade: migrateSchema,
    );
  }

  static Future<void> createSchema(Database db, int version) async {
    await _tables(db, '');
    await _extras(db);
  }

  static Future<void> _tables(Database db, String suffix) async {
    await db.execute(
      '''CREATE TABLE customers$suffix (
      id TEXT PRIMARY KEY, user_id INTEGER NOT NULL, name TEXT NOT NULL,
      contact_information TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0, sync_status TEXT NOT NULL, server_version INTEGER, local_revision INTEGER NOT NULL DEFAULT 0)''',
    );
    await db.execute(
      '''CREATE TABLE sites$suffix (
      id TEXT PRIMARY KEY, customer_id TEXT NOT NULL REFERENCES customers$suffix(id) ON DELETE CASCADE,
      site_name TEXT NOT NULL, address TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0, sync_status TEXT NOT NULL, server_version INTEGER, local_revision INTEGER NOT NULL DEFAULT 0)''',
    );
    await db.execute(
      '''CREATE TABLE field_notes$suffix (
      id TEXT PRIMARY KEY, site_id TEXT NOT NULL REFERENCES sites$suffix(id) ON DELETE CASCADE,
      title TEXT NOT NULL, description TEXT, location TEXT, date_time TEXT NOT NULL, status TEXT NOT NULL,
      photo TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0, sync_status TEXT NOT NULL, server_version INTEGER, local_revision INTEGER NOT NULL DEFAULT 0)''',
    );
  }

  static Future<void> _extras(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS sync_metadata (user_id INTEGER PRIMARY KEY, snapshot_tag TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_user ON customers(user_id, is_deleted, sync_status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sites_customer ON sites(customer_id, is_deleted)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notes_site_status ON field_notes(site_id, status, is_deleted)',
    );
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS sync_conflicts (
      id TEXT NOT NULL, user_id INTEGER NOT NULL, entity_type TEXT NOT NULL,
      local_data TEXT NOT NULL, server_data TEXT, message TEXT NOT NULL, created_at TEXT NOT NULL, PRIMARY KEY(user_id,entity_type,id))''',
    );
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS recovered_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT, entity_type TEXT NOT NULL, data TEXT NOT NULL)''',
    );
  }

  static Future<void> migrateSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _tables(db, '_new');
      await db.execute(
        '''CREATE TABLE IF NOT EXISTS recovered_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT, entity_type TEXT NOT NULL, data TEXT NOT NULL)''',
      );
      for (final table in ['customers', 'sites', 'field_notes']) {
        final rows = await db.query(table);
        for (final row in rows) {
          final parentTable = table == 'sites' ? 'customers_new' : 'sites_new';
          final parentKey = table == 'sites' ? 'customer_id' : 'site_id';
          if (table != 'customers' &&
              (await db.query(
                parentTable,
                where: 'id = ?',
                whereArgs: [row[parentKey]],
              )).isEmpty) {
            await db.insert('recovered_records', {
              'entity_type': table,
              'data': jsonEncode(row),
            });
          } else {
            await db.insert('${table}_new', row);
          }
        }
      }
      for (final table in ['field_notes', 'sites', 'customers']) {
        await db.execute('DROP TABLE $table');
      }
      for (final table in ['customers', 'sites', 'field_notes']) {
        await db.execute('ALTER TABLE ${table}_new RENAME TO $table');
      }
      await _extras(db);
    }
    if (oldVersion < 3) {
      await db.execute(
        """CREATE TABLE sync_conflicts_v3 (
        id TEXT NOT NULL,user_id INTEGER NOT NULL,entity_type TEXT NOT NULL,local_data TEXT NOT NULL,
        server_data TEXT,message TEXT NOT NULL,created_at TEXT NOT NULL,PRIMARY KEY(user_id,entity_type,id))""",
      );
      await db.execute(
        'INSERT INTO sync_conflicts_v3 SELECT * FROM sync_conflicts',
      );
      await db.execute('DROP TABLE sync_conflicts');
      await db.execute(
        'ALTER TABLE sync_conflicts_v3 RENAME TO sync_conflicts',
      );
      await _extras(db);
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
    _opening = null;
  }
}
