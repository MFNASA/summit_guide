import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {

  final String text;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {

    return SizedBox(

      width: double.infinity,
      height: 58,

      child: ElevatedButton(

        onPressed: onPressed,

        style: ElevatedButton.styleFrom(

          backgroundColor: Colors.greenAccent.shade400,

          elevation: 10,

          shadowColor:
              Colors.greenAccent.withOpacity(0.5),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          padding: const EdgeInsets.symmetric(
            vertical: 15,
          ),
        ),

        child: Text(
          text,

          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}