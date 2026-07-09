import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone2/core/utils/api_config.dart';
import 'package:capstone2/modules/sewa_jasa/views/PaymentWebviewPage.dart';

class TiketController extends GetxController {
  var isLoading = false.obs;
  var listBasecamp = <dynamic>[].obs;
  var errorMessage = ''.obs;

  var myTickets = <dynamic>[].obs;
  var isLoadingHistory = false.obs;

  // PENTING: pakai GetStorage yang SAMA dengan yang dipakai AuthController
  // saat menyimpan token setelah login (key: 'token').
  // Jangan pakai SharedPreferences di sini, karena AuthController tidak
  // pernah menulis ke SharedPreferences — hanya ke GetStorage.
  final GetStorage _box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    fetchTickets();
  }

  String? _getToken() {
    return _box.read('token');
  }

  Future<void> fetchTickets() async {
    errorMessage.value = '';
    final token = _getToken();

    if (token == null || token.isEmpty) {
      errorMessage.value = 'Token tidak ditemukan. Silakan login ulang.';
      print("TiketController: token kosong, batalkan fetch.");
      return;
    }

    try {
      isLoading.value = true;

      final response = await GetConnect().get(
        "${ApiConfig.baseUrl}/api/mountains",
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          // WAJIB untuk ngrok free tier, kalau tidak akan ketahan
          // halaman warning HTML alih-alih JSON asli dari Flask.
          "ngrok-skip-browser-warning": "true",
        },
      );

      print("TiketController: status ${response.statusCode}");

      if (response.statusCode == 200) {
        var raw = response.body;
        List<Map<String, dynamic>> temp = [];

        if (raw is List) {
          for (var m in raw) {
            for (var bc in (m['basecamps'] ?? [])) {
              temp.add({
                "id": bc['id'],
                "nama_gunung": m['name'],
                "basecamp": bc['name'],
                "harga": bc['ticket_price'] ?? 0,
                "kuota": bc['daily_quota'] ?? 0,
              });
            }
          }
          listBasecamp.assignAll(temp);

          if (temp.isEmpty) {
            errorMessage.value =
                'Belum ada basecamp yang tersedia untuk dipesan.';
          }
        } else {
          // raw bukan List — kemungkinan besar masih halaman HTML ngrok
          // atau format response tidak sesuai ekspektasi.
          errorMessage.value = 'Format data dari server tidak sesuai.';
          print("TiketController: raw response bukan List -> $raw");
        }
      } else if (response.statusCode == 401) {
        errorMessage.value = 'Sesi habis, silakan login kembali.';
      } else {
        errorMessage.value =
            'Gagal memuat data tiket (status ${response.statusCode}).';
        print("TiketController: error body -> ${response.body}");
      }
    } catch (e) {
      errorMessage.value = 'Tidak dapat terhubung ke server.';
      print("TiketController: exception -> $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Booking tiket.
  /// [hikingDate] wajib diisi, format "yyyy-MM-dd" sesuai yang diharapkan Flask.
  /// [quantity] jumlah tiket yang mau dipesan, default 1.
  Future<void> bookTicket(
    int basecampId,
    String mountainName, {
    required String hikingDate,
    int quantity = 1,
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

    if (quantity < 1) {
      Get.snackbar(
        "Gagal",
        "Jumlah tiket minimal 1.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final res = await GetConnect().post(
        "${ApiConfig.baseUrl}/api/tickets/book",
        {
          "basecamp_id": basecampId,
          "hiking_date": hikingDate,
          "quantity": quantity,
        },
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
      );

      print("bookTicket status: ${res.statusCode}, body: ${res.body}");

      if (res.statusCode == 201) {
        final paymentUrl = res.body['payment_url'];

        Get.snackbar(
          "Tiket Dibuat ✅",
          "$quantity tiket untuk $mountainName ($hikingDate) berhasil dibuat. Silakan lanjutkan ke pembayaran.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        if (paymentUrl != null) {
          Get.to(() => PaymentWebviewPage(paymentUrl: paymentUrl));
        }

        // Refresh kuota setelah booking berhasil
        fetchTickets();
      } else {
        final message = res.body is Map
            ? (res.body['message'] ?? 'Gagal membuat tiket.')
            : 'Gagal membuat tiket (status ${res.statusCode}).';

        Get.snackbar(
          "Gagal Booking",
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("bookTicket exception: $e");
      Get.snackbar(
        "Error",
        "Tidak dapat terhubung ke server: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> fetchMyTickets() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return;

    try {
      isLoadingHistory.value = true;
      final response = await GetConnect().get(
        "${ApiConfig.baseUrl}/api/tickets/my",
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
      );

      if (response.statusCode == 200 && response.body is List) {
        myTickets.assignAll(response.body);
      }
    } catch (e) {
      print("fetchMyTickets exception: $e");
    } finally {
      isLoadingHistory.value = false;
    }
  }
}