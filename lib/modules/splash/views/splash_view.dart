import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashView extends StatelessWidget {
  SplashView({super.key});

  final SplashController controller =
      Get.put(SplashController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Center(

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: const [

            Icon(
              Icons.landscape,
              size: 120,
              color: Colors.green,
            ),

            SizedBox(height: 20),

            Text(
              "Summit Explore",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            CircularProgressIndicator(),

          ],
        ),
      ),
    );
  }
}