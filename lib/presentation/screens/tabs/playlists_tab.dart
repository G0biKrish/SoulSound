import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../providers/music_providers.dart';
import '../../../main.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/song.dart'; // import Song
import '../playlist_detail_screen.dart';

class PlaylistsTab extends ConsumerWidget {
  const PlaylistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    final allSongsAsync = ref.watch(allSongsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: playlistsAsync.when(
        data: (playlists) {
          final userPlaylists = List<Playlist>.from(playlists);

          Playlist? favoritesPlaylist;
          final favIndex =
              userPlaylists.indexWhere((p) => p.name == 'Favorites');
          if (favIndex != -1) {
            favoritesPlaylist = userPlaylists.removeAt(favIndex);
          }

          return allSongsAsync.when(
            data: (allSongs) {
              final mostPlayedSongs = List<Song>.from(allSongs)
                ..sort((a, b) => b.playCount.compareTo(a.playCount));
              final topPlayed = mostPlayedSongs.take(50).toList();

              final mostPlayedPlaylist = Playlist(
                id: -100,
                name: 'Most Played',
                songs: topPlayed.where((s) => s.playCount > 0).toList(),
                dateCreated: DateTime.now(),
              );

              final likedPlaylist = favoritesPlaylist ??
                  Playlist(
                      id: -200,
                      name: 'Liked Songs',
                      songs: [],
                      dateCreated: DateTime.now());

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  // 1. Add New Playlist Card
                  _buildAddCard(context, ref),

                  const SizedBox(height: 12),

                  // 2. Most Played Card
                  _buildPlaylistCard(
                    context,
                    mostPlayedPlaylist,
                    icon: Icons.bar_chart_rounded,
                    iconColor: Colors.purpleAccent,
                    isSmart: true,
                  ),

                  const SizedBox(height: 12),

                  // 3. Liked Songs Card
                  _buildPlaylistCard(
                    context,
                    likedPlaylist,
                    icon: Icons.favorite_rounded,
                    iconColor: Colors.redAccent,
                    isSmart: true,
                  ),

                  if (userPlaylists.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Text(
                        'Your Playlists',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...userPlaylists.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildPlaylistCard(context, p, ref: ref),
                        )),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildAddCard(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showCreatePlaylistDialog(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.playlist_add,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              const Text(
                'Create New Playlist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(BuildContext context, Playlist playlist,
      {bool isSmart = false,
      IconData? icon,
      Color? iconColor,
      WidgetRef? ref}) {
    final color = iconColor ?? Colors.blueAccent;
    IconData displayIcon = icon ?? Icons.music_note_rounded;

    // Check for custom icon
    if (!isSmart && playlist.iconCode != null) {
      displayIcon = IconData(playlist.iconCode!, fontFamily: 'MaterialIcons');
    }

    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlaylistDetailScreen(playlist: playlist),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Icon Box or Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: (playlist.artworkPath != null)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FutureBuilder<Uint8List?>(
                          future: _loadEncryptedArtwork(playlist.artworkPath!),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return Image.memory(
                                snapshot.data!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(displayIcon,
                                      color: color, size: 28);
                                },
                              );
                            }
                            // Show icon while loading or on error
                            return Icon(displayIcon, color: color, size: 28);
                          },
                        ),
                      )
                    : Icon(displayIcon, color: color, size: 28),
              ),
              const SizedBox(width: 16),

              // Text Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name == 'Favorites'
                          ? 'Liked Songs'
                          : playlist.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playlist.songs.length} Tracks',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Options Menu (only for user playlists)
              if (!isSmart)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                  color: Colors.grey[850],
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'rename',
                        child: Text('Rename',
                            style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Colors.white))),
                  ],
                  onSelected: (value) async {
                    if (ref == null) return;
                    if (value == 'delete') {
                      await ref
                          .read(musicRepositoryProvider)
                          .deletePlaylist(playlist.id);
                      ref.invalidate(playlistsProvider);
                    } else if (value == 'rename') {
                      // Delay slightly to let menu close, though usually auto-closes
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (context.mounted)
                          _showRenamePlaylistDialog(context, ref, playlist);
                      });
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    int? selectedIconCode;
    String? selectedImagePath; // Store selected image path

    // Available icons for selection
    final List<IconData> availableIcons = [
      Icons.music_note_rounded,
      Icons.album_rounded,
      Icons.headphones_rounded,
      Icons.speaker_rounded,
      Icons.queue_music_rounded,
      Icons.library_music_rounded,
      Icons.star_rounded,
      Icons.bolt_rounded,
      Icons.local_fire_department_rounded,
      Icons.spa_rounded,
      Icons.filter_vintage_rounded,
      Icons.nightlight_round,
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('New Playlist',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Playlist Name',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),

                  // Image Picker Section
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final result = await FilePicker.platform
                            .pickFiles(type: FileType.image);
                        if (result != null &&
                            result.files.single.path != null) {
                          setState(() {
                            selectedImagePath = result.files.single.path;
                            // If image is picked, clear icon selection to avoid confusion (optional)
                            selectedIconCode = null;
                          });
                        }
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(16),
                          image: selectedImagePath != null
                              ? DecorationImage(
                                  image: FileImage(File(selectedImagePath!)),
                                  fit: BoxFit.cover)
                              : null,
                          border:
                              Border.all(color: Colors.grey[700]!, width: 1),
                        ),
                        child: selectedImagePath == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      color: Colors.white54, size: 32),
                                  SizedBox(height: 8),
                                  Text('Add Cover',
                                      style: TextStyle(
                                          color: Colors.white54, fontSize: 12)),
                                ],
                              )
                            : Stack(
                                children: [
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedImagePath = null;
                                        });
                                      },
                                      child: const CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.black54,
                                        child: Icon(Icons.close,
                                            size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Or Select Icon',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150, // Limit height for grid
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: availableIcons.length,
                      itemBuilder: (ctx, index) {
                        final icon = availableIcons[index];
                        final isSelected = selectedIconCode == icon.codePoint;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIconCode = icon.codePoint;
                              // If icon is picked, clear image
                              selectedImagePath = null;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                            ),
                            child: Icon(
                              icon,
                              color: isSelected ? Colors.white : Colors.white54,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  String? finalArtworkPath;
                  if (selectedImagePath != null) {
                    finalArtworkPath =
                        await _savePlaylistArtwork(selectedImagePath!);

                    if (finalArtworkPath == null) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text(
                                'Failed to save playlist image. Please rebuild app if this persists.')));
                      }
                    }
                  }

                  await ref.read(musicRepositoryProvider).createPlaylist(
                      controller.text,
                      iconCode: selectedIconCode,
                      artworkPath: finalArtworkPath);
                  ref.invalidate(playlistsProvider); // Refresh
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      }),
    );
  }

  /// XOR encrypt/decrypt bytes with a simple key
  List<int> _encryptBytes(List<int> bytes) {
    // Simple XOR cipher - same operation for encrypt and decrypt
    const key = [
      0x53,
      0x6F,
      0x75,
      0x6C,
      0x53,
      0x6F,
      0x75,
      0x6E,
      0x64
    ]; // "SoulSound"
    final result = <int>[];
    for (int i = 0; i < bytes.length; i++) {
      result.add(bytes[i] ^ key[i % key.length]);
    }
    return result;
  }

  /// Load and decrypt artwork file
  Future<Uint8List?> _loadEncryptedArtwork(String encryptedPath) async {
    try {
      final file = File(encryptedPath);
      if (!await file.exists()) return null;

      final encryptedBytes = await file.readAsBytes();
      final decryptedBytes = _encryptBytes(encryptedBytes);
      return Uint8List.fromList(decryptedBytes);
    } catch (e) {
      debugPrint('Error loading encrypted artwork: $e');
      return null;
    }
  }

  Future<String?> _savePlaylistArtwork(String sourcePath) async {
    try {
      // 1. Cleanup old legacy folders if they exist
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final legacyDirs = ['playlist_art', 'art', '.private_art'];
        for (final dirName in legacyDirs) {
          final dir = Directory(p.join(docDir.path, dirName));
          if (await dir.exists()) {
            await dir.delete(recursive: true);
            debugPrint('Cleaned up legacy dir: $dirName');
          }
        }
      } catch (e) {
        // Ignore cleanup errors
      }

      // 2. Use ApplicationSupportDirectory + hidden .soulSound folder
      final appDir = await getApplicationSupportDirectory();
      final artDir = Directory(p.join(appDir.path, '.soulSound', 'artwork'));
      if (!artDir.existsSync()) {
        await artDir.create(recursive: true);
        // Create .nomedia file
        try {
          await File(p.join(artDir.path, '.nomedia')).create();
        } catch (_) {}
      }

      final fileName = '.enc_${DateTime.now().millisecondsSinceEpoch}.dat';
      final targetPath = p.join(artDir.path, fileName);

      // Read source image bytes
      final sourceBytes = await File(sourcePath).readAsBytes();

      // Encrypt the bytes
      final encryptedBytes = _encryptBytes(sourceBytes);

      // Write encrypted bytes to file
      await File(targetPath).writeAsBytes(encryptedBytes);

      debugPrint('Encrypted image saved to: $targetPath');

      // AGGRESSIVE CLEANUP:
      // 1. Clear FilePicker's internal cache
      try {
        await FilePicker.platform.clearTemporaryFiles();
      } catch (_) {}

      // 2. Explicitly try to delete the source file if it looks like a cache file
      // (This removes the "copy" the user sees in their gallery/files app if the picker put it there)
      try {
        final cacheDir = await getTemporaryDirectory();
        if (sourcePath.contains(cacheDir.path) ||
            sourcePath.contains('cache')) {
          final sourceFile = File(sourcePath);
          if (await sourceFile.exists()) {
            await sourceFile.delete();
            debugPrint('Deleted temporary source file: $sourcePath');
          }
        }
      } catch (e) {
        debugPrint(
            'Could not delete source file (might be original user file): $e');
      }

      return targetPath;
    } catch (e) {
      debugPrint('Error saving playlist artwork: $e');
      return null;
    }
  }

  void _showRenamePlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await ref
                    .read(musicRepositoryProvider)
                    .renamePlaylist(playlist.id, controller.text);
                ref.invalidate(playlistsProvider); // Refresh
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}
