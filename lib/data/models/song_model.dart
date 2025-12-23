import 'package:isar/isar.dart';

part 'song_model.g.dart';

@collection
class SongModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String path;

  @Index(caseSensitive: false)
  late String title;

  @Index(caseSensitive: false)
  late String artist;

  @Index(caseSensitive: false)
  late String album;

  @Index()
  late String genre;

  late int durationMs;

  int? trackNumber;

  late int mediaId;

  String? artworkPath;

  late DateTime dateAdded;

  // For playback history / stats
  int playCount = 0;
  int monthlyPlayCount = 0;
  int playtimeMs = 0; // Total time played
  DateTime? lastPlayed;
}
