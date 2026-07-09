import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {

  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {

    return TextField(

      controller: controller,
      obscureText: obscureText,

      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),

      decoration: InputDecoration(

        hintText: hint,

        hintStyle: const TextStyle(
          color: Colors.white54,
        ),

        prefixIcon: Icon(
          icon,
          color: Colors.greenAccent,
        ),

        filled: true,

        fillColor: Colors.white10,

        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 20,
        ),

        enabledBorder: OutlineInputBorder(

          borderRadius: BorderRadius.circular(20),

          borderSide: const BorderSide(
            color: Colors.white12,
          ),
        ),

        focusedBorder: OutlineInputBorder(

          borderRadius: BorderRadius.circular(20),

          borderSide: const BorderSide(
            color: Colors.greenAccent,
            width: 1.5,
          ),
        ),

        border: OutlineInputBorder(

          borderRadius: BorderRadius.circular(20),

          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}