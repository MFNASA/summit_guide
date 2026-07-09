import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    checkLogin();
  }

  void checkLogin() {
    Timer(
      const Duration(seconds: 2),
      () {
        final isLoggedIn = box.read('isLoggedIn') ?? false;

        if (isLoggedIn) {
          Get.offAllNamed(AppRoutes.MAIN_NAVIGATION);
        } else {
          Get.offAllNamed(AppRoutes.LOGIN);
        }
      },
    );
  }
}