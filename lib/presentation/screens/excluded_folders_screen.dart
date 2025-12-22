import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

final excludedFoldersProvider = StateNotifierProvider<ExcludedFoldersNotifier, List<String>>((ref) {
  return ExcludedFoldersNotifier();
});

class ExcludedFoldersNotifier extends StateNotifier<List<String>> {
  ExcludedFoldersNotifier() : super([]) {
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final foldersJson = prefs.getString('excluded_folders');
    if (foldersJson != null) {
      final List<dynamic> folders = jsonDecode(foldersJson);
      state = folders.cast<String>();
    }
  }

  Future<void> _saveFolders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('excluded_folders', jsonEncode(state));
  }

  Future<void> addFolder(String folderPath) async {
    if (!state.contains(folderPath)) {
      state = [...state, folderPath];
      await _saveFolders();
    }
  }

  Future<void> removeFolder(String folderPath) async {
    state = state.where((folder) => folder != folderPath).toList();
    await _saveFolders();
  }
}

class ExcludedFoldersScreen extends ConsumerWidget {
  const ExcludedFoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final excludedFolders = ref.watch(excludedFoldersProvider);
    final notifier = ref.read(excludedFoldersProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Excluded Folders'),
      ),
      body: excludedFolders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No folders excluded',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add folders to exclude from music scanning',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: excludedFolders.length,
              itemBuilder: (context, index) {
                final folder = excludedFolders[index];
                return ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(
                    folder,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      await notifier.removeFolder(folder);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Removed: ${folder.split('/').last}')),
                        );
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await FilePicker.platform.getDirectoryPath();
          if (result != null) {
            await notifier.addFolder(result);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added: ${result.split('/').last}')),
              );
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

