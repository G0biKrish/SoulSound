class Song {
  final int id; // Isar ID or negative for transient
  final int mediaId; // Original MediaStore ID
  final String path;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final Duration duration;
  final int? trackNumber;
  final String? artworkPath; // Path to cached artwork file
  final DateTime dateAdded;
  final int playCount;
  final int monthlyPlays;

  const Song({
    required this.id,
    required this.mediaId,
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    this.genre = 'Unknown',
    required this.duration,
    this.trackNumber,
    this.artworkPath,
    required this.dateAdded,
    this.playCount = 0,
    this.monthlyPlays = 0,
  });

  // Empty factory for defaults
  factory Song.empty() {
    return Song(
      id: -1,
      mediaId: -1,
      path: '',
      title: 'Unknown Title',
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      duration: Duration.zero,
      dateAdded: DateTime.now(),
    );
  }
}
