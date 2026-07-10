import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class AppWeatherController extends GetxController {
  var isLoading = true.obs;
  var temperature = '0'.obs;
  var condition = 'Mencari...'.obs;
  var sunrise = '--:--'.obs;
  var sunset = '--:--'.obs;
  var cityName = 'Lokasi...'.obs;
  var errorMessage = ''.obs;

  // TODO: Ganti pake API Key asli lo dari openweathermap.org kalau mau cuacanya sinkron real-time
  final String apiKey = 'ISI_DENGAN_API_KEY_OPENWEATHER_LO'; 

  @override
  void onInit() {
    super.onInit();
    fetchRealtimeWeather();
  }

  Future<void> fetchRealtimeWeather() async {
    try {
      isLoading(true);
      errorMessage('');

      // 1. Cek & Minta Izin GPS HP
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'GPS lo mati, Chief. Nyalain dulu lewat pengaturan HP.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Izin akses lokasi ditolak oleh user.';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Izin lokasi diblokir permanen. Silakan aktifkan di pengaturan HP.';
      }

      // 2. Tarik Titik Koordinat Asli dari GPS HP
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 3. SEGMEN AMBIL NAMA KECAMATAN VIA HTTP API (Bypass Package Geocoding)
      String namaDaerah = "Koordinat Terdeteksi";
      try {
        final urlGeo = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=14&addressdetails=1');
        
        // Nominatim wajib dikasih header User-Agent bebas biar gak diblokir
        final responseGeo = await http.get(urlGeo, headers: {'User-Agent': 'SummitExploreApp'});
        
        if (responseGeo.statusCode == 200) {
          final dataGeo = jsonDecode(utf8.decode(responseGeo.bodyBytes));
          if (dataGeo['address'] != null) {
            final address = dataGeo['address'];
            // Di Indonesia, nama Kecamatan biasanya masuk ke key 'subdistrict', 'town', atau 'suburb'
            namaDaerah = address['subdistrict'] ?? 
                         address['town'] ?? 
                         address['village'] ?? 
                         address['suburb'] ?? 
                         address['city'] ?? "Lokasi Terdeteksi";
          }
        }
      } catch (e) {
        // Jika internet putus atau API down, fallback ke angka koordinat biar gak crash
        namaDaerah = "Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}";
      }

      // Set hasil nama kecamatan ke UI
      cityName.value = namaDaerah;

      // 4. JIKA API KEY MASIH DEFAULT, LANGSUNG MASUK MODE SIMULASI LOKASI ASLI
      if (apiKey == 'ISI_DENGAN_API_KEY_OPENWEATHER_LO') {
        _loadDummyData(namaDaerah);
        return;
      }

      // 5. Tarik Data Cuaca Asli dari OpenWeatherMap
      final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric&lang=id');
      
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        temperature.value = data['main']['temp'].round().toString();
        condition.value = data['weather'][0]['description'].toString().capitalizeFirst ?? 'Cerah';

        final sr = DateTime.fromMillisecondsSinceEpoch(data['sys']['sunrise'] * 1000);
        final ss = DateTime.fromMillisecondsSinceEpoch(data['sys']['sunset'] * 1000);
        
        sunrise.value = DateFormat('hh:mm a').format(sr);
        sunset.value = DateFormat('hh:mm a').format(ss);
      } else {
        final serverMessage = data['message'] ?? 'Gagal narik data server cuaca.';
        throw 'Error ${response.statusCode}: ${serverMessage.toString().capitalizeFirst}';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading(false);
    }
  }

  // Fungsi penampung data dummy saat API Key belum dikonfigurasi
  void _loadDummyData(String currentRealLocation) {
    temperature.value = '24';
    condition.value = 'Cerah Berawan';
    cityName.value = currentRealLocation; 
    sunrise.value = '05:45 AM';
    sunset.value = '05:50 PM';
  }
}