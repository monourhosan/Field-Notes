import 'package:equatable/equatable.dart';
import 'sync_status.dart';

class FieldNote extends Equatable {
  final String id;
  final String siteId;
  final String? siteName;
  final String? customerId;
  final String? customerName;
  final String title;
  final String? description;
  final String? location;
  final DateTime dateTime;
  final String status;
  final String? photo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final SyncStatus syncStatus;

  const FieldNote({
    required this.id,
    required this.siteId,
    this.siteName,
    this.customerId,
    this.customerName,
    required this.title,
    this.description,
    this.location,
    required this.dateTime,
    required this.status,
    this.photo,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.synced,
  });

  FieldNote copyWith({
    String? id,
    String? siteId,
    String? siteName,
    String? customerId,
    String? customerName,
    String? title,
    String? description,
    String? location,
    DateTime? dateTime,
    String? status,
    String? photo,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    SyncStatus? syncStatus,
  }) {
    return FieldNote(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      photo: photo ?? this.photo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        siteId,
        siteName,
        customerId,
        customerName,
        title,
        description,
        location,
        dateTime,
        status,
        photo,
        createdAt,
        updatedAt,
        isDeleted,
        syncStatus,
      ];
}
