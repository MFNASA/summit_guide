import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:geolocator/geolocator.dart';
import 'package:capstone2/core/utils/api_config.dart';

class AppMapController extends GetxController {
  final GetStorage _box = GetStorage();

  // Key GetStorage untuk menyimpan daftar id gunung yang sudah didownload
  static const String _downloadedIdsKey = 'downloaded_mountain_ids';

  // Prefix key GetStorage untuk cache data gunung & GPX per-gunung
  // (supaya gunung yang SUDAH didownload tetap muncul & bisa dipakai
  // walau tidak ada koneksi internet sama sekali)
  static const String _cachedMountainDataPrefix = 'mountain_data_';
  static const String _cachedGpxPrefix = 'mountain_gpx_';

  // URL template tile yang dipakai di seluruh app (dipakai juga waktu bulk download,
  // HARUS SAMA PERSIS dengan urlTemplate di TileLayer, kalau beda tile tidak akan match)
  static const String tileUrlTemplate =
      'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=GuvUnGbKCI22KPYfULSZ';

  // ============================
  // STATE: DAFTAR GUNUNG
  // ============================
  var mountains = <Map<String, dynamic>>[].obs;
  var isLoadingMountains = false.obs;
  var mountainErrorMessage = ''.obs;
  // true kalau data yang sedang ditampilkan berasal dari cache offline,
  // bukan dari server (dipakai buat kasih tahu user via banner di UI)
  var isShowingOfflineData = false.obs;

  // ============================
  // STATE: RUTE GPX (per gunung yang dipilih)
  // ============================
  var routePoints = <LatLng>[].obs;
  var isLoading = false.obs; // dipakai di MapDetailView
  var isRouteFromCache = false.obs; // GPX ditampilkan dari cache offline

  // ============================
  // STATE: OFFLINE MAP (FMTC)
  // ============================
  var downloadedMountainIds = <String>{}.obs; // id gunung yg sudah offline
  var downloadingMountainId = RxnString(); // id gunung yg SEDANG didownload
  var downloadProgress = 0.0.obs; // 0.0 - 1.0
  var downloadStatusText = ''.obs;

  // ============================
  // STATE: GPS TRACKING (posisi pengguna real-time)
  // ============================
  var currentPosition = Rxn<LatLng>(); // posisi GPS terkini pengguna
  var isTracking = false.obs; // status tracking aktif/tidak
  var gpsAccuracy = 0.0.obs; // akurasi GPS dalam meter (opsional, buat info)
  StreamSubscription<Position>? _positionSubscription;

  @override
  void onInit() {
    super.onInit();
    _restoreDownloadedIds();
    fetchMountains();
  }

  void _restoreDownloadedIds() {
    final saved = _box.read<List>(_downloadedIdsKey);
    if (saved != null) {
      downloadedMountainIds.addAll(saved.map((e) => e.toString()));
    }
  }

  Future<void> _persistDownloadedIds() async {
    await _box.write(_downloadedIdsKey, downloadedMountainIds.toList());
  }

  // ============================
  // CACHE DATA GUNUNG (untuk mode offline)
  // ============================

  /// Simpan data lengkap satu gunung ke local storage. Dipanggil setiap
  /// gunung tersebut selesai didownload tile-nya, supaya nanti tanpa
  /// internet, data gunung ini masih bisa ditampilkan.
  Future<void> _cacheMountainData(Map<String, dynamic> mountain) async {
    final String mountainId = mountain["id"].toString();
    await _box.write(_cachedMountainDataPrefix + mountainId, mountain);
  }

  /// Ambil data gunung yang sudah di-cache untuk semua id yang statusnya
  /// "downloaded". Dipakai sebagai fallback saat fetchMountains() gagal
  /// (tidak ada internet).
  List<Map<String, dynamic>> _loadCachedMountains() {
    final List<Map<String, dynamic>> cached = [];
    for (final id in downloadedMountainIds) {
      final data = _box.read(_cachedMountainDataPrefix + id);
      if (data != null) {
        cached.add(Map<String, dynamic>.from(data as Map));
      }
    }
    return cached;
  }

  /// Hapus cache data gunung tertentu (dipanggil saat user hapus peta offline)
  Future<void> _removeCachedMountainData(String mountainId) async {
    await _box.remove(_cachedMountainDataPrefix + mountainId);
    await _box.remove(_cachedGpxPrefix + mountainId);
  }

  // ============================
  // FETCH DAFTAR GUNUNG DARI BACKEND
  // ============================
  Future<void> fetchMountains() async {
    isLoadingMountains.value = true;
    mountainErrorMessage.value = '';
    isShowingOfflineData.value = false;

    final String? token = _box.read('token');

    if (token == null) {
      mountainErrorMessage.value =
          'Token tidak ditemukan. Silakan login ulang.';
      _fallbackToCachedMountains();
      isLoadingMountains.value = false;
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.mountainsEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        mountains.value = data.map((m) {
          return {
            "id": m["id"].toString(),
            "name": m["name"] ?? "Tanpa Nama",
            "location": (m["basecamps"] != null &&
                    (m["basecamps"] as List).isNotEmpty)
                ? m["basecamps"][0]["name"]
                : "Lokasi tidak diketahui",
            "image":
                "https://images.unsplash.com/photo-1506744038136-46273834b3fb",
            "gpxPath": m["gpx_url"],
            "latitude": m["latitude"],
            "longitude": m["longitude"],
            "description": m["description"],
            "basecamps": m["basecamps"] ?? [],
          };
        }).toList();

        // Refresh cache untuk gunung yang sudah didownload, supaya data
        // offline-nya tetap up-to-date setiap kali online.
        for (final mountain in mountains) {
          final id = mountain["id"].toString();
          if (downloadedMountainIds.contains(id)) {
            await _cacheMountainData(mountain);
          }
        }
      } else if (response.statusCode == 401) {
        mountainErrorMessage.value = 'Sesi habis, silakan login kembali.';
        _fallbackToCachedMountains();
      } else {
        mountainErrorMessage.value =
            'Gagal memuat data gunung (${response.statusCode}).';
        _fallbackToCachedMountains();
      }
    } catch (e) {
      // Kemungkinan besar tidak ada koneksi internet — coba tampilkan
      // data gunung yang sudah pernah didownload sebelumnya.
      mountainErrorMessage.value = 'Tidak dapat terhubung ke server.';
      print("Error fetchMountains: $e");
      _fallbackToCachedMountains();
    } finally {
      isLoadingMountains.value = false;
    }
  }

  /// Kalau gagal ambil data online, tampilkan gunung yang sudah di-cache
  /// (yaitu gunung yang sebelumnya sudah didownload untuk offline).
  void _fallbackToCachedMountains() {
    final cached = _loadCachedMountains();
    if (cached.isNotEmpty) {
      mountains.value = cached;
      isShowingOfflineData.value = true;
      mountainErrorMessage.value =
          'Tidak ada koneksi internet. Menampilkan ${cached.length} peta yang sudah didownload.';
    }
  }

  // ============================
  // LOAD RUTE GPX UNTUK GUNUNG TERPILIH
  // ============================
  /// [mountainId] opsional, tapi WAJIB diisi kalau gunung ini sudah/akan
  /// didownload, supaya GPX-nya bisa di-cache dan dipakai offline nanti.
  Future<void> loadGpxRoute(String gpxUrlPath, {String? mountainId}) async {
    isLoading.value = true;
    isRouteFromCache.value = false;
    routePoints.clear();

    final String fullUrl = '${ApiConfig.baseUrl}$gpxUrlPath';
    String? gpxString;

    try {
      final response = await http
          .get(
            Uri.parse(fullUrl),
            headers: {'ngrok-skip-browser-warning': 'true'},
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        gpxString = response.body;
        // Simpan ke cache supaya bisa dipakai offline nanti
        if (mountainId != null) {
          await _box.write(_cachedGpxPrefix + mountainId, gpxString);
        }
      } else {
        print("Gagal memuat GPX: status code ${response.statusCode}");
      }
    } catch (e) {
      print("Gagal memuat GPX online: $e");
    }

    // Kalau gagal dari internet (offline / error), coba pakai cache lokal
    if (gpxString == null && mountainId != null) {
      final cached = _box.read<String>(_cachedGpxPrefix + mountainId);
      if (cached != null) {
        gpxString = cached;
        isRouteFromCache.value = true;
      }
    }

    if (gpxString != null) {
      try {
        final gpx = GpxReader().fromString(gpxString);
        List<LatLng> points = [];

        for (var trk in gpx.trks) {
          for (var seg in trk.trksegs) {
            for (var pt in seg.trkpts) {
              points.add(LatLng(pt.lat!, pt.lon!));
            }
          }
        }

        routePoints.value = points;
      } catch (e) {
        print("Gagal parsing GPX: $e");
      }
    }

    isLoading.value = false;
  }

  // ============================
  // OFFLINE MAP (FMTC) — DOWNLOAD TILE
  // ============================

  /// Nama store FMTC untuk gunung tertentu. Konsisten dipakai untuk
  /// download & untuk FMTCTileProvider di MapDetailView.
  String storeNameFor(String mountainId) => 'mountain_$mountainId';

  /// Cek apakah store untuk gunung tertentu sudah ada & siap dipakai.
  Future<bool> isStoreReady(String mountainId) async {
    try {
      final store = FMTCStore(storeNameFor(mountainId));
      return await store.manage.ready;
    } catch (_) {
      return false;
    }
  }

  /// Download seluruh tile di sekitar jalur GPX gunung tertentu, PLUS
  /// cache data gunung & GPX-nya, supaya semuanya bisa dipakai tanpa
  /// koneksi internet sama sekali.
  Future<void> downloadMountainTiles(Map<String, dynamic> mountain) async {
    final String mountainId = mountain["id"].toString();
    final String? gpxPath = mountain["gpxPath"];

    if (gpxPath == null) {
      Get.snackbar(
        "Gagal",
        "Gunung ini belum punya data GPX, tidak bisa didownload.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (downloadingMountainId.value != null) {
      Get.snackbar("Tunggu", "Ada proses download lain yang sedang berjalan.");
      return;
    }

    downloadingMountainId.value = mountainId;
    downloadProgress.value = 0;
    downloadStatusText.value = 'Memuat rute...';

    try {
      // Pastikan rute GPX termuat (sekaligus otomatis ter-cache lewat
      // parameter mountainId) supaya tahu area yang perlu didownload
      // DAN supaya GPX-nya tersimpan offline.
      await loadGpxRoute(gpxPath, mountainId: mountainId);

      if (routePoints.isEmpty) {
        throw Exception('Rute GPX kosong / gagal dimuat.');
      }

      final storeName = storeNameFor(mountainId);
      final store = FMTCStore(storeName);
      await store.manage.create();

      // Beri padding di sekitar bounding box rute supaya area sekitar jalur
      // (bukan cuma garis tipis) ikut terdownload.
      final bounds = LatLngBounds.fromPoints(routePoints);
      final paddedBounds = LatLngBounds(
        LatLng(bounds.south - 0.01, bounds.west - 0.01),
        LatLng(bounds.north + 0.01, bounds.east + 0.01),
      );

      final downloadableRegion = RectangleRegion(paddedBounds).toDownloadable(
        minZoom: 11,
        maxZoom: 16, // makin besar makin detail, tapi makin besar juga ukurannya
        options: TileLayer(urlTemplate: tileUrlTemplate),
      );

      downloadStatusText.value = 'Mengunduh tile peta...';

      final progressStream =
          store.download.startForeground(region: downloadableRegion);

      await for (final progress in progressStream) {
        downloadProgress.value = (progress.percentageProgress / 100)
            .clamp(0.0, 1.0);
        downloadStatusText.value =
            '${progress.attemptedTiles}/${progress.maxTiles} tile '
            '(${progress.failedTiles} gagal)';

        if (progress.isComplete) break;
      }

      // Simpan data gunung ini (nama, basecamp, koordinat, dll) supaya
      // tetap bisa ditampilkan walau tidak ada internet sama sekali.
      await _cacheMountainData(mountain);

      downloadedMountainIds.add(mountainId);
      await _persistDownloadedIds();

      Get.snackbar(
        "Berhasil Download 📥",
        "${mountain["name"]} siap dipakai sepenuhnya offline (peta + rute).",
        backgroundColor: Colors.greenAccent,
        colorText: Colors.black,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print("Gagal download tile: $e");
      Get.snackbar(
        "Gagal Download",
        "Terjadi kesalahan: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      downloadingMountainId.value = null;
      downloadProgress.value = 0;
      downloadStatusText.value = '';
    }
  }

  /// Hapus data offline gunung tertentu (bebasin storage): tile, data
  /// gunung, dan GPX yang sudah di-cache.
  Future<void> deleteDownloadedMountain(String mountainId) async {
    try {
      final store = FMTCStore(storeNameFor(mountainId));
      await store.manage.delete();
    } catch (e) {
      print("Gagal hapus store: $e");
    } finally {
      downloadedMountainIds.remove(mountainId);
      await _persistDownloadedIds();
      await _removeCachedMountainData(mountainId);
    }
  }

  // ============================
  // GPS TRACKING — posisi pengguna real-time mengikuti pergerakan
  // ============================

  /// Cek & minta izin lokasi. Return true kalau boleh lanjut, false kalau
  /// ditolak/GPS mati (snackbar penjelasan sudah otomatis ditampilkan).
  Future<bool> _ensureLocationPermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        "GPS Nonaktif",
        "Aktifkan layanan lokasi (GPS) di pengaturan HP kamu terlebih dahulu.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          "Izin Ditolak",
          "Aplikasi butuh izin lokasi untuk menampilkan posisi kamu di peta.",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        "Izin Diblokir Permanen",
        "Aktifkan izin lokasi lewat Pengaturan > Aplikasi > (nama app) > Izin.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  /// Mulai tracking GPS: ambil posisi sekali di awal (biar langsung
  /// tampil), lalu berlangganan stream posisi supaya titik biru di peta
  /// terus update setiap pengguna bergerak.
  Future<void> startTracking() async {
    final bool granted = await _ensureLocationPermission();
    if (!granted) return;

    // Ambil posisi awal sekali dulu supaya marker langsung muncul,
    // tidak perlu menunggu update pertama dari stream.
    try {
      final initial = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentPosition.value = LatLng(initial.latitude, initial.longitude);
      gpsAccuracy.value = initial.accuracy;
    } catch (e) {
      print("Gagal ambil posisi GPS awal: $e");
    }

    // Berlangganan stream posisi — update tiap kali user bergeser
    // minimal 5 meter, supaya tidak terlalu boros baterai/proses.
    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      (Position position) {
        currentPosition.value = LatLng(position.latitude, position.longitude);
        gpsAccuracy.value = position.accuracy;
      },
      onError: (e) {
        print("Error GPS stream: $e");
      },
    );

    isTracking.value = true;
  }

  /// Hentikan tracking GPS (dipanggil saat user tekan tombol stop, atau
  /// otomatis saat keluar dari halaman peta).
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    isTracking.value = false;
  }

  @override
  void onClose() {
    _positionSubscription?.cancel();
    super.onClose();
  }
}