import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import '../../backup/services/backup_service.dart';

class WifiSyncService {
  static final WifiSyncService _instance = WifiSyncService._();
  factory WifiSyncService() => _instance;
  WifiSyncService._();

  HttpServer? _server;
  bool _isRunning = false;
  String? _localIp;
  final int _port = 8642;

  bool get isRunning => _isRunning;
  String? get localIp => _localIp;
  int get port => _port;

  /// Get the device's WiFi IP address
  Future<String?> getWifiIp() async {
    try {
      final info = NetworkInfo();
      _localIp = await info.getWifiIP();
      return _localIp;
    } catch (e) {
      return null;
    }
  }

  /// Start a local HTTP server that serves sync data
  Future<bool> startSyncServer() async {
    if (_isRunning) return true;

    try {
      _localIp = await getWifiIp();
      if (_localIp == null) return false;

      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _isRunning = true;

      _server!.listen((request) async {
        try {
          if (request.method == 'GET' && request.uri.path == '/sync') {
            // Serve all app data as JSON
            final data = BackupService().exportAllData();
            final json = jsonEncode(data);
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.json
              ..write(json);
            await request.response.close();
          } else if (request.method == 'POST' && request.uri.path == '/sync') {
            // Receive and import data
            final body = await utf8.decodeStream(request);
            final data = jsonDecode(body) as Map<String, dynamic>;
            await BackupService().importAllData(data);
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.json
              ..write('{"status":"ok"}');
            await request.response.close();
          } else {
            request.response
              ..statusCode = HttpStatus.notFound
              ..write('Not found');
            await request.response.close();
          }
        } catch (e) {
          request.response
            ..statusCode = HttpStatus.internalServerError
            ..write('Error: $e');
          await request.response.close();
        }
      });

      return true;
    } catch (e) {
      _isRunning = false;
      return false;
    }
  }

  /// Connect to another device's sync server and exchange data
  Future<bool> syncWithDevice(String ip, int port) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      // GET remote data
      final getRequest =
          await client.getUrl(Uri.parse('http://$ip:$port/sync'));
      final getResponse = await getRequest.close();
      final remoteJson = await utf8.decodeStream(getResponse);
      final remoteData = jsonDecode(remoteJson) as Map<String, dynamic>;

      // POST our data to remote
      final localData = BackupService().exportAllData();
      final postRequest =
          await client.postUrl(Uri.parse('http://$ip:$port/sync'));
      postRequest.headers.contentType = ContentType.json;
      postRequest.write(jsonEncode(localData));
      final postResponse = await postRequest.close();
      await utf8.decodeStream(postResponse);

      // Import remote data locally
      await BackupService().importAllData(remoteData);

      client.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Stop the sync server
  Future<void> stopServer() async {
    await _server?.close();
    _server = null;
    _isRunning = false;
  }

  void dispose() {
    stopServer();
  }
}
