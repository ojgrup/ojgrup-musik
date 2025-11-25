import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'main.dart'; // Import untuk mengakses AssetSong dan _assetSongs

// Konversi Model AssetSong ke MediaItem
MediaItem convertSongToMediaItem(AssetSong song) {
  return MediaItem(
    id: song.assetPath,
    album: 'Lagu Sasak',
    title: song.title,
    artist: song.artist,
    // Kita tidak menggunakan URL gambar, jadi kita kosongkan atau gunakan dummy
    artUri: Uri.parse('https://example.com/cover.jpg'), 
    extras: {'assetPath': song.assetPath},
  );
}

// ----------------------------------------------------
// CLASS INTI YANG MENANGANI PEMUTARAN DI BACKGROUND/NOTIFIKASI
// ----------------------------------------------------
class AudioPlayerHandler extends BaseAudioHandler with QueueHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);

  AudioPlayerHandler() {
    // 1. Muat Daftar Putar saat Handler dibuat
    _loadInitialPlaylist();
    
    // 2. Dengarkan perubahan status pemutar JustAudio dan kirim ke AudioService
    _listenForPlayerStateChanges();
    
    // 3. Logika untuk Putar Otomatis (Ganti Lagu Saat Selesai)
    _listenForSequenceStateChanges();
  }

  // Muat semua lagu assets ke playlist JustAudio
  Future<void> _loadInitialPlaylist() async {
    final mediaItems = _assetSongs.map(convertSongToMediaItem).toList();
    
    // Konversi MediaItem ke AudioSource
    final audioSources = mediaItems.map((item) => AudioSource.asset(item.id)).toList();
    
    // Muat playlist ke JustAudio
    await _player.setAudioSource(_playlist, initialIndex: 0, initialPosition: Duration.zero);
    await _playlist.addAll(audioSources);

    // Kirim daftar lagu ke AudioService (untuk ditampilkan di Notifikasi)
    playbackState.add(playbackState.value.copyWith(controls: [
      MediaControl.skipToPrevious,
      MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ]));
    
    mediaItem.add(mediaItems[0]);
    queue.add(mediaItems);
  }

  // --- LOGIKA PUTAR OTOMATIS (GANTI LAGU SAAT SELESAI) ---
  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((sequenceState) {
      if (sequenceState == null) return;
      
      // Update mediaItem (lagu yang sedang diputar) berdasarkan index saat ini
      final event = sequenceState.currentSource;
      final index = sequenceState.currentIndex;

      if (index != null && index < queue.value.length) {
          mediaItem.add(queue.value[index]);
      }
      
      // JustAudio secara default akan pindah ke lagu berikutnya (loopMode: off)
      // Jika mode repeat di JustAudio diatur ke LoopMode.all, ia akan mengulang playlist
    });
  }

  // Logika untuk mengirim status (play/pause/loading) ke Notifikasi
  void _listenForPlayerStateChanges() {
    _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      
      if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
        playbackState.add(playbackState.value.copyWith(
          controls: [MediaControl.skipToPrevious, MediaControl.pause, MediaControl.skipToNext],
          androidCompactActionIndices: const [0, 1, 2],
          processingState: AudioProcessingState.loading,
          playing: isPlaying,
        ));
      } else if (processingState != ProcessingState.completed) {
        playbackState.add(playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            isPlaying ? MediaControl.pause : MediaControl.play,
            MediaControl.skipToNext,
          ],
          androidCompactActionIndices: const [0, 1, 2],
          processingState: AudioProcessingState.ready,
          playing: isPlaying,
        ));
      }
    });
  }
  
  // --- OVERRIDE FUNGSI KONTROL (Dipanggil dari Notifikasi) ---

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    // Berhenti total dari background
    return super.stop();
  }
}
