// rescue_connectivity_service.dart
//
// Deteksi pendaki sekitar + kirim pesan darurat SECARA OFFLINE.
// Menggunakan package `nearby_connections` yang berjalan di atas
// Bluetooth / BLE / WiFi Direct — TIDAK butuh internet atau server.
//
// Cara kerja singkat:
// 1. Setiap device saling "advertise" dan "discover" satu sama lain
//    lewat Bluetooth (radius biasanya puluhan meter, tergantung medan).
// 2. Saat dua device saling terlihat, mereka otomatis connect dan
//    bertukar identitas (nama).
// 3. Saat user menekan SOS, payload darurat dikirim ke semua device
//    yang sedang terhubung. Setiap device yang menerima akan
//    meneruskan (relay) ke device lain yang terhubung dengannya,
//    sehingga pesan bisa menjalar seperti mesh network sederhana
//    walau di luar jangkauan langsung.
//
// PENTING (Android only): package nearby_connections membungkus
// Google Nearby Connections API yang hanya tersedia di Android.
// Untuk iOS, fitur ini akan gagal start dan sebaiknya disembunyikan
// atau diganti alternatif (mis. MultipeerConnectivity custom plugin).

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

class RescueConnectivityService {
  RescueConnectivityService._internal();
  static final RescueConnectivityService instance =
      RescueConnectivityService._internal();

  // Strategy P2P_CLUSTER = banyak-ke-banyak (M-to-N), paling cocok
  // untuk kelompok pendaki yang saling mendeteksi.
  final Strategy _strategy = Strategy.P2P_CLUSTER;
  final String _serviceId = "id.capstone2.sos_rescue";

  final Map<String, NearbyUser> _nearbyUsers = {}; // key: userId
  final Map<String, String> _endpointToUserId = {}; // endpointId -> userId
  final Set<String> _relayedMessageIds = {}; // hindari relay pesan berulang

  /// Dipanggil setiap kali daftar pengguna sekitar berubah (dipakai utk radar UI).
  void Function(Map<String, NearbyUser> users)? onUsersChanged;

  /// Dipanggil ketika ada pesan SOS masuk dari pendaki lain.
  void Function(String senderName, String message)? onEmergencyReceived;

  /// Dipanggil ketika koneksi gagal / permission ditolak, dsb.
  void Function(String error)? onError;

  String myName = "Pendaki";
  bool _running = false;
  bool get isRunning => _running;
  Map<String, NearbyUser> get nearbyUsers => Map.unmodifiable(_nearbyUsers);

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();

    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  /// Mulai mode "selalu mendengarkan" — advertise + discover berjalan
  /// terus di background selama user berada di halaman SOS, supaya
  /// radar selalu menunjukkan pendaki terdekat walau SOS belum ditekan.
  Future<void> start({required String userName}) async {
    if (_running) return;
    myName = userName.isEmpty ? "Pendaki" : userName;

    final granted = await requestPermissions();
    if (!granted) {
      onError?.call(
          "Izin Bluetooth/Lokasi ditolak. Fitur SOS offline tidak bisa berjalan.");
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
      onError?.call("Gagal mengaktifkan deteksi offline: $e");
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
    if (status == Status.CONNECTED) {
      // Begitu tersambung, langsung kirim identitas kita supaya
      // muncul di radar lawan bicara meski belum ada SOS.
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

    // Relay ke device lain yang terhubung supaya sinyal SOS
    // bisa "menjalar" walau si pengirim asli sudah di luar jangkauan
    // penerima berikutnya (mesh sederhana), tapi cegah loop tak berujung.
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
    _running = false;
  }
}
