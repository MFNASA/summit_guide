import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:capstone2/modules/map/controllers/map_controller.dart';
import 'package:capstone2/modules/map/views/map_view.dart'; // untuk MapDetailView
import 'package:capstone2/core/utils/api_config.dart';

// Path disesuaikan dengan lokasi asli TiketController di project kamu
import 'package:capstone2/modules/sewa_jasa/controllers/tiket_controller.dart';

/// Halaman info deskriptif tentang satu gunung — ditampilkan sebelum
/// masuk ke peta. Berisi: deskripsi, prakiraan cuaca 14 hari, status
/// GPX/offline, dan daftar basecamp yang bisa dipesan tiketnya.
class MountainDetailView extends StatelessWidget {
  final Map<String, dynamic> mountain;

  const MountainDetailView({super.key, required this.mountain});

  /// Menampilkan date picker, lalu memanggil bookTicket() dengan tanggal
  /// yang dipilih. Diperlukan karena hikingDate sekarang wajib diisi
  /// (required) di TiketController.bookTicket().
  Future<void> _pesanTiket(
    BuildContext context,
    TiketController tiketController,
    int basecampId,
    String mountainName,
  ) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: "Pilih Tanggal Pendakian",
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.greenAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF203A43),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return; // user batal pilih tanggal

    final String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);

    await tiketController.bookTicket(
      basecampId,
      mountainName,
      hikingDate: formattedDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppMapController mapController = Get.find<AppMapController>();

    // Reuse instance TiketController yang sudah ada kalau sebelumnya
    // pernah di-put (misal dari halaman Sewa Jasa), supaya data booking
    // konsisten satu sumber. Kalau belum ada, buat baru.
    final TiketController tiketController = Get.isRegistered<TiketController>()
        ? Get.find<TiketController>()
        : Get.put(TiketController());

    final String mountainId = mountain["id"].toString();
    final String? gpxPath = mountain["gpxPath"];
    final List<Map<String, dynamic>> basecamps =
        List<Map<String, dynamic>>.from(mountain["basecamps"] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: CustomScrollView(
        slivers: [
          // ====== HEADER GAMBAR + JUDUL ======
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF0F2027),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    mountain["image"],
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0F2027).withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mountain["name"],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 5),
                            Text(
                              mountain["location"] ?? "-",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ====== ISI KONTEN ======
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- DESKRIPSI ----
                  const Text(
                    "Tentang Jalur",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    (mountain["description"] != null &&
                            mountain["description"].toString().isNotEmpty)
                        ? mountain["description"]
                        : "Belum ada deskripsi untuk jalur ini.",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ---- PRAKIRAAN CUACA (dari backend Flask: /api/weather/forecast & /history) ----
                  const Text(
                    "Prakiraan Cuaca",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "7 hari ke belakang & beberapa hari ke depan",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  _WeatherForecastSection(
                    mountainName: mountain["name"],
                  ),

                  const SizedBox(height: 25),

                  // ---- SECTION PETA & OFFLINE ----
                  const Text(
                    "Peta & Navigasi",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Tombol lihat peta jalur GPX
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: gpxPath == null
                              ? null
                              : () {
                                  Get.to(
                                    () => MapDetailView(
                                      mapName: mountain["name"],
                                      image: mountain["image"],
                                      gpxPath: gpxPath,
                                      mountainId: mountainId,
                                      basecamps: basecamps,
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.map),
                          label: const Text("Lihat Peta"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white10,
                            disabledForegroundColor: Colors.white30,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Tombol download peta offline — status & progress
                      // reaktif terhadap AppMapController (sama seperti di MapView)
                      Expanded(
                        child: Obx(() {
                          final isDownloaded = mapController
                              .downloadedMountainIds
                              .contains(mountainId);
                          final isThisDownloading =
                              mapController.downloadingMountainId.value ==
                                  mountainId;
                          final anyDownloading =
                              mapController.downloadingMountainId.value !=
                                  null;

                          return ElevatedButton.icon(
                            onPressed: (gpxPath == null ||
                                    isDownloaded ||
                                    anyDownloading)
                                ? null
                                : () => mapController
                                    .downloadMountainTiles(mountain),
                            icon: isThisDownloading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : Icon(isDownloaded
                                    ? Icons.download_done
                                    : Icons.download),
                            label:
                                Text(isDownloaded ? "Tersimpan" : "Download"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDownloaded
                                  ? Colors.white10
                                  : Colors.greenAccent,
                              foregroundColor: isDownloaded
                                  ? Colors.white38
                                  : Colors.black,
                              disabledBackgroundColor: Colors.white10,
                              disabledForegroundColor: Colors.white38,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),

                  // Info kalau peta ini sudah bisa dipakai full offline
                  Obx(() {
                    final isDownloaded = mapController.downloadedMountainIds
                        .contains(mountainId);
                    if (!isDownloaded) return const SizedBox.shrink();
                    return const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.greenAccent, size: 14),
                          SizedBox(width: 6),
                          Text(
                            "Peta & rute jalur ini sudah tersimpan, siap dipakai tanpa internet.",
                            style: TextStyle(
                                color: Colors.greenAccent, fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Progress bar download (muncul kalau sedang proses)
                  Obx(() {
                    final isThisDownloading =
                        mapController.downloadingMountainId.value ==
                            mountainId;
                    if (!isThisDownloading) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: mapController.downloadProgress.value,
                              backgroundColor: Colors.white24,
                              color: Colors.greenAccent,
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mapController.downloadStatusText.value,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 30),

                  // ---- SECTION BASECAMP & TIKET ----
                  const Text(
                    "Pilih Basecamp & Pesan Tiket",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (basecamps.isEmpty)
                    const Text(
                      "Belum ada basecamp terdaftar untuk gunung ini.",
                      style: TextStyle(color: Colors.white70),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: basecamps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final b = basecamps[index];
                        final price = b["ticket_price"] ?? 0;
                        final quota = b["daily_quota"] ?? 0;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b["name"] ?? "Basecamp",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Kuota harian: $quota",
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Rp ${price.toString()}",
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: (quota is num && quota <= 0)
                                    ? null
                                    : () {
                                        _pesanTiket(
                                          context,
                                          tiketController,
                                          b["id"],
                                          mountain["name"],
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.greenAccent,
                                  foregroundColor: Colors.black,
                                  disabledBackgroundColor: Colors.white10,
                                  disabledForegroundColor: Colors.white38,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  (quota is num && quota <= 0)
                                      ? "Penuh"
                                      : "Pesan",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================================
/// PRAKIRAAN CUACA
/// Sumber: backend Flask sendiri
///   - Forecast (beberapa hari ke depan)  -> GET /api/weather/forecast?name=<mountain_name>
///   - History  (7 hari ke belakang)      -> GET /api/weather/history?name=<mountain_name>
///
/// PENTING: backend membaca nama gunung lewat QUERY PARAMETER (?name=...),
/// bukan lewat path (/history/<nama>). Ini yang sebelumnya menyebabkan
/// request selalu 404 dan prakiraan cuaca tidak pernah muncul.
///
/// Data mentah backend berbentuk per-jam / per-3-jam, sehingga di sini
/// dikelompokkan dulu menjadi ringkasan per-hari (suhu max/min + kondisi
/// yang mewakili, diambil dari jam paling dekat dengan tengah hari).
/// =======================================
class _WeatherForecastSection extends StatefulWidget {
  final String mountainName;

  const _WeatherForecastSection({required this.mountainName});

  @override
  State<_WeatherForecastSection> createState() =>
      _WeatherForecastSectionState();
}

class _WeatherForecastSectionState extends State<_WeatherForecastSection> {
  bool _isLoading = true;
  String? _errorMessage;
  List<_DayWeather> _days = [];

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final headers = {
        "Accept": "application/json",
        "ngrok-skip-browser-warning": "true",
      };

      // FIX: gunakan query parameter ?name=..., sesuai dengan route Flask:
      //   @app.route('/api/weather/forecast', methods=['GET'])
      //   mountain_name = request.args.get('name', '')
      // .replace(queryParameters: {...}) otomatis meng-encode nama gunung
      // (spasi, karakter khusus, dll) dengan benar.
      final historyUri = Uri.parse("${ApiConfig.baseUrl}/api/weather/history")
          .replace(queryParameters: {"name": widget.mountainName});
      final forecastUri =
          Uri.parse("${ApiConfig.baseUrl}/api/weather/forecast")
              .replace(queryParameters: {"name": widget.mountainName});

      final responses = await Future.wait([
        http
            .get(historyUri, headers: headers)
            .timeout(const Duration(seconds: 12)),
        http
            .get(forecastUri, headers: headers)
            .timeout(const Duration(seconds: 12)),
      ]);

      final historyRes = responses[0];
      final forecastRes = responses[1];

      final Map<String, _DayWeather> byDate = {};

      if (historyRes.statusCode == 200) {
        final histData = jsonDecode(historyRes.body);
        final List<dynamic> history = histData['history'] ?? [];
        _groupHourlyIntoDays(
          entries: history,
          dateParser: (s) => DateTime.parse(s),
          into: byDate,
        );
      } else {
        print(
            "WeatherForecast: history gagal (${historyRes.statusCode}) -> ${historyRes.body}");
      }

      if (forecastRes.statusCode == 200) {
        final foreData = jsonDecode(forecastRes.body);
        final List<dynamic> forecast = foreData['forecast'] ?? [];
        _groupHourlyIntoDays(
          entries: forecast,
          dateParser: (s) => DateTime.parse(s.replaceFirst(' ', 'T')),
          into: byDate,
        );
      } else {
        print(
            "WeatherForecast: forecast gagal (${forecastRes.statusCode}) -> ${forecastRes.body}");
      }

      if (byDate.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Data cuaca belum tersedia untuk gunung ini.';
        });
        return;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final filtered = byDate.values.where((d) {
        final diff = d.date.difference(today).inDays;
        return diff >= -7 && diff <= 7;
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      setState(() {
        _days = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Tidak dapat terhubung ke layanan cuaca. Cek koneksi internet.';
      });
    }
  }

  /// Mengelompokkan data per-jam (history/forecast) jadi ringkasan per-hari:
  /// suhu maksimum, suhu minimum, dan kondisi cuaca yang mewakili (diambil
  /// dari jam yang paling dekat dengan tengah hari, jam 12:00).
  void _groupHourlyIntoDays({
    required List<dynamic> entries,
    required DateTime Function(String) dateParser,
    required Map<String, _DayWeather> into,
  }) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final e in entries) {
      final map = Map<String, dynamic>.from(e as Map);
      DateTime dt;
      try {
        dt = dateParser(map['datetime'].toString());
      } catch (_) {
        continue; // lewati entri yang formatnya tidak terduga, jangan sampai crash
      }
      final key = DateFormat('yyyy-MM-dd').format(dt);
      map['_parsedDate'] = dt;
      grouped.putIfAbsent(key, () => []).add(map);
    }

    grouped.forEach((dateKey, hourly) {
      double? maxTemp;
      double? minTemp;
      Map<String, dynamic>? closestToNoon;
      int closestDiff = 999999;

      for (final h in hourly) {
        final temp = (h['temp'] as num?)?.toDouble();
        if (temp != null) {
          maxTemp = (maxTemp == null || temp > maxTemp) ? temp : maxTemp;
          minTemp = (minTemp == null || temp < minTemp) ? temp : minTemp;
        }
        final DateTime dt = h['_parsedDate'];
        final diff = (dt.hour - 12).abs();
        if (diff < closestDiff) {
          closestDiff = diff;
          closestToNoon = h;
        }
      }

      if (maxTemp == null || minTemp == null || closestToNoon == null) return;

      into[dateKey] = _DayWeather(
        date: DateTime.parse(dateKey),
        maxTemp: maxTemp,
        minTemp: minTemp,
        iconCategory: closestToNoon['icon_category']?.toString() ?? 'unknown',
      );
    });
  }

  Map<String, dynamic> _weatherVisual(String iconCategory) {
    switch (iconCategory) {
      case 'clear':
        return {'icon': Icons.wb_sunny, 'color': Colors.amber};
      case 'partly_cloudy':
        return {'icon': Icons.wb_cloudy, 'color': Colors.amberAccent};
      case 'cloudy':
        return {'icon': Icons.cloud, 'color': Colors.blueGrey};
      case 'fog':
        return {'icon': Icons.blur_on, 'color': Colors.grey};
      case 'drizzle':
        return {'icon': Icons.grain, 'color': Colors.lightBlueAccent};
      case 'rain':
        return {'icon': Icons.umbrella, 'color': Colors.blueAccent};
      case 'snow':
        return {'icon': Icons.ac_unit, 'color': Colors.white};
      case 'thunderstorm':
        return {'icon': Icons.thunderstorm, 'color': Colors.deepPurpleAccent};
      default:
        return {'icon': Icons.help_outline, 'color': Colors.white54};
    }
  }

  String _formatDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Hari Ini';
    if (diff == -1) return 'Kemarin';
    if (diff == 1) return 'Besok';

    const hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return '${hari[date.weekday - 1]}, ${date.day}/${date.month}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
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
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white54),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_errorMessage!,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final day = _days[index];
          final visual = _weatherVisual(day.iconCategory);
          final bool isToday = _isToday(day.date);

          return Container(
            width: 92,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: isToday
                  ? Colors.greenAccent.withOpacity(0.15)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isToday ? Colors.greenAccent : Colors.white24,
                width: isToday ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDayLabel(day.date),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isToday ? Colors.greenAccent : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Icon(visual['icon'] as IconData,
                    color: visual['color'] as Color, size: 28),
                const SizedBox(height: 10),
                Text(
                  "${day.maxTemp.round()}° / ${day.minTemp.round()}°",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DayWeather {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final String iconCategory;

  _DayWeather({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.iconCategory,
  });
}