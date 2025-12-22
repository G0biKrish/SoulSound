import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/song.dart';
import '../providers/music_providers.dart';
import '../../main.dart'; // For musicRepositoryProvider
import '../widgets/song_tile.dart';
import '../../core/audio/audio_handler.dart';
import 'package:audio_service/audio_service.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-fetch playlist to get updates
    final playlistsAsync = ref.watch(playlistsProvider);
    final currentPlaylist = playlistsAsync.value?.firstWhere(
          (p) => p.id == playlist.id,
          orElse: () => playlist,
        ) ??
        playlist;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPlaylist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddSongsDialog(context, ref, currentPlaylist);
            },
          ),
        ],
      ),
      body: currentPlaylist.songs.isEmpty
          ? const Center(child: Text('No songs in this playlist.'))
          : ListView.builder(
              itemCount: currentPlaylist.songs.length,
              itemBuilder: (context, index) {
                final song = currentPlaylist.songs[index];
                return SongTile(
                  song: song,
                  onTap: () {
                    _playSong(ref, currentPlaylist.songs, index);
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () async {
                      await ref
                          .read(musicRepositoryProvider)
                          .removeSongFromPlaylist(currentPlaylist.id, song.id);
                      ref.invalidate(playlistsProvider);
                    },
                  ),
                );
              },
            ),
    );
  }

  void _playSong(WidgetRef ref, List<Song> songs, int index) {
    final handler =
        ref.read(audioHandlerProvider); // Ensure this cast works or use method
    // We need to cast to AudioPlayerHandler if we added playSongList there,
    // OR we should expose it via interface.
    // Ideally AudioHandler is the interface. customAction or standard queue manipulation.
    // For now, let's assume direct cast or standard queue methods.

    // Convert to MediaItems
    final items = songs
        .map((s) => MediaItem(
              id: s.path,
              album: s.album,
              title: s.title,
              artist: s.artist,
              duration: s.duration,
              artUri: s.artworkPath != null ? Uri.file(s.artworkPath!) : null,
              extras: {'dbId': s.id, 'mediaId': s.mediaId},
            ))
        .toList();

    // Reset queue and play
    // Assuming AudioPlayerHandler has playSongList as implemented earlier
    (handler as AudioPlayerHandler).playSongList(items, index);
  }

  void _showAddSongsDialog(
      BuildContext context, WidgetRef ref, Playlist playlist) async {
    final allSongs = await ref.read(allSongsProvider.future);
    // Filter out songs already in playlist
    final existingIds = playlist.songs.map((s) => s.id).toSet();
    final availableSongs =
        allSongs.where((s) => !existingIds.contains(s.id)).toList();

    if (!context.mounted) return;

    if (availableSongs.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No more songs to add.')));
      return;
    }

    final selectedIds = <int>{};

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Add Songs'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  itemCount: availableSongs.length,
                  itemBuilder: (context, index) {
                    final song = availableSongs[index];
                    final isSelected = selectedIds.contains(song.id);
                    return CheckboxListTile(
                      title: Text(song.title, maxLines: 1),
                      subtitle: Text(song.artist, maxLines: 1),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedIds.add(song.id);
                          } else {
                            selectedIds.remove(song.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedIds.isNotEmpty) {
                      await ref
                          .read(musicRepositoryProvider)
                          .addSongsToPlaylist(
                              playlist.id, selectedIds.toList());
                      ref.invalidate(playlistsProvider);
                    }
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
