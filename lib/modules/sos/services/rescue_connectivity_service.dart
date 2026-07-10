// rescue_connectivity_service.dart
//
// Deteksi pendaki sekitar + kirim pesan darurat SECARA OFFLINE.
// Menggunakan package `nearby_connections` yang berjalan di atas
// Bluetooth / BLE / WiFi Direct — TIDAK butuh internet atau server.

import 'dart:async';
import 'dart:convert';

import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

enum RescueSignalType { identify, sos, safe }

class NearbyUser {
  final String id;
  String name;
  DateTime lastSeen;
  bool isInDanger;
  String? lastMessage;

  NearbyUser({
    required this.id,
    required this.name,
    required this.lastSeen,
    this.isInDanger = false,
    this.lastMessage,
  });
}

/// DITAMBAHKAN: hasil permission dibedakan supaya UI bisa menampilkan
/// pesan & tombol aksi yang berbeda (retry biasa vs buka Settings).
enum PermissionResultStatus { granted, denied, permanentlyDenied, serviceDisabled }

class RescueConnectivityService {
  RescueConnectivityService._internal();
  static final RescueConnectivityService instance =
      RescueConnectivityService._internal();

  final Strategy _strategy = Strategy.P2P_CLUSTER;
  final String _serviceId = "id.capstone2.sos_rescue";

  final Map<String, NearbyUser> _nearbyUsers = {};
  final Map<String, String> _endpointToUserId = {};
  final Set<String> _relayedMessageIds = {};

  /// DITAMBAHKAN: menyimpan endpoint yang sedang dalam proses connect,
  /// supaya kita tidak requestConnection dua arah sekaligus (race condition).
  final Set<String> _pendingConnections = {};
  final Set<String> _connectedEndpoints = {};

  void Function(Map<String, NearbyUser> users)? onUsersChanged;
  void Function(String senderName, String message)? onEmergencyReceived;

  /// DIUBAH: sekarang membawa status, bukan cuma pesan string, supaya
  /// UI tahu kapan harus menampilkan tombol "Buka Pengaturan".
  void Function(String message, PermissionResultStatus status)? onError;

  String myName = "Pendaki";
  bool _running = false;
  bool get isRunning => _running;
  Map<String, NearbyUser> get nearbyUsers => Map.unmodifiable(_nearbyUsers);

  /// Cek + minta semua izin yang dibutuhkan Nearby Connections.
  /// DIUBAH TOTAL: sekarang membedakan denied biasa vs permanently denied,
  /// dan juga mengecek apakah Location Service (GPS toggle) aktif —
  /// karena BLE scan akan gagal diam-diam kalau GPS mati walau izin granted.
  Future<PermissionResultStatus> requestPermissions() async {
    final permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ];

    final statuses = await permissions.request();

    // DITAMBAHKAN: debug print status ASLI tiap izin satu-satu.
    // Cek ini di terminal `flutter run` setelah tekan tombol SOS,
    // supaya tahu persis izin mana yang bermasalah dan kenapa.
    statuses.forEach((permission, status) {
      // ignore: avoid_print
      print('[SOS_PERMISSION_DEBUG] $permission => $status');
    });

    final anyPermanentlyDenied =
        statuses.values.any((s) => s.isPermanentlyDenied);
    final allGranted = statuses.values.every((s) => s.isGranted);

    if (anyPermanentlyDenied) {
      onError?.call(
        "Izin Bluetooth/Lokasi ditolak permanen. Ketuk untuk membuka "
        "Pengaturan Aplikasi dan aktifkan izin secara manual.",
        PermissionResultStatus.permanentlyDenied,
      );
      return PermissionResultStatus.permanentlyDenied;
    }

    if (!allGranted) {
      onError?.call(
        "Izin Bluetooth/Lokasi ditolak. Fitur SOS offline tidak bisa berjalan.",
        PermissionResultStatus.denied,
      );
      return PermissionResultStatus.denied;
    }

    // Izin sudah granted, tapi GPS/Location Service di HP bisa saja masih
    // dimatikan dari Quick Settings — ini penyebab umum discovery gagal
    // padahal semua izin sudah "granted".
    final serviceEnabled = await Permission.location.serviceStatus.isEnabled;
    if (!serviceEnabled) {
      onError?.call(
        "Aktifkan Location/GPS di pengaturan HP agar SOS offline bisa "
        "mendeteksi pendaki lain di sekitar.",
        PermissionResultStatus.serviceDisabled,
      );
      return PermissionResultStatus.serviceDisabled;
    }

    return PermissionResultStatus.granted;
  }

  /// DITAMBAHKAN: dipanggil dari UI saat user menekan banner error
  /// untuk kasus permanently denied.
  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<void> start({required String userName}) async {
    if (_running) return;
    myName = userName.isEmpty ? "Pendaki" : userName;

    final result = await requestPermissions();
    if (result != PermissionResultStatus.granted) {
      // Pesan error sudah dikirim lewat onError di dalam requestPermissions().
      return;
    }

    _running = true;

    try {
      await Nearby().startAdvertising(
        myName,
        _strategy,
        serviceId: _serviceId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );

      await Nearby().startDiscovery(
        myName,
        _strategy,
        serviceId: _serviceId,
        onEndpointFound: (id, name, serviceId) {
          // DIUBAH: cegah race condition P2P_CLUSTER.
          // Kalau endpoint ini sudah connected atau sedang pending, jangan
          // requestConnection lagi. Selain itu, untuk menghindari kedua sisi
          // saling requestConnection bersamaan (yang bisa memicu
          // STATUS_ALREADY_CONNECTED_TO_ENDPOINT / gagal connect), hanya
          // device dengan id (nama+hashCode) "lebih kecil" yang menginisiasi.
          if (_connectedEndpoints.contains(id) ||
              _pendingConnections.contains(id)) {
            return;
          }

          final myKey = myName.hashCode;
          final otherKey = name.hashCode;
          final iShouldInitiate = myKey <= otherKey;

          if (!iShouldInitiate) return;

          _pendingConnections.add(id);
          Nearby().requestConnection(
            myName,
            id,
            onConnectionInitiated: _onConnectionInitiated,
            onConnectionResult: _onConnectionResult,
            onDisconnected: _onDisconnected,
          );
        },
        onEndpointLost: (id) {
          if (id == null) return;
          _pendingConnections.remove(id);
          final userId = _endpointToUserId[id];
          if (userId != null) {
            _nearbyUsers.remove(userId);
            _endpointToUserId.remove(id);
            onUsersChanged?.call(_nearbyUsers);
          }
        },
      );
    } catch (e) {
      _running = false;
      onError?.call(
        "Gagal mengaktifkan deteksi offline: $e",
        PermissionResultStatus.denied,
      );
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type != PayloadType.BYTES || payload.bytes == null) return;
        try {
          final map = jsonDecode(utf8.decode(payload.bytes!));
          _handleIncomingPayload(endpointId, map);
        } catch (_) {
          // payload rusak / tidak dikenal, abaikan
        }
      },
    );
  }

  void _onConnectionResult(String id, Status status) {
    _pendingConnections.remove(id);
    if (status == Status.CONNECTED) {
      _connectedEndpoints.add(id);
      _sendPayload(id, {
        'msgId': _newMsgId(),
        'senderId': myName.hashCode.toString(),
        'senderName': myName,
        'type': 'identify',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void _onDisconnected(String id) {
    _pendingConnections.remove(id);
    _connectedEndpoints.remove(id);
    final userId = _endpointToUserId[id];
    if (userId != null) {
      _nearbyUsers.remove(userId);
      _endpointToUserId.remove(id);
      onUsersChanged?.call(_nearbyUsers);
    }
  }

  void _handleIncomingPayload(String endpointId, Map<String, dynamic> map) {
    final msgId = map['msgId'] as String?;
    final senderId = map['senderId'] as String? ?? endpointId;
    final senderName = map['senderName'] as String? ?? 'Tidak dikenal';
    final type = map['type'] as String? ?? 'identify';
    final message = map['message'] as String?;

    _endpointToUserId[endpointId] = senderId;
    _nearbyUsers[senderId] = NearbyUser(
      id: senderId,
      name: senderName,
      lastSeen: DateTime.now(),
      isInDanger: type == 'sos',
      lastMessage: message,
    );
    onUsersChanged?.call(_nearbyUsers);

    if (type == 'sos') {
      onEmergencyReceived?.call(senderName, message ?? 'Butuh bantuan segera!');
    }

    if (msgId != null && !_relayedMessageIds.contains(msgId)) {
      _relayedMessageIds.add(msgId);
      for (final otherEndpoint in _endpointToUserId.keys) {
        if (otherEndpoint == endpointId) continue;
        _sendPayload(otherEndpoint, map);
      }
    }
  }

  String _newMsgId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${myName.hashCode}';

  Future<void> _sendPayload(String endpointId, Map<String, dynamic> map) async {
    try {
      final bytes = utf8.encode(jsonEncode(map));
      await Nearby().sendBytesPayload(endpointId, bytes);
    } catch (_) {
      // koneksi mungkin sudah putus, biarkan onDisconnected yang membersihkan
    }
  }

  Future<void> broadcastSOS({String message = "Butuh bantuan segera!"}) async {
    final payload = {
      'msgId': _newMsgId(),
      'senderId': myName.hashCode.toString(),
      'senderName': myName,
      'type': 'sos',
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _relayedMessageIds.add(payload['msgId'] as String);
    for (final endpointId in _endpointToUserId.keys) {
      await _sendPayload(endpointId, payload);
    }
  }

  Future<void> broadcastSafe() async {
    final payload = {
      'msgId': _newMsgId(),
      'senderId': myName.hashCode.toString(),
      'senderName': myName,
      'type': 'safe',
      'timestamp': DateTime.now().toIso8601String(),
    };
    _relayedMessageIds.add(payload['msgId'] as String);
    for (final endpointId in _endpointToUserId.keys) {
      await _sendPayload(endpointId, payload);
    }
  }

  Future<void> stop() async {
    try {
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
      await Nearby().stopAllEndpoints();
    } catch (_) {}
    _nearbyUsers.clear();
    _endpointToUserId.clear();
    _pendingConnections.clear();
    _connectedEndpoints.clear();
    _running = false;
  }
}