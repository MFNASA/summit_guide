import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/checklist_controller.dart';

class EquipmentHistoryView extends StatelessWidget {
  const EquipmentHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final ChecklistController controller = Get.isRegistered<ChecklistController>()
        ? Get.find<ChecklistController>()
        : Get.put(ChecklistController());

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
              // HEADER
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
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      "Riwayat Perlengkapan",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Obx(() {
                  if (controller.history.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: Text(
                          "Belum ada riwayat perlengkapan yang disimpan.\nMulai scan di halaman Scan untuk menyimpan checklist pertamamu.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 15),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: controller.history.length,
                    itemBuilder: (context, index) {
                      final entry = controller.history[index];
                      final formattedDate =
                          DateFormat('dd MMM yyyy, HH:mm').format(entry.date);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.backpack,
                                        color: Colors.greenAccent, size: 22),
                                    const SizedBox(width: 10),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Get.defaultDialog(
                                      title: "Hapus Riwayat?",
                                      middleText:
                                          "Checklist tanggal $formattedDate akan dihapus permanen.",
                                      textConfirm: "Hapus",
                                      textCancel: "Batal",
                                      confirmTextColor: Colors.white,
                                      onConfirm: () {
                                        controller.deleteEntry(entry.id);
                                        Get.back();
                                      },
                                    );
                                  },
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${entry.checkedCount}/${entry.totalCount} barang dibawa",
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(color: Colors.white12, height: 24),
                            ...entry.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.isChecked
                                          ? Icons.check_circle
                                          : Icons.cancel_outlined,
                                      color: item.isChecked
                                          ? Colors.greenAccent
                                          : Colors.white24,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: TextStyle(
                                          color: item.isChecked
                                              ? Colors.white
                                              : Colors.white38,
                                          fontSize: 14,
                                          decoration: item.isChecked
                                              ? TextDecoration.none
                                              : TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ),
                                    if (item.fromAI)
                                      const Icon(
                                        Icons.auto_awesome,
                                        color: Colors.greenAccent,
                                        size: 14,
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
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