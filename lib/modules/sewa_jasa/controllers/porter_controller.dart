import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone2/core/utils/api_config.dart';

class PorterController extends GetxController {
  var isLoading = false.obs;
  var listPorter = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    // fetchPorters(); // Buka komentar kalau API udah siap
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('jwt_token') ?? '';
    if (token.startsWith("Bearer ")) {
      token = token.replaceFirst("Bearer ", "");
    }
    return token;
  }

  void fetchPorters() async {
    try {
      isLoading.value = true;
      String token = await _getToken();

      // GANTI ENDPOINT INI SESUAI API LO
      final response = await GetConnect().get(
        "${ApiConfig.baseUrl}/api/porters", 
        headers: {"Authorization": token},
      ).timeout(const Duration(seconds: 10));

      isLoading.value = false;

      if (response.statusCode == 200 && response.body != null) {
        listPorter.assignAll(response.body); // Asumsi response berbentuk List
      } else {
        Get.snackbar("Gagal", "Gagal mengambil data porter");
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Koneksi ke server gagal.");
    }
  }
}