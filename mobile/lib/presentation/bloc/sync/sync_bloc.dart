import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../domain/repositories/sync_repository.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncRepository _syncRepository;

  SyncBloc(this._syncRepository) : super(SyncInitial()) {
    on<CheckPendingSync>(_onCheckPendingSync, transformer: sequential());
    on<TriggerSync>(_onTriggerSync, transformer: droppable());
  }

  Future<void> _onCheckPendingSync(
    CheckPendingSync event,
    Emitter<SyncState> emit,
  ) async {
    if (state is SyncInProgress) return;
    try {
      final count = await _syncRepository.getPendingSyncCount();
      emit(SyncIdle(count));
    } catch (_) {
      emit(const SyncIdle(0));
    }
  }

  Future<void> _onTriggerSync(
    TriggerSync event,
    Emitter<SyncState> emit,
  ) async {
    try {
      final currentCount = await _syncRepository.getPendingSyncCount();
      emit(SyncInProgress(currentCount));
      await _syncRepository.syncAll();
      final newCount = await _syncRepository.getPendingSyncCount();
      emit(const SyncSuccess('Synchronization completed successfully'));
      emit(SyncIdle(newCount));
    } catch (e) {
      var count = 0;
      try {
        count = await _syncRepository.getPendingSyncCount();
      } catch (_) {}
      emit(SyncFailure(e.toString().replaceAll('Exception: ', ''), count));
    }
  }
}
