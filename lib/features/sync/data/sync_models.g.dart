// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_models.dart';

class DeviceInfoAdapter extends TypeAdapter<DeviceInfo> {
  @override
  final int typeId = 7;

  @override
  DeviceInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeviceInfo(
      id: fields[0] as String,
      name: fields[1] as String,
      lastSyncAt: fields[2] as DateTime,
      syncMethod: fields[3] as String,
      isTrusted: fields[4] as bool,
      pairedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DeviceInfo obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.lastSyncAt)
      ..writeByte(3)..write(obj.syncMethod)
      ..writeByte(4)..write(obj.isTrusted)
      ..writeByte(5)..write(obj.pairedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceInfoAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class SyncLogAdapter extends TypeAdapter<SyncLog> {
  @override
  final int typeId = 70;

  @override
  SyncLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncLog(
      id: fields[0] as String,
      deviceId: fields[1] as String,
      syncedAt: fields[2] as DateTime,
      itemsSynced: fields[3] as int,
      direction: fields[4] as String,
      success: fields[5] as bool,
      errorMessage: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncLog obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.deviceId)
      ..writeByte(2)..write(obj.syncedAt)
      ..writeByte(3)..write(obj.itemsSynced)
      ..writeByte(4)..write(obj.direction)
      ..writeByte(5)..write(obj.success)
      ..writeByte(6)..write(obj.errorMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncLogAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
