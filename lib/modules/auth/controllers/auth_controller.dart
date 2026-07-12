import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// IMPORT FILE CONFIG PUSAT
import '../../../core/utils/api_config.dart';
import '../../../core/utils/local_activity_logger.dart'; // Sesuaikan letak folder api_config.dart kamu

class AuthController extends GetxController {
  // Controller untuk menangkap input dari textfield
  final otpController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // State loading untuk efek interaksi premium saat proses API backend berjalan
  var isLoading = false.obs;

  // Storage untuk menyimpan token JWT secara persisten
  final GetStorage _box = GetStorage();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '886718944338-84i2evu6l6t8kn71pot55omjqb53nmv7.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  /// Helper terpusat untuk menyimpan token + data user setelah login berhasil.
  /// Dipanggil baik dari login email maupun login Google, supaya konsisten.
  Future<void> _saveSession(Map<String, dynamic> data) async {
    final token = data['token'];
    if (token != null) {
      await _box.write('token', token);
    }

    // Simpan juga info user dasar kalau backend mengirimkannya,
    // berguna untuk ditampilkan di halaman profile tanpa perlu fetch ulang.
    if (data['user'] != null) {
      await _box.write('user', jsonEncode(data['user']));
    }
    await LocalActivityLogger.log('Login berhasil');
  }

  /// ==========================================
  /// 1. FUNGSI LOGIN BIASA (EMAIL & PASSWORD)
  /// ==========================================
  Future<void> login() async {
    // Validasi awal agar user tidak mengirim form kosong
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      Get.snackbar(
        "Peringatan", "Email dan Password tidak boleh kosong!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Aktifkan efek loading
      isLoading.value = true;
      print("Mengirim data login ke Flask...");

      // Mengirim request POST ke endpoint login biasa di Flask
      final response = await http.post(
        Uri.parse(ApiConfig.emailLogin),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
        }),
      );

      // Mengecek respon dari server Flask (Umumnya mengembalikan status 200 OK jika sukses)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Login Biasa Sukses! JWT: ${data['token']}");

        // ====== PERBAIKAN UTAMA: simpan token ke GetStorage ======
        await _saveSession(data);

        Get.snackbar(
          "Sukses", "Selamat Datang Kembali!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Bersihkan textfield setelah sukses login
        emailController.clear();
        passwordController.clear();

        // Langsung arahkan user masuk ke halaman utama / Home Page
        Get.offAllNamed('/main-navigation');
      } else {
        // Handle jika password salah atau email tidak terdaftar
        final errorData = jsonDecode(response.body);
        print("Login Gagal: ${response.body}");

        Get.snackbar(
          "Login Gagal", errorData['message'] ?? "Email atau Password salah.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (error) {
      print("Terjadi kesalahan saat Login Biasa: $error");
      Get.snackbar(
        "Error", "Tidak dapat terhubung ke server backend: $error",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      // Matikan efek loading
      isLoading.value = false;
    }
  }

  /// ==========================================
  /// 2. REGISTER
  /// ==========================================
  Future<bool> register() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      Get.snackbar(
        "Peringatan",
        "Semua kolom wajib diisi!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return false;
    }

    try {
      isLoading.value = true;

      final response = await http.post(
        Uri.parse(ApiConfig.emailRegister),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          "Berhasil",
          "Kode OTP berhasil dikirim ke email.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // JANGAN CLEAR CONTROLLER DI SINI
        // JANGAN PINDAH KE MAIN NAVIGATION

        return true;
      } else {
        final data = jsonDecode(response.body);

        Get.snackbar(
          "Register Gagal",
          data["message"] ?? "Terjadi kesalahan.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );

        return false;
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// ==========================================
  /// 2b. VERIFIKASI OTP
  /// ==========================================
  /// Memanggil endpoint /api/auth/verify-otp di Flask, dan kalau sukses,
  /// langsung menyimpan token JWT yang dikembalikan backend.
  /// Return true/false supaya OtpView tahu harus navigasi atau tidak.
  Future<bool> verifyOtp(String email, String otp) async {
    if (otp.trim().length != 6) {
      Get.snackbar(
        "Peringatan",
        "Kode OTP harus 6 digit!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return false;
    }

    try {
      isLoading.value = true;

      final response = await http.post(
        Uri.parse(ApiConfig.verifyOtp),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Simpan token JWT yang dikembalikan backend setelah verifikasi sukses
        await _saveSession(data);

        Get.snackbar(
          "Berhasil",
          data['message'] ?? "Verifikasi berhasil!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        return true;
      } else {
        Get.snackbar(
          "Verifikasi Gagal",
          data['message'] ?? "Kode OTP salah atau sudah kedaluwarsa.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      print("Error verifyOtp: $e");
      Get.snackbar(
        "Error",
        "Tidak dapat terhubung ke server: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// ==========================================
  /// 2c. KIRIM ULANG OTP
  /// ==========================================
  Future<void> resendOtp(String email) async {
    try {
      isLoading.value = true;

      final response = await http.post(
        Uri.parse(ApiConfig.resendOtp),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Get.snackbar(
          "OTP Terkirim",
          data['message'] ?? "Kode OTP baru telah dikirim ke email kamu.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "Gagal",
          data['message'] ?? "Gagal mengirim ulang OTP.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("Error resendOtp: $e");
      Get.snackbar(
        "Error",
        "Tidak dapat terhubung ke server: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// ==========================================
  /// 3. FUNGSI LOGIN VIA GOOGLE AUTHENTICATION
  /// ==========================================
  Future<void> signInWithGoogle() async {
    try {
      // Aktifkan status loading
      isLoading.value = true;

      // Langkah A: Munculkan popup login Google di HP
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("User membatalkan login");
        return;
      }

      // Langkah B: Dapatkan token autentikasi
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken != null) {
        print("Google Auth sukses, mengirim token ke Flask...");

        // Langkah C: Kirim token ke API Flask ngrok kamu menggunakan ApiConfig pusat
        final response = await http.post(
          Uri.parse(ApiConfig.googleLogin),
          headers: {
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true',
          },
          body: jsonEncode({'token': idToken}),
        );

        // Langkah D: Cek respon dari Flask
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("Login Sukses! JWT: ${data['token']}");

          // ====== PERBAIKAN UTAMA: simpan token ke GetStorage ======
          await _saveSession(data);

          Get.snackbar(
            "Sukses", "Selamat Datang!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );

          // PINDAH KE HALAMAN HOME / MAIN NAVIGATION
          Get.offAllNamed('/main-navigation');
        } else {
          print("Login Gagal dari Server: ${response.body}");
          Get.snackbar(
            "Login Gagal", "Verifikasi server gagal: ${response.body}",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        }
      }
    } catch (error) {
      print("Terjadi kesalahan Google Auth: $error");
      Get.snackbar(
        "Error", "Terjadi kesalahan: $error",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      // Matikan status loading entah prosesnya sukses ataupun gagal
      isLoading.value = false;
    }
  }

  /// ==========================================
  /// 4. LOGOUT — hapus token dari storage
  /// ==========================================
  Future<void> logout() async {
    await _box.remove('token');
    await _box.remove('user');
    Get.offAllNamed('/login'); // sesuaikan dengan nama route login kamu
  }

  @override
  void onClose() {
    // Dipanggil untuk mencegah kebocoran memori (memory leak)
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}