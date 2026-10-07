import 'package:equatable/equatable.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

class CheckPendingSync extends SyncEvent {}

class TriggerSync extends SyncEvent {}
