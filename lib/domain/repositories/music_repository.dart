import '../entities/song.dart';
import '../entities/album.dart';
import '../entities/artist.dart';
import '../entities/playlist.dart';

abstract class MusicRepository {
  // Scanning
  Future<void> scanDeviceForMusic(
      {bool forceRescan = false, List<String> excludedFolders = const []});

  // Queries
  Future<List<Song>> getAllSongs();
  Stream<List<Song>> watchAllSongs(); // New: Watch for changes
  Future<List<Album>> getAlbums();
  Future<List<Artist>> getArtists();
  Future<List<Song>> getSongsByAlbum(String albumName);
  Future<List<Song>> getSongsByArtist(String artistName);
  Future<List<Song>> getSongsByGenre(String genre);

  // Search
  Future<List<Song>> searchSongs(String query);

  // Playlists
  Future<List<Playlist>> getPlaylists();
  Future<void> createPlaylist(String name,
      {int? iconCode, String? artworkPath});
  Future<void> deletePlaylist(int playlistId);
  Future<void> addSongsToPlaylist(int playlistId, List<int> songIds);
  Future<void> removeSongFromPlaylist(int playlistId, int songId);
  Future<void> renamePlaylist(int playlistId, String newName);

  // Stats / Memories
  Future<void> logSongPlay(Song song);
  Future<Map<String, dynamic>> getMonthlyStats();

  // Management
  Future<void> deleteSongs(List<int> songIds);
}
