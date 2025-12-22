import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart';

class MetadataScanner {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<List<SongModel>> scanDevice({List<String> excludedFolders = const []}) async {
    // Request permissions
    bool permissionStatus = await _audioQuery.permissionsStatus();
    if (!permissionStatus) {
      await _audioQuery.permissionsRequest();
    }

    // Query all songs from device
    final allSongs = await _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    // Filter out songs from excluded folders
    if (excludedFolders.isEmpty) {
      return allSongs;
    }

    return allSongs.where((song) {
      final songPath = song.data;
      // Check if song path starts with any excluded folder
      return !excludedFolders.any((folder) => songPath.startsWith(folder));
    }).toList();
  }

  Future<File?> getArtwork(int songId) async {
    // Note: on_audio_query provides artwork as Uint8List
    // We'd need to handle it differently in the repository
    return null;
  }
}
