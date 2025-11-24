import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, dynamic>> People = [
    {
      "name": "Expert Plumbing",
      "image": "assets/images/Robin.png",
      "price": "\$35",
      "review": "⭐ 4.4 (1.800 reviews)",
      "job": "Plumber",
    },
    {
      "name": "Electrical Service",
      "image": "assets/images/Sunday.png",
      "price": "\$45",
      "review": "⭐ 4.3 (900 reviews)",
      "job": "Electrician",
    },
    {
      "name": "Deep Home Cleaning",
      "image": "assets/images/M7.png",
      "price": "\$30",
      "review": "⭐ 4.7 (1.500 reviews)",
      "job": "Mason",
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Memberi warna latar belakang yang membedakan dengan header.
    // Misal, abu-abu muda.
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER KUSTOM (APP BAR) YANG TIDAK TRANSPARAN ---
            Container(
              // INI ADALAH PERBAIKAN: Memberikan warna latar belakang solid
              color: Colors.white, 
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              // Tambahkan SafeArea agar konten tidak tertutup status bar
              child: SafeArea( 
                bottom: false, // Hanya perlu aman di bagian atas
                child: Row(
                  children: [
                    Icon(Icons.account_circle, size: 40),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hallo ✨"),
                        Text("Dennis Dwi Musti"),
                      ],
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(Icons.notifications, size: 30),
                    ),
                  ],
                ),
              ),
            ),
            // --- AKHIR HEADER KUSTOM ---

            SizedBox(height: 20),

            // Lanjutkan dengan Search Bar dan konten lainnya...

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Search For Any Service",
                          suffixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.candlestick_chart, size: 30),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Konten lainnya dihilangkan untuk menjaga fokus, tetapi asumsikan kode sebelumnya dilanjutkan di sini
            
            // ... (Lanjutan kode banner, kategori, dan list popular near you)
            
            // Catatan: Jika Anda menginginkan header ini tetap di atas (Sticky AppBar),
            // Anda harus memindahkannya ke properti 'appBar' pada Scaffold.
            // Namun, karena Anda membuatnya kustom, solusi di atas adalah yang paling sederhana.
          ],
        ),
      ),
    );
  } 
}
