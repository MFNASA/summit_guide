import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone2/core/utils/api_config.dart';
import 'package:capstone2/core/utils/local_activity_logger.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  var isLoading = true.obs;
  var isUpdating = false.obs;
  var userData = {}.obs;

  // Log aktivitas gabungan (lokal + server)
  var activityLogs = <Map<String, dynamic>>[].obs;
  var isLoadingActivity = false.obs;

  final GetStorage _box = GetStorage();
  final ImagePicker _picker = ImagePicker();

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final oldPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  var selectedImagePath = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
    fetchActivityLogs();
  }

  String? _getToken() {
    return _box.read('token');
  }

  // ==========================================================
  // LOG AKTIVITAS: gabungan log lokal (login, update profil)
  // + data dari API yang SUDAH ADA di backend (tiket & sewa),
  // TANPA perlu endpoint atau tabel baru sama sekali.
  // ==========================================================
  Future<void> fetchActivityLogs() async {
    isLoadingActivity.value = true;
    final List<Map<String, dynamic>> combined = [];

    // --- 1. Log lokal (login, update profil) ---
    for (final log in LocalActivityLogger.getAll()) {
      combined.add({
        'title': log['title'],
        'subtitle': null,
        'timestamp': log['timestamp'],
      });
    }

    final token = _getToken();
    if (token != null && token.isNotEmpty) {
      final headers = {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "ngrok-skip-browser-warning": "true",
      };

      try {
        // --- 2. Riwayat tiket (endpoint sudah ada: /api/user/history) ---
        final ticketRes = await GetConnect().get(
          "${ApiConfig.baseUrl}/api/user/history",
          headers: headers,
        );
        if (ticketRes.statusCode == 200) {
          final List<dynamic> tickets = ticketRes.body['history'] ?? [];
          for (final t in tickets) {
            combined.add({
              'title': 'Pemesanan Tiket ${t['basecamp_name'] ?? '-'}',
              'subtitle': 'Tanggal: ${t['date'] ?? '-'} • ${t['payment_status'] ?? '-'}',
              'timestamp': t['date'], // tanggal booking sebagai acuan urutan
            });
          }
        }

        // --- 3. Riwayat sewa alat (endpoint sudah ada: /api/rental/my) ---
        final rentalRes = await GetConnect().get(
          "${ApiConfig.baseUrl}/api/rental/my",
          headers: headers,
        );
        if (rentalRes.statusCode == 200) {
          final List<dynamic> rentals = rentalRes.body['rentals'] ?? [];
          for (final r in rentals) {
            combined.add({
              'title': 'Sewa ${r['item_name'] ?? '-'} (${r['qty']}x)',
              'subtitle': '${r['start_date'] ?? '-'} s/d ${r['end_date'] ?? '-'} • ${r['payment_status'] ?? '-'}',
              'timestamp': r['start_date'],
            });
          }
        }
      } catch (e) {
        print('Gagal ambil sebagian log aktivitas dari server: $e');
        // Tidak apa-apa kalau gagal, log lokal tetap tampil
      }
    }

    // Urutkan dari yang paling baru
    combined.sort((a, b) {
      final dateA = DateTime.tryParse(a['timestamp']?.toString() ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['timestamp']?.toString() ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    activityLogs.value = combined;
    isLoadingActivity.value = false;
  }

  Map<String, dynamic> _parseUserCache(dynamic raw) {
    if (raw == null) return {};
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
      } catch (_) {
        return {};
      }
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Future<void> fetchProfile() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return;

    try {
      isLoading.value = true;
      final response = await GetConnect().get(
        "${ApiConfig.baseUrl}/api/user/profile",
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
      );

      if (response.statusCode == 200) {
        final fresh = response.body['user'] ?? response.body;
        userData.value = _parseUserCache(fresh);
        _box.write('user', userData);
      } else {
        userData.value = _parseUserCache(_box.read('user'));
      }

      nameCtrl.text = userData['name'] ?? '';
      phoneCtrl.text = userData['phone'] ?? '';
    } catch (e) {
      userData.value = _parseUserCache(_box.read('user'));
    } finally {
      isLoading.value = false;
    }
  }

  String? get avatarUrl {
    final photo = userData['profile_photo'];
    if (photo == null || photo.toString().isEmpty) return null;
    if (photo.toString().startsWith('http')) return photo;
    return "${ApiConfig.baseUrl}$photo";
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImagePath.value = image.path;
    }
  }

  Future<void> updateProfile() async {
    final token = _getToken();
    if (token == null) return;

    if (newPassCtrl.text.isNotEmpty && oldPassCtrl.text.isEmpty) {
      Get.snackbar("Gagal", "Password lama wajib diisi.", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      isUpdating.value = true;
      final form = FormData({
        if (nameCtrl.text.isNotEmpty) 'name': nameCtrl.text,
        if (phoneCtrl.text.isNotEmpty) 'phone': phoneCtrl.text,
        if (oldPassCtrl.text.isNotEmpty) 'old_password': oldPassCtrl.text,
        if (newPassCtrl.text.isNotEmpty) 'new_password': newPassCtrl.text,
      });

      if (selectedImagePath.value.isNotEmpty) {
        File file = File(selectedImagePath.value);
        form.files.add(MapEntry(
          'profile_photo',
          MultipartFile(file, filename: file.path.split('/').last),
        ));
      }

      final response = await GetConnect().put(
        "${ApiConfig.baseUrl}/api/user/profile",
        form,
        headers: {"Authorization": "Bearer $token", "ngrok-skip-browser-warning": "true"},
      );

      if (response.statusCode == 200) {
        final updatedUser = _parseUserCache(response.body['user']);
        final merged = <String, dynamic>{...userData, ...updatedUser};
        userData.value = merged;
        _box.write('user', merged);

        await LocalActivityLogger.log('Profil diperbarui'); // <-- catat lokal
        await fetchActivityLogs(); // refresh timeline biar langsung update

        Get.back();
        Get.snackbar("Sukses", "Data berhasil diperbarui.", backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar("Gagal", response.body?['message'] ?? 'Error.', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } finally {
      isUpdating.value = false;
    }
  }

  void logout() {
    _box.remove('token');
    _box.remove('user');
    Get.offAllNamed('/login');
  }
}