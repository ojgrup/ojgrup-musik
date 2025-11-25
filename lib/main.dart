import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

// Impor file-file navigasi, helper, dan service
import 'common.dart'; 
import 'splash_screen.dart'; 
import 'category_screen.dart'; 
import 'audio_player_handler.dart'; // Handler Service

// --- SETUP SERVICE AUDIO GLOBAL ---
late AudioHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inisialisasi AudioService di background
  _audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.musicplayer.channel',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/ic_bg_service_small', 
      androidShowNotificationBadge: true,
    ),
  );
  
  // 2. Jalankan Aplikasi
  runApp(const MyApp());
}

// --- MODEL DATA LAGU DARI ASSETS ---
class AssetSong {
  final String title;
  final String artist;
  final String assetPath; 
  final String id; // Tambahkan ID unik

  AssetSong({required this.title, required this.artist, required this.assetPath})
      : id = assetPath;
}

// DAFTAR LAGU GLOBAL
final List<AssetSong> _assetSongs = [
  AssetSong(
    title: "Lagu Sasak Pertama",
    artist: "Artis Lombok A",
    assetPath: "assets/audio/lagu_sasak_1.mp3", 
  ),
  AssetSong(
    title: "Lagu Sasak Kedua",
    artist: "Artis Lombok B",
    assetPath: "assets/audio/lagu_sasak_2.mp3", 
  ),
  AssetSong(
    title: "Lagu Sasak Ketiga",
    artist: "Artis Lombok C",
    assetPath: "assets/audio/lagu_sasak_3.mp3", 
  ),
];


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pemutar Musik Asset Offline',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.dark,
        sliderTheme: const SliderThemeData(
          trackHeight: 2.0,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
        )
      ),
      home: const SplashScreen(),
    );
  }
}

// --- SCREEN DAFTAR MUSIK UTAMA ---

class MusicPlayerScreen extends StatefulWidget {
  final List<AssetSong> songs;
  const MusicPlayerScreen({super.key, required this.songs});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {

  // Tidak perlu lagi AudioPlayer, kita pakai AudioHandler global
  // final AudioPlayer _audioPlayer = AudioPlayer(); 
  
  // State lokal untuk melacak indeks lagu yang sedang diputar di UI
  int? _currentPlayingIndex;

  @override
  void initState() {
    super.initState();
    // Dengarkan perubahan pada AudioHandler untuk mengupdate UI lokal
    _listenToAudioServiceChanges();
  }
  
  void _listenToAudioServiceChanges() {
    // Dengarkan perubahan index pemutaran dari service (misalnya, setelah next/previous)
    _audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem == null || _audioHandler.queue.value.isEmpty) return;
      
      // Cari index lagu yang sedang diputar berdasarkan ID (assetPath)
      final index = _audioHandler.queue.value.indexWhere((item) => item.id == mediaItem.id);
      
      if (mounted) {
        setState(() {
          _currentPlayingIndex = index >= 0 ? index : null;
        });
      }
    });
  }

  @override
  void dispose() {
    // Jangan dispose handler global, biarkan ia terus berjalan
    super.dispose();
  }

  // Fungsi Memutar Lagu
  Future<void> _playSong(int index) async {
    // Perintah ke AudioHandler untuk pindah ke index tertentu
    if (_audioHandler.queue.value.isEmpty) {
        // Ini tidak boleh terjadi jika _audioHandler sudah dimuat di main()
        return; 
    }
    await _audioHandler.skipToQueueIndex(index); 
    _audioHandler.play();
  }
  
  // Fungsi Toggle Play/Pause
  void _togglePlayPause() {
    final playing = _audioHandler.playbackState.value.playing;
    if (playing) {
      _audioHandler.pause();
    } else {
      _audioHandler.play();
    }
  }

  // UI Utama
  @override
  Widget build(BuildContext context) {
    // Kita gunakan StreamBuilder untuk mendapatkan lagu yang sedang dimainkan dari service
    return StreamBuilder<MediaItem?>(
      stream: _audioHandler.mediaItem,
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("🎵 Daftar Lagu"),
            backgroundColor: Colors.blueGrey[900],
          ),
          body: ListView.builder(
            itemCount: widget.songs.length,
            itemBuilder: (context, index) {
              final song = widget.songs[index];
              // Cek apakah lagu ini sedang diputar (berdasarkan index lokal)
              final isPlaying = index == _currentPlayingIndex;
              
              return ListTile(
                leading: const Icon(Icons.music_note, color: Colors.blueAccent),
                title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(song.artist, style: TextStyle(color: Colors.white70)),
                trailing: isPlaying
                    ? const Icon(Icons.volume_up, color: Colors.blue)
                    : null,
                onTap: () {
                  // Logika untuk Play/Pause/Pindah Lagu
                  if (isPlaying) {
                    _togglePlayPause();
                  } else {
                    _playSong(index); // Perintah ke Service untuk putar
                  }
                },
              );
            },
          ),
          
          // Kontrol Pemutar di Bagian Bawah (Mini-Player)
          bottomNavigationBar: _currentPlayingIndex != null
              ? MiniPlayerWidget(
                  audioHandler: _audioHandler, // Kirim handler
                  currentSong: widget.songs[_currentPlayingIndex!],
                  onTogglePlayPause: _togglePlayPause,
                )
              : null,
        );
      }
    );
  }
}


// --- WIDGET MINI PLAYER (Diadaptasi untuk AudioHandler) ---

class MiniPlayerWidget extends StatelessWidget {
  // Ganti AudioPlayer dengan AudioHandler
  final AudioHandler audioHandler;
  final AssetSong currentSong; 
  final VoidCallback onTogglePlayPause;

  const MiniPlayerWidget({
    super.key,
    required this.audioHandler,
    required this.currentSong,
    required this.onTogglePlayPause,
  });

  // Fungsi untuk maju/mundur (seek)
  void _onSeek(double value) {
    audioHandler.seek(Duration(milliseconds: value.toInt()));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0, left: 8.0, right: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Baris 1: Informasi Lagu & Kontrol Play/Pause
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSong.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currentSong.artist,
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // Kontrol Play/Pause: Gunakan StreamBuilder pada playbackState
              StreamBuilder<PlaybackState>(
                stream: audioHandler.playbackState,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  final processingState = snapshot.data?.processingState ?? AudioProcessingState.idle;

                  if (processingState == AudioProcessingState.loading ||
                      processingState == AudioProcessingState.buffering) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                      ),
                    );
                  } else {
                    return IconButton(
                      icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 48, color: Colors.white),
                      onPressed: onTogglePlayPause,
                    );
                  }
                },
              ),
            ],
          ),
          
          // Baris 2: Slider Progress Bar dan Waktu
          // Note: Kita menggunakan getPositionDataStream global, namun ia mengambil data dari stream handler
          StreamBuilder<PositionData>(
            stream: getPositionDataStream(audioHandler.player as AudioPlayer), // Casting AudioHandler's player back to AudioPlayer
            builder: (context, snapshot) {
              final positionData = snapshot.data;
              final position = positionData?.position ?? Duration.zero;
              final duration = positionData?.duration ?? Duration.zero;
              
              double sliderValue = position.inMilliseconds.toDouble();
              if (sliderValue > duration.inMilliseconds) {
                sliderValue = duration.inMilliseconds.toDouble();
              }
              
              return Column(
                children: [
                  Slider(
                    min: 0.0,
                    max: duration.inMilliseconds.toDouble(),
                    value: sliderValue,
                    activeColor: Colors.blueAccent,
                    inactiveColor: Colors.white38,
                    onChanged: (value) { /* Do nothing here */ }, 
                    onChangeEnd: _onSeek,
                  ),
                  
                  // Teks Waktu Lagu
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatDuration(position), style: TextStyle(fontSize: 12)), 
                        Text(formatDuration(duration), style: TextStyle(fontSize: 12)), 
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
