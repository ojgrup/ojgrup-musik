import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:audio_service/audio_service.dart'; // Import baru
import 'audio_player_handler.dart'; // Import untuk mengakses player internal

// --- 1. MODEL DATA UNTUK PROGRESS BAR ---
class PositionData {
  const PositionData( 
    this.position,
    this.bufferedPosition,
    this.duration,
  );

  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
}

// --- 2. FUNGSI UNTUK MENGGABUNGKAN STREAM ---
// Menerima AudioHandler dan menggunakan player internalnya (yang diekspos di handler)
Stream<PositionData> getPositionDataStream(AudioHandler audioHandler) {
  // Ambil player JustAudio dari handler untuk stream posisi dan buffered
  final AudioPlayer player = (audioHandler as AudioPlayerHandler).player;
  
  return Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
    player.positionStream, // Posisi
    player.bufferedPositionStream, // Posisi Buffer
    audioHandler.mediaItem.map((item) => item?.duration ?? Duration.zero), // Durasi dari MediaItem
    (position, bufferedPosition, duration) {
      return PositionData(
        position, 
        bufferedPosition, 
        duration ?? Duration.zero, 
      );
    },
  );
}

// --- 3. FUNGSI HELPER UNTUK FORMAT WAKTU ---
String formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
