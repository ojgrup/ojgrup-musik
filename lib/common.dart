import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

// --- 1. MODEL DATA UNTUK PROGRESS BAR ---
// Class yang menyatukan semua data yang dibutuhkan untuk UI pemutar (Slider)
class PositionData {
  const Position PositionData(
    this.position,
    this.bufferedPosition,
    this.duration,
  );

  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
}

// --- 2. FUNGSI UNTUK MENGGABUNGKAN STREAM ---
// Stream ini menggabungkan posisi pemutaran, posisi buffer, dan durasi total 
// menjadi satu stream PositionData. Ini penting agar slider dan teks waktu 
// di UI dapat diupdate secara bersamaan.
Stream<PositionData> getPositionDataStream(AudioPlayer audioPlayer) {
  return Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
    audioPlayer.positionStream,
    audioPlayer.bufferedPositionStream,
    audioPlayer.durationStream,
    (position, bufferedPosition, duration) {
      return PositionData(
        position, 
        bufferedPosition, 
        duration ?? Duration.zero, // Jika durasi null (lagu belum dimuat), anggap 0
      );
    },
  );
}

// --- 3. FUNGSI HELPER UNTUK FORMAT WAKTU ---
// Fungsi untuk mengubah objek Duration (misalnya 120 detik) menjadi string 
// yang mudah dibaca (misalnya "02:00").
String formatDuration(Duration d) {
  // Hitung menit (sisanya setelah jam)
  final minutes = d.inMinutes.remainder(60);
  // Hitung detik (sisanya setelah menit)
  final seconds = d.inSeconds.remainder(60);
  
  // Menggunakan padLeft untuk memastikan format 00:00 (misalnya 8 detik menjadi 08)
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
