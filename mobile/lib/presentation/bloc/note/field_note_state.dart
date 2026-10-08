import 'package:equatable/equatable.dart';

import '../../../domain/entities/field_note.dart';

abstract class FieldNoteState extends Equatable {
  const FieldNoteState();
  @override
  List<Object?> get props => [];
}

class FieldNoteInitial extends FieldNoteState {}

class FieldNoteLoading extends FieldNoteState {}

class FieldNoteLoaded extends FieldNoteState {
  final List<FieldNote> notes;
  final String? currentQuery;
  final String? currentSiteId;
  final String? currentStatus;

  const FieldNoteLoaded(
    this.notes, {
    this.currentQuery,
    this.currentSiteId,
    this.currentStatus,
  });

  @override
  List<Object?> get props => [
    notes,
    currentQuery,
    currentSiteId,
    currentStatus,
  ];
}

class FieldNoteError extends FieldNoteState {
  final String message;
  const FieldNoteError(this.message);
  @override
  List<Object?> get props => [message];
}

class FieldNoteSaving extends FieldNoteState {}

class FieldNoteSaved extends FieldNoteState {}
