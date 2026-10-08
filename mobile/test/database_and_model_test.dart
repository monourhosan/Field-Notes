import 'package:flutter_test/flutter_test.dart';
import 'package:field_notes_app/data/models/customer_model.dart';
import 'package:field_notes_app/data/models/field_note_model.dart';
import 'package:field_notes_app/domain/entities/sync_status.dart';

void main() {
  group('Models & Offline Serialization', () {
    test('CustomerModel serializes to and from DB map correctly', () {
      final now = DateTime.now();
      final customer = CustomerModel(
        id: 'cust-uuid-1',
        userId: 42,
        name: 'Metro Water Dept',
        contactInformation: 'info@metrowater.gov',
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
        syncStatus: SyncStatus.pendingCreate,
      );

      final dbMap = customer.toDbMap();
      expect(dbMap['id'], 'cust-uuid-1');
      expect(dbMap['name'], 'Metro Water Dept');
      expect(dbMap['sync_status'], 'PENDING_CREATE');
      expect(dbMap['is_deleted'], 0);

      final restored = CustomerModel.fromDbMap(dbMap);
      expect(restored.id, customer.id);
      expect(restored.name, customer.name);
      expect(restored.syncStatus, SyncStatus.pendingCreate);
    });

    test('FieldNoteModel serializes to and from DB map correctly', () {
      final now = DateTime.now();
      final note = FieldNoteModel(
        id: 'note-uuid-9',
        siteId: 'site-uuid-2',
        title: 'Safety Valve Test',
        description: 'Pressure stable at 45 PSI',
        location: '37.7749,-122.4194',
        dateTime: now,
        status: 'COMPLETED',
        photo: 'data:image/jpeg;base64,abc123',
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
        syncStatus: SyncStatus.pendingUpdate,
      );

      final dbMap = note.toDbMap();
      expect(dbMap['id'], 'note-uuid-9');
      expect(dbMap['status'], 'COMPLETED');
      expect(dbMap['sync_status'], 'PENDING_UPDATE');

      final restored = FieldNoteModel.fromDbMap(
        dbMap,
        siteName: 'Plant 4',
        customerName: 'Energy Inc',
      );
      expect(restored.id, note.id);
      expect(restored.title, note.title);
      expect(restored.siteName, 'Plant 4');
      expect(restored.customerName, 'Energy Inc');
      expect(restored.syncStatus, SyncStatus.pendingUpdate);
    });

    test('SyncStatus enum converts accurately', () {
      expect(SyncStatus.fromString('PENDING_CREATE'), SyncStatus.pendingCreate);
      expect(SyncStatus.fromString('PENDING_UPDATE'), SyncStatus.pendingUpdate);
      expect(SyncStatus.fromString('PENDING_DELETE'), SyncStatus.pendingDelete);
      expect(SyncStatus.fromString('SYNCED'), SyncStatus.synced);
      expect(SyncStatus.fromString('UNKNOWN'), SyncStatus.synced);
    });
  });
}
