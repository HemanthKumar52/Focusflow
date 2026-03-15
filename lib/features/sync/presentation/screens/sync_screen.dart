import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/neu_badge.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_card.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../../../core/widgets/neu_icon_button.dart';
import '../../data/sync_models.dart';
import '../../providers/sync_provider.dart';
import '../../services/bluetooth_sync_service.dart';
import '../../services/sync_service.dart';
import '../../services/wifi_sync_service.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  // Bluetooth state
  bool _bluetoothEnabled = false;
  bool _bluetoothScanning = false;
  String? _bluetoothError;
  List<DiscoveredBluetoothDevice> _btDevices = [];

  // WiFi state
  bool _wifiServerRunning = false;
  String? _wifiIp;
  bool _wifiConnecting = false;

  // Services
  final _btService = BluetoothSyncService();
  final _wifiService = WifiSyncService();

  @override
  void dispose() {
    _btService.dispose();
    _wifiService.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Bluetooth Actions
  // ---------------------------------------------------------------------------

  Future<void> _toggleBluetooth(bool value) async {
    setState(() {
      _bluetoothEnabled = value;
      _bluetoothError = null;
    });

    if (value) {
      final available = await _btService.isAvailable();
      if (!available) {
        setState(() {
          _bluetoothEnabled = false;
          _bluetoothError = 'Bluetooth is not available or turned off. '
              'Please enable Bluetooth in your device settings.';
        });
        return;
      }
      await _startBluetoothScan();
    } else {
      await _btService.stopScan();
      setState(() {
        _btDevices = [];
        _bluetoothScanning = false;
      });
    }
  }

  Future<void> _startBluetoothScan() async {
    setState(() {
      _bluetoothScanning = true;
      _btDevices = [];
      _bluetoothError = null;
    });

    try {
      await _btService.startScan(timeout: const Duration(seconds: 10));
      setState(() {
        _btDevices = _btService.getDiscoveredDevices();
        _bluetoothScanning = false;
      });
    } catch (e) {
      setState(() {
        _bluetoothScanning = false;
        _bluetoothError = 'Scan failed: $e';
      });
    }
  }

  Future<void> _pairBluetoothDevice(DiscoveredBluetoothDevice device) async {
    final service = ref.read(syncServiceProvider);
    final ok = await service.pair(
      device.id,
      name: device.name,
      method: 'bluetooth',
    );
    if (ok && mounted) {
      ref.read(deviceProvider.notifier).refresh();
      _showSnackBar('Paired with ${device.name}');
    }
  }

  // ---------------------------------------------------------------------------
  // WiFi Actions
  // ---------------------------------------------------------------------------

  Future<void> _fetchWifiIp() async {
    final ip = await _wifiService.getWifiIp();
    if (mounted) {
      setState(() => _wifiIp = ip);
    }
  }

  Future<void> _toggleWifiServer() async {
    if (_wifiServerRunning) {
      await _wifiService.stopServer();
      setState(() => _wifiServerRunning = false);
    } else {
      final started = await _wifiService.startSyncServer();
      if (mounted) {
        setState(() => _wifiServerRunning = started);
        if (started) {
          setState(() => _wifiIp = _wifiService.localIp);
          _showSnackBar(
              'Sync server running on ${_wifiService.localIp}:${_wifiService.port}');
        } else {
          _showSnackBar('Failed to start sync server. Check WiFi connection.');
        }
      }
    }
  }

  Future<void> _connectToDevice() async {
    final controller = TextEditingController();
    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Connect to Device'),
        content: Padding(
          padding: const EdgeInsets.only(top: AppSizes.md),
          child: Column(
            children: [
              const Text(
                'Enter the IP address shown on the other device:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: AppSizes.sm),
              CupertinoTextField(
                controller: controller,
                placeholder: '192.168.1.100',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Connect'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    // Parse IP and optional port
    String ip = result;
    int port = 8642;
    if (result.contains(':')) {
      final parts = result.split(':');
      ip = parts[0];
      port = int.tryParse(parts[1]) ?? 8642;
    }

    setState(() => _wifiConnecting = true);
    final success = await _wifiService.syncWithDevice(ip, port);
    if (mounted) {
      setState(() => _wifiConnecting = false);
      if (success) {
        ref.read(syncLogProvider.notifier).refresh();
        _showSnackBar('Sync completed successfully!');
      } else {
        _showSnackBar('Failed to connect. Check the IP and ensure the '
            'other device is running its sync server.');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // QR Code Actions
  // ---------------------------------------------------------------------------

  void _showMyQr() {
    final ip = _wifiService.localIp ?? _wifiIp;
    final port = _wifiService.port;

    if (ip == null) {
      _showSnackBar('Could not determine WiFi IP. Start the sync server first or connect to WiFi.');
      return;
    }

    final qrData = '$ip:$port';

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('My Sync QR Code'),
        content: Padding(
          padding: const EdgeInsets.only(top: AppSizes.md),
          child: Column(
            children: [
              Container(
                width: 220,
                height: 220,
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                qrData,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              const Text(
                'Scan this QR code from the other device to connect.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _scanQr() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _QrScannerPage(
          onScanned: (data) async {
            if (!mounted) return;
            Navigator.of(context).pop();

            // Parse IP:port from QR data
            String ip = data;
            int port = 8642;
            if (data.contains(':')) {
              final parts = data.split(':');
              ip = parts[0];
              port = int.tryParse(parts[1]) ?? 8642;
            }

            setState(() => _wifiConnecting = true);
            final success = await _wifiService.syncWithDevice(ip, port);
            if (mounted) {
              setState(() => _wifiConnecting = false);
              if (success) {
                ref.read(syncLogProvider.notifier).refresh();
                _showSnackBar('QR sync completed successfully!');
              } else {
                _showSnackBar('QR sync failed. Check connection.');
              }
            }
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Legacy sync actions (paired devices)
  // ---------------------------------------------------------------------------

  Future<void> _unpairDevice(String deviceId) async {
    final service = ref.read(syncServiceProvider);
    await service.unpair(deviceId);
    ref.read(deviceProvider.notifier).removeDevice(deviceId);
  }

  Future<void> _syncDevice(String deviceId) async {
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
    final service = ref.read(syncServiceProvider);
    await service.syncWithDevice(deviceId);
    ref.read(deviceProvider.notifier).refresh();
    ref.read(syncLogProvider.notifier).refresh();
    ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
  }

  Future<void> _syncAll() async {
    final devices = ref.read(deviceProvider);
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
    final service = ref.read(syncServiceProvider);
    for (final device in devices) {
      await service.syncWithDevice(device.id);
    }
    ref.read(deviceProvider.notifier).refresh();
    ref.read(syncLogProvider.notifier).refresh();
    ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchWifiIp();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final devices = ref.watch(deviceProvider);
    final status = ref.watch(syncStatusProvider);
    final logs = ref.watch(syncLogProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // -- App Bar --
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.sm),
              child: Row(
                children: [
                  NeuIconButton(
                    icon: CupertinoIcons.back,
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      'Sync & Devices',
                      style: TextStyle(
                        fontSize: AppSizes.heading2,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  if (status == SyncStatus.syncing ||
                      _bluetoothScanning ||
                      _wifiConnecting)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),

            // -- Content --
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                children: [
                  // ===== Bluetooth Section =====
                  _buildBluetoothSection(
                      textPrimary, textSecondary, isDark),
                  const SizedBox(height: AppSizes.sm),

                  // ===== WiFi Sync Section =====
                  _buildWifiSection(textPrimary, textSecondary, isDark),
                  const SizedBox(height: AppSizes.sm),

                  // ===== QR Code Section =====
                  _buildQrSection(textPrimary, textSecondary),
                  const SizedBox(height: AppSizes.sm),

                  // ===== Paired Devices =====
                  NeuCard(
                    title: 'Paired Devices',
                    child: devices.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.md),
                            child: Center(
                              child: Text(
                                'No paired devices yet.',
                                style: TextStyle(
                                  fontSize: AppSizes.body,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: devices
                                .map((d) => _PairedDeviceTile(
                                      device: d,
                                      onSync: () => _syncDevice(d.id),
                                      onRemove: () => _unpairDevice(d.id),
                                      isSyncing:
                                          status == SyncStatus.syncing,
                                    ))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: AppSizes.sm),

                  // ===== Sync History =====
                  NeuCard(
                    title: 'Sync History',
                    child: logs.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.md),
                            child: Center(
                              child: Text(
                                'No sync history yet.',
                                style: TextStyle(
                                  fontSize: AppSizes.body,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: logs
                                .take(10)
                                .map((log) => _SyncLogTile(
                                      log: log,
                                      devices: devices,
                                    ))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // ===== Sync All =====
                  NeuButton(
                    label: 'Sync All Devices',
                    icon: CupertinoIcons.arrow_2_circlepath,
                    size: NeuButtonSize.large,
                    isFullWidth: true,
                    isLoading: status == SyncStatus.syncing,
                    onPressed: devices.isEmpty ? null : _syncAll,
                  ),
                  const SizedBox(height: AppSizes.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bluetooth Section
  // ---------------------------------------------------------------------------

  Widget _buildBluetoothSection(
      Color textPrimary, Color textSecondary, bool isDark) {
    return NeuCard(
      title: 'Bluetooth',
      trailing: CupertinoSwitch(
        value: _bluetoothEnabled,
        activeTrackColor: AppColors.primary,
        onChanged: _toggleBluetooth,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error message
          if (_bluetoothError != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.exclamationmark_triangle,
                      size: AppSizes.iconSm, color: AppColors.warning),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      _bluetoothError!,
                      style: TextStyle(
                          fontSize: AppSizes.bodySmall, color: textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.sm),
          ],

          // Scanning indicator
          if (_bluetoothScanning) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.md),
                child: Column(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: AppSizes.sm),
                    Text(
                      'Scanning for nearby devices...',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Not enabled message
          if (!_bluetoothEnabled && _bluetoothError == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              child: Center(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.bluetooth,
                        size: 32,
                        color: textSecondary.withValues(alpha: 0.5)),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      'Toggle Bluetooth to scan for nearby devices.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: AppSizes.body, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ),

          // Discovered BT devices list
          if (_bluetoothEnabled &&
              !_bluetoothScanning &&
              _btDevices.isEmpty &&
              _bluetoothError == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons
                          .antenna_radiowaves_left_right,
                      size: 32,
                      color: textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      'No devices found. Tap to scan again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: AppSizes.body, color: textSecondary),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    NeuButton(
                      label: 'Scan Again',
                      icon: CupertinoIcons.search,
                      size: NeuButtonSize.small,
                      variant: NeuButtonVariant.outline,
                      onPressed: _startBluetoothScan,
                    ),
                  ],
                ),
              ),
            ),

          if (_btDevices.isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            ...List.generate(_btDevices.length, (i) {
              final device = _btDevices[i];
              final signalColor = device.signalStrength == 'Strong'
                  ? AppColors.success
                  : device.signalStrength == 'Medium'
                      ? AppColors.warning
                      : AppColors.danger;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: NeuContainer(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.bluetooth,
                          color: AppColors.primary,
                          size: AppSizes.iconMd),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              style: TextStyle(
                                fontSize: AppSizes.body,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '${device.rssi} dBm',
                                  style: TextStyle(
                                    fontSize: AppSizes.bodySmall,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.sm),
                                NeuBadge(
                                  label: device.signalStrength,
                                  color: signalColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      NeuButton(
                        label: 'Pair',
                        size: NeuButtonSize.small,
                        onPressed: () => _pairBluetoothDevice(device),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSizes.xs),
            Center(
              child: NeuButton(
                label: 'Scan Again',
                icon: CupertinoIcons.search,
                size: NeuButtonSize.small,
                variant: NeuButtonVariant.outline,
                onPressed: _startBluetoothScan,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WiFi Sync Section
  // ---------------------------------------------------------------------------

  Widget _buildWifiSection(
      Color textPrimary, Color textSecondary, bool isDark) {
    return NeuCard(
      title: 'WiFi Sync',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IP Address row
          Row(
            children: [
              Icon(CupertinoIcons.wifi,
                  size: AppSizes.iconMd, color: AppColors.primary),
              const SizedBox(width: AppSizes.sm),
              Text(
                'IP Address: ',
                style: TextStyle(
                  fontSize: AppSizes.body,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              Expanded(
                child: Text(
                  _wifiIp ?? 'Not connected',
                  style: TextStyle(
                    fontSize: AppSizes.body,
                    fontFamily: 'monospace',
                    color: _wifiIp != null ? textPrimary : textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),

          // Server status
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _wifiServerRunning ? AppColors.success : AppColors.danger,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                _wifiServerRunning
                    ? 'Server Running on port ${_wifiService.port}'
                    : 'Server Stopped',
                style: TextStyle(
                  fontSize: AppSizes.bodySmall,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: NeuButton(
                  label: _wifiServerRunning ? 'Stop Server' : 'Start Server',
                  icon: _wifiServerRunning
                      ? CupertinoIcons.stop_circle
                      : CupertinoIcons.play_circle,
                  variant: _wifiServerRunning
                      ? NeuButtonVariant.secondary
                      : NeuButtonVariant.primary,
                  isFullWidth: true,
                  onPressed: _toggleWifiServer,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: NeuButton(
                  label: 'Connect',
                  icon: CupertinoIcons.arrow_right_arrow_left,
                  variant: NeuButtonVariant.outline,
                  isFullWidth: true,
                  isLoading: _wifiConnecting,
                  onPressed: _wifiConnecting ? null : _connectToDevice,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // QR Code Section
  // ---------------------------------------------------------------------------

  Widget _buildQrSection(Color textPrimary, Color textSecondary) {
    return NeuCard(
      title: 'QR Code Pairing',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share your connection info via QR code or scan another device.',
            style: TextStyle(
              fontSize: AppSizes.bodySmall,
              color: textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: NeuButton(
                  label: 'Show My QR',
                  icon: CupertinoIcons.qrcode,
                  variant: NeuButtonVariant.primary,
                  isFullWidth: true,
                  onPressed: _showMyQr,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: NeuButton(
                  label: 'Scan QR',
                  icon: CupertinoIcons.camera,
                  variant: NeuButtonVariant.outline,
                  isFullWidth: true,
                  onPressed: _scanQr,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// QR Scanner Page
// =============================================================================

class _QrScannerPage extends StatefulWidget {
  final void Function(String data) onScanned;

  const _QrScannerPage({required this.onScanned});

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_hasScanned) return;
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final rawValue = barcodes.first.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  _hasScanned = true;
                  widget.onScanned(rawValue);
                }
              }
            },
          ),
          // Overlay with scanning frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Text(
                  'Point at the QR code on the other device',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Private Widgets (kept from original)
// =============================================================================

class _PairedDeviceTile extends StatelessWidget {
  final DeviceInfo device;
  final VoidCallback onSync;
  final VoidCallback onRemove;
  final bool isSyncing;

  const _PairedDeviceTile({
    required this.device,
    required this.onSync,
    required this.onRemove,
    required this.isSyncing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final fmt = DateFormat('MMM d, h:mm a');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: NeuContainer(
        padding: const EdgeInsets.all(AppSizes.sm),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.device_phone_portrait,
              color: AppColors.secondary,
              size: AppSizes.iconLg,
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: TextStyle(
                      fontSize: AppSizes.body,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Last synced: ${fmt.format(device.lastSyncAt)}',
                    style: TextStyle(
                      fontSize: AppSizes.bodySmall,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  NeuBadge(
                    label: device.syncMethod,
                    color: AppColors.info,
                  ),
                ],
              ),
            ),
            NeuIconButton(
              icon: CupertinoIcons.arrow_2_circlepath,
              tooltip: 'Sync',
              onPressed: isSyncing ? null : onSync,
              iconColor: AppColors.primary,
            ),
            const SizedBox(width: AppSizes.xs),
            NeuIconButton(
              icon: CupertinoIcons.xmark_circle,
              tooltip: 'Remove',
              onPressed: onRemove,
              iconColor: AppColors.danger,
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncLogTile extends StatelessWidget {
  final SyncLog log;
  final List<DeviceInfo> devices;

  const _SyncLogTile({
    required this.log,
    required this.devices,
  });

  String _deviceName() {
    final match = devices.where((d) => d.id == log.deviceId);
    return match.isNotEmpty ? match.first.name : 'Unknown Device';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final fmt = DateFormat('MMM d, h:mm a');

    final directionColor = switch (log.direction) {
      'sent' => AppColors.info,
      'received' => AppColors.secondary,
      _ => AppColors.primary,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        children: [
          Icon(
            log.success
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.xmark_circle_fill,
            size: AppSizes.iconSm,
            color: log.success ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _deviceName(),
                  style: TextStyle(
                    fontSize: AppSizes.body,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '${fmt.format(log.syncedAt)} - ${log.itemsSynced} items',
                  style: TextStyle(
                    fontSize: AppSizes.bodySmall,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          NeuBadge(
            label: log.direction,
            color: directionColor,
          ),
        ],
      ),
    );
  }
}
