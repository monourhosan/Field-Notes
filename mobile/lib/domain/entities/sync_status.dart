enum SyncStatus {
  pendingCreate,
  pendingUpdate,
  pendingDelete,
  synced;

  static SyncStatus fromString(String? value) {
    switch (value) {
      case 'PENDING_CREATE':
        return SyncStatus.pendingCreate;
      case 'PENDING_UPDATE':
        return SyncStatus.pendingUpdate;
      case 'PENDING_DELETE':
        return SyncStatus.pendingDelete;
      case 'SYNCED':
      default:
        return SyncStatus.synced;
    }
  }

  String toDbString() {
    switch (this) {
      case SyncStatus.pendingCreate:
        return 'PENDING_CREATE';
      case SyncStatus.pendingUpdate:
        return 'PENDING_UPDATE';
      case SyncStatus.pendingDelete:
        return 'PENDING_DELETE';
      case SyncStatus.synced:
        return 'SYNCED';
    }
  }
}
