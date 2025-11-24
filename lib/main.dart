import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
// Impor file common.dart untuk fungsi helper dan PositionData
import 'common.dart'; 

// --- MODEL DATA LAGU DARI ASSETS ---
class AssetSong {
  final String title;
  final String artist;
  // assetPath adalah jalur relatif ke file di folder assets
  final String assetPath; 

  AssetSong({required this.title, required this.artist, required this.assetPath});
}

// Ganti daftar ini dengan detail dan path file di folder assets/audio/ milikmu!
final List<AssetSong> _assetSongs = [
  AssetSong(
    title: "Lagu Sasak Pertama",
    artist: "Artis Lombok A",
    assetPath: "assets/audio/Zias Band - Ku Harus Pergi.mp3", // PASTIKAN NAMA FILE INI ADA!
  ),
  AssetSong(
    title: "Lagu Sasak Kedua",
    artist: "Artis Lombok B",
    assetPath: "assets/audio/lagu_sasak_2.mp3", // PASTIKAN NAMA FILE INI ADA!
  ),
  AssetSong(
    title: "Lagu Sasak Ketiga",
    artist: "Artis Lombok C",
    assetPath: "assets/audio/lagu_sasak_3.mp3", // PASTIKAN NAMA FILE INI ADA!
  ),
];


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pemutar Musik Asset Offline',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.dark,
        // Konfigurasi slider untuk tampilan yang bersih
        sliderTheme: const SliderThemeData(
          trackHeight: 2.0,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
        )
      ),
      home: const MusicPlayerScreen(songs: _assetSongs),
    );
  }
}

// --- SCREEN UTAMA ---

class MusicPlayerScreen extends StatefulWidget {
  final List<AssetSong> songs;
  const MusicPlayerScreen({super.key, required this.songs});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  // 1. Instansiasi Player
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _currentPlayingIndex;

  @override
  void dispose() {
    _audioPlayer.dispose(); // Wajib untuk membersihkan sumber daya
    super.dispose();
  }

  // 2. Fungsi Memutar Lagu dari Assets
  Future<void> _playAssetSong(int index) async {
    final song = widget.songs[index];
    
    try {
      // **Kunci: Menggunakan setAsset()**
      await _audioPlayer.setAsset(song.assetPath); 
      _audioPlayer.play();
      
      setState(() {
        _currentPlayingIndex = index;
      });
    } catch (e) {
      print("Error memutar asset: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memutar lagu: $e. Pastikan path asset benar.')),
      );
    }
  }
  
  // 3. Fungsi Toggle Play/Pause
  void _togglePlayPause() {
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  // 4. UI Utama
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🎵 Musik Offline (Assets)"),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: ListView.builder(
              itemCount: widget.songs.length,
              itemBuilder: (context, index) {
                final song = widget.songs[index];
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
                      _togglePlayPause(); // Jika lagu yang sama di-tap
                    } else {
                      _playAssetSong(index); // Putar lagu baru
                    }
                  },
                );
              },
            ),
      
      // 5. Kontrol Pemutar di Bagian Bawah (Mini-Player)
      bottomNavigationBar: _currentPlayingIndex != null
          ? MiniPlayerWidget(
              audioPlayer: _audioPlayer,
              currentSong: widget.songs[_currentPlayingIndex!],
              onTogglePlayPause: _togglePlayPause,
            )
          : null,
    );
  }
}


// --- WIDGET MINI PLAYER (Dengan Progress Bar dan Seek) ---

class MiniPlayerWidget extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final AssetSong currentSong; 
  final VoidCallback onTogglePlayPause;

  const MiniPlayerWidget({
    super.key,
    required this.audioPlayer,
    required this.currentSong,
    required this.onTogglePlayPause,
  });

  // Fungsi untuk maju/mundur (seek)
  void _onSeek(double value) {
    audioPlayer.seek(Duration(milliseconds: value.toInt()));
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
              // Info Lagu
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
              // Kontrol Play/Pause
              StreamBuilder<PlayerState>(
                stream: audioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing ?? false;
                  
                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
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
          StreamBuilder<PositionData>(
            stream: getPositionDataStream(audioPlayer), // Stream dari common.dart
            builder: (context, snapshot) {
              final positionData = snapshot.data;
              final position = positionData?.position ?? Duration.zero;
              final duration = positionData?.duration ?? Duration.zero;
              
              double sliderValue = position.inMilliseconds.toDouble();
              // Batasi agar slider value tidak melebihi durasi
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
                    // Kita menggunakan onChanged hanya untuk visual, seek dilakukan di onChangeEnd
                    onChanged: (value) { /* Do nothing here */ }, 
                    onChangeEnd: _onSeek, // Fungsi seek dipanggil saat user selesai menggeser
                  ),
                  
                  // Teks Waktu Lagu
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatDuration(position), style: TextStyle(fontSize: 12)), // Posisi saat ini
                        Text(formatDuration(duration), style: TextStyle(fontSize: 12)), // Durasi total
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
