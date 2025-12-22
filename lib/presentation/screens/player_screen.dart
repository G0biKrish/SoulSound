import 'package:audio_service/audio_service.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// useful for streams
import '../widgets/waveform_seek_bar.dart';
import '../providers/audio_providers.dart';
import '../providers/music_providers.dart'; // Added for playlists
import '../../main.dart'; // for audioHandlerProvider
import '../widgets/rotating_album_art.dart';
import '../widgets/soul_land.dart';
import '../widgets/marquee_text.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _isVolumeOverlayVisible = false;

  void _openVolumeOverlay(BuildContext context) {
    setState(() {
      _isVolumeOverlayVisible = true;
    });
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // Only overlay the slider
      builder: (context) {
        return SoulLand(
          autoCloseDuration: const Duration(seconds: 10),
          icon: const Icon(Icons.volume_up, color: Colors.green, size: 24),
          onClosed: () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          },
          child: const _VolumeSlider(),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isVolumeOverlayVisible = false;
        });
      }
    });
  }

  Future<void> _toggleFavorite(WidgetRef ref, int? songId) async {
    if (songId == null) return;
    final repo = ref.read(musicRepositoryProvider);
    final playlists = await ref.read(playlistsProvider.future);

    var favList = playlists.where((p) => p.name == 'Favorites');
    var fav = favList.isNotEmpty ? favList.first : null;

    if (fav == null) {
      await repo.createPlaylist('Favorites');
      ref.invalidate(playlistsProvider);
      // Wait a tick for rebuild or verify existence?
      // Simplified: Just invalidate. Next tap will find it.
      // Or manually fetch for immediate "Add".
      final updated = await repo.getPlaylists();
      fav = updated.firstWhere((p) => p.name == 'Favorites');
    }

    final isLiked = fav.songs.any((s) => s.id == songId);

    if (isLiked) {
      await repo.removeSongFromPlaylist(fav.id, songId);
    } else {
      await repo.addSongsToPlaylist(fav.id, [songId]);
    }

    ref.invalidate(playlistsProvider);
  }

  AudioServiceRepeatMode _nextRepeatMode(AudioServiceRepeatMode mode) {
    switch (mode) {
      case AudioServiceRepeatMode.none:
        return AudioServiceRepeatMode.all;
      case AudioServiceRepeatMode.all:
        return AudioServiceRepeatMode.one;
      case AudioServiceRepeatMode.one:
        return AudioServiceRepeatMode.none;
      default:
        return AudioServiceRepeatMode.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final playbackStateAsync = ref.watch(playbackStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isVolumeOverlayVisible ? 0.0 : 1.0,
            child: IgnorePointer(
              ignoring: _isVolumeOverlayVisible,
              child: IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () {
                  _openVolumeOverlay(context);
                },
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Album Art
            mediaItemAsync.when(
              data: (item) {
                if (item == null) return const SizedBox(height: 300);

                final isPlaying = playbackStateAsync.value?.playing ?? false;

                return Consumer(
                  builder: (context, ref, child) {
                    final positionState = ref.watch(currentPositionProvider);
                    return RotatingAlbumArt(
                      mediaId: item.extras?['mediaId'] ?? -1,
                      artworkPath: item.artUri?.toFilePath(),
                      size: 320,
                      isPlaying: isPlaying,
                      currentPosition: positionState.value ?? Duration.zero,
                    );
                  },
                );
              },
              loading: () => const SizedBox(height: 300),
              error: (_, __) => const SizedBox(height: 300),
            ),
            const SizedBox(height: 40),

            // Title & Artist
            // Title & Artist with Like Button
            mediaItemAsync.when(
              data: (item) {
                final playlists =
                    ref.watch(playlistsProvider).valueOrNull ?? [];
                final favList = playlists.where((p) => p.name == 'Favorites');
                final favPlaylist = favList.isNotEmpty ? favList.first : null;
                final currentId = item?.extras?['dbId'] as int?;
                final isLiked = favPlaylist != null &&
                    currentId != null &&
                    favPlaylist.songs.any((s) => s.id == currentId);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line 1: Main Title (Full Width)
                      MarqueeText(
                        item?.title ?? 'Not Playing',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        velocity: 20,
                        pauseDuration: 2.0,
                      ),
                      const SizedBox(height: 8),

                      // Line 2: Artist + Actions
                      Row(
                        children: [
                          // Artist Name
                          Expanded(
                            child: MarqueeText(
                              item?.artist ?? '',
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              velocity: 20,
                            ),
                          ),

                          // Actions
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.translate(
                                offset: const Offset(
                                    16, 0), // Shift right towards the dots
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isLiked
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                  ),
                                  onPressed: () =>
                                      _toggleFavorite(ref, currentId),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(8, 0), // Push towards edge
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    Icons.more_vert,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'More options coming soon!')),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 30),

            // Seek Bar
            Consumer(
              builder: (context, ref, child) {
                final positionAsync = ref.watch(currentPositionProvider);
                final mediaItem = ref.watch(currentMediaItemProvider).value;
                final total = mediaItem?.duration ?? Duration.zero;

                return positionAsync.when(
                  data: (position) => WaveformSeekBar(
                    duration: total,
                    position: position,
                    onChangeEnd: (newPosition) {
                      ref.read(audioHandlerProvider).seek(newPosition);
                    },
                  ),
                  loading: () => const SizedBox(height: 80),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),

            const SizedBox(height: 20),

            // Controls
            playbackStateAsync.when(
              data: (state) {
                final playing = state.playing;
                final shuffleMode = state.shuffleMode;
                final repeatMode = state.repeatMode;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shuffle),
                      color: shuffleMode == AudioServiceShuffleMode.all
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      onPressed: () {
                        final newMode =
                            shuffleMode == AudioServiceShuffleMode.none
                                ? AudioServiceShuffleMode.all
                                : AudioServiceShuffleMode.none;
                        ref.read(audioHandlerProvider).setShuffleMode(newMode);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 36),
                      color: Theme.of(context).colorScheme.onSurface,
                      onPressed: () =>
                          ref.read(audioHandlerProvider).skipToPrevious(),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          playing ? Icons.pause : Icons.play_arrow,
                          size: 32,
                        ),
                        color: Theme.of(context).colorScheme.onPrimary,
                        onPressed: () {
                          final handler = ref.read(audioHandlerProvider);
                          playing ? handler.pause() : handler.play();
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 36),
                      color: Theme.of(context).colorScheme.onSurface,
                      onPressed: () =>
                          ref.read(audioHandlerProvider).skipToNext(),
                    ),
                    IconButton(
                      icon: Icon(
                        repeatMode == AudioServiceRepeatMode.one
                            ? Icons.repeat_one
                            : Icons.repeat,
                      ),
                      color: repeatMode == AudioServiceRepeatMode.none
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.primary,
                      onPressed: () {
                        final newMode = _nextRepeatMode(repeatMode);
                        ref.read(audioHandlerProvider).setRepeatMode(newMode);
                      },
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeSlider extends ConsumerStatefulWidget {
  const _VolumeSlider();

  @override
  ConsumerState<_VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends ConsumerState<_VolumeSlider> {
  double _currentVal = 1.0;
  bool _isDragging = false; // Add dragging state to prevent loop jitter

  @override
  void initState() {
    super.initState();
    _initVolume();
  }

  Future<void> _initVolume() async {
    // Hide default system UI to use our custom overlay
    await FlutterVolumeController.updateShowSystemUI(false);

    // Get current system volume
    try {
      final currentVol = await FlutterVolumeController.getVolume();
      if (mounted && currentVol != null) {
        setState(() {
          _currentVal = currentVol;
        });
      }
    } catch (_) {}

    // Listen to system volume changes
    FlutterVolumeController.addListener((volume) {
      if (mounted && !_isDragging) {
        // Only update if NOT dragging
        setState(() {
          _currentVal = volume;
        });
      }
    });
  }

  @override
  void dispose() {
    FlutterVolumeController.removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_currentVal * 100).toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Volume Percentage and Icon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _currentVal == 0 ? Icons.volume_off : Icons.volume_up,
              color: Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '$percentage%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Custom Thick Slider
        SizedBox(
          height: 30, // Compact touch area
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 12, // Thick track
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.transparent, // Hide default thumb
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
              trackShape: _CustomTrackShape(), // Rounded ends
            ),
            child: Slider(
              value: _currentVal,
              onChangeStart: (_) {
                _isDragging = true;
              },
              onChangeEnd: (_) {
                _isDragging = false;
              },
              onChanged: (value) {
                setState(() {
                  _currentVal = value;
                });
                FlutterVolumeController.setVolume(value);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset, // Make nullable to match super
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    super.paint(context, offset,
        parentBox: parentBox,
        sliderTheme: sliderTheme,
        enableAnimation: enableAnimation,
        textDirection: textDirection,
        thumbCenter: thumbCenter,
        secondaryOffset: secondaryOffset,
        isDiscrete: isDiscrete,
        isEnabled: isEnabled,
        additionalActiveTrackHeight: 0 // Keep consistent track height
        );
  }
}
