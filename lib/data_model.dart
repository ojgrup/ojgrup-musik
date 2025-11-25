// lib/data_model.dart

class AssetSong {
  final String title;
  final String artist;
  final String assetPath; 
  final String id; 

  AssetSong({required this.title, required this.artist, required this.assetPath})
      : id = assetPath;
}

// DAFTAR LAGU GLOBAL (PUBLIC)
final List<AssetSong> assetSongs = [
  AssetSong(title: "Lagu Sasak Pertama", artist: "Artis Lombok A", assetPath: "assets/audio/lagu_sasak_1.mp3"),
  AssetSong(title: "Lagu Sasak Kedua", artist: "Artis Lombok B", assetPath: "assets/audio/lagu_sasak_2.mp3"),
  AssetSong(title: "Lagu Sasak Ketiga", artist: "Artis Lombok C", assetPath: "assets/audio/lagu_sasak_3.mp3"),
];
