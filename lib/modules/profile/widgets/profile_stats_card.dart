import 'package:flutter/material.dart';

class ProfileStatsCard extends StatelessWidget {

  final String title;
  final String value;

  const ProfileStatsCard({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {

    return Expanded(
      child: Container(

        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 20),

        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),

          border: Border.all(
            color: Colors.white12,
          ),
        ),

        child: Column(
          children: [

            Text(
              value,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),

          ],
        ),
      ),
    );
  }
}