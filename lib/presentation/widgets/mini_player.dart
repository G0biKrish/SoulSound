import 'artwork_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_providers.dart';
import '../screens/player_screen.dart';
import '../../main.dart'; // for audioHandlerProvider usage if needed directly

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final playbackStateAsync = ref.watch(playbackStateProvider);

    return mediaItemAsync.when(
      data: (item) {
        if (item == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const PlayerScreen()),
            );
          },
          child: Container(
            height: 64,
            width: double.infinity,
            color: Colors.transparent,
            child: Row(
              children: [
                // Art
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 48,
                    height: 48,
                    child: ArtworkWidget(
                      mediaId: item.extras?['mediaId'] ?? -1,
                      artworkPath: item.artUri?.toFilePath(),
                      width: 48,
                      height: 48,
                      borderRadius: 24, // Circular
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        item.artist ?? 'Unknown',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Controls
                playbackStateAsync.when(
                  data: (state) {
                    final playing = state.playing;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                          color: Theme.of(context).colorScheme.onSurface,
                          onPressed: () {
                            final handler = ref.read(audioHandlerProvider);
                            if (playing) {
                              handler.pause();
                            } else {
                              handler.play();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          color: Theme.of(context).colorScheme.onSurface,
                          onPressed: () {
                            ref.read(audioHandlerProvider).skipToNext();
                          },
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

extension UriFilePath on Uri {
  String toFilePath() => path; // Simplified
}
