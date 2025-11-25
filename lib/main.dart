// lib/main.dart

import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart'; 
import 'package:just_audio/just_audio.dart';

// Import yang dibutuhkan
import 'data_model.dart'; 
import 'common.dart'; 
import 'audio_player_handler.dart'; 
import 'category_screen.dart'; 

// --- SETUP SERVICE AUDIO GLOBAL ---
late AudioHandler _audioHandler;
bool _isAudioServiceInitialized = false; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
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
    _isAudioServiceInitialized = true; 
    print("✅ AudioService berhasil diinisialisasi.");
  } catch (e, stacktrace) {
    print("❌ KESALAHAN FATAL AUDIO SERVICE: $e");
    print("Stacktrace: $stacktrace");
    _isAudioServiceInitialized = false;
  }
  
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
        sliderTheme: const SliderThemeData(
          trackHeight: 2.0,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
        )
      ),
      // Langsung menuju CategoryScreen jika berhasil
      home: _isAudioServiceInitialized 
          ? const CategoryScreen() 
          : const ErrorOrLoadingScreen(),
    );
  }
}

class ErrorOrLoadingScreen extends StatelessWidget {
  const ErrorOrLoadingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Memuat data, jika lama/crash, ada error di AudioService."),
          ],
        ),
      ),
    );
  }
}

// --- MUSIC PLAYER SCREEN ---

class MusicPlayerScreen extends StatefulWidget {
  final List<AssetSong> songs;
  const MusicPlayerScreen({super.key, required this.songs});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  
  int? _currentPlayingIndex;

  @override
  void initState() {
    super.initState();
    _listenToAudioServiceChanges();
  }
  
  void _listenToAudioServiceChanges() {
    _audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem == null || _audioHandler.queue.value.isEmpty) return;
      
      final index = assetSongs.indexWhere((item) => item.id == mediaItem.id);
      
      if (mounted) {
        setState(() {
          _currentPlayingIndex = index >= 0 ? index : null;
        });
      }
    });
  }

  Future<void> _playSong(int index) async {
    if (_audioHandler.queue.value.isEmpty) {
        return; 
    }
    
    await _audioHandler.customAction('skipToQueueIndex', {'index': index}); 
    
    _audioHandler.play();
  }
  
  void _togglePlayPause() {
    final playing = _audioHandler.playbackState.value.playing;
    if (playing) {
      _audioHandler.pause();
    } else {
      _audioHandler.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: _audioHandler.mediaItem,
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(title: const Text("🎵 Daftar Lagu"), backgroundColor: Colors.blueGrey[900]),
          body: ListView.builder(
            itemCount: widget.songs.length,
            itemBuilder: (context, index) {
              final song = widget.songs[index];
              final isPlaying = index == _currentPlayingIndex;
              
              return ListTile(
                leading: const Icon(Icons.music_note, color: Colors.blueAccent),
                title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(song.artist, style: TextStyle(color: Colors.white70)),
                trailing: isPlaying ? const Icon(Icons.volume_up, color: Colors.blue) : null,
                onTap: () {
                  if (isPlaying) {
                    _togglePlayPause();
                  } else {
                    _playSong(index); 
                  }
                },
              );
            },
          ),
          bottomNavigationBar: _currentPlayingIndex != null
              ? MiniPlayerWidget(
                  audioHandler: _audioHandler, 
                  currentSong: widget.songs[_currentPlayingIndex!],
                  onTogglePlayPause: _togglePlayPause,
                )
              : null,
        );
      }
    );
  }
}

// --- WIDGET MINI PLAYER ---
class MiniPlayerWidget extends StatelessWidget {
  final AudioHandler audioHandler;
  final AssetSong currentSong; 
  final VoidCallback onTogglePlayPause;

  const MiniPlayerWidget({super.key, required this.audioHandler, required this.currentSong, required this.onTogglePlayPause});

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
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentSong.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(currentSong.artist, style: const TextStyle(fontSize: 12, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
              StreamBuilder<PlaybackState>(
                stream: audioHandler.playbackState,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  final processingState = snapshot.data?.processingState ?? AudioProcessingState.idle;

                  if (processingState == AudioProcessingState.loading ||
                      processingState == AudioProcessingState.buffering) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent)),
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
          
          StreamBuilder<PositionData>(
            stream: getPositionDataStream(audioHandler),
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
