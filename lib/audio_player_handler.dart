// lib/audio_player_handler.dart

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'data_model.dart'; // Import dari file baru

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
  final _playlist = ConcatenatingAudioSource(children: []); 

  AudioPlayer get player => _player;

  AudioPlayerHandler() {
    // Hanya panggil listener yang aman di constructor
    _listenForPlayerStateChanges();
    _listenForSequenceStateChanges();
  }
  
  // KOREKSI CRASH RUNTIME: Logika Async di onStart()
  @override
  Future<void> onStart(Map<String, dynamic>? params) async {
    await _loadInitialPlaylist();
  }

  // Muat semua lagu assets ke playlist JustAudio
  Future<void> _loadInitialPlaylist() async {
    if (assetSongs.isEmpty) return;
    
    final mediaItems = assetSongs.map(convertSongToMediaItem).toList();
    // Path lagu ada di field id MediaItem (yang berasal dari assetPath)
    final audioSources = mediaItems.map((item) => AudioSource.asset(item.id)).toList();
    
    // Set AudioSource dengan playlist kosong
    await _player.setAudioSource(_playlist);
    await _playlist.addAll(audioSources);

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
          androidCompactActionIndices: const [0, 1, 2], 
          processingState: {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[processingState] ?? AudioProcessingState.idle,
          playing: isPlaying,
          updatePosition: position, 
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

  @override
  Future<void> skipToQueueIndex(int index) async {
    await _player.seek(Duration.zero, index: index);
    mediaItem.add(queue.value[index]);
  }
  
  // KOREKSI ERROR COMPILE: customAction untuk skipToQueueIndex
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
