import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/song.dart';
import '../../providers/music_providers.dart';
import '../../widgets/song_tile.dart';
import '../../../main.dart';
import '../../../core/audio/audio_handler.dart';

class SongsTab extends ConsumerWidget {
  const SongsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(sortedSongsProvider);

    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(
            child: Text('No songs found. Try scanning in Settings.'),
          );
        }
        return ListView.builder(
          itemExtent: 72.0, // Fixed height for performance
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return SongTile(
              song: song,
              onTap: () {
                _playSong(ref, songs, index);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  void _playSong(WidgetRef ref, List<Song> songs, int index) {
    final handler = ref.read(audioHandlerProvider) as AudioPlayerHandler;
    final items = songs
        .map(
          (s) => MediaItem(
            id: s.path, // Use path as ID for simplicity
            album: s.album,
            title: s.title,
            artist: s.artist,
            duration: s.duration,
            artUri: s.artworkPath != null ? Uri.file(s.artworkPath!) : null,
            extras: {'dbId': s.id, 'mediaId': s.mediaId},
          ),
        )
        .toList();

    handler.playSongList(items, index);
  }
}
