import 'package:hive/hive.dart';

part 'sync_models.g.dart';

@HiveType(typeId: 7)
class DeviceInfo extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime lastSyncAt;

  @HiveField(3)
  String syncMethod; // 'bluetooth', 'wifi', 'qr'

  @HiveField(4)
  bool isTrusted;

  @HiveField(5)
  DateTime pairedAt;

  DeviceInfo({
    required this.id,
    required this.name,
    required this.lastSyncAt,
    required this.syncMethod,
    this.isTrusted = false,
    required this.pairedAt,
  });

  DeviceInfo copyWith({
    String? name,
    DateTime? lastSyncAt,
    String? syncMethod,
    bool? isTrusted,
    DateTime? pairedAt,
  }) {
    return DeviceInfo(
      id: id,
      name: name ?? this.name,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncMethod: syncMethod ?? this.syncMethod,
      isTrusted: isTrusted ?? this.isTrusted,
      pairedAt: pairedAt ?? this.pairedAt,
    );
  }
}

@HiveType(typeId: 70)
class SyncLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String deviceId;

  @HiveField(2)
  DateTime syncedAt;

  @HiveField(3)
  int itemsSynced;

  @HiveField(4)
  String direction; // 'sent', 'received', 'both'

  @HiveField(5)
  bool success;

  @HiveField(6)
  String? errorMessage;

  SyncLog({
    required this.id,
    required this.deviceId,
    required this.syncedAt,
    required this.itemsSynced,
    required this.direction,
    this.success = true,
    this.errorMessage,
  });
}
