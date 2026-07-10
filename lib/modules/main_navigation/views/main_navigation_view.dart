import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../home/views/home_view.dart';
import '../../profile/views/profile_view.dart';
import '../../map/views/map_view.dart';
import '../../scan/views/scan_view.dart';
import '../../sos/views/sos_screen.dart';

// 1. IMPORT BARU (Sewa Jasa) menggantikan Rental yang udah dihapus
import '../../sewa_jasa/views/sewa_jasa_view.dart'; 

import '../controllers/main_navigation_controller.dart';

class MainNavigationView extends StatelessWidget {
  MainNavigationView({super.key});

  final MainNavigationController controller =
      Get.put(MainNavigationController());

  // 2. GANTI RentalView() jadi SewaJasaView()
  final List<Widget> pages = [
    const HomeView(),
    const MapView(),
    const SewaJasaView(), // <- Panggil fitur all-in-one di sini
    const ScanView(),
    const SosScreen(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    final dynamic args = Get.arguments;
    final int selectedPage = args is int ? args : 0;

    controller.selectedIndex.value = selectedPage;

    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0F2027),
                Color(0xFF203A43),
                Color(0xFF2C5364),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: controller.selectedIndex.value,
            onTap: controller.changeIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.greenAccent,
            unselectedItemColor: Colors.white54,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'Map',
              ),
              // 3. Label diubah jadi 'Layanan' biar mencakup semua (Rental, Porter, Tiket)
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag),
                label: 'Layanan', 
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner),
                label: 'Scan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sos),
                label: 'SOS',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}