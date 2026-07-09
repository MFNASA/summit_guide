import 'dart:math';

import 'package:flutter/material.dart';

class SosView extends StatefulWidget {
  const SosView({super.key});

  @override
  State<SosView> createState() => _SosViewState();
}

class _SosViewState extends State<SosView>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  bool sosActive = false;

  String? selectedUser;

  final List<Map<String, dynamic>> nearbyUsers = [

    {
      "name": "Rizky",
      "distance": "120 m",
      "angle": 20.0,
      "status": "Online",
      "battery": "89%",
    },

    {
      "name": "Andi",
      "distance": "250 m",
      "angle": 120.0,
      "status": "Mendaki",
      "battery": "71%",
    },

    {
      "name": "Fajar",
      "distance": "80 m",
      "angle": 220.0,
      "status": "Camping",
      "battery": "63%",
    },

    {
      "name": "Budi",
      "distance": "400 m",
      "angle": 310.0,
      "status": "Istirahat",
      "battery": "52%",
    },

  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void activateSOS() {

    setState(() {
      sosActive = true;
    });

    showDialog(

      context: context,

      builder: (_) {

        return Dialog(

          backgroundColor: Colors.transparent,

          child: Container(

            padding: const EdgeInsets.all(25),

            decoration: BoxDecoration(

              borderRadius:
                  BorderRadius.circular(35),

              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1B2735),
                  Color(0xFF203A43),
                ],
              ),

              border: Border.all(
                color: Colors.orangeAccent,
                width: 2,
              ),

              boxShadow: [

                BoxShadow(
                  color: Colors.orangeAccent
                      .withOpacity(0.4),

                  blurRadius: 25,
                ),

              ],
            ),

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                Container(

                  width: 95,
                  height: 95,

                  decoration: BoxDecoration(

                    shape: BoxShape.circle,

                    gradient: LinearGradient(
                      colors: [
                        Colors.orange,
                        Colors.deepOrangeAccent,
                      ],
                    ),

                    boxShadow: [

                      BoxShadow(
                        color: Colors.orange
                            .withOpacity(0.7),

                        blurRadius: 35,
                      ),

                    ],
                  ),

                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 55,
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  "SOS BERHASIL DIKIRIM",
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  "Pendaki sekitar menerima notifikasi darurat dan lokasi Anda.",
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 30),

                Container(

                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius:
                        BorderRadius.circular(22),
                  ),

                  child: const Row(

                    children: [

                      Icon(
                        Icons.location_on,
                        color: Colors.orangeAccent,
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          "Lokasi darurat berhasil dibagikan",
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(

                  width: double.infinity,

                  child: ElevatedButton(

                    onPressed: () {
                      Navigator.pop(context);
                    },

                    style: ElevatedButton.styleFrom(

                      backgroundColor:
                          Colors.orangeAccent,

                      foregroundColor:
                          Colors.black,

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 18,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          22,
                        ),
                      ),
                    ),

                    child: const Text(
                      "OKE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        );
      },
    );
  }

  void showUserDetail(Map<String, dynamic> user) {

    setState(() {
      selectedUser = user["name"];
    });

    showModalBottomSheet(

      context: context,

      backgroundColor: Colors.transparent,

      isScrollControlled: true,

      builder: (_) {

        return Container(

          padding: const EdgeInsets.all(25),

          decoration: const BoxDecoration(

            color: Color(0xFF1B2735),

            borderRadius: BorderRadius.vertical(
              top: Radius.circular(35),
            ),
          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Container(
                width: 70,
                height: 5,

                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 25),

              Container(

                width: 100,
                height: 100,

                decoration: BoxDecoration(

                  shape: BoxShape.circle,

                  gradient: LinearGradient(
                    colors: [
                      Colors.greenAccent,
                      Colors.green,
                    ],
                  ),

                  boxShadow: [

                    BoxShadow(
                      color: Colors.greenAccent
                          .withOpacity(0.5),

                      blurRadius: 30,
                    ),

                  ],
                ),

                child: const Icon(
                  Icons.person,
                  color: Colors.black,
                  size: 50,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                user["name"],

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  _miniInfo(
                    Icons.social_distance,
                    user["distance"],
                  ),

                  const SizedBox(width: 15),

                  _miniInfo(
                    Icons.battery_full,
                    user["battery"],
                  ),

                ],
              ),

              const SizedBox(height: 18),

              Container(

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),

                decoration: BoxDecoration(
                  color: Colors.greenAccent
                      .withOpacity(0.15),

                  borderRadius:
                      BorderRadius.circular(20),
                ),

                child: Text(
                  user["status"],

                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Container(

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius:
                      BorderRadius.circular(25),
                ),

                child: const Text(
                  "Pendaki dapat dihubungi untuk membantu proses evakuasi atau bantuan darurat.",
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: [

                  Expanded(

                    child: ElevatedButton.icon(

                      onPressed: () {

                        Navigator.pop(context);

                        showConnectingUI(
                          user["name"],
                          true,
                        );
                      },

                      icon: const Icon(
                        Icons.call,
                      ),

                      label: const Text(
                        "Hubungi",
                      ),

                      style:
                          ElevatedButton.styleFrom(

                        backgroundColor:
                            Colors.greenAccent,

                        foregroundColor:
                            Colors.black,

                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 18,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(

                    child: ElevatedButton.icon(

                      onPressed: () {

                        Navigator.pop(context);

                        showConnectingUI(
                          user["name"],
                          false,
                        );
                      },

                      icon: const Icon(
                        Icons.chat_bubble,
                      ),

                      label: const Text(
                        "Chat",
                      ),

                      style:
                          ElevatedButton.styleFrom(

                        backgroundColor:
                            Colors.blueAccent,

                        foregroundColor:
                            Colors.white,

                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 18,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
              ),

              const SizedBox(height: 20),

            ],
          ),
        );
      },
    );
  }

  void showConnectingUI(
    String name,
    bool isCall,
  ) {

    showDialog(

      context: context,

      barrierDismissible: false,

      builder: (_) {

        return Dialog(

          backgroundColor: Colors.transparent,

          child: Container(

            padding: const EdgeInsets.all(28),

            decoration: BoxDecoration(

              color: const Color(0xFF203A43),

              borderRadius:
                  BorderRadius.circular(35),

              border: Border.all(
                color: isCall
                    ? Colors.greenAccent
                    : Colors.blueAccent,
              ),
            ),

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                TweenAnimationBuilder(

                  tween: Tween<double>(
                    begin: 0.8,
                    end: 1.1,
                  ),

                  duration:
                      const Duration(seconds: 1),

                  curve: Curves.easeInOut,

                  builder: (context, value, child) {

                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },

                  child: Container(

                    width: 100,
                    height: 100,

                    decoration: BoxDecoration(

                      shape: BoxShape.circle,

                      gradient: LinearGradient(
                        colors: isCall
                            ? [
                                Colors.greenAccent,
                                Colors.green,
                              ]
                            : [
                                Colors.blueAccent,
                                Colors.lightBlue,
                              ],
                      ),
                    ),

                    child: Icon(
                      isCall
                          ? Icons.call
                          : Icons.chat,

                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Text(
                  isCall
                      ? "Menghubungi $name"
                      : "Membuka chat $name",

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                const CircularProgressIndicator(
                  color: Colors.white,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Menunggu respon pengguna...",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(

                  width: double.infinity,

                  child: ElevatedButton(

                    onPressed: () {
                      Navigator.pop(context);
                    },

                    style: ElevatedButton.styleFrom(

                      backgroundColor:
                          Colors.redAccent,

                      foregroundColor:
                          Colors.white,

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 16,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),
                    ),

                    child: const Text(
                      "Batalkan",
                    ),
                  ),
                ),

              ],
            ),
          ),
        );
      },
    );
  }

  Widget _miniInfo(
    IconData icon,
    String text,
  ) {

    return Container(

      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 10,
      ),

      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Row(

        children: [

          Icon(
            icon,
            color: Colors.greenAccent,
            size: 18,
          ),

          const SizedBox(width: 8),

          Text(
            text,

            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

        ],
      ),
    );
  }

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

          child: Column(

            children: [

              const SizedBox(height: 20),

              const Text(
                "SOS Rescue",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Deteksi pendaki sekitar",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 35),

              Expanded(

                child: Center(

                  child: AnimatedBuilder(

                    animation: _controller,

                    builder: (context, child) {

                      return SizedBox(

                        width: 350,
                        height: 350,

                        child: Stack(

                          alignment: Alignment.center,

                          children: [

                            CustomPaint(

                              size: const Size(
                                350,
                                350,
                              ),

                              painter: RadarPainter(
                                animationValue:
                                    _controller.value,
                              ),
                            ),

                            ...nearbyUsers.map((user) {

                              final angle =
                                  (user["angle"] as double) *
                                      pi /
                                      180;

                              final radius = 125.0;

                              final dx =
                                  175 +
                                      radius *
                                          cos(angle);

                              final dy =
                                  175 +
                                      radius *
                                          sin(angle);

                              return Positioned(

                                left: dx - 25,
                                top: dy - 25,

                                child: GestureDetector(

                                  onTap: () {
                                    showUserDetail(user);
                                  },

                                  child: Column(

                                    children: [

                                      Container(

                                        width: 28,
                                        height: 28,

                                        decoration:
                                            BoxDecoration(

                                          shape:
                                              BoxShape.circle,

                                          gradient:
                                              const LinearGradient(

                                            colors: [
                                              Colors.greenAccent,
                                              Colors.green,
                                            ],
                                          ),

                                          boxShadow: [

                                            BoxShadow(
                                              color: Colors
                                                  .greenAccent
                                                  .withOpacity(
                                                      0.8),

                                              blurRadius: 20,
                                            ),

                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 5),

                                      Text(
                                        user["name"],

                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.white,
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),

                                    ],
                                  ),
                                ),
                              );
                            }).toList(),

                            GestureDetector(

                              onTap: activateSOS,

                              child: Container(

                                width: 110,
                                height: 110,

                                decoration: BoxDecoration(

                                  shape: BoxShape.circle,

                                  gradient:
                                      LinearGradient(

                                    colors: sosActive
                                        ? [
                                            Colors.orange,
                                            Colors.deepOrange,
                                          ]
                                        : [
                                            Colors.redAccent,
                                            Colors.red,
                                          ],
                                  ),

                                  boxShadow: [

                                    BoxShadow(
                                      color:
                                          Colors.redAccent
                                              .withOpacity(
                                                  0.7),

                                      blurRadius: 40,
                                    ),

                                  ],
                                ),

                                child: const Icon(
                                  Icons.sos,
                                  color: Colors.white,
                                  size: 55,
                                ),
                              ),
                            ),

                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              Padding(

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                child: Container(

                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(

                    color: Colors.white10,

                    borderRadius:
                        BorderRadius.circular(28),

                    border: Border.all(
                      color: Colors.white12,
                    ),
                  ),

                  child: Row(

                    children: [

                      Container(

                        width: 60,
                        height: 60,

                        decoration: BoxDecoration(

                          shape: BoxShape.circle,

                          color: Colors.greenAccent
                              .withOpacity(0.15),
                        ),

                        child: const Icon(
                          Icons.people,
                          color: Colors.greenAccent,
                          size: 30,
                        ),
                      ),

                      const SizedBox(width: 18),

                      Expanded(

                        child: Column(

                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            const Text(
                              "Pendaki Terdeteksi",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "${nearbyUsers.length} pengguna aktif di sekitar area Anda",
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),

                          ],
                        ),
                      ),

                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

            ],
          ),
        ),
      ),
    );
  }
}

class RadarPainter extends CustomPainter {

  final double animationValue;

  RadarPainter({
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {

    final center =
        Offset(size.width / 2, size.height / 2);

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..color =
              Colors.greenAccent.withOpacity(0.15)
          ..strokeWidth = 2;

    canvas.drawCircle(center, 60, paint);
    canvas.drawCircle(center, 100, paint);
    canvas.drawCircle(center, 140, paint);

    final sweepPaint =
        Paint()
          ..shader = SweepGradient(

            colors: [

              Colors.greenAccent
                  .withOpacity(0.0),

              Colors.greenAccent
                  .withOpacity(0.35),

            ],

            transform: GradientRotation(
              animationValue * 2 * pi,
            ),

          ).createShader(

            Rect.fromCircle(
              center: center,
              radius: 160,
            ),
          );

    canvas.drawCircle(
      center,
      160,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}