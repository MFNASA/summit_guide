import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import 'edit_profile_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.put(ProfileController());

    return Scaffold(
      // Background utama disesuaikan dengan warna dark teal dari gambar
      backgroundColor: const Color(0xFF1A2E31),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'PROFILE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            // Ikon aksen diubah menjadi hijau
            icon: const Icon(Icons.edit_note, color: Color(0xFF4CAF50), size: 30),
            onPressed: () => Get.to(() => const EditProfileView()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            // Loading indicator hijau
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
          );
        }

        var user = controller.userData;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Foto Profil — pakai avatarUrl (sudah digabung base URL di controller)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Border hijau
                  border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                  boxShadow: [
                    BoxShadow(
                      // Shadow hijau transparansi
                      color: const Color(0xFF4CAF50).withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  // Background placeholder disesuaikan dengan warna card
                  backgroundColor: const Color(0xFF243B3E),
                  backgroundImage: controller.avatarUrl != null
                      ? NetworkImage(controller.avatarUrl!)
                      : null,
                  child: controller.avatarUrl == null
                      ? const Icon(Icons.person_outline, size: 50, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                user['name'] ?? 'USER TIDAK DIKENAL',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user['email'] ?? 'Belum ada email terhubung',
                style: const TextStyle(
                  // Warna text subtitle disesuaikan agak kebiruan
                  color: Color(0xFF98A9AC),
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 40),

              // ==== SECTION: INFORMASI AKUN ====
              _sectionLabel('INFORMASI AKUN'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  // Warna container list disesuaikan dengan card di gambar
                  color: const Color(0xFF243B3E),
                  borderRadius: BorderRadius.circular(16),
                  // Border antar container
                  border: Border.all(color: const Color(0xFF314B4F)),
                ),
                child: Column(
                  children: [
                    _buildListTile(Icons.phone_android, 'Nomor HP', user['phone'] ?? 'Belum diatur'),
                    // Divider color
                    const Divider(color: Color(0xFF314B4F), height: 1),
                    _buildListTile(
                      Icons.verified_user_outlined,
                      'Status Akun',
                      _statusLabel(user['status']),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C), // Tetap merah untuk tombol logout
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () => controller.logout(),
                  child: const Text(
                    'LOGOUT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _statusLabel(dynamic status) {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'unverified':
        return 'Belum Verifikasi Email';
      case 'suspended':
        return 'Diblokir';
      default:
        return 'Tidak diketahui';
    }
  }

  Widget _sectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          // Warna teks label
          color: Color(0xFF98A9AC),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            // Background icon menggunakan warna background utama agar terlihat "masuk"
            color: const Color(0xFF1A2E31),
            borderRadius: BorderRadius.circular(10),
          ),
          // Warna ikon diubah ke hijau
          child: Icon(icon, color: const Color(0xFF4CAF50), size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF98A9AC),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}