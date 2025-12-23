import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/album.dart';
import '../../domain/entities/artist.dart';
import '../../domain/entities/playlist.dart';
import '../../main.dart';
import '../screens/excluded_folders_screen.dart';

enum SortOption { title, recentlyAdded, mostPlayed, artist, duration }

// State provider for sort order
final sortOrderProvider = StateProvider<SortOption>(
  (ref) => SortOption.recentlyAdded,
);

// Raw songs source
final allSongsProvider = StreamProvider<List<Song>>((ref) {
  final repo = ref.watch(musicRepositoryProvider);
  return repo.watchAllSongs();
});

// Sorted/Filtered songs
final sortedSongsProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final allSongsAsync = ref.watch(allSongsProvider);
  final sortOption = ref.watch(sortOrderProvider);

  return allSongsAsync.whenData((allSongs) {
    // create a copy to sort
    final sorted = List<Song>.from(allSongs);

    switch (sortOption) {
      case SortOption.title:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case SortOption.recentlyAdded:
        sorted.sort(
          (a, b) => b.dateAdded.compareTo(a.dateAdded),
        ); // Newest first
        break;
      case SortOption.mostPlayed:
        sorted.sort(
          (a, b) => b.playCount.compareTo(a.playCount),
        ); // Highest first
        break;
      case SortOption.artist:
        sorted.sort(
          (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
        );
        break;
      case SortOption.duration:
        sorted.sort(
          (a, b) => b.duration.compareTo(a.duration),
        ); // Longest first
        break;
    }
    return sorted;
  });
});

final albumsProvider = FutureProvider<List<Album>>((ref) async {
  final repo = ref.watch(musicRepositoryProvider);
  return repo.getAlbums();
});

final artistsProvider = FutureProvider<List<Artist>>((ref) async {
  final repo = ref.watch(musicRepositoryProvider);
  return repo.getArtists();
});

final playlistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final repo = ref.watch(musicRepositoryProvider);
  return repo.getPlaylists();
});

final memoriesStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(musicRepositoryProvider);
  return repo.getMonthlyStats();
});

// Scanning State
class ScanNotifier extends StateNotifier<bool> {
  final Ref ref;
  ScanNotifier(this.ref) : super(false);

  Future<bool> scan() async {
    // Request permissions based on Android version implicitly by trying relevant ones
    bool granted = false;

    if (await Permission.audio.request().isGranted) {
      granted = true;
    } else if (await Permission.storage.request().isGranted) {
      granted = true;
    } else if (await Permission.manageExternalStorage.request().isGranted) {
      granted = true;
    }

    if (!granted) {
      return false; // Permission denied
    }

    state = true;
    try {
      // Load excluded folders
      final excludedFolders = ref.read(excludedFoldersProvider);
      await ref
          .read(musicRepositoryProvider)
          .scanDeviceForMusic(excludedFolders: excludedFolders);
      // Invalidate providers to refresh UI
      ref.invalidate(allSongsProvider);
      ref.invalidate(albumsProvider);
      ref.invalidate(artistsProvider);
      return true;
    } finally {
      state = false;
    }
  }
}

final scanProvider = StateNotifierProvider<ScanNotifier, bool>((ref) {
  return ScanNotifier(ref);
});
