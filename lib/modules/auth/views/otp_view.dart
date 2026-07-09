import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone2/modules/auth/controllers/auth_controller.dart';

class OtpView extends StatefulWidget {
  const OtpView({super.key});

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  final TextEditingController otpController = TextEditingController();
  final AuthController controller = Get.find<AuthController>();

  late final String email;

  @override
  void initState() {
    super.initState();
    email = Get.arguments ?? "example@gmail.com";
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  // ICON
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      color: Colors.greenAccent,
                      size: 55,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Verifikasi OTP",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Masukkan kode OTP yang telah dikirim ke",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // OTP TEXTFIELD
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: "******",
                      hintStyle: const TextStyle(
                        color: Colors.white38,
                      ),
                      filled: true,
                      fillColor: Colors.white.withAlpha(20),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // BUTTON — sekarang benar-benar memanggil API verifikasi
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          disabledBackgroundColor:
                              Colors.greenAccent.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: controller.isLoading.value
                            ? null
                            : () async {
                                final success = await controller.verifyOtp(
                                  email,
                                  otpController.text,
                                );

                                // Hanya pindah halaman kalau verifikasi
                                // benar-benar sukses di backend
                                if (success) {
                                  Get.offAllNamed('/main-navigation');
                                }
                              },
                        child: controller.isLoading.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Verifikasi",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Tidak menerima kode?",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),

                  // Tombol resend — sekarang benar-benar memanggil API
                  TextButton(
                    onPressed: () {
                      controller.resendOtp(email);
                    },
                    child: const Text(
                      "Kirim Ulang OTP",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}