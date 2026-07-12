// lib/core/utils/local_activity_logger.dart
import 'package:get_storage/get_storage.dart';

/// Helper untuk mencatat aktivitas yang TIDAK dicatat di backend
/// (login, update profil, dll) secara lokal di device menggunakan
/// GetStorage. Tidak memerlukan perubahan apapun di backend Flask.
class LocalActivityLogger {
  static final GetStorage _box = GetStorage();
  static const String _key = 'local_activity_logs';
  static const int _maxLogs = 30; // batasi biar storage tidak membengkak

  /// Catat satu event aktivitas lokal baru.
  static Future<void> log(String title) async {
    final List<dynamic> existing = _box.read<List>(_key) ?? [];

    existing.insert(0, {
      'title': title,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Buang log paling lama kalau sudah melebihi batas
    if (existing.length > _maxLogs) {
      existing.removeRange(_maxLogs, existing.length);
    }

    await _box.write(_key, existing);
  }

  /// Ambil semua log lokal yang tersimpan.
  static List<Map<String, dynamic>> getAll() {
    final List<dynamic> raw = _box.read<List>(_key) ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}