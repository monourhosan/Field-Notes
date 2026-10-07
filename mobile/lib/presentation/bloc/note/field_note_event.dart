import 'package:equatable/equatable.dart';

abstract class FieldNoteEvent extends Equatable {
  const FieldNoteEvent();
  @override
  List<Object?> get props => [];
}

class LoadFieldNotes extends FieldNoteEvent {
  final String? query;
  final String? siteId;
  final String? status;

  const LoadFieldNotes({this.query, this.siteId, this.status});

  @override
  List<Object?> get props => [query, siteId, status];
}

class CreateFieldNoteEvent extends FieldNoteEvent {
  final String siteId;
  final String title;
  final String? description;
  final String? location;
  final DateTime? dateTime;
  final String status;
  final String? photo;

  const CreateFieldNoteEvent({
    required this.siteId,
    required this.title,
    this.description,
    this.location,
    this.dateTime,
    required this.status,
    this.photo,
  });

  @override
  List<Object?> get props => [siteId, title, description, location, dateTime, status, photo];
}

class UpdateFieldNoteEvent extends FieldNoteEvent {
  final String id;
  final String siteId;
  final String title;
  final String? description;
  final String? location;
  final DateTime? dateTime;
  final String status;
  final String? photo;

  const UpdateFieldNoteEvent({
    required this.id,
    required this.siteId,
    required this.title,
    this.description,
    this.location,
    this.dateTime,
    required this.status,
    this.photo,
  });

  @override
  List<Object?> get props => [id, siteId, title, description, location, dateTime, status, photo];
}

class DeleteFieldNoteEvent extends FieldNoteEvent {
  final String id;
  const DeleteFieldNoteEvent(this.id);
  @override
  List<Object?> get props => [id];
}
