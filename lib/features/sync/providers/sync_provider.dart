import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/services/database_service.dart';
import '../data/sync_models.dart';
import '../services/sync_service.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum SyncStatus { idle, discovering, syncing, error }

// ---------------------------------------------------------------------------
// Device Notifier
// ---------------------------------------------------------------------------

class DeviceNotifier extends StateNotifier<List<DeviceInfo>> {
  DeviceNotifier() : super([]) {
    _load();
  }

  void _load() {
    final box = Hive.box<DeviceInfo>(DatabaseService.devicesBox);
    state = box.values.toList();
  }

  Future<void> addDevice(DeviceInfo device) async {
    final box = Hive.box<DeviceInfo>(DatabaseService.devicesBox);
    await box.put(device.id, device);
    state = [...state, device];
  }

  Future<void> removeDevice(String id) async {
    final box = Hive.box<DeviceInfo>(DatabaseService.devicesBox);
    await box.delete(id);
    state = state.where((d) => d.id != id).toList();
  }

  Future<void> updateDevice(DeviceInfo device) async {
    final box = Hive.box<DeviceInfo>(DatabaseService.devicesBox);
    await box.put(device.id, device);
    state = [
      for (final d in state)
        if (d.id == device.id) device else d,
    ];
  }

  void refresh() => _load();
}

// ---------------------------------------------------------------------------
// Sync Log Notifier
// ---------------------------------------------------------------------------

class SyncLogNotifier extends StateNotifier<List<SyncLog>> {
  SyncLogNotifier() : super([]) {
    _load();
  }

  void _load() {
    final box = Hive.box<SyncLog>(DatabaseService.syncLogsBox);
    final logs = box.values.toList()
      ..sort((a, b) => b.syncedAt.compareTo(a.syncedAt));
    state = logs;
  }

  void refresh() => _load();
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final deviceProvider =
    StateNotifierProvider<DeviceNotifier, List<DeviceInfo>>((ref) {
  return DeviceNotifier();
});

final syncLogProvider =
    StateNotifierProvider<SyncLogNotifier, List<SyncLog>>((ref) {
  return SyncLogNotifier();
});

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

final discoveredDevicesProvider =
    StateProvider<List<DiscoveredDevice>>((ref) => []);

final syncServiceProvider = Provider<SyncService>((ref) => SyncService());
