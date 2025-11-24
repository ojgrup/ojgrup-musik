import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

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
    assetPath: "assets/audio/Zias Band - Ku Harus Pergi.mp3", 
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
        SnackBar(content: Text('Gagal memutar lagu: $e. Pastikan file ada di assets/audio/ dan dideklarasikan di pubspec.yaml.')),
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
      ),
      body: ListView.builder(
              itemCount: widget.songs.length,
              itemBuilder: (context, index) {
                final song = widget.songs[index];
                final isPlaying = index == _currentPlayingIndex;
                
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.artist),
                  trailing: isPlaying
                      ? const Icon(Icons.volume_up, color: Colors.blue)
                      : null,
                  onTap: () {
                    if (isPlaying && _audioPlayer.playing) {
                      _togglePlayPause(); 
                    } else if (isPlaying && !_audioPlayer.playing) {
                      _togglePlayPause(); 
                    } else {
                      _playAssetSong(index); // Putar lagu baru dari assets
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


// --- WIDGET MINI PLAYER ---

class MiniPlayerWidget extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final AssetSong currentSong; // Menggunakan AssetSong
  final VoidCallback onTogglePlayPause;

  const MiniPlayerWidget({
    super.key,
    required this.audioPlayer,
    required this.currentSong,
    required this.onTogglePlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8.0)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
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
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // StreamBuilder untuk mengupdate ikon Play/Pause secara real-time
          StreamBuilder<PlayerState>(
            stream: audioPlayer.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing ?? false;

              if (processingState == ProcessingState.loading ||
                  processingState == ProcessingState.buffering) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              } else if (playing) {
                return IconButton(
                  icon: const Icon(Icons.pause, size: 36),
                  onPressed: onTogglePlayPause,
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.play_arrow, size: 36),
                  onPressed: onTogglePlayPause,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
