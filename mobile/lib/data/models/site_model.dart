import '../../domain/entities/site.dart';
import '../../domain/entities/sync_status.dart';

class SiteModel extends Site {
  const SiteModel({
    super.serverVersion,
    required super.id,
    required super.customerId,
    super.customerName,
    required super.siteName,
    super.address,
    required super.createdAt,
    required super.updatedAt,
    super.isDeleted,
    super.syncStatus,
  });

  factory SiteModel.fromEntity(Site entity) {
    return SiteModel(
      serverVersion: entity.serverVersion,
      id: entity.id,
      customerId: entity.customerId,
      customerName: entity.customerName,
      siteName: entity.siteName,
      address: entity.address,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isDeleted: entity.isDeleted,
      syncStatus: entity.syncStatus,
    );
  }

  factory SiteModel.fromDbMap(
    Map<String, dynamic> map, {
    String? customerName,
  }) {
    return SiteModel(
      serverVersion: map['server_version'] as int?,
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      customerName: customerName ?? map['customer_name'] as String?,
      siteName: map['site_name'] as String,
      address: map['address'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDeleted: (map['is_deleted'] as int) == 1,
      syncStatus: SyncStatus.fromString(map['sync_status'] as String?),
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'server_version': serverVersion,
      'id': id,
      'customer_id': customerId,
      'site_name': siteName,
      'address': address,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'sync_status': syncStatus.toDbString(),
    };
  }

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      serverVersion: (json['version'] as num?)?.toInt(),
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String?,
      siteName: json['siteName'] as String,
      address: json['address'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      isDeleted: json['deleted'] == true,
      syncStatus: SyncStatus.synced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'siteName': siteName,
      'address': address,
      'deleted': isDeleted,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'baseVersion': serverVersion,
    };
  }
}
