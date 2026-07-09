import 'package:get/get.dart';

import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/register_view.dart';
import '../modules/home/views/home_view.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/main_navigation/views/main_navigation_view.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/map/views/map_view.dart';
import '../modules/profile/bindings/profile_binding.dart';

// Import file SewaJasaView yang baru ditambahkan di sini
import '../modules/sewa_jasa/views/sewa_jasa_view.dart';

import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => LoginView(),
    ),
    GetPage(
      name: AppRoutes.REGISTER,
      page: () => RegisterView(),
    ),
    GetPage(
      name: AppRoutes.HOME,
      page: () => HomeView(),
    ),
    GetPage(
      name: AppRoutes.PROFILE,
      page: () => ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => SplashView(),
    ),
    GetPage(
      name: AppRoutes.MAP,
      page: () => const MapView(),
    ),
    GetPage(
      name: AppRoutes.MAIN_NAVIGATION,
      page: () => MainNavigationView(),
    ),
    GetPage(
      name: AppRoutes.SEWA_JASA,
      page: () => const SewaJasaView(),
    ),
    
  ];
}