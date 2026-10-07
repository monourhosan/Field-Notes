import 'package:equatable/equatable.dart';
import 'sync_status.dart';

class Customer extends Equatable {
  final String id;
  final int userId;
  final String name;
  final String? contactInformation;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final SyncStatus syncStatus;

  const Customer({
    required this.id,
    required this.userId,
    required this.name,
    this.contactInformation,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.synced,
  });

  Customer copyWith({
    String? id,
    int? userId,
    String? name,
    String? contactInformation,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    SyncStatus? syncStatus,
  }) {
    return Customer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      contactInformation: contactInformation ?? this.contactInformation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [id, userId, name, contactInformation, createdAt, updatedAt, isDeleted, syncStatus];
}
