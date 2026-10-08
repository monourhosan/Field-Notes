import 'package:equatable/equatable.dart';

import 'sync_status.dart';

class Site extends Equatable {
  final int? serverVersion;
  final String id;
  final String customerId;
  final String? customerName;
  final String siteName;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final SyncStatus syncStatus;

  const Site({
    this.serverVersion,
    required this.id,
    required this.customerId,
    this.customerName,
    required this.siteName,
    this.address,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.synced,
  });

  Site copyWith({
    int? serverVersion,
    String? id,
    String? customerId,
    String? customerName,
    String? siteName,
    String? address,
    bool clearAddress = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    SyncStatus? syncStatus,
  }) {
    return Site(
      serverVersion: serverVersion ?? this.serverVersion,
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      siteName: siteName ?? this.siteName,
      address: clearAddress ? null : (address ?? this.address),
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
    customerId,
    customerName,
    siteName,
    address,
    createdAt,
    updatedAt,
    isDeleted,
    syncStatus,
  ];
}
