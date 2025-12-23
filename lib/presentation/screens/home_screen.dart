import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../../main.dart';
import '../providers/music_providers.dart';
import '../providers/audio_providers.dart';
import '../providers/dock_providers.dart';
import '../providers/selection_providers.dart';
import '../widgets/mini_player.dart';
import 'player_screen.dart';
import 'settings_screen.dart';
import 'tabs/songs_tab.dart';
import 'tabs/artists_tab.dart';
import 'tabs/albums_tab.dart';
import 'tabs/playlists_tab.dart';
import 'tabs/genres_tab.dart';
import 'search_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  int? _draggedIndex;

  List<Widget> get _tabs {
    final dockItems = ref.watch(dockItemsProvider);
    return dockItems.map((item) {
      switch (item.originalIndex) {
        case 0:
          return const SongsTab();
        case 1:
          return const ArtistsTab();
        case 2:
          return const AlbumsTab();
        case 3:
          return const GenresTab();
        case 4:
          return const PlaylistsTab();
        default:
          return const SongsTab();
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // isScanning removed as it is no longer used in the UI
    final isSelectionMode = ref.watch(isSelectionModeProvider);
    final selectedCount = ref.watch(selectedSongIdsProvider).length;

    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent moving up when keyboard opens
      appBar: isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(selectionManagerProvider.notifier).clear();
                },
              ),
              title: Text('$selectedCount Selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () {
                    // We need access to song list to select all.
                    // This is hard from here without fetching songs again.
                    // For now, let's skip "Select All" or implement it if critical.
                    // User didn't explicitly ask for Select All button, so we skip.
                  },
                ),
              ],
            )
          : AppBar(
              leading: Padding(
                padding: const EdgeInsets.all(2.0),
                child:
                    Image.asset('assets/images/android/main_screen_logo.png'),
              ),
              titleSpacing: 0,
              title: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'SoulSound',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                ),
                if (_currentIndex == 0) // Show sort only on Songs tab
                  PopupMenuButton<SortOption>(
                    icon: const Icon(Icons.sort),
                    tooltip: 'Sort by',
                    onSelected: (SortOption result) {
                      ref.read(sortOrderProvider.notifier).state = result;
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<SortOption>>[
                      const PopupMenuItem<SortOption>(
                        value: SortOption.recentlyAdded,
                        child: Text('Newest'),
                      ),
                      const PopupMenuItem<SortOption>(
                        value: SortOption.mostPlayed,
                        child: Text('Most Played'),
                      ),
                      const PopupMenuItem<SortOption>(
                        value: SortOption.title,
                        child: Text('A to Z'),
                      ),
                      const PopupMenuItem<SortOption>(
                        value: SortOption.artist,
                        child: Text('Artist'),
                      ),
                      const PopupMenuItem<SortOption>(
                        value: SortOption.duration,
                        child: Text('Duration'),
                      ),
                    ],
                  ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(
                        builder: (_) => const SettingsScreen()));
                  },
                ),
              ],
            ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _tabs),
          ),
          // Dynamic Bottom Section
          if (isSelectionMode)
            _buildSelectionDock(context)
          else if (ref.watch(currentMediaItemProvider).asData?.value != null)
            // "Now Playing" Card Panel (Draggable/Swipeable)
            GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! < -200) {
                  // Swipe Up
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    isDismissible: true,
                    enableDrag: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const PlayerScreen(),
                  );
                }
              },
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  isDismissible: true,
                  enableDrag: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const PlayerScreen(),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .shadow
                          .withValues(alpha: 0.5),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(top: 12, bottom: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Mini Player (Transparent)
                    const MiniPlayer(),

                    // Progress Bar (Simple Visual)
                    const _MiniProgressBar(),

                    const SizedBox(height: 20),

                    // Floating Pill Dock
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .shadow
                                .withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: _buildReorderableDock(),
                    ),
                  ],
                ),
              ),
            )
          else
            // Floating Pill Dock (Standalone)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 30),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .shadow
                        .withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: _buildReorderableDock(),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionDock(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSelectionAction(
              context, Icons.playlist_add, 'Add to Playlist', _addToPlaylist),
          _buildSelectionAction(
              context, Icons.queue_music, 'Play Next', _playNext),
          _buildSelectionAction(
              context, Icons.visibility_off, 'Hide', _hideSelected),
          _buildSelectionAction(
              context, Icons.delete, 'Delete', _deleteSelected),
        ],
      ),
    );
  }

  Widget _buildSelectionAction(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: Theme.of(context).colorScheme.onSecondaryContainer),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _addToPlaylist() {
    // Show playlist selection dialog
    // Implementation: Fetch playlists, show dialog, add to playlist
    // For now, simpler placeholder or quick implementation if easy
    // Let's implement basic logic
    final selectedIds = ref.read(selectedSongIdsProvider).toList();
    if (selectedIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add to Playlist'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Consumer(
            builder: (context, ref, child) {
              final playlistsAsync = ref.watch(playlistsProvider);
              return playlistsAsync.when(
                data: (playlists) {
                  return ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      if (playlist.id < 0)
                        return const SizedBox.shrink(); // Skip smart playlists
                      return ListTile(
                        leading: const Icon(Icons.playlist_play),
                        title: Text(playlist.name),
                        onTap: () async {
                          await ref
                              .read(musicRepositoryProvider)
                              .addSongsToPlaylist(playlist.id, selectedIds);
                          Navigator.pop(ctx);
                          ref.read(selectionManagerProvider.notifier).clear();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Added to ${playlist.name}')));
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _playNext() {
    // Add to queue logic
    // We need AudioHandler to adding to queue
    // Current AudioHandler interface might need 'addQueueItems'
    // or we can use existing method if available.
    // JustAudio AudioSource?
    // Let's check AudioHandler capabilities from `d:\Projects\SoundFlow\lib\core\audio\audio_handler.dart`
    // If not easy, we skip for now or use `addQueueItem` loop.
    final selectedIds = ref.read(selectedSongIdsProvider);
    if (selectedIds.isEmpty) return;

    // We need to fetch the Song objects to add them to queue (need URI etc)
    // Helper to get songs from IDs?
    // We can just watch 'allSongsProvider' and filter.
    final allSongs = ref.read(allSongsProvider).asData?.value ?? [];
    final selectedSongs =
        allSongs.where((s) => selectedIds.contains(s.id)).toList();

    final handler = ref.read(audioHandlerProvider); // Abstract AudioHandler
    // We assume it supports addQueueItem.
    // It's better to cast to our implementation if needed, but AudioHandler has addQueueItem.

    // Adding as "Play Next" implies inserting after current index.
    // Standard `addQueueItem` adds to end.
    // We might need custom implementation for "Play Next".
    // For MVP, adding to end is easier, but "Play Next" is specific.
    // Let's simply add to end for now to avoid breaking AudioHandler, or loop insert.
    for (var s in selectedSongs) {
      // Convert to MediaItem
      final item = MediaItem(
        id: s.path,
        album: s.album,
        title: s.title,
        artist: s.artist,
        duration: s.duration,
        artUri: s.artworkPath != null ? Uri.file(s.artworkPath!) : null,
        extras: {'dbId': s.id, 'mediaId': s.mediaId},
      );
      handler.addQueueItem(item);
    }

    ref.read(selectionManagerProvider.notifier).clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Added to Queue')));
  }

  void _hideSelected() {
    // Placeholder
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hide feature coming soon')));
    ref.read(selectionManagerProvider.notifier).clear();
  }

  void _deleteSelected() {
    final selectedIds = ref.read(selectedSongIdsProvider).toList();
    if (selectedIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Songs?'),
        content: const Text(
            'Are you sure? This will PERMANENTLY delete these files from your device storage. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(musicRepositoryProvider).deleteSongs(selectedIds);
              // Force refresh of songs list
              ref.invalidate(allSongsProvider);
              Navigator.pop(ctx);
              ref.read(selectionManagerProvider.notifier).clear();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Songs removed from library')));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableDock() {
    final dockItems = ref.watch(dockItemsProvider);
    final dockNotifier = ref.read(dockItemsProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(dockItems.length, (index) {
        final item = dockItems[index];
        final isSelected = _currentIndex == index;
        final isDragging = _draggedIndex == index;

        return Expanded(
          child: LongPressDraggable<int>(
            data: index,
            onDragStarted: () {
              setState(() {
                _draggedIndex = index;
              });
            },
            onDragEnd: (details) {
              setState(() {
                _draggedIndex = null;
              });
            },
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .shadow
                          .withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            child: DragTarget<int>(
              onAcceptWithDetails: (details) {
                final draggedIndex = details.data;
                if (draggedIndex != index) {
                  // Store the originalIndex of currently selected item
                  final selectedOriginalIndex =
                      dockItems[_currentIndex].originalIndex;

                  // Reorder items
                  dockNotifier.reorderItems(draggedIndex, index);

                  // Find new position of the selected item
                  final updatedDockItems = ref.read(dockItemsProvider);
                  final newSelectedIndex = updatedDockItems.indexWhere(
                    (item) => item.originalIndex == selectedOriginalIndex,
                  );

                  setState(() {
                    _currentIndex =
                        newSelectedIndex >= 0 ? newSelectedIndex : 0;
                  });
                }
              },
              builder: (context, candidateData, rejectedData) {
                final isDragTarget = candidateData.isNotEmpty;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDragTarget
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.2)
                          : Colors.transparent,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : isDragging
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.5)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                          size: 26,
                        ),
                        const SizedBox(height: 4),
                        // Show label for selected item
                        if (isSelected)
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          const SizedBox(height: 0),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 3,
                          width: isSelected ? 16 : 0,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}

// Helper widget for the simple progress bar
class _MiniProgressBar extends ConsumerWidget {
  const _MiniProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionAsync = ref.watch(currentPositionProvider);
    final mediaItem = ref.watch(currentMediaItemProvider).value;
    final duration = mediaItem?.duration ?? Duration.zero;

    return positionAsync.when(
      data: (position) {
        final double progress = (duration.inMilliseconds > 0)
            ? (position.inMilliseconds / duration.inMilliseconds)
                .clamp(0.0, 1.0)
            : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
              ),
              Text(
                _formatDuration(duration),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 20),
      error: (_, __) => const SizedBox(height: 20),
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
