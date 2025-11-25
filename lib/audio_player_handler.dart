import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
// Import list lagu publik (assetSongs) dan model AssetSong
import 'main.dart'; 

// Konversi Model AssetSong ke MediaItem
MediaItem convertSongToMediaItem(AssetSong song) {
  return MediaItem(
    id: song.assetPath,
    album: 'Lagu Sasak',
    title: song.title,
    artist: song.artist,
    // Ganti dengan URI gambar cover art yang valid jika ada
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

  // Getter yang diekspos (digunakan oleh common.dart untuk stream posisi yang detail)
  AudioPlayer get player => _player;

  AudioPlayerHandler() {
    // KOREKSI KRITIS: Hapus pemanggilan _loadInitialPlaylist() dari constructor.
    // Logika async harus ada di onStart().
    _listenForPlayerStateChanges();
    _listenForSequenceStateChanges();
  }
  
  // KOREKSI KRITIS: Override onStart() untuk inisialisasi async yang aman.
  @override
  Future<void> onStart(Map<String, dynamic>? params) async {
    await _loadInitialPlaylist();
  }

  // Muat semua lagu assets ke playlist JustAudio
  Future<void> _loadInitialPlaylist() async {
    // Pastikan queue tidak kosong agar inisialisasi berjalan
    if (assetSongs.isEmpty) return;

    // Menggunakan assetSongs publik dari main.dart
    final mediaItems = assetSongs.map(convertSongToMediaItem).toList();
    
    // Konversi MediaItem ke AudioSource (AssetSource untuk local asset)
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
    
    // Set item yang sedang diputar ke lagu pertama
    mediaItem.add(mediaItems[0]);
    queue.add(mediaItems);
  }

  // Logika untuk Putar Otomatis (Ganti Lagu Saat Selesai)
  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((sequenceState) {
      if (sequenceState == null) return;
      
      final index = sequenceState.currentIndex;

      if (index != null && index < queue.value.length) {
          // Update MediaItem yang sedang aktif di Notifikasi/UI
          mediaItem.add(queue.value[index]);
      }
    });
  }

  // Logika untuk mengirim status (play/pause/loading) ke Notifikasi
  void _listenForPlayerStateChanges() {
    // Kombinasikan stream status player JustAudio dan stream posisi
    Rx.combineLatest2<PlayerState, Duration, PlaybackState>(
      _player.playerStateStream, 
      _player.positionStream, 
      (playerState, position) {
        final isPlaying = playerState.playing;
        final processingState = playerState.processingState;

        final controls = [
          MediaControl.skipToPrevious,
          isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ];
        
        return playbackState.value.copyWith(
          controls: controls,
          // Ini menentukan tombol mana yang akan muncul sebagai tombol ringkas di Android
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
  
  // --- OVERRIDE FUNGSI KONTROL STANDAR ---

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

  // Digunakan internal oleh customAction
  @override
  Future<void> skipToQueueIndex(int index) async {
    await _player.seek(Duration.zero, index: index);
    mediaItem.add(queue.value[index]);
  }
  
  // --- OVERRIDE FUNGSI CUSTOM ACTION (Solusi Error Compile) ---

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? arguments]) async {
    if (name == 'skipToQueueIndex') {
      final index = arguments?['index'] as int?;
      if (index != null) {
        await skipToQueueIndex(index);
      }
    }
    return super.customAction(name, arguments);
  }
}
