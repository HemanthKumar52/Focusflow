import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothSyncService {
  static final BluetoothSyncService _instance = BluetoothSyncService._();
  factory BluetoothSyncService() => _instance;
  BluetoothSyncService._();

  final _scanResults = <ScanResult>[];
  StreamSubscription<List<ScanResult>>? _scanSub;
  bool _isScanning = false;

  bool get isScanning => _isScanning;
  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);

  /// Check if Bluetooth is available and on
  Future<bool> isAvailable() async {
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) return false;
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  /// Start scanning for nearby BLE devices
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_isScanning) return;
    _scanResults.clear();
    _isScanning = true;

    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      _scanResults.clear();
      _scanResults.addAll(results);
    });

    await FlutterBluePlus.startScan(timeout: timeout);
    _isScanning = false;
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
    _isScanning = false;
  }

  /// Get list of discovered devices with names
  List<DiscoveredBluetoothDevice> getDiscoveredDevices() {
    return _scanResults
        .where((r) => r.device.platformName.isNotEmpty)
        .map((r) => DiscoveredBluetoothDevice(
              id: r.device.remoteId.str,
              name: r.device.platformName,
              rssi: r.rssi,
            ))
        .toList();
  }

  /// Dispose resources
  void dispose() {
    _scanSub?.cancel();
    _scanSub = null;
  }
}

class DiscoveredBluetoothDevice {
  final String id;
  final String name;
  final int rssi;

  DiscoveredBluetoothDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });

  /// Signal strength as a human-readable indicator
  String get signalStrength {
    if (rssi > -60) return 'Strong';
    if (rssi > -80) return 'Medium';
    return 'Weak';
  }
}
