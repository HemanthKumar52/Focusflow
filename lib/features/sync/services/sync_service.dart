import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/database_service.dart';
import '../data/sync_models.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class DiscoveredDevice {
  final String id;
  final String name;
  final String method; // 'bluetooth', 'wifi', 'qr'
  final int signalStrength; // 0-100

  const DiscoveredDevice({
    required this.id,
    required this.name,
    required this.method,
    required this.signalStrength,
  });
}

class SyncResult {
  final int sent;
  final int received;
  final int conflicts;
  final bool success;

  const SyncResult({
    required this.sent,
    required this.received,
    required this.conflicts,
    required this.success,
  });
}

// ---------------------------------------------------------------------------
// Sync Service
// ---------------------------------------------------------------------------

class SyncService {
  static const _uuid = Uuid();

  /// Stub — scans for nearby devices via Bluetooth / Wi-Fi Direct.
  /// Returns an empty list until platform plugins are integrated.
  Future<List<DiscoveredDevice>> discoverDevices() async {
    // TODO: integrate nearby_connections or flutter_blue_plus
    await Future<void>.delayed(const Duration(seconds: 2));
    return [];
  }

  /// Pairs with a discovered device and stores it as trusted.
  Future<bool> pair(String deviceId, {String name = 'Unknown', String method = 'wifi'}) async {
    try {
      final box = Hive.box<DeviceInfo>(DatabaseService.devicesBox);
      final device = DeviceInfo(
        id: deviceId,
        name: name,
        lastSyncAt: DateTime.now(),
        syncMethod: method,
        isTrusted: true,
        pairedAt: DateTime.now(),
      );
      await box.put(deviceId, device);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Removes a paired device.
  Future<void> unpair(String deviceId) async {
    final box = Hive.box<DeviceInfo>(DatabaseService.devicesBox);
    await box.delete(deviceId);
  }

  /// Syncs data with a specific paired device.
  Future<SyncResult> syncWithDevice(String deviceId) async {
    // TODO: implement real data transfer via nearby_connections
    final payload = exportSyncPayload();
    final sent = payload.values.fold<int>(
      0,
      (sum, v) => sum + ((v is Map) ? v.length : 0),
    );

    // Record sync log
    final logBox = Hive.box<SyncLog>(DatabaseService.syncLogsBox);
    final log = SyncLog(
      id: _uuid.v4(),
      deviceId: deviceId,
      syncedAt: DateTime.now(),
      itemsSynced: sent,
      direction: 'both',
      success: true,
    );
    await logBox.put(log.id, log);

    // Update device last sync time
    final devBox = Hive.box<DeviceInfo>(DatabaseService.devicesBox);
    final device = devBox.get(deviceId);
    if (device != null) {
      device.lastSyncAt = DateTime.now();
      await device.save();
    }

    return SyncResult(sent: sent, received: 0, conflicts: 0, success: true);
  }

  /// Exports all Hive data as a JSON-serialisable map.
  Map<String, dynamic> exportSyncPayload() {
    final payload = <String, dynamic>{};

    payload['todos'] = _boxToMap(DatabaseService.todos);
    payload['notes'] = _boxToMap(DatabaseService.notes);
    payload['notebooks'] = _boxToMap(DatabaseService.notebooks);
    payload['tasks'] = _boxToMap(DatabaseService.tasks);
    payload['projects'] = _boxToMap(DatabaseService.projects);
    payload['studyPlans'] = _boxToMap(DatabaseService.studyPlans);
    payload['studySessions'] = _boxToMap(DatabaseService.studySessions);
    payload['voiceNotes'] = _boxToMap(DatabaseService.voiceNotes);
    payload['habits'] = _boxToMap(DatabaseService.habits);
    payload['habitEntries'] = _boxToMap(DatabaseService.habitEntries);

    return payload;
  }

  /// Imports and merges a sync payload using last-write-wins conflict
  /// resolution.
  Future<void> importSyncPayload(Map<String, dynamic> payload) async {
    for (final entry in payload.entries) {
      final boxName = entry.key;
      final items = entry.value;
      if (items is! Map) continue;

      // Open the raw box to write values by key
      final box = await Hive.openBox(boxName);

      for (final itemEntry in items.entries) {
        final key = itemEntry.key as String;
        final remoteValue = itemEntry.value;

        final localValue = box.get(key);
        if (localValue == null) {
          // No conflict — insert remote
          await box.put(key, remoteValue);
        } else {
          // Conflict resolution: last-write-wins
          final resolved = resolveConflict(localValue, remoteValue);
          await box.put(key, resolved);
        }
      }
    }
  }

  /// Resolves a conflict between a local and remote item by picking the one
  /// with the latest timestamp (last-write-wins).
  dynamic resolveConflict(dynamic local, dynamic remote) {
    DateTime? localTime;
    DateTime? remoteTime;

    if (local is HiveObject) {
      localTime = _extractTimestamp(local);
    }
    if (remote is HiveObject) {
      remoteTime = _extractTimestamp(remote);
    }

    if (localTime != null && remoteTime != null) {
      return remoteTime.isAfter(localTime) ? remote : local;
    }

    // If we can't determine timestamps, prefer remote (incoming) data
    return remote;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _boxToMap(Box box) {
    final map = <String, dynamic>{};
    for (final key in box.keys) {
      map[key.toString()] = box.get(key);
    }
    return map;
  }

  DateTime? _extractTimestamp(dynamic obj) {
    // Try common field names via reflection-free approach
    try {
      // ignore: avoid_dynamic_calls
      return obj.createdAt as DateTime?;
    } catch (_) {
      return null;
    }
  }
}
