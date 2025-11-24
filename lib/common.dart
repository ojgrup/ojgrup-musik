import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

// --- 1. MODEL DATA UNTUK PROGRESS BAR ---
class PositionData {
  // Constructor: Nama harus sama dengan nama class, tanpa return type.
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
Stream<PositionData> getPositionDataStream(AudioPlayer audioPlayer) {
  return Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
    audioPlayer.positionStream,
    audioPlayer.bufferedPositionStream,
    audioPlayer.durationStream,
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
