import 'package:flutter/material.dart';
// Import class MusicPlayerScreen dan daftar lagu publik
import 'main.dart'; 

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  // Daftar kategori dummy
  final List<String> categories = const [
    "Lagu Sasak Pilihan",
    "Kidung Klasik",
    "Pop Kontemporer",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Kategori Musik"),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final categoryName = categories[index];
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: Colors.blueGrey[800],
            child: ListTile(
              leading: const Icon(Icons.folder_open, color: Colors.yellow),
              title: Text(
                categoryName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
              onTap: () {
                // PERBAIKAN: Hapus 'const'
                Navigator.of(context).push(
                  MaterialPageRoute(
                    // Menggunakan assetSongs publik
                    builder: (context) => MusicPlayerScreen(songs: assetSongs), 
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
