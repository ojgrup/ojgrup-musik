import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
// Import list lagu publik (assetSongs)
import 'main.dart'; 

// Konversi Model AssetSong ke MediaItem
MediaItem convertSongToMediaItem(AssetSong song) {
  return MediaItem(
    id: song.assetPath,
    album: 'Lagu Sasak',
    title: song.title,
    artist: song.artist,
    artUri: Uri.parse('https://example.com/cover.jpg'), 
    extras: {'assetPath': song.assetPath},
  );
}

// ----------------------------------------------------
// CLASS INTI YANG MENANGANI PEMUTARAN DI BACKGROUND/NOTIFIKASI
// ----------------------------------------------------
class AudioPlayerHandler extends BaseAudioHandler with QueueHandler {
  final _player = AudioPlayer();
  // Gunakan playlist dengan ConcatenatingAudioSource untuk urutan lagu
  final _playlist = ConcatenatingAudioSource(children: []); 

  // Getter yang diekspos (untuk common.dart yang membutuhkan posisi JustAudio)
  AudioPlayer get player => _player;

  AudioPlayerHandler() {
    _loadInitialPlaylist();
    _listenForPlayerStateChanges();
    _listenForSequenceStateChanges();
  }

  // Muat semua lagu assets ke playlist JustAudio
  Future<void> _loadInitialPlaylist() async {
    // PERBAIKAN D: Menggunakan assetSongs publik
    final mediaItems = assetSongs.map(convertSongToMediaItem).toList();
    
    // Konversi MediaItem ke AudioSource
    final audioSources = mediaItems.map((item) => AudioSource.asset(item.id)).toList();
    
    // Set AudioSource dengan ConcatenatingAudioSource
    await _player.setAudioSource(_playlist, initialIndex: 0, initialPosition: Duration.zero);
    await _playlist.addAll(audioSources);

    // Kirim daftar lagu ke AudioService
    playbackState.add(playbackState.value.copyWith(controls: [
      MediaControl.skipToPrevious,
      MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ]));
    
    mediaItem.add(mediaItems[0]);
    queue.add(mediaItems);
  }

  // Logika untuk Putar Otomatis (Ganti Lagu Saat Selesai)
  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((sequenceState) {
      if (sequenceState == null) return;
      
      final index = sequenceState.currentIndex;

      if (index != null && index < queue.value.length) {
          mediaItem.add(queue.value[index]);
      }
    });
  }

  // Logika untuk mengirim status (play/pause/loading) ke Notifikasi
  void _listenForPlayerStateChanges() {
    // Kombinasikan stream status player JustAudio dan stream posisi
    Rx.combineLatest2<PlayerState, Duration, PlaybackState>(
      _player.playerStateStream, 
      _player.positionStream, // Menggunakan stream posisi JustAudio
      (playerState, position) {
        // ... (Logika status tetap sama) ...
        final isPlaying = playerState.playing;
        final processingState = playerState.processingState;

        // ... (Kode kontrol sama seperti di perbaikan sebelumnya) ...
        final controls = [
          MediaControl.skipToPrevious,
          isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ];
        
        return playbackState.value.copyWith(
          controls: controls,
          androidCompactActionIndices: const [0, 1, 2],
          processingState: {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[processingState] ?? AudioProcessingState.idle,
          playing: isPlaying,
          updatePosition: position, // UPDATE POSISI DI SINI
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
        );
      }
    ).listen((state) {
      playbackState.add(state);
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
    return super.stop();
  }

  // Override skipToQueueIndex dari QueueHandler
  @override
  Future<void> skipToQueueIndex(int index) async {
    await _player.seek(Duration.zero, index: index);
    mediaItem.add(queue.value[index]);
  }
}
