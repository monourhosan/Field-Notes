import 'package:equatable/equatable.dart';

abstract class SyncState extends Equatable {
  const SyncState();
  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {}

class SyncInProgress extends SyncState {
  final int pendingCount;
  const SyncInProgress(this.pendingCount);
  @override
  List<Object?> get props => [pendingCount];
}

class SyncIdle extends SyncState {
  final int pendingCount;
  const SyncIdle(this.pendingCount);
  @override
  List<Object?> get props => [pendingCount];
}

class SyncSuccess extends SyncState {
  final String message;
  const SyncSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class SyncFailure extends SyncState {
  final String message;
  final int pendingCount;
  const SyncFailure(this.message, this.pendingCount);
  @override
  List<Object?> get props => [message, pendingCount];
}
