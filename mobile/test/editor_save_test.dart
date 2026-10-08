import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:field_notes_app/domain/entities/field_note.dart';
import 'package:field_notes_app/domain/entities/site.dart';
import 'package:field_notes_app/domain/repositories/field_note_repository.dart';
import 'package:field_notes_app/domain/repositories/site_repository.dart';
import 'package:field_notes_app/domain/repositories/settings_repository.dart';
import 'package:field_notes_app/presentation/bloc/note/field_note_bloc.dart';
import 'package:field_notes_app/presentation/bloc/site/site_bloc.dart';
import 'package:field_notes_app/presentation/bloc/settings/settings_bloc.dart';
import 'package:field_notes_app/presentation/screens/field_note_editor_screen.dart';

class DelayedNotes implements FieldNoteRepository {
  final saved = Completer<FieldNote>();
  String? savedStatus;
  @override
  Future<List<FieldNote>> getNotes({
    String? query,
    String? siteId,
    String? status,
  }) async => [];
  @override
  Future<FieldNote> createNote({
    required String siteId,
    required String title,
    String? description,
    String? location,
    DateTime? dateTime,
    required String status,
    String? photo,
  }) {
    savedStatus = status;
    return saved.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestSites implements SiteRepository {
  @override
  Future<List<Site>> getSites({String? customerId}) async => [
    Site(
      id: 'site',
      customerId: 'customer',
      siteName: 'Test site',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestSettings implements SettingsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> showEditor(WidgetTester tester, {String siteId = 'site'}) async {
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => FieldNoteBloc(DelayedNotes())),
        BlocProvider(create: (_) => SiteBloc(TestSites())),
        BlocProvider(
          create: (_) =>
              SettingsBloc(TestSettings(), initialDefaultStatus: 'COMPLETED'),
        ),
      ],
      child: MaterialApp(
        home: FieldNoteEditorScreen(preselectedSiteId: siteId),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, 'Retain this note');
}

void main() {
  testWidgets('an unavailable preselected site does not crash or save', (
    tester,
  ) async {
    await showEditor(tester, siteId: 'deleted-site');
    expect(tester.takeException(), isNull);
    final save = find.text('Record Field Note');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Please select a site'), findsOneWidget);
    expect(find.text('Retain this note'), findsOneWidget);
    expect(find.text('Saving...'), findsNothing);
  });
  for (final reason in ['disabled', 'denied', 'deniedForever']) {
    testWidgets('GPS $reason preserves the note and restores the button', (
      tester,
    ) async {
      const channel = MethodChannel('flutter.baseflow.com/geolocator');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        switch (call.method) {
          case 'isLocationServiceEnabled':
            return reason != 'disabled';
          case 'checkPermission':
            return reason == 'deniedForever' ? 1 : 0;
          case 'requestPermission':
            return 0;
          default:
            throw PlatformException(code: 'unexpected', message: call.method);
        }
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await showEditor(tester);
      await tester.ensureVisible(find.byIcon(Icons.my_location));
      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Retain this note'), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final source in ['Take Photo (Camera)', 'Choose from Gallery']) {
    testWidgets('$source handles permission failure without losing input', (
      tester,
    ) async {
      const channel = MethodChannel('plugins.flutter.io/image_picker');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(
          code: 'access_denied',
          message: 'Permission denied',
        ),
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await showEditor(tester);
      final attach = find.text('Attach Photo (Camera / Gallery)');
      await tester.ensureVisible(attach);
      await tester.tap(attach);
      await tester.pumpAndSettle();
      await tester.tap(find.text(source));
      await tester.pumpAndSettle();
      expect(find.textContaining('Image selection failed:'), findsOneWidget);
      expect(find.text('Retain this note'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final succeed in [true, false]) {
    testWidgets(
      'editor waits for storage and ${succeed ? "closes on success" : "retains input on failure"}',
      (tester) async {
        final repo = DelayedNotes();
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => FieldNoteBloc(repo)),
              BlocProvider(create: (_) => SiteBloc(TestSites())),
              BlocProvider(
                create: (_) => SettingsBloc(
                  TestSettings(),
                  initialDefaultStatus: 'COMPLETED',
                ),
              ),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FieldNoteEditorScreen(
                          preselectedSiteId: 'site',
                        ),
                      ),
                    ),
                    child: const Text('Open editor'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open editor'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'My inspection',
        );
        final save = find.text('Record Field Note');
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pump();
        expect(find.byType(FieldNoteEditorScreen), findsOneWidget);
        expect(find.text('Saving...'), findsOneWidget);
        expect(repo.savedStatus, 'COMPLETED');
        if (succeed) {
          repo.saved.complete(
            FieldNote(
              id: 'note',
              siteId: 'site',
              title: 'My inspection',
              status: 'COMPLETED',
              dateTime: DateTime.utc(2026),
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
            ),
          );
        } else {
          repo.saved.completeError(Exception('Disk full'));
        }
        await tester.pumpAndSettle();
        expect(
          find.byType(FieldNoteEditorScreen),
          succeed ? findsNothing : findsOneWidget,
        );
        if (!succeed) expect(find.text('My inspection'), findsOneWidget);
      },
    );
  }
}
