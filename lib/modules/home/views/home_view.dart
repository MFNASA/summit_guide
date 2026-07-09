import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../routes/app_routes.dart';
// import '../../main_navigation/controllers/main_navigation_controller.dart';
import '../../map/controllers/map_controller.dart';
import '../../map/views/map_view.dart'; // untuk MapDetailView
import 'mountain_fact_detail_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse instance AppMapController yang sama dipakai di halaman Maps,
    // supaya data gunung tidak perlu di-fetch ulang kalau sudah pernah dibuka.
    final AppMapController mapController = Get.isRegistered<AppMapController>()
        ? Get.find<AppMapController>()
        : Get.put(AppMapController());

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello Explorer 👋",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Summit Explore",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Get.toNamed(AppRoutes.PROFILE);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white24,
                              width: 2,
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.green,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  /// WEATHER CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF203A43),
                          Color(0xFF2C5364),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white12,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// TOP
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Cuaca Hari Ini",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Cerah ☀️",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "27°C",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 55,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: const Icon(
                                Icons.wb_sunny_rounded,
                                color: Colors.greenAccent,
                                size: 55,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        /// STATUS PENDAKIAN
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.hiking,
                                color: Colors.greenAccent,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Cuaca cocok untuk mendaki dan camping outdoor 🔥",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// INFO WEATHER
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.wb_twilight,
                                      color: Colors.greenAccent,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Sunrise",
                                      style: TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "05:32 AM",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.nightlight_round,
                                      color: Colors.greenAccent,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Sunset",
                                      style: TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "17:48 PM",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  /// FAKTA UNIK GUNUNG INDONESIA (diambil dari Wikipedia)
                  const Text(
                    "Fakta Unik Gunung Indonesia",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Tahukah kamu? Ketuk kartu untuk baca selengkapnya",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),

                  const SizedBox(height: 20),

                  const _MountainFactsSection(),

                  const SizedBox(height: 35),

                  /// REKOMENDASI — sekarang diambil dari data backend
                  const Text(
                    "Rekomendasi Gunung",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Ketuk untuk lihat peta jalur pendakian",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),

                  const SizedBox(height: 20),

                  Obx(() {
                    if (mapController.isLoadingMountains.value) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: Colors.greenAccent,
                          ),
                        ),
                      );
                    }

                    if (mapController.mountainErrorMessage.value.isNotEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_off, color: Colors.white54),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                mapController.mountainErrorMessage.value,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (mapController.mountains.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Belum ada data gunung tersedia.",
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    // Tampilkan maksimal 5 gunung di beranda supaya tidak
                    // kepanjangan — sisanya bisa dilihat lengkap di halaman Maps.
                    final recommended = mapController.mountains.take(5).toList();

                    return Column(
                      children: recommended.map((mountain) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _mountainCard(mountain, mapController),
                        );
                      }).toList(),
                    );
                  }),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// CARD GUNUNG — sekarang navigasi ke MapDetailView pakai data asli
  Widget _mountainCard(
    Map<String, dynamic> mountain,
    AppMapController mapController,
  ) {
    final String? gpxPath = mountain["gpxPath"];
    final String mountainId = mountain["id"].toString();

    return GestureDetector(
      onTap: () {
        if (gpxPath == null) {
          Get.snackbar(
            "Peta Belum Tersedia",
            "Jalur GPX untuk ${mountain["name"]} belum diunggah admin.",
            backgroundColor: Colors.orangeAccent,
            colorText: Colors.black,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }

        Get.to(
          () => MapDetailView(
            mapName: mountain["name"],
            image: mountain["image"],
            gpxPath: gpxPath,
            mountainId: mountainId,
            basecamps:
                List<Map<String, dynamic>>.from(mountain["basecamps"] ?? []),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          image: DecorationImage(
            image: NetworkImage(mountain["image"]),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                mountain["name"],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      mountain["location"] ?? "-",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =======================================
/// FAKTA UNIK GUNUNG INDONESIA
/// Sumber: Wikipedia Bahasa Indonesia REST API
/// https://id.wikipedia.org/api/rest_v1/page/summary/<judul_halaman>
/// Gratis, tanpa API key. Mengambil ringkasan (extract) dari beberapa
/// halaman gunung terkenal di Indonesia secara paralel.
/// Sekarang setiap kartu bisa DIKLIK -> buka MountainFactDetailView,
/// yang juga punya tombol untuk membuka artikel Wikipedia asli.
/// =======================================
class _MountainFactsSection extends StatefulWidget {
  const _MountainFactsSection();

  @override
  State<_MountainFactsSection> createState() => _MountainFactsSectionState();
}

class _MountainFactsSectionState extends State<_MountainFactsSection> {
  // Daftar judul halaman Wikipedia (bahasa Indonesia) yang mau ditampilkan.
  // Bisa ditambah/dikurangi sesuai kebutuhan — pastikan judulnya persis
  // sama dengan judul artikel di id.wikipedia.org.
  static const List<String> _mountainTitles = [
    "Gunung Semeru",
    "Gunung Rinjani",
    "Gunung Kerinci",
    "Gunung Merapi",
    "Gunung Bromo",
    "Gunung Slamet",
    "Gunung Sindoro",
    "Gunung Sumbing",
    "Gunung Prau",
    "Gunung Agung",
  ];

  bool _isLoading = true;
  String? _errorMessage;
  final List<MountainFact> _facts = [];

  @override
  void initState() {
    super.initState();
    _fetchFacts();
  }

  Future<void> _fetchFacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Ambil semua fakta secara paralel supaya tidak lambat menunggu satu-satu
      final results = await Future.wait(
        _mountainTitles.map((title) => _fetchSingleFact(title)),
      );

      final facts = results.whereType<MountainFact>().toList();

      if (facts.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Tidak dapat memuat fakta gunung saat ini.';
        });
        return;
      }

      setState(() {
        _facts
          ..clear()
          ..addAll(facts);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Tidak dapat terhubung ke Wikipedia. Cek koneksi internet.';
      });
    }
  }

  /// Ambil ringkasan satu halaman gunung. Return null kalau gagal
  /// (dilewati saja, tidak menghentikan proses gunung lain).
  Future<MountainFact?> _fetchSingleFact(String title) async {
    try {
      final encodedTitle = Uri.encodeComponent(title.replaceAll(' ', '_'));
      final uri = Uri.parse(
        'https://id.wikipedia.org/api/rest_v1/page/summary/$encodedTitle',
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;

      // Decode manual pakai utf8 supaya karakter khusus (é, ü, dsb) tidak rusak
      final data = jsonDecode(utf8.decode(res.bodyBytes));

      final extract = data['extract']?.toString();
      if (extract == null || extract.isEmpty) return null;

      // Ambil URL artikel lengkap dari response, fallback ke URL manual
      // kalau field content_urls tidak ada.
      final String wikiUrl = data['content_urls']?['desktop']?['page'] ??
          'https://id.wikipedia.org/wiki/$encodedTitle';

      // Thumbnail (kalau ada) untuk mempercantik halaman detail
      final String? imageUrl = data['thumbnail']?['source'];

      return MountainFact(
        name: (data['title']?.toString().isNotEmpty ?? false)
            ? data['title'].toString()
            : title,
        extract: extract,
        wikiUrl: wikiUrl,
        imageUrl: imageUrl,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 190,
        child: Center(
          child: CircularProgressIndicator(
              color: Colors.greenAccent, strokeWidth: 2),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white54),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _facts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 15),
        itemBuilder: (context, index) => _factCard(_facts[index]),
      ),
    );
  }

  Widget _factCard(MountainFact fact) {
    return GestureDetector(
      onTap: () {
        Get.to(() => MountainFactDetailView(fact: fact));
      },
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.terrain, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Colors.white38, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                fact.extract,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Ketuk untuk baca selengkapnya",
              style: TextStyle(color: Colors.greenAccent, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}