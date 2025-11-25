import 'package:flutter/material.dart';
import 'dart:async'; // Import untuk menggunakan Timer

// Import layar tujuan navigasi
import 'category_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // Panggil fungsi _navigateToHome setelah 3 detik
    Timer(const Duration(seconds: 3), _navigateToCategory);
  }

  void _navigateToCategory() {
    // Navigasi menggantikan layar saat ini (agar user tidak bisa kembali ke splash screen)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const CategoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.music_note_sharp,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              "Pemutar Musik Lombok",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 50),
            // Tampilkan loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }
}
