import '../../domain/entities/field_note.dart';
import '../../domain/entities/sync_status.dart';

class FieldNoteModel extends FieldNote {
  const FieldNoteModel({
    super.serverVersion,
    required super.id,
    required super.siteId,
    super.siteName,
    super.customerId,
    super.customerName,
    required super.title,
    super.description,
    super.location,
    required super.dateTime,
    required super.status,
    super.photo,
    required super.createdAt,
    required super.updatedAt,
    super.isDeleted,
    super.syncStatus,
  });

  factory FieldNoteModel.fromEntity(FieldNote entity) {
    return FieldNoteModel(
      serverVersion: entity.serverVersion,
      id: entity.id,
      siteId: entity.siteId,
      siteName: entity.siteName,
      customerId: entity.customerId,
      customerName: entity.customerName,
      title: entity.title,
      description: entity.description,
      location: entity.location,
      dateTime: entity.dateTime,
      status: entity.status,
      photo: entity.photo,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isDeleted: entity.isDeleted,
      syncStatus: entity.syncStatus,
    );
  }

  factory FieldNoteModel.fromDbMap(
    Map<String, dynamic> map, {
    String? siteName,
    String? customerId,
    String? customerName,
  }) {
    return FieldNoteModel(
      serverVersion: map['server_version'] as int?,
      id: map['id'] as String,
      siteId: map['site_id'] as String,
      siteName: siteName ?? map['site_name'] as String?,
      customerId: customerId ?? map['customer_id'] as String?,
      customerName: customerName ?? map['customer_name'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      location: map['location'] as String?,
      dateTime: DateTime.parse(map['date_time'] as String),
      status: map['status'] as String,
      photo: map['photo'] as String?,
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
      'site_id': siteId,
      'title': title,
      'description': description,
      'location': location,
      'date_time': dateTime.toUtc().toIso8601String(),
      'status': status,
      'photo': photo,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'sync_status': syncStatus.toDbString(),
    };
  }

  factory FieldNoteModel.fromJson(Map<String, dynamic> json) {
    return FieldNoteModel(
      serverVersion: (json['version'] as num?)?.toInt(),
      id: json['id'] as String,
      siteId: json['siteId'] as String,
      siteName: json['siteName'] as String?,
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      dateTime: json['dateTime'] != null
          ? DateTime.parse(json['dateTime'] as String)
          : DateTime.now(),
      status: json['status'] as String? ?? 'DRAFT',
      photo: json['photo'] as String?,
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
      'siteId': siteId,
      'title': title,
      'description': description,
      'location': location,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'status': status,
      'photo': photo,
      'deleted': isDeleted,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'baseVersion': serverVersion,
    };
  }
}
