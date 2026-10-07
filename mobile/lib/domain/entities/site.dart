import 'package:equatable/equatable.dart';
import 'sync_status.dart';

class Site extends Equatable {
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
    String? id,
    String? customerId,
    String? customerName,
    String? siteName,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    SyncStatus? syncStatus,
  }) {
    return Site(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      siteName: siteName ?? this.siteName,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [id, customerId, customerName, siteName, address, createdAt, updatedAt, isDeleted, syncStatus];
}
