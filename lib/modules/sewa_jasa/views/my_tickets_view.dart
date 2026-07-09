import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controllers/tiket_controller.dart';

class MyTicketsView extends StatefulWidget {
  const MyTicketsView({super.key});

  @override
  State<MyTicketsView> createState() => _MyTicketsViewState();
}

class _MyTicketsViewState extends State<MyTicketsView> {
  final TiketController tiketController = Get.find();

  @override
  void initState() {
    super.initState();
    tiketController.fetchMyTickets();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.greenAccent;
      case 'pending':
        return Colors.orangeAccent;
      default:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text("Tiket Saya"),
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        if (tiketController.isLoadingHistory.value) {
          return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
        }
        if (tiketController.myTickets.isEmpty) {
          return const Center(
            child: Text("Belum ada tiket.", style: TextStyle(color: Colors.white70)),
          );
        }
        return RefreshIndicator(
          onRefresh: tiketController.fetchMyTickets,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: tiketController.myTickets.length,
            itemBuilder: (context, index) {
              final t = tiketController.myTickets[index];
              final bool isPaid = t['payment_status'] == 'paid';

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t['nama_gunung'] ?? '-',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _statusColor(t['payment_status']).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            (t['payment_status'] ?? '-').toString().toUpperCase(),
                            style: TextStyle(color: _statusColor(t['payment_status']), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(t['basecamp'] ?? '-', style: const TextStyle(color: Colors.white70)),
                    Text("Tanggal: ${t['booking_date'] ?? '-'}", style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 15),

                    // QR Code hanya muncul kalau sudah dibayar
                    if (isPaid) ...[
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                          child: QrImageView(
                            data: t['qr_code'] ?? '',
                            version: QrVersions.auto,
                            size: 160,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(t['qr_code'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ),
                    ] else
                      Center(
                        child: Text(
                          "QR Code muncul setelah pembayaran berhasil",
                          style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}