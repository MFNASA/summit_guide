import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/rental_controller.dart';

/// Menampilkan daftar alat yang sedang/sudah disewa oleh user,
/// mengikuti field yang benar-benar dikirim oleh backend
/// (id, item_name, image_url, qty, start_date, end_date, total_price,
/// status, payment_status, sedang_disewa, belum_dikembalikan,
/// terlambat_dikembalikan).
class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  final RentalController rentalController = Get.find();

  @override
  void initState() {
    super.initState();
    rentalController.fetchMyRentals();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.greenAccent;
      case 'completed':
        return Colors.blueAccent;
      case 'pending':
        return Colors.orangeAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  Color _paymentColor(String paymentStatus) {
    switch (paymentStatus) {
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
        title: const Text("Alat yang Saya Sewa"),
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        if (rentalController.isLoadingHistory.value) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent));
        }
        if (rentalController.myRentals.isEmpty) {
          return const Center(
            child: Text("Belum ada alat yang disewa.",
                style: TextStyle(color: Colors.white70)),
          );
        }
        return RefreshIndicator(
          onRefresh: rentalController.fetchMyRentals,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: rentalController.myRentals.length,
            itemBuilder: (context, index) {
              final r = Map<String, dynamic>.from(
                  rentalController.myRentals[index] as Map);

              final String status = (r['status'] ?? '').toString();
              final String paymentStatus =
                  (r['payment_status'] ?? '').toString();
              final bool sedangDisewa = r['sedang_disewa'] == true;
              final bool belumDikembalikan = r['belum_dikembalikan'] == true;
              final bool terlambat = r['terlambat_dikembalikan'] == true;
              final String? imageUrl = r['image_url']?.toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: terlambat ? Colors.redAccent : Colors.white24,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (imageUrl != null && imageUrl.isNotEmpty)
                          Container(
                            width: 55,
                            height: 55,
                            margin: const EdgeInsets.only(right: 15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.greenAccent.withOpacity(0.2),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.backpack,
                                      color: Colors.greenAccent),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            (r['item_name'] ?? '-').toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // === Badge Status Sewa & Pembayaran ===
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _badge(
                          status.isNotEmpty ? status.toUpperCase() : '-',
                          _statusColor(status),
                        ),
                        _badge(
                          paymentStatus.isNotEmpty
                              ? paymentStatus.toUpperCase()
                              : '-',
                          _paymentColor(paymentStatus),
                        ),
                        if (terlambat)
                          _badge("TERLAMBAT DIKEMBALIKAN", Colors.redAccent),
                        if (sedangDisewa && !terlambat)
                          _badge("SEDANG DISEWA", Colors.greenAccent),
                        if (belumDikembalikan && !sedangDisewa && !terlambat)
                          _badge("BELUM DIKEMBALIKAN", Colors.orangeAccent),
                      ],
                    ),
                    const SizedBox(height: 15),

                    Text("Jumlah: ${r['qty'] ?? '-'} unit",
                        style: const TextStyle(color: Colors.white70)),
                    Text("Mulai: ${r['start_date'] ?? '-'}",
                        style: const TextStyle(color: Colors.white70)),
                    Text("Selesai: ${r['end_date'] ?? '-'}",
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      "Total: Rp ${r['total_price'] ?? 0}",
                      style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
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

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}