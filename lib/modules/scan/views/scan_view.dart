import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../controllers/checklist_controller.dart';
import 'equipment_history_view.dart';

class ScanView extends StatefulWidget {
  const ScanView({super.key});

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> {
  File? selectedImage;
  bool isAnalyzing = false;

  // Checklist saat ini — gabungan dari hasil deteksi AI + barang manual.
  // Setiap item bisa dicentang/dibatalkan manual oleh user kapan saja.
  final List<ChecklistItem> items = [];

  final TextEditingController manualItemCtrl = TextEditingController();

  late final ChecklistController checklistController;

  // ====== MODEL YOLOv8 — dimuat SEKALI saat halaman dibuka, dipakai ulang ======
  late final YOLO _yolo;
  bool _isModelReady = false;

  // Minimal confidence supaya hasil deteksi tidak terlalu banyak noise
  static const double _confidenceThreshold = 0.5;

  @override
  void initState() {
    super.initState();
    checklistController = Get.isRegistered<ChecklistController>()
        ? Get.find<ChecklistController>()
        : Get.put(ChecklistController());

    _initModel();
  }

  Future<void> _initModel() async {
    _yolo = YOLO(
      modelPath: 'assets/models/best.tflite',
      task: YOLOTask.detect,
    );

    try {
      await _yolo.loadModel();
      setState(() {
        _isModelReady = true;
      });
    } catch (e) {
      print("Gagal load model YOLO: $e");
      Get.snackbar(
        "Gagal Memuat Model",
        "Model deteksi tidak dapat dimuat: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void dispose() {
    manualItemCtrl.dispose();
    super.dispose();
  }

  Future<void> pickImage(ImageSource source) async {
    if (!_isModelReady) {
      Get.snackbar(
        "Tunggu Sebentar",
        "Model AI masih dimuat, coba lagi sesaat lagi.",
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.black,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
        isAnalyzing = true;
      });

      try {
        // ====== INFERENSI ASLI — bukan simulasi lagi ======
        final imageBytes = await selectedImage!.readAsBytes();

        // PENTING: predict() mengembalikan Map<String, dynamic>, BUKAN List.
        // Hasil deteksi ada di dalam key 'boxes', dan tiap item di dalamnya
        // adalah Map dengan key 'class' & 'confidence' (bukan property .className/.confidence).
        final Map<String, dynamic> results = await _yolo.predict(imageBytes);
        final List<dynamic> boxes = (results['boxes'] as List<dynamic>?) ?? [];

        // Ambil nama kelas unik yang lolos threshold confidence
        final detectedNames = <String>{};
        for (final box in boxes) {
          final box_ = box as Map<String, dynamic>;
          final double confidence = (box_['confidence'] as num?)?.toDouble() ?? 0.0;
          final String? className = box_['class'] as String?;

          if (className != null && confidence >= _confidenceThreshold) {
            detectedNames.add(className);
          }
        }

        setState(() {
          isAnalyzing = false;

          for (final name in detectedNames) {
            final alreadyExists = items.any(
              (i) => i.name.toLowerCase() == name.toLowerCase(),
            );
            if (!alreadyExists) {
              items.add(
                ChecklistItem(name: name, isChecked: true, fromAI: true),
              );
            }
          }

          if (detectedNames.isEmpty) {
            Get.snackbar(
              "Tidak Terdeteksi",
              "Tidak ada perlengkapan yang terdeteksi di gambar ini.",
              backgroundColor: Colors.orangeAccent,
              colorText: Colors.black,
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        });
      } catch (e) {
        print("Error saat inferensi: $e");
        setState(() {
          isAnalyzing = false;
        });
        Get.snackbar(
          "Gagal Menganalisa",
          "Terjadi kesalahan: $e",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  void _toggleItem(int index) {
    setState(() {
      items[index].isChecked = !items[index].isChecked;
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  void _addManualItem() {
    final text = manualItemCtrl.text.trim();
    if (text.isEmpty) return;

    final alreadyExists =
        items.any((i) => i.name.toLowerCase() == text.toLowerCase());

    if (alreadyExists) {
      Get.snackbar(
        "Sudah Ada",
        "\"$text\" sudah ada di daftar.",
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.black,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      items.add(ChecklistItem(name: text, isChecked: true, fromAI: false));
      manualItemCtrl.clear();
    });
  }

  Future<void> _saveChecklist() async {
    if (items.isEmpty) {
      Get.snackbar(
        "Checklist Kosong",
        "Tambahkan minimal satu barang sebelum menyimpan.",
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.black,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await checklistController.saveChecklist(items);

    Get.snackbar(
      "Tersimpan ✅",
      "Perlengkapan berhasil disimpan ke riwayat.",
      backgroundColor: Colors.greenAccent,
      colorText: Colors.black,
      snackPosition: SnackPosition.BOTTOM,
    );

    Get.to(() => const EquipmentHistoryView());
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "AI Outdoor Scanner",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Scan Peralatan",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.to(() => const EquipmentHistoryView());
                            },
                            child: Container(
                              width: 65,
                              height: 65,
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.history,
                                color: Colors.greenAccent,
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // IMAGE CONTAINER
                  Container(
                    width: double.infinity,
                    height: 350,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.image,
                                size: 90,
                                color: Colors.white38,
                              ),
                              SizedBox(height: 20),
                              Text(
                                "Belum ada gambar dipilih",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Upload gambar perlengkapan pendakian",
                                style: TextStyle(color: Colors.white38),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(selectedImage!, fit: BoxFit.cover),
                                if (isAnalyzing)
                                  Container(
                                    color: Colors.black54,
                                    child: const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(
                                            color: Colors.greenAccent,
                                          ),
                                          SizedBox(height: 20),
                                          Text(
                                            "AI Sedang Menganalisa...",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),

                  const SizedBox(height: 30),

                  // BUTTON CAMERA & GALLERY
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton.icon(
                            onPressed: () => pickImage(ImageSource.camera),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Kamera"),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton.icon(
                            onPressed: () => pickImage(ImageSource.gallery),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.image),
                            label: const Text("Galeri"),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // ==== TAMBAH BARANG MANUAL ====
                  const Text(
                    "Tambah Barang Manual",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: manualItemCtrl,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (_) => _addManualItem(),
                          decoration: InputDecoration(
                            hintText: "Misal: Jas Hujan, Kompor Portable...",
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white10,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 52,
                        width: 52,
                        child: ElevatedButton(
                          onPressed: _addManualItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Icon(Icons.add, color: Colors.black),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // ==== CHECKLIST PERLENGKAPAN ====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Checklist Perlengkapan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (items.isNotEmpty)
                        Text(
                          "${items.where((i) => i.isChecked).length}/${items.length}",
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Ketuk untuk centang/batal — hasil scan AI otomatis tercentang",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),

                  const SizedBox(height: 20),

                  if (items.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Belum ada barang. Scan pakai kamera/galeri atau tambah manual di atas.",
                        style: TextStyle(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...List.generate(items.length, (index) {
                      final item = items[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                          border: item.fromAI
                              ? Border.all(
                                  color: Colors.greenAccent.withOpacity(0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _toggleItem(index),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: item.isChecked
                                      ? Colors.greenAccent.withOpacity(0.2)
                                      : Colors.white10,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: item.isChecked
                                        ? Colors.greenAccent
                                        : Colors.white24,
                                  ),
                                ),
                                child: Icon(
                                  item.isChecked
                                      ? Icons.check
                                      : Icons.circle_outlined,
                                  color: item.isChecked
                                      ? Colors.greenAccent
                                      : Colors.white38,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      decoration: item.isChecked
                                          ? TextDecoration.none
                                          : TextDecoration.none,
                                    ),
                                  ),
                                  if (item.fromAI)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 3),
                                      child: Text(
                                        "Terdeteksi AI",
                                        style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _removeItem(index),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white38,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 30),

                  // ==== TOMBOL SIMPAN ====
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton.icon(
                      onPressed: _saveChecklist,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.save_alt),
                      label: const Text(
                        "SIMPAN PERLENGKAPAN",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}