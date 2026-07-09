import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone2/core/utils/api_config.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  var isLoading = true.obs;
  var isUpdating = false.obs;
  var userData = {}.obs;

  final GetStorage _box = GetStorage();
  final ImagePicker _picker = ImagePicker();

  // Controller untuk form edit
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final oldPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  var selectedImagePath = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  String? _getToken() {
    return _box.read('token');
  }

  // Parse cache dengan aman — bisa berupa String JSON (kalau AuthController
  // menyimpan pakai jsonEncode) ATAU Map langsung. Ini mencegah error
  // "_TypeError: type 'String' is not a subtype of type 'Map<...>'"
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

  // ==========================================================
  // AMBIL DATA PROFIL
  // ==========================================================
  // Sekarang backend sudah punya GET /api/user/profile, jadi data
  // profil (termasuk phone & profile_photo) selalu ditarik langsung
  // dari database, bukan cuma dari cache login yang datanya minim.
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
        _box.write('user', userData); // update cache biar sinkron
      } else {
        userData.value = _parseUserCache(_box.read('user'));
      }

      nameCtrl.text = userData['name'] ?? '';
      phoneCtrl.text = userData['phone'] ?? '';
    } catch (e) {
      print("Error fetch profile: $e");
      userData.value = _parseUserCache(_box.read('user'));
      nameCtrl.text = userData['name'] ?? '';
      phoneCtrl.text = userData['phone'] ?? '';
    } finally {
      isLoading.value = false;
    }
  }

  // Bikin URL foto profil jadi URL lengkap (backend cuma kirim path relatif)
  String? get avatarUrl {
    final photo = userData['profile_photo'];
    if (photo == null || photo.toString().isEmpty) return null;
    if (photo.toString().startsWith('http')) return photo;
    return "${ApiConfig.baseUrl}$photo";
  }

  // Pilih Foto dari Galeri
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImagePath.value = image.path;
    }
  }

  // ==========================================================
  // UPDATE PROFIL (sesuai endpoint PUT /api/user/profile di backend)
  // ==========================================================
  Future<void> updateProfile() async {
    final token = _getToken();
    if (token == null) return;

    // Validasi ringan di sisi klien sebelum kirim ke server
    if (newPassCtrl.text.isNotEmpty && oldPassCtrl.text.isEmpty) {
      Get.snackbar(
        "Gagal",
        "Password lama wajib diisi untuk mengganti password.",
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
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
        headers: {
          "Authorization": "Bearer $token",
          "ngrok-skip-browser-warning": "true",
        },
      );

      if (response.statusCode == 200) {
        // Backend hanya mengembalikan {id, name, phone, profile_photo}
        // (tidak termasuk email/role), jadi kita GABUNG dengan data lama
        // supaya email & role tidak hilang dari cache.
        final updatedUser = _parseUserCache(response.body['user']);
        final merged = <String, dynamic>{...userData, ...updatedUser};

        userData.value = merged;
        _box.write('user', merged); // simpan lagi ke cache biar konsisten

        Get.back();
        Get.snackbar(
          "Sukses",
          "Data berhasil diperbarui.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        oldPassCtrl.clear();
        newPassCtrl.clear();
        selectedImagePath.value = '';
      } else {
        Get.snackbar(
          "Gagal Update",
          response.body?['message'] ?? 'Terjadi kesalahan.',
          backgroundColor: const Color(0xFFD32F2F),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("Error update profile: $e");
      Get.snackbar("Error", "Server tidak merespon.",
          backgroundColor: Colors.red, colorText: Colors.white);
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