// sos_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sos_controller.dart';
import '../services/rescue_connectivity_service.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with SingleTickerProviderStateMixin {
  final SosController c = Get.put(SosController());
  late final AnimationController _pulseController;

  static const double _radarSize = 320;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1B22),
      body: SafeArea(
        child: Obx(() {
          final users = c.nearbyUsers.values.toList();
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                const Text(
                  "SOS Rescue",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Deteksi pendaki sekitar",
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
                const SizedBox(height: 32),
                _buildRadar(users),
                const SizedBox(height: 32),
                if (c.errorMessage.value.isNotEmpty) _buildErrorBanner(),
                _buildDetectedCard(users.length),
                const SizedBox(height: 24),
                if (c.emergencyLog.isNotEmpty) _buildEmergencyLog(),
                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                c.errorMessage.value,
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadar(List<NearbyUser> users) {
    return SizedBox(
      width: _radarSize,
      height: _radarSize,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // ring luar berdenyut
              _pulsingRing(_radarSize, 0.15),
              _pulsingRing(_radarSize * 0.78, 0.22),
              _pulsingRing(_radarSize * 0.56, 0.30),
              // titik-titik pendaki di sekitar radar
              for (int i = 0; i < users.length; i++)
                _userDot(users[i], i, users.length),
              // tombol SOS di tengah
              _sosButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _pulsingRing(double baseSize, double opacity) {
    final t = _pulseController.value;
    final size = baseSize * (0.9 + 0.1 * sin(t * 2 * pi));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2E5C4F).withOpacity(opacity),
        border: Border.all(
          color: const Color(0xFF4FD1A5).withOpacity(0.25),
        ),
      ),
    );
  }

  Widget _userDot(NearbyUser user, int index, int total) {
    final angle = (2 * pi * index / max(total, 1)) - pi / 2;
    final radius = _radarSize * 0.38;
    final dx = radius * cos(angle);
    final dy = radius * sin(angle);

    final color = user.isInDanger ? Colors.redAccent : const Color(0xFF4FD1A5);

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color, color.withOpacity(0.6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.6),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sosButton() {
    return GestureDetector(
      onTap: () => c.toggleSOS(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 190,
        height: 190,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: c.isSosActive.value
                ? [const Color(0xFFFF5252), const Color(0xFFB71C1C)]
                : [const Color(0xFFFF6B5B), const Color(0xFFE53935)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: c.isSosActive.value ? 6 : 2,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          c.isSosActive.value ? "STOP" : "SOS",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildDetectedCard(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2E5C4F).withOpacity(0.5),
              ),
              child: const Icon(Icons.groups_rounded,
                  color: Color(0xFF4FD1A5), size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pendaki Terdeteksi",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.isInitializing.value
                        ? "Mengaktifkan deteksi offline..."
                        : "$count pengguna aktif di sekitar area Anda",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyLog() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Riwayat Sinyal Darurat",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          for (final entry in c.emergencyLog.take(5))
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emergency_rounded,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "${entry['name']}: ${entry['message']}",
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  Text(
                    entry['time'] ?? '',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
