import 'package:flutter/material.dart';

class ProfileMenuItem extends StatelessWidget {

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.only(bottom: 15),

      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: Colors.white12,
        ),
      ),

      child: ListTile(

        leading: Icon(
          icon,
          color: color ?? Colors.greenAccent,
        ),

        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),

        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white54,
          size: 16,
        ),

        onTap: onTap,
      ),
    );
  }
}