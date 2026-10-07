import '../../domain/entities/customer.dart';
import '../../domain/entities/sync_status.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.userId,
    required super.name,
    super.contactInformation,
    required super.createdAt,
    required super.updatedAt,
    super.isDeleted,
    super.syncStatus,
  });

  factory CustomerModel.fromEntity(Customer entity) {
    return CustomerModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      contactInformation: entity.contactInformation,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isDeleted: entity.isDeleted,
      syncStatus: entity.syncStatus,
    );
  }

  factory CustomerModel.fromDbMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as String,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      contactInformation: map['contact_information'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDeleted: (map['is_deleted'] as int) == 1,
      syncStatus: SyncStatus.fromString(map['sync_status'] as String?),
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'contact_information': contactInformation,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'sync_status': syncStatus.toDbString(),
    };
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      userId: json['userId'] != null ? (json['userId'] as num).toInt() : 0,
      name: json['name'] as String,
      contactInformation: json['contactInformation'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
      isDeleted: json['deleted'] == true,
      syncStatus: SyncStatus.synced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contactInformation': contactInformation,
      'deleted': isDeleted,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}
