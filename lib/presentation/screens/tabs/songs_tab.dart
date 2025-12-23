import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/song.dart';
import '../../providers/music_providers.dart';
import '../../providers/selection_providers.dart';
import '../../widgets/song_tile.dart';
import '../../widgets/streak_icons.dart';
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

        // Calculate Top 10 Songs of the Month
        final topSongsParams = List<Song>.from(songs)
          ..sort((a, b) => b.monthlyPlays.compareTo(a.monthlyPlays));

        // Get IDs of top 10 (exclude those with 0 plays)
        final top10Ids = topSongsParams
            .take(10)
            .where((s) => s.monthlyPlays > 0)
            .map((s) => s.id)
            .toSet();

        final top1Id =
            topSongsParams.isNotEmpty && topSongsParams.first.monthlyPlays > 0
                ? topSongsParams.first.id
                : -1;

        return ListView.builder(
          itemExtent: 72.0, // Fixed height for performance
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            Widget? streakWidget;

            if (top10Ids.contains(song.id)) {
              if (song.id == top1Id) {
                streakWidget = BurningFireIcon(count: song.monthlyPlays);
              } else {
                streakWidget = StreakIcon(count: song.monthlyPlays);
              }
            }

            final isSelectionMode = ref.watch(isSelectionModeProvider);
            final selectedIds = ref.watch(selectedSongIdsProvider);
            final isSelected = selectedIds.contains(song.id);

            return SongTile(
              key: ValueKey(song.id),
              song: song,
              streakWidget: streakWidget,
              isSelected: isSelected,
              onLongPress: () {
                ref.read(isSelectionModeProvider.notifier).state = true;
                ref
                    .read(selectionManagerProvider.notifier)
                    .toggleSelection(song.id);
              },
              onTap: () {
                if (isSelectionMode) {
                  ref
                      .read(selectionManagerProvider.notifier)
                      .toggleSelection(song.id);
                } else {
                  _playSong(ref, songs, index);
                }
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
