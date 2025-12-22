import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/music_providers.dart';
import '../providers/audio_providers.dart';
import '../providers/dock_providers.dart';
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

    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent moving up when keyboard opens
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Image.asset('assets/images/android/main_screen_logo.png'),
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
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
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
          if (ref.watch(currentMediaItemProvider).asData?.value != null)
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
