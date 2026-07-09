import 'package:flutter/material.dart';
import 'package:get/get.dart';

// === IMPORT CONTROLLER ===
import '../controllers/tiket_controller.dart';
import '../controllers/rental_controller.dart';

// === IMPORT CART VIEW ===
import 'cart_view.dart';

// === IMPORT MY TICKETS VIEW ===
import 'my_tickets_view.dart';

class SewaJasaView extends StatefulWidget {
  const SewaJasaView({super.key});

  @override
  State<SewaJasaView> createState() => _SewaJasaViewState();
}

class _SewaJasaViewState extends State<SewaJasaView> {
  final TiketController tiketController = Get.put(TiketController());
  final RentalController rentalController = Get.put(RentalController());

  final TextEditingController searchController = TextEditingController();

  // 0 = Peralatan (Rental, dari API), 1 = Tiket (dari API)
  int selectedCategory = 0;
  String searchQuery = "";

  void changeCategory(int index) {
    setState(() {
      selectedCategory = index;
      searchController.clear();
      searchQuery = "";
      // Rental & Tiket difilter langsung di widget builder-nya (data reaktif)
    });
  }

  void searchItem(String value) {
    setState(() {
      searchQuery = value.toLowerCase();
      // Rental & Tiket difilter langsung di widget builder-nya (data reaktif)
    });
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  String _formatDateDisplay(DateTime date) {
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return "${date.day} ${bulan[date.month - 1]} ${date.year}";
  }

  // === BOTTOM SHEET: PILIH TANGGAL MULAI, DURASI, & JUMLAH SEWA ALAT ===
  // Disesuaikan dengan payload backend: item_id, qty, start_date, end_date
  void _showRentalBookingSheet(Map<String, dynamic> item) {
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    int durationDays = 1;
    int qty = 1;

    final int itemId = item['id'] is int ? item['id'] : int.tryParse(item['id'].toString()) ?? 0;
    final String itemName = item['name']?.toString() ?? '-';
    final int stockTersedia = item['stock'] is int
        ? item['stock']
        : int.tryParse(item['stock'].toString()) ?? 0;
    final double hargaPerHari = item['price'] is num
        ? (item['price'] as num).toDouble()
        : double.tryParse(item['price'].toString()) ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final DateTime endDate = startDate.add(Duration(days: durationDays));
            final double totalHarga = hargaPerHari * qty * durationDays;

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 25,
                bottom: MediaQuery.of(context).viewInsets.bottom + 25,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF203A43),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    itemName,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Rp ${hargaPerHari.toStringAsFixed(0)} / hari",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 25),

                  // === TANGGAL MULAI SEWA ===
                  const Text("Tanggal Mulai Sewa", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Colors.greenAccent,
                                onPrimary: Colors.black,
                                surface: Color(0xFF203A43),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          startDate = picked;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.greenAccent, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _formatDateDisplay(startDate),
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // === DURASI SEWA (HARI) ===
                  const Text("Durasi Sewa (hari)", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _stepperButton(
                          icon: Icons.remove,
                          onTap: () {
                            if (durationDays > 1) {
                              setModalState(() => durationDays--);
                            }
                          },
                        ),
                        Text(
                          durationDays.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        _stepperButton(
                          icon: Icons.add,
                          onTap: () => setModalState(() => durationDays++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // === JUMLAH UNIT ===
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Jumlah Unit", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(
                        "Sisa Stok: $stockTersedia",
                        style: TextStyle(
                          color: stockTersedia > 0 ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _stepperButton(
                          icon: Icons.remove,
                          onTap: () {
                            if (qty > 1) {
                              setModalState(() => qty--);
                            }
                          },
                        ),
                        Text(
                          qty.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        _stepperButton(
                          icon: Icons.add,
                          onTap: () {
                            if (qty < stockTersedia) {
                              setModalState(() => qty++);
                            } else {
                              Get.snackbar(
                                "Stok Terbatas",
                                "Jumlah unit tidak boleh melebihi sisa stok.",
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.orangeAccent,
                                colorText: Colors.black,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // === TOTAL HARGA ===
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Harga", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Text(
                          "Rp ${totalHarga.toStringAsFixed(0)}",
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // === TOMBOL KONFIRMASI ===
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: stockTersedia < 1
                          ? null
                          : () {
                              Navigator.pop(context);
                              rentalController.bookRental(
                                itemId,
                                itemName,
                                startDate: _formatDate(startDate),
                                endDate: _formatDate(endDate),
                                qty: qty,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("Konfirmasi & Bayar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // === BOTTOM SHEET: PILIH TANGGAL & JUMLAH TIKET ===
  void _showTicketBookingSheet(Map<String, dynamic> item) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    int quantity = 1;
    final int kuotaTersedia = (item['kuota'] ?? 0) is int
        ? item['kuota']
        : int.tryParse(item['kuota'].toString()) ?? 0;
    final int hargaSatuan = (item['harga'] ?? 0) is int
        ? item['harga']
        : int.tryParse(item['harga'].toString()) ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final int totalHarga = hargaSatuan * quantity;

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 25,
                bottom: MediaQuery.of(context).viewInsets.bottom + 25,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF203A43),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    item['nama_gunung'] ?? '-',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['basecamp'] ?? '-',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 25),
                  const Text("Tanggal Pendakian", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Colors.greenAccent,
                                onPrimary: Colors.black,
                                surface: Color(0xFF203A43),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.greenAccent, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _formatDateDisplay(selectedDate),
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Jumlah Tiket", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(
                        "Sisa Kuota: $kuotaTersedia",
                        style: TextStyle(
                          color: kuotaTersedia > 0 ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _stepperButton(
                          icon: Icons.remove,
                          onTap: () {
                            if (quantity > 1) {
                              setModalState(() => quantity--);
                            }
                          },
                        ),
                        Text(
                          quantity.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        _stepperButton(
                          icon: Icons.add,
                          onTap: () {
                            if (quantity < kuotaTersedia) {
                              setModalState(() => quantity++);
                            } else {
                              Get.snackbar(
                                "Kuota Terbatas",
                                "Jumlah tiket tidak boleh melebihi sisa kuota.",
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.orangeAccent,
                                colorText: Colors.black,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Harga", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Text(
                          "Rp $totalHarga",
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: kuotaTersedia < 1
                          ? null
                          : () {
                              Navigator.pop(context);
                              tiketController.bookTicket(
                                item['id'],
                                item['nama_gunung'],
                                hikingDate: _formatDate(selectedDate),
                                quantity: quantity,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("Konfirmasi & Bayar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _stepperButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedCategory == 1 ? "Booking Resmi" : "Layanan Ekspedisi",
                            style: const TextStyle(color: Colors.white70, fontSize: 16)
                          ),
                          const SizedBox(height: 5),
                          Text(
                            selectedCategory == 0 ? "Rental Alat" : "Tiket Basecamp",
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.to(() => const MyTicketsView());
                            },
                            child: Container(
                              width: 65, height: 65,
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Center(
                                child: Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 32),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Get.to(() => const CartView());
                            },
                            child: Container(
                              width: 65, height: 65,
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Center(
                                child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                    child: TextField(
                      controller: searchController,
                      onChanged: searchItem,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: selectedCategory == 1 ? "Cari jalur gunung..." : "Cari alat...",
                        hintStyle: const TextStyle(color: Colors.white60),
                        prefixIcon: const Icon(Icons.search, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),

                  const Text("Kategori Layanan", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _categoryCard(Icons.backpack, "Rental", 0)),
                      const SizedBox(width: 15),
                      Expanded(child: _categoryCard(Icons.confirmation_number, "Tiket", 1)),
                    ],
                  ),
                  const SizedBox(height: 35),

                  Text(
                    selectedCategory == 0 ? "List Alat Tersedia (Realtime)" : "Jadwal Realtime (API)",
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  if (selectedCategory == 0)
                    _buildDynamicRentalList()
                  else
                    _buildDynamicTiketList(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryCard(IconData icon, String title, int index) {
    final bool isActive = selectedCategory == index;
    return GestureDetector(
      onTap: () => changeCategory(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 110,
        decoration: BoxDecoration(
          color: isActive ? Colors.greenAccent : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.greenAccent : Colors.white24),
          boxShadow: isActive ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? Colors.black : Colors.white70, size: 35),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(color: isActive ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // === WIDGET: LIST RENTAL DARI API (REALTIME) ===
  Widget _buildDynamicRentalList() {
    return Obx(() {
      if (rentalController.isLoading.value) {
        return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Colors.greenAccent)));
      }
      if (rentalController.errorMessage.value.isNotEmpty && rentalController.listRental.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              children: [
                Text(rentalController.errorMessage.value, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => rentalController.fetchRentals(),
                  child: const Text("Coba lagi", style: TextStyle(color: Colors.greenAccent)),
                ),
              ],
            ),
          ),
        );
      }
      if (rentalController.listRental.isEmpty) {
        return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text("Belum ada alat tersedia.", style: TextStyle(color: Colors.white70))));
      }

      final displayed = rentalController.listRental.where((item) {
        return item['name'].toString().toLowerCase().contains(searchQuery);
      }).toList();

      return ListView.builder(
        itemCount: displayed.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final item = displayed[index];
          final int stock = item['stock'] is int ? item['stock'] : int.tryParse(item['stock'].toString()) ?? 0;
          final bool tersedia = stock > 0;
          final double price = item['price'] is num ? (item['price'] as num).toDouble() : double.tryParse(item['price'].toString()) ?? 0;
          final String? imageUrl = item['image_url']?.toString();

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: tersedia ? Colors.white24 : Colors.redAccent.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.greenAccent.withOpacity(0.2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.backpack, color: Colors.greenAccent, size: 40),
                          )
                        : const Icon(Icons.backpack, color: Colors.greenAccent, size: 40),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item["name"].toString(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text(
                          "Stok: ${tersedia ? stock : 'Habis'}",
                          style: TextStyle(color: tersedia ? Colors.white70 : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text("Rp ${price.toStringAsFixed(0)} / hari", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: tersedia ? () => _showRentalBookingSheet(item) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tersedia ? Colors.greenAccent : Colors.grey[800],
                      foregroundColor: tersedia ? Colors.black : Colors.white54,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(tersedia ? "Sewa" : "Habis", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  // === WIDGET: LIST TIKET API (REALTIME) ===
  Widget _buildDynamicTiketList() {
    return Obx(() {
      if (tiketController.isLoading.value) {
        return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Colors.greenAccent)));
      }
      if (tiketController.listBasecamp.isEmpty) {
        return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text("Data dari server kosong / gagal ditarik.", style: TextStyle(color: Colors.white70))));
      }

      var displayedTickets = tiketController.listBasecamp.where((item) {
        return item['nama_gunung'].toString().toLowerCase().contains(searchQuery) ||
               item['basecamp'].toString().toLowerCase().contains(searchQuery);
      }).toList();

      return ListView.builder(
        itemCount: displayedTickets.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          var item = displayedTickets[index];
          bool isTersedia = item['kuota'] > 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white10, borderRadius: BorderRadius.circular(25),
                border: Border.all(color: isTersedia ? Colors.white24 : Colors.redAccent.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.airplane_ticket, color: Colors.greenAccent, size: 35),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item["nama_gunung"], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text(item["basecamp"], style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 5),
                        Text("Sisa Kuota: ${isTersedia ? item['kuota'] : 'Penuh'}", style: TextStyle(color: isTersedia ? Colors.greenAccent : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text("Rp ${item['harga']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isTersedia ? () => _showTicketBookingSheet(item) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTersedia ? Colors.greenAccent : Colors.grey[800],
                      foregroundColor: isTersedia ? Colors.black : Colors.white54,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(isTersedia ? "Beli" : "Full", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}