import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:capstone2/core/widgets/custom_button.dart';
import 'package:capstone2/core/widgets/custom_textfield.dart';
import 'package:capstone2/modules/auth/controllers/auth_controller.dart';
import 'package:capstone2/modules/auth/views/otp_view.dart';

class RegisterView extends StatelessWidget {
  RegisterView({super.key});

  final AuthController controller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white10,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.4),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_add,
                      size: 85,
                      color: Colors.greenAccent,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Create Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Register and start your adventure",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 45),

                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white12,
                      ),
                    ),
                    child: Column(
                      children: [
                        CustomTextField(
                          hint: "Nama Lengkap",
                          icon: Icons.person,
                          controller: controller.nameController,
                        ),

                        const SizedBox(height: 20),

                        CustomTextField(
                          hint: "Email",
                          icon: Icons.email,
                          controller: controller.emailController,
                        ),

                        const SizedBox(height: 20),

                        CustomTextField(
                          hint: "Password",
                          icon: Icons.lock,
                          obscureText: true,
                          controller: controller.passwordController,
                        ),

                        const SizedBox(height: 35),

                        Obx(() {
                          if (controller.isLoading.value) {
                            return const CircularProgressIndicator(
                              color: Colors.greenAccent,
                            );
                          }

                          return CustomButton(
                            text: "Register",
                            onPressed: () async {

  bool success = await controller.register();

  if (success) {
    Get.to(
      () => OtpView(),
      arguments: controller.emailController.text.trim(),
    );
  }

},
                          );
                        }),

                        const SizedBox(height: 20),

                        TextButton(
                          onPressed: () {
                            Get.back();
                          },
                          child: const Text(
                            "Sudah punya akun? Login",
                            style: TextStyle(
                              color: Colors.greenAccent,
                            ),
                          ),
                        ),
                      ],
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