import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Satu barang di dalam checklist — bisa berasal dari deteksi AI
/// atau ditambahkan manual oleh user lewat ketikan.
class ChecklistItem {
  String name;
  bool isChecked;
  bool fromAI;

  ChecklistItem({
    required this.name,
    this.isChecked = false,
    this.fromAI = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'isChecked': isChecked,
        'fromAI': fromAI,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        name: json['name'] ?? '',
        isChecked: json['isChecked'] ?? false,
        fromAI: json['fromAI'] ?? false,
      );
}

/// Satu entri riwayat — dibuat setiap kali user menekan "Simpan Perlengkapan".
/// Menyimpan snapshot seluruh checklist beserta status centangnya saat itu.
class ChecklistHistoryEntry {
  final String id;
  final DateTime date;
  final List<ChecklistItem> items;

  ChecklistHistoryEntry({
    required this.id,
    required this.date,
    required this.items,
  });

  int get checkedCount => items.where((i) => i.isChecked).length;
  int get totalCount => items.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory ChecklistHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ChecklistHistoryEntry(
      id: json['id']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => ChecklistItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class ChecklistController extends GetxController {
  final GetStorage _box = GetStorage();
  static const String _historyKey = 'equipment_checklist_history';

  var history = <ChecklistHistoryEntry>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  void loadHistory() {
    try {
      final raw = _box.read(_historyKey);
      if (raw == null) return;

      final decoded = raw is String ? jsonDecode(raw) : raw;
      final list = (decoded as List)
          .map((e) =>
              ChecklistHistoryEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // Urutkan yang terbaru di paling atas
      list.sort((a, b) => b.date.compareTo(a.date));
      history.assignAll(list);
    } catch (e) {
      print("ChecklistController: gagal load history -> $e");
    }
  }

  /// Simpan snapshot checklist saat ini sebagai satu entri riwayat baru.
  Future<void> saveChecklist(List<ChecklistItem> items) async {
    final entry = ChecklistHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      items: items
          .map((i) => ChecklistItem(
                name: i.name,
                isChecked: i.isChecked,
                fromAI: i.fromAI,
              ))
          .toList(),
    );

    history.insert(0, entry);
    await _persist();
  }

  Future<void> deleteEntry(String id) async {
    history.removeWhere((e) => e.id == id);
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final list = history.map((e) => e.toJson()).toList();
      await _box.write(_historyKey, jsonEncode(list));
    } catch (e) {
      print("ChecklistController: gagal simpan history -> $e");
    }
  }
}