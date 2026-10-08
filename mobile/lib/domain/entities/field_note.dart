import 'package:equatable/equatable.dart';

import 'sync_status.dart';

class FieldNote extends Equatable {
  final int? serverVersion;
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
    this.serverVersion,
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
    int? serverVersion,
    String? id,
    String? siteId,
    String? siteName,
    String? customerId,
    String? customerName,
    String? title,
    String? description,
    bool clearDescription = false,
    String? location,
    bool clearLocation = false,
    DateTime? dateTime,
    String? status,
    String? photo,
    bool clearPhoto = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    SyncStatus? syncStatus,
  }) {
    return FieldNote(
      serverVersion: serverVersion ?? this.serverVersion,
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      location: clearLocation ? null : (location ?? this.location),
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      photo: clearPhoto ? null : (photo ?? this.photo),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [
    serverVersion,
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
