import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:latlong2/latlong.dart';
import 'package:capstone2/modules/map/controllers/map_controller.dart';
import 'package:capstone2/modules/map/views/mountain_detail_view.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final AppMapController controller = Get.put(AppMapController());

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Mountain Navigation 🗺️",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Offline Maps",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(() => const DownloadedMapsView());
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Stack(
                          children: [
                            const Icon(
                              Icons.download,
                              color: Colors.white,
                              size: 32,
                            ),
                            Obx(() {
                              final count =
                                  controller.downloadedMountainIds.length;
                              if (count == 0) return const SizedBox.shrink();
                              return Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      count.toString(),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// BANNER MODE OFFLINE — muncul kalau data yang ditampilkan
              /// berasal dari cache lokal (tidak ada koneksi internet)
              Obx(() {
                if (!controller.isShowingOfflineData.value) {
                  return const SizedBox.shrink();
                }
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.blueAccent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          controller.mountainErrorMessage.value,
                          style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 10),

              /// TITLE
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Pilih Jalur Pendakian",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// LIST MAPS — diambil dari backend (atau cache offline)
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingMountains.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.greenAccent,
                      ),
                    );
                  }

                  // Full-screen error HANYA kalau tidak ada data sama sekali
                  // untuk ditampilkan (termasuk dari cache offline).
                  if (controller.mountains.isEmpty &&
                      controller.mountainErrorMessage.value.isNotEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off,
                                color: Colors.white54, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              controller.mountainErrorMessage.value,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => controller.fetchMountains(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text("Coba Lagi"),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (controller.mountains.isEmpty) {
                    return const Center(
                      child: Text(
                        "Belum ada data gunung tersedia",
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: controller.mountains.length,
                    itemBuilder: (context, index) {
                      final map = controller.mountains[index];
                      final String mountainId = map["id"].toString();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 25),
                        child: Container(
                          height: 280,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            image: DecorationImage(
                              image: NetworkImage(map["image"]),
                              fit: BoxFit.cover,
                            ),
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
                                  Colors.black.withOpacity(0.85),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent
                                            .withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(15),
                                      ),
                                      child: Text(
                                        map["gpxPath"] != null
                                            ? "GPX TERSEDIA"
                                            : "GPX BELUM ADA",
                                        style: const TextStyle(
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Obx(() {
                                      final isDownloaded = controller
                                          .downloadedMountainIds
                                          .contains(mountainId);
                                      if (!isDownloaded) {
                                        return const SizedBox.shrink();
                                      }
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent
                                              .withOpacity(0.25),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.offline_pin,
                                                color: Colors.blueAccent,
                                                size: 16),
                                            SizedBox(width: 4),
                                            Text(
                                              "OFFLINE",
                                              style: TextStyle(
                                                color: Colors.blueAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  map["name"],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      map["location"],
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                /// PROGRESS BAR — hanya muncul saat gunung ini sedang didownload
                                Obx(() {
                                  final isThisDownloading =
                                      controller.downloadingMountainId
                                              .value ==
                                          mountainId;
                                  if (!isThisDownloading) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value: controller
                                                .downloadProgress.value,
                                            backgroundColor: Colors.white24,
                                            color: Colors.greenAccent,
                                            minHeight: 6,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          controller.downloadStatusText.value,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                                Row(
                                  children: [
                                    Expanded(
                                      child: Obx(() {
                                        final isDownloaded = controller
                                            .downloadedMountainIds
                                            .contains(mountainId);
                                        final isThisDownloading = controller
                                                .downloadingMountainId
                                                .value ==
                                            mountainId;
                                        final anyDownloading = controller
                                                .downloadingMountainId
                                                .value !=
                                            null;

                                        return ElevatedButton.icon(
                                          onPressed: (map["gpxPath"] ==
                                                      null ||
                                                  isDownloaded ||
                                                  anyDownloading)
                                              ? null
                                              : () => controller
                                                  .downloadMountainTiles(map),
                                          icon: isThisDownloading
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.black,
                                                  ),
                                                )
                                              : Icon(isDownloaded
                                                  ? Icons.download_done
                                                  : Icons.download),
                                          label: Text(
                                            isDownloaded
                                                ? "Tersimpan"
                                                : "Download",
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isDownloaded
                                                ? Colors.white10
                                                : Colors.greenAccent,
                                            foregroundColor: isDownloaded
                                                ? Colors.white38
                                                : Colors.black,
                                            disabledBackgroundColor:
                                                Colors.white10,
                                            disabledForegroundColor:
                                                Colors.white38,
                                            padding: const EdgeInsets
                                                .symmetric(
                                              vertical: 18,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 15),

                                    /// TOMBOL DETAIL — mengarah ke
                                    /// MountainDetailView (info + basecamp + tiket),
                                    /// bukan langsung ke peta lagi.
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Get.to(
                                            () => MountainDetailView(
                                              mountain: map,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.info_outline),
                                        label: const Text("Detail"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white10,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =======================================
/// DOWNLOADED MAPS — daftar gunung yang sudah offline
/// =======================================
class DownloadedMapsView extends StatelessWidget {
  const DownloadedMapsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppMapController controller = Get.find<AppMapController>();

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      "Peta Saya",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  final downloadedMaps = controller.mountains
                      .where((m) => controller.downloadedMountainIds
                          .contains(m["id"].toString()))
                      .toList();

                  if (downloadedMaps.isEmpty) {
                    return const Center(
                      child: Text(
                        "Belum ada peta yang di-download",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: downloadedMaps.length,
                    itemBuilder: (context, index) {
                      final map = downloadedMaps[index];
                      final String mountainId = map["id"].toString();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: GestureDetector(
                          onTap: () {
                            Get.to(
                              () => MapDetailView(
                                mapName: map["name"],
                                image: map["image"],
                                gpxPath: map["gpxPath"],
                                mountainId: mountainId,
                                basecamps: List<Map<String, dynamic>>.from(
                                    map["basecamps"] ?? []),
                              ),
                            );
                          },
                          child: Container(
                            height: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              image: DecorationImage(
                                image: NetworkImage(map["image"]),
                                fit: BoxFit.cover,
                              ),
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
                                    Colors.black.withOpacity(0.85),
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.greenAccent
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.download_done,
                                              color: Colors.greenAccent,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Offline",
                                              style: TextStyle(
                                                color: Colors.greenAccent,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () {
                                          Get.defaultDialog(
                                            title: "Hapus Peta Offline?",
                                            middleText:
                                                "${map["name"]} akan dihapus dari penyimpanan offline.",
                                            textConfirm: "Hapus",
                                            textCancel: "Batal",
                                            confirmTextColor: Colors.white,
                                            onConfirm: () {
                                              controller
                                                  .deleteDownloadedMountain(
                                                      mountainId);
                                              Get.back();
                                            },
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    map["name"],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        map["location"],
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =======================================
/// MAP DETAIL — Menampilkan peta GPX asli dari backend (atau cache offline)
/// + tile offline (FMTC) + marker pos/basecamp + kompas ala Google Maps
/// =======================================
class MapDetailView extends StatefulWidget {
  final String mapName;
  final String image;
  final String gpxPath;
  final String mountainId;
  final List<Map<String, dynamic>> basecamps;

  const MapDetailView({
    super.key,
    required this.mapName,
    required this.image,
    required this.gpxPath,
    required this.mountainId,
    this.basecamps = const [],
  });

  @override
  State<MapDetailView> createState() => _MapDetailViewState();
}

class _MapDetailViewState extends State<MapDetailView> {
  final AppMapController controller = Get.find<AppMapController>();
  bool _trackingStarted = false;

  // true = kamera otomatis mengikuti posisi GPS user.
  bool _followMode = true;

  final MapController _flutterMapController = MapController();

  late final FMTCTileProvider _tileProvider;
  Worker? _positionWorker;

  // ====== KOMPAS (arah hadap HP) ======
  // heading dalam derajat, 0 = Utara, searah jarum jam (persis kompas asli)
  double _heading = 0;
  StreamSubscription<CompassEvent>? _compassSubscription;

  // ====== ROTASI PETA (gesture 2 jari) ======
  // dipakai untuk menampilkan/menyembunyikan tombol kompas
  double _mapRotation = 0;

  // Tinggi area yang "dicadangkan" di bawah untuk panel tombol, supaya
  // peta (dan marker posisi user) tidak pernah tertutup/numpuk dengan
  // panel "MULAI PENDAKIAN" di bawah.
  // (Tidak lagi mencadangkan ruang khusus di bawah peta — sudah dihapus,
  // solusinya sekarang tombol dipindah ke atas layar.)

  @override
  void initState() {
    super.initState();
    _tileProvider = FMTCStore(
      controller.storeNameFor(widget.mountainId),
    ).getTileProvider();

    controller.loadGpxRoute(widget.gpxPath, mountainId: widget.mountainId);

    // Ikuti posisi GPS secara otomatis kalau follow mode aktif
    _positionWorker = ever<LatLng?>(controller.currentPosition, (pos) {
      if (pos != null && _followMode && mounted) {
        _flutterMapController.move(pos, _flutterMapController.camera.zoom);
      }
    });

    // Dengarkan sensor kompas HP — event.heading berisi derajat 0-360
    // (0 = Utara). Beberapa device tidak punya magnetometer, makanya
    // event.heading bisa null — di-skip saja kalau begitu.
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null && mounted) {
        setState(() {
          _heading = event.heading!;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionWorker?.dispose();
    _compassSubscription?.cancel();
    controller.stopTracking();
    super.dispose();
  }

  List<Marker> _buildBasecampMarkers() {
    return widget.basecamps.map((b) {
      final lat = b['latitude'];
      final lng = b['longitude'];
      if (lat == null || lng == null) return null;

      return Marker(
        point: LatLng(
          (lat as num).toDouble(),
          (lng as num).toDouble(),
        ),
        width: 60,
        height: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_pin,
              color: Colors.orangeAccent,
              size: 34,
            ),
            if (b['name'] != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  b['name'],
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      );
    }).whereType<Marker>().toList();
  }

  /// Marker posisi user — bentuk PANAH/SEGITIGA (persis Google Maps navigasi),
  /// berputar mengikuti arah hadap HP secara real-time via sensor kompas.
  Widget _buildUserLocationArrow() {
    return Transform.rotate(
      // event kompas dalam derajat, widget butuh radian
      angle: _heading * (math.pi / 180),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueAccent.withOpacity(0.18),
        ),
        child: const Center(
          child: Icon(
            Icons.navigation, // ikon panah/segitiga bawaan Material
            color: Colors.blueAccent,
            size: 30,
            shadows: [
              Shadow(color: Colors.black45, blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleTracking() async {
    if (!_trackingStarted) {
      await controller.startTracking();

      if (!controller.isTracking.value) {
        return;
      }

      setState(() {
        _trackingStarted = true;
        _followMode = true;
      });

      final pos = controller.currentPosition.value;
      if (pos != null) {
        _flutterMapController.move(pos, 16.0);
      }

      Get.snackbar(
        "Pendakian Dimulai 🏔️",
        "GPS Tracking aktif, posisi kamu akan terus diperbarui di peta.",
        backgroundColor: Colors.greenAccent,
        colorText: Colors.black,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      controller.stopTracking();
      setState(() {
        _trackingStarted = false;
      });
      Get.snackbar(
        "Tracking Dihentikan",
        "GPS tracking sudah nonaktif.",
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.black,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _recenterToUser() {
    final pos = controller.currentPosition.value;
    if (pos == null) return;
    setState(() => _followMode = true);
    _flutterMapController.move(pos, _flutterMapController.camera.zoom);
  }

  /// Reset rotasi peta kembali ke Utara (persis tombol kompas Google Maps).
  void _resetMapRotation() {
    _flutterMapController.rotate(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ====== PETA — full screen, tidak ada lagi area "dicadangkan"
          // di bawah (itu yang bikin ada strip blank kemarin). ======
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final points = controller.routePoints;
            final basecampMarkers = _buildBasecampMarkers();
            final userPosition = controller.currentPosition.value;

            return FlutterMap(
              mapController: _flutterMapController,
              options: MapOptions(
                initialCenter: points.isNotEmpty
                    ? points.first
                    : const LatLng(-7.186, 109.929),
                initialZoom: 13.0,
                // interactionOptions.flags.all SUDAH TERMASUK rotate —
                // ini yang mengaktifkan gesture putar peta pakai 2 jari,
                // sebelumnya tidak ada sama sekali di kode lama.
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture && _followMode) {
                    setState(() => _followMode = false);
                  }
                },
                // Dipanggil tiap kali peta di-pan/zoom/ROTATE. Dipakai
                // buat tahu kapan tombol kompas harus muncul.
                onMapEvent: (MapEvent event) {
                  final newRotation = event.camera.rotation;
                  if ((newRotation - _mapRotation).abs() > 0.5) {
                    setState(() => _mapRotation = newRotation);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: AppMapController.tileUrlTemplate,
                  userAgentPackageName: 'com.summitguide.app',
                  tileProvider: _tileProvider,
                ),
                if (points.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        strokeWidth: 4.0,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                if (points.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: points.first,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.trip_origin,
                          color: Colors.green,
                        ),
                      ),
                      Marker(
                        point: points.last,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.flag,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                if (basecampMarkers.isNotEmpty)
                  MarkerLayer(markers: basecampMarkers),
                // MARKER POSISI GPS — bentuk panah/segitiga,
                // berputar mengikuti arah hadap HP (kompas)
                if (userPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: userPosition,
                        width: 50,
                        height: 50,
                        child: _buildUserLocationArrow(),
                      ),
                    ],
                  ),
              ],
            );
          }),

          // ====== GRUP TOMBOL KOMPAS + RECENTER — DIPINDAH KE ATAS,
          // di bawah header (bukan lagi mepet panel tracking di bawah). ======
          Positioned(
            right: 20,
            top: 130,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tombol kompas — selalu tampil, gaya gelap transparan
                // konsisten dengan tombol lain di app.
                GestureDetector(
                  onTap: _resetMapRotation,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    // Jarum kompas berputar berlawanan arah rotasi peta,
                    // supaya selalu menunjuk Utara asli (persis Google Maps).
                    child: Transform.rotate(
                      angle: -_mapRotation * (math.pi / 180),
                      child: const Icon(Icons.explore, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Tombol recenter — hanya muncul saat tracking aktif TAPI
                // follow mode sedang mati (user habis geser peta manual).
                Obx(() {
                  final showRecenter =
                      controller.isTracking.value && !_followMode;
                  if (!showRecenter) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: _recenterToUser,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child:
                          const Icon(Icons.my_location, color: Colors.black),
                    ),
                  );
                }),
              ],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            widget.mapName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  Obx(() {
                    if (!controller.isRouteFromCache.value) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            "Rute ditampilkan dari data offline",
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),

                  Obx(() {
                    if (!controller.isLoading.value &&
                        controller.routePoints.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Text(
                          "Gagal memuat rute GPX. Periksa koneksi ke server "
                          "atau pastikan peta ini sudah didownload untuk mode offline.",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  Obx(() {
                    if (!controller.isTracking.value) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.gps_fixed, color: Colors.greenAccent, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            "Akurasi GPS: ±${controller.gpsAccuracy.value.toStringAsFixed(0)} m",
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  }),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _toggleTracking,
                      icon: Icon(
                        _trackingStarted ? Icons.check_circle : Icons.hiking,
                      ),
                      label: Text(
                        _trackingStarted
                            ? "TRACKING AKTIF (Ketuk untuk Stop)"
                            : "MULAI PENDAKIAN",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _trackingStarted
                            ? Colors.white24
                            : Colors.greenAccent,
                        foregroundColor:
                            _trackingStarted ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}