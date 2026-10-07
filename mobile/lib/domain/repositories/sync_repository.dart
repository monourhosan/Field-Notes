abstract class SyncRepository {
  Future<int> getPendingSyncCount();
  Future<void> syncAll();
}
