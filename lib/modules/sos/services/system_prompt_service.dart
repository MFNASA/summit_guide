// system_prompt_service.dart
//
// Khusus untuk fitur SOS: memicu dialog SISTEM (bukan cuma buka Settings)
// agar user bisa langsung mengaktifkan Bluetooth & Lokasi tanpa keluar app.
//
// - Bluetooth: pakai native Android intent ACTION_REQUEST_ENABLE lewat
//   MethodChannel (lihat MainActivity.kt) -> muncul dialog
//   "Izinkan aplikasi menyalakan Bluetooth?" dengan tombol Izinkan/Tolak.
// - Lokasi: pakai package `location` yang membungkus Google Play Services
//   SettingsClient -> muncul dialog "Aktifkan Lokasi perangkat?" dengan
//   tombol Ya, tanpa membuka halaman Settings.
//
// PENTING: file ini HANYA dipakai oleh alur SOS. Tidak menyentuh
// permission/location service milik fitur Map, jadi Map tetap berjalan
// seperti biasa.

import 'package:flutter/services.dart';
import 'package:location/location.dart' as loc;

class SystemPromptService {
  static const _channel = MethodChannel('sos_rescue/bluetooth');

  /// Cek apakah adapter Bluetooth device sedang menyala.
  Future<bool> isBluetoothEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isBluetoothEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Munculkan dialog sistem untuk menyalakan Bluetooth.
  /// Return true kalau user menekan "Izinkan" dan Bluetooth berhasil menyala.
  Future<bool> requestEnableBluetooth() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('requestEnableBluetooth');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Cek apakah Location Service (GPS toggle) sedang aktif.
  Future<bool> isLocationServiceEnabled() async {
    final location = loc.Location();
    return await location.serviceEnabled();
  }

  /// Munculkan dialog sistem "Aktifkan Lokasi perangkat?".
  /// Return true kalau user menekan "Ya" dan lokasi berhasil aktif.
  Future<bool> requestEnableLocation() async {
    final location = loc.Location();
    final enabled = await location.serviceEnabled();
    if (enabled) return true;
    final result = await location.requestService();
    return result;
  }
}
