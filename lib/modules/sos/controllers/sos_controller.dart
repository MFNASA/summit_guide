// sos_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/rescue_connectivity_service.dart';
import '../services/flashlight_sos_service.dart';
import '../services/alarm_sound_service.dart';
import '../services/system_prompt_service.dart'; // DITAMBAHKAN

class SosController extends GetxController {
  final RescueConnectivityService _connectivity =
      RescueConnectivityService.instance;
  final FlashlightSosService _flashlight = FlashlightSosService();
  final AlarmSoundService _alarm = AlarmSoundService();
  final SystemPromptService _systemPrompt = SystemPromptService(); // DITAMBAHKAN

  final RxBool isSosActive = false.obs;
  final RxBool isInitializing = true.obs;
  final RxString errorMessage = ''.obs;
  final Rx<PermissionResultStatus?> errorStatus =
      Rx<PermissionResultStatus?>(null);

  final RxMap<String, NearbyUser> nearbyUsers = <String, NearbyUser>{}.obs;
  final RxList<Map<String, String>> emergencyLog = <Map<String, String>>[].obs;

  String userName = "Andi";

  @override
  void onInit() {
    super.onInit();

    _connectivity.onUsersChanged = (users) {
      nearbyUsers.assignAll(users);
    };

    _connectivity.onEmergencyReceived = (name, message) {
      emergencyLog.insert(0, {
        'name': name,
        'message': message,
        'time': TimeOfDay.now().format(Get.context!),
      });
      Get.snackbar(
        "🚨 SOS Diterima",
        "$name membutuhkan bantuan: $message",
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      );
    };

    _connectivity.onError = (err, status) {
      errorMessage.value = err;
      errorStatus.value = status;
    };

    _startBackgroundDiscovery();
  }

  Future<void> _startBackgroundDiscovery() async {
    isInitializing.value = true;
    errorMessage.value = '';
    errorStatus.value = null;
    await _connectivity.start(userName: userName);
    isInitializing.value = false;
  }

  Future<void> retryPermissions() async {
    await _connectivity.stop();
    await _startBackgroundDiscovery();
  }

  Future<void> openSettings() async {
    await _connectivity.openSettings();
  }

  /// DITAMBAHKAN: dipanggil SEBELUM SOS diaktifkan. Mengecek Bluetooth &
  /// Location Service device secara berurutan, dan memunculkan dialog
  /// sistem untuk mengaktifkan kalau masih mati. Baru setelah itu, lanjut
  /// ke pengecekan izin aplikasi seperti biasa.
  ///
  /// Return true kalau semua siap (Bluetooth ON, Lokasi ON, izin granted).
  Future<bool> _ensureSystemReadyForSOS() async {
    // 1. Cek & minta nyalakan Bluetooth lewat dialog sistem.
    final btEnabled = await _systemPrompt.isBluetoothEnabled();
    if (!btEnabled) {
      final granted = await _systemPrompt.requestEnableBluetooth();
      if (!granted) {
        errorMessage.value =
            "Bluetooth harus aktif agar SOS offline bisa mendeteksi pendaki lain.";
        errorStatus.value = PermissionResultStatus.denied;
        return false;
      }
    }

    // 2. Cek & minta nyalakan Location Service lewat dialog sistem.
    //    Catatan: ini TIDAK mengubah izin lokasi milik fitur Map,
    //    hanya toggle GPS di level device (sama-sama dipakai semua fitur,
    //    jadi kalau Map sudah jalan berarti ini kemungkinan sudah ON).
    final locEnabled = await _systemPrompt.isLocationServiceEnabled();
    if (!locEnabled) {
      final granted = await _systemPrompt.requestEnableLocation();
      if (!granted) {
        errorMessage.value =
            "Lokasi (GPS) harus aktif agar SOS offline bisa berjalan.";
        errorStatus.value = PermissionResultStatus.serviceDisabled;
        return false;
      }
    }

    // 3. Terakhir, pastikan izin aplikasi (Bluetooth/Lokasi runtime
    //    permission) sudah granted. Kalau connectivity service belum
    //    running (karena sebelumnya gagal), coba mulai ulang di sini.
    if (!_connectivity.isRunning) {
      await _connectivity.start(userName: userName);
    }

    if (!_connectivity.isRunning) {
      // errorMessage/errorStatus sudah di-set oleh _connectivity.onError
      return false;
    }

    errorMessage.value = '';
    errorStatus.value = null;
    return true;
  }

  Future<void> toggleSOS() async {
    if (isSosActive.value) {
      await _deactivateSOS();
    } else {
      // DIUBAH: sebelum aktivasi SOS, pastikan Bluetooth & Lokasi ON dulu.
      final ready = await _ensureSystemReadyForSOS();
      if (!ready) {
        // Banner error di UI akan otomatis update lewat errorMessage/errorStatus.
        return;
      }
      await _activateSOS();
    }
  }

  Future<void> _activateSOS() async {
    isSosActive.value = true;

    try {
      await _connectivity.broadcastSOS(
        message: "$userName membutuhkan bantuan darurat!",
      );
    } catch (e) {
      errorMessage.value = "Gagal mengirim sinyal SOS: $e";
    }

    await _flashlight.startSOSFlash();

    try {
      await _alarm.startAlarm();
    } catch (e) {
      errorMessage.value = "Gagal memutar suara alarm: $e";
    }
  }

  Future<void> _deactivateSOS() async {
    isSosActive.value = false;
    await _connectivity.broadcastSafe();
    await _flashlight.stop();
    await _alarm.stopAlarm();
  }

  @override
  void onClose() {
    _flashlight.stop();
    _alarm.dispose();
    _connectivity.stop();
    super.onClose();
  }
}