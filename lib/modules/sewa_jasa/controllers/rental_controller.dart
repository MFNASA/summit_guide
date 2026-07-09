import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone2/core/utils/api_config.dart';
import 'package:capstone2/modules/sewa_jasa/views/PaymentWebviewPage.dart';

class RentalController extends GetxController {
  var isLoading = false.obs;
  var listRental = <dynamic>[].obs;
  var errorMessage = ''.obs;

  // === RIWAYAT SEWA (alat yang sudah/sedang disewa user) ===
  var myRentals = <dynamic>[].obs;
  var isLoadingHistory = false.obs;

  final GetStorage _box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    fetchRentals();
  }

  String? _getToken() {
    return _box.read('token');
  }

  /// Ambil katalog rental dari server.
  /// [basecampId] opsional, sesuai query param di endpoint Flask.
  Future<void> fetchRentals({int? basecampId}) async {
    errorMessage.value = '';
    final token = _getToken();

    if (token == null || token.isEmpty) {
      errorMessage.value = 'Token tidak ditemukan. Silakan login ulang.';
      print("RentalController: token kosong, batalkan fetch.");
      return;
    }

    try {
      isLoading.value = true;

      // ENDPOINT SESUAI SERVER: /api/rental/catalog (bukan /api/rentals)
      String url = "${ApiConfig.baseUrl}/api/rental/catalog";
      if (basecampId != null) {
        url += "?basecamp_id=$basecampId";
      }

      final response = await GetConnect().get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
      ).timeout(const Duration(seconds: 10));

      print("RentalController: status ${response.statusCode}");

      if (response.statusCode == 200) {
        final body = response.body;

        // Server balikin objek: { "items": [ ... ] }
        // BUKAN raw List, jadi harus diambil dari key "items".
        if (body is Map && body['items'] is List) {
          final List items = body['items'];
          listRental.assignAll(items);

          if (items.isEmpty) {
            errorMessage.value = 'Belum ada alat yang tersedia untuk disewa.';
          }
        } else {
          errorMessage.value = 'Format data dari server tidak sesuai.';
          print("RentalController: format tidak sesuai -> $body");
        }
      } else if (response.statusCode == 401) {
        errorMessage.value = 'Sesi habis, silakan login kembali.';
      } else {
        errorMessage.value =
            'Gagal memuat data rental (status ${response.statusCode}).';
        print("RentalController: error body -> ${response.body}");
      }
    } catch (e) {
      errorMessage.value = 'Tidak dapat terhubung ke server.';
      print("RentalController: exception -> $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Booking/sewa alat sesuai kontrak endpoint /api/rental/checkout.
  /// [startDate] dan [endDate] format "yyyy-MM-dd".
  Future<void> bookRental(
    int itemId,
    String itemName, {
    required String startDate,
    required String endDate,
    int qty = 1,
  }) async {
    final token = _getToken();

    if (token == null || token.isEmpty) {
      Get.snackbar(
        "Gagal",
        "Token tidak ditemukan. Silakan login ulang.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (qty < 1) {
      Get.snackbar(
        "Gagal",
        "Jumlah sewa minimal 1.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // ENDPOINT & PAYLOAD SESUAI SERVER: /api/rental/checkout
      // field: item_id, qty, start_date, end_date
      final res = await GetConnect().post(
        "${ApiConfig.baseUrl}/api/rental/checkout",
        {
          "item_id": itemId,
          "qty": qty,
          "start_date": startDate,
          "end_date": endDate,
        },
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
      );

      print("bookRental status: ${res.statusCode}, body: ${res.body}");

      // Server mengembalikan status 200 saat sukses (bukan 201)
      if (res.statusCode == 200 && res.body is Map) {
        final paymentUrl = res.body['payment_url'];

        Get.snackbar(
          "Sewa Dibuat ✅",
          "$qty unit $itemName berhasil dipesan.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        if (paymentUrl != null) {
          Get.to(() => PaymentWebviewPage(paymentUrl: paymentUrl));
        }

        // Refresh stok setelah booking berhasil
        fetchRentals();
        // Refresh juga riwayat sewa supaya item baru langsung muncul
        fetchMyRentals();
      } else {
        final message = res.body is Map
            ? (res.body['message'] ?? 'Gagal membuat sewa.')
            : 'Gagal membuat sewa (status ${res.statusCode}).';

        Get.snackbar(
          "Gagal Sewa",
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("bookRental exception: $e");
      Get.snackbar(
        "Error",
        "Tidak dapat terhubung ke server: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  /// Ambil daftar alat yang SUDAH/SEDANG disewa oleh user (riwayat sewa),
  /// dipakai di halaman "Alat yang Saya Sewa" (CartView).
  ///
  /// PENTING: backend mengembalikan objek { "rentals": [ ... ] },
  /// BUKAN raw List, jadi harus diambil dari key "rentals".
  Future<void> fetchMyRentals() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return;

    try {
      isLoadingHistory.value = true;

      final response = await GetConnect().get(
        "${ApiConfig.baseUrl}/api/rental/my",
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
      );

      print("fetchMyRentals status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final body = response.body;

        if (body is Map && body['rentals'] is List) {
          myRentals.assignAll(body['rentals']);
        } else {
          print("RentalController: format fetchMyRentals tidak sesuai -> $body");
        }
      } else {
        print(
            "RentalController: fetchMyRentals gagal (${response.statusCode}) -> ${response.body}");
      }
    } catch (e) {
      print("fetchMyRentals exception: $e");
    } finally {
      isLoadingHistory.value = false;
    }
  }
}