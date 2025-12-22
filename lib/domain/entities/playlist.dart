import 'song.dart';

class Playlist {
  final int id;
  final String name;
  final List<Song> songs;
  final DateTime dateCreated;
  final int? iconCode;
  final String? artworkPath;

  const Playlist({
    required this.id,
    required this.name,
    required this.songs,
    required this.dateCreated,
    this.iconCode,
    this.artworkPath,
  });
}
