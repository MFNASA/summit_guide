import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String username;
  final String email;

  const ProfileHeader({
    super.key,
    required this.username,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage(
            'assets/images/profile.jpg',
          ),
        ),
        const SizedBox(height: 14),
        Text(
          username,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}