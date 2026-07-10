// sos_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/rescue_connectivity_service.dart';
import '../services/flashlight_sos_service.dart';
import '../services/alarm_sound_service.dart';

class SosController extends GetxController {
  final RescueConnectivityService _connectivity =
      RescueConnectivityService.instance;
  final FlashlightSosService _flashlight = FlashlightSosService();
  final AlarmSoundService _alarm = AlarmSoundService();

  final RxBool isSosActive = false.obs;
  final RxBool isInitializing = true.obs;
  final RxString errorMessage = ''.obs;
  final RxMap<String, NearbyUser> nearbyUsers = <String, NearbyUser>{}.obs;
  final RxList<Map<String, String>> emergencyLog = <Map<String, String>>[].obs;

  /// TODO: ganti dengan nama user yang sedang login di aplikasi.
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

    _connectivity.onError = (err) {
      errorMessage.value = err;
    };

    _startBackgroundDiscovery();
  }

  Future<void> _startBackgroundDiscovery() async {
    isInitializing.value = true;
    await _connectivity.start(userName: userName);
    isInitializing.value = false;
  }

  Future<void> toggleSOS() async {
    if (isSosActive.value) {
      await _deactivateSOS();
    } else {
      await _activateSOS();
    }
  }

  Future<void> _activateSOS() async {
    isSosActive.value = true;

    // 1. Kirim sinyal darurat ke semua pendaki sekitar via Bluetooth.
    try {
      await _connectivity.broadcastSOS(
        message: "$userName membutuhkan bantuan darurat!",
      );
    } catch (e) {
      errorMessage.value = "Gagal mengirim sinyal SOS: $e";
    }

    // 2. Nyalakan flash HP dengan pola morse SOS.
    await _flashlight.startSOSFlash();

    // 3. Bunyikan alarm dari speaker HP.
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
