import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();

    return Scaffold(
      // Background utama disesuaikan dengan warna dark teal
      backgroundColor: const Color(0xFF1A2E31),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'EDIT PROFIL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0, // disamakan dengan ProfileView (sebelumnya 1.5)
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        // Prioritas tampilan foto: foto baru yang baru dipilih > foto lama dari server > icon default
        ImageProvider? previewImage;
        if (controller.selectedImagePath.value.isNotEmpty) {
          previewImage = FileImage(File(controller.selectedImagePath.value));
        } else if (controller.avatarUrl != null) {
          previewImage = NetworkImage(controller.avatarUrl!);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar — treatment sama persis dengan ProfileView (border hijau + glow)
              GestureDetector(
                onTap: () => controller.pickImage(),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Border hijau
                        border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                        boxShadow: [
                          BoxShadow(
                            // Shadow hijau
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
                        backgroundImage: previewImage,
                        child: previewImage == null
                            ? const Icon(Icons.person_outline, size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        // Background icon kamera hijau
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      // Icon kamera diubah jadi putih agar kontras dengan hijau
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Ketuk untuk ganti foto",
                // Warna teks redup kebiruan
                style: TextStyle(color: Color(0xFF98A9AC), fontSize: 12),
              ),
              const SizedBox(height: 40),

              // ==== SECTION: INFORMASI AKUN — dibungkus card, sama seperti ProfileView ====
              _sectionLabel('INFORMASI AKUN'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // Warna card teal terang
                  color: const Color(0xFF243B3E),
                  borderRadius: BorderRadius.circular(16),
                  // Warna border card
                  border: Border.all(color: const Color(0xFF314B4F)),
                ),
                child: Column(
                  children: [
                    _buildTextField(controller.nameCtrl, 'Nama Lengkap', Icons.person),
                    const SizedBox(height: 14),
                    _buildTextField(controller.phoneCtrl, 'Nomor HP', Icons.phone),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ==== SECTION: KEAMANAN — dibungkus card, style label sama dengan section di atas ====
              _sectionLabel('KEAMANAN (OPSIONAL)'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // Warna card teal terang
                  color: const Color(0xFF243B3E),
                  borderRadius: BorderRadius.circular(16),
                  // Warna border card
                  border: Border.all(color: const Color(0xFF314B4F)),
                ),
                child: Column(
                  children: [
                    _buildTextField(controller.oldPassCtrl, 'Password Lama', Icons.lock_outline, isObscure: true),
                    const SizedBox(height: 14),
                    _buildTextField(controller.newPassCtrl, 'Password Baru', Icons.lock, isObscure: true),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // Warna tombol simpan diubah ke hijau
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: controller.isUpdating.value ? null : () => controller.updateProfile(),
                  child: controller.isUpdating.value
                      // Indikator loading dan teks diubah putih agar kontras dengan hijau
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SIMPAN PERUBAHAN',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ==== HELPER UI: sama persis dengan yang dipakai di ProfileView biar serasi ====
  Widget _sectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          // Teks label kebiruan
          color: Color(0xFF98A9AC),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {bool isObscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        // Hint text disamakan warnanya dengan teks redup
        hintStyle: const TextStyle(color: Color(0xFF98A9AC)),
        // Ikon prefix jadi hijau
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
        filled: true,
        // Fill color TextField menggunakan background utama supaya terlihat "masuk" ke dalam card
        fillColor: const Color(0xFF1A2E31),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          // Border saat fokus menjadi hijau
          borderSide: const BorderSide(color: Color(0xFF4CAF50)),
        ),
      ),
    );
  }
}