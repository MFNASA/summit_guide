import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // WAJIB: inisialisasi backend FMTC SEBELUM store/tile manapun dipakai.
  // Tanpa ini, semua operasi download peta offline akan gagal dengan
  // error "RootUnavailable".
  await FMTCObjectBoxBackend().initialise();

  await GetStorage.init(); // wajib

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.SPLASH,
      getPages: AppPages.pages,
    );
  }
}