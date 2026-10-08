import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_notes_app/data/local/database_helper.dart';
import 'package:field_notes_app/data/local/settings_local_data_source.dart';
import 'package:field_notes_app/domain/repositories/auth_repository.dart';
import 'package:field_notes_app/domain/repositories/customer_repository.dart';
import 'package:field_notes_app/domain/repositories/site_repository.dart';
import 'package:field_notes_app/domain/repositories/field_note_repository.dart';
import 'package:field_notes_app/domain/repositories/sync_repository.dart';
import 'package:field_notes_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:field_notes_app/presentation/bloc/customer/customer_bloc.dart';
import 'package:field_notes_app/presentation/bloc/site/site_bloc.dart';
import 'package:field_notes_app/presentation/bloc/site/site_event.dart';
import 'package:field_notes_app/presentation/bloc/note/field_note_bloc.dart';
import 'package:field_notes_app/presentation/bloc/note/field_note_event.dart';
import 'package:field_notes_app/presentation/bloc/sync/sync_bloc.dart';
import 'package:field_notes_app/presentation/widgets/sync_coordinator.dart';

class EmptyCustomers implements CustomerRepository {
  @override
  Future<List<Never>> getCustomers() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class EmptySites implements SiteRepository {
  String? lastCustomerId;
  @override
  Future<List<Never>> getSites({String? customerId}) async {
    lastCustomerId = customerId;
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class EmptyNotes implements FieldNoteRepository {
  String? lastQuery;
  String? lastSiteId;
  String? lastStatus;
  @override
  Future<List<Never>> getNotes({
    String? query,
    String? siteId,
    String? status,
  }) async {
    lastQuery = query;
    lastSiteId = siteId;
    lastStatus = status;
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class UnusedAuth implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ControlledSync implements SyncRepository {
  int calls = 0;
  Completer<void>? gate;
  @override
  Future<int> getPendingSyncCount() async => 0;
  @override
  Future<void> syncAll() async {
    calls++;
    await gate?.future;
  }
}

void main() {
  late SettingsLocalDataSource settings;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    settings = SettingsLocalDataSource(await SharedPreferences.getInstance());
    await settings.initialize();
    await settings.saveAuthData(
      token: 'test',
      userId: 1,
      username: 'test',
      email: 'test@example.com',
    );
  });
  testWidgets(
    'restored sessions sync, queued edits resync, reconnection and resume trigger sync',
    (tester) async {
      final network = StreamController<List<ConnectivityResult>>.broadcast();
      final repository = ControlledSync()..gate = Completer<void>();
      final sites = EmptySites();
      final notes = EmptyNotes();
      final siteBloc = SiteBloc(sites)
        ..add(const LoadSites(customerId: 'filtered-customer'));
      final noteBloc = FieldNoteBloc(notes)
        ..add(
          const LoadFieldNotes(
            query: 'voltage',
            siteId: 'filtered-site',
            status: 'COMPLETED',
          ),
        );
      final helper = DatabaseHelper.instance;
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => AuthBloc(UnusedAuth())),
            BlocProvider(create: (_) => CustomerBloc(EmptyCustomers())),
            BlocProvider(create: (_) => siteBloc),
            BlocProvider(create: (_) => noteBloc),
            BlocProvider(create: (_) => SyncBloc(repository)),
          ],
          child: MaterialApp(
            home: SyncCoordinator(
              dbHelper: helper,
              settings: settings,
              connectivityChanges: network.stream,
              child: const Scaffold(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
      expect(repository.calls, 1);
      helper.notifyChange();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(repository.calls, 1);
      repository.gate!.complete();
      repository.gate = null;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
      expect(repository.calls, 2);
      expect(sites.lastCustomerId, 'filtered-customer');
      expect(notes.lastQuery, 'voltage');
      expect(notes.lastSiteId, 'filtered-site');
      expect(notes.lastStatus, 'COMPLETED');
      network.add([ConnectivityResult.wifi]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
      expect(repository.calls, 3);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      helper.notifyChange();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(repository.calls, 3);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
      expect(repository.calls, 4);
      await settings.clearAuthData();
      helper.notifyChange();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(repository.calls, 4);
      await tester.pumpWidget(const SizedBox());
      await network.close();
    },
  );
}
