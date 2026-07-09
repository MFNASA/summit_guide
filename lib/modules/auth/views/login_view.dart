import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';

import '../../../routes/app_routes.dart';

import '../controllers/auth_controller.dart';

class LoginView extends StatelessWidget {

  LoginView({super.key});

  final AuthController controller =
      Get.put(AuthController());

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

                  const SizedBox(height: 20),

                  /// LOGO
                  Container(
                    padding: const EdgeInsets.all(25),

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white10,

                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.greenAccent.withOpacity(0.4),
                          blurRadius: 25,
                        ),
                      ],
                    ),

                    child: const Icon(
                      Icons.landscape,
                      size: 90,
                      color: Colors.greenAccent,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// TITLE
                  const Text(
                    "Summit Explore",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Explore Nature With Confidence",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 50),

                  /// FORM CONTAINER
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

                        /// EMAIL
                        CustomTextField(
                          hint: "Email",
                          icon: Icons.email,

                          controller:
                              controller.emailController,
                        ),

                        const SizedBox(height: 20),

                        /// PASSWORD
                        CustomTextField(
                          hint: "Password",
                          icon: Icons.lock,
                          obscureText: true,

                          controller:
                              controller.passwordController,
                        ),

                        const SizedBox(height: 30),

                        /// LOGIN BUTTON
                        CustomButton(
                          text: "Login",

                          onPressed: () {

                            controller.login();

                          },
                        ),

                        const SizedBox(height: 20),

                        /// GOOGLE LOGIN
                        SizedBox(
                          width: double.infinity,
                          height: 55,

                          child: OutlinedButton.icon(

                            style: OutlinedButton.styleFrom(

                              side: const BorderSide(
                                color: Colors.white24,
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                            ),

                            onPressed: () {

                              controller
                                  .signInWithGoogle();

                            },

                            icon: const Icon(
                              Icons.login,
                              color: Colors.white,
                            ),

                            label: const Text(
                              "Login with Google",

                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// REGISTER
                        TextButton(

                          onPressed: () {

                            Get.toNamed(
                              AppRoutes.REGISTER,
                            );

                          },

                          child: const Text(
                            "Belum punya akun? Register",

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