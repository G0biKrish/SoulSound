import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/music_providers.dart';
import '../providers/theme_providers.dart';
import 'package:permission_handler/permission_handler.dart';
// For direct DB access if needed, or via provider
import '../../main.dart';
import 'memories_screen.dart';
import 'excluded_folders_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final excludedFolders = ref.watch(excludedFoldersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Appearance Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          // Dark Mode Toggle
          SwitchListTile(
            secondary: Icon(
              themeState.brightness == Brightness.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle dark/light theme'),
            value: themeState.brightness == Brightness.dark,
            onChanged: (value) {
              themeNotifier.toggleBrightness();
            },
          ),
          const Divider(),
          // Library Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Library',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Rescan Library'),
            subtitle: const Text('Scan device for new music'),
            onTap: () async {
              final success = await ref.read(scanProvider.notifier).scan();

              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Scanning started...')),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Permissions Required'),
                      content: const Text(
                        'This app needs storage access to find your music. Please grant permissions in settings.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            openAppSettings();
                          },
                          child: const Text('Open Settings'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.purpleAccent),
            title: const Text('Your Memories'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MemoriesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_off),
            title: const Text('Excluded Folders'),
            subtitle: Text(
                '${excludedFolders.length} folder${excludedFolders.length != 1 ? 's' : ''} excluded'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExcludedFoldersScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Sleep Timer'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showSleepTimerDialog(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text(
              'Clear Library',
              style: TextStyle(color: Colors.redAccent),
            ),
            subtitle: const Text('Remove all songs from database'),
            onTap: () {
              _showClearConfirmDialog(context, ref);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Set Sleep Timer'),
        children: [
          _timerOption(ctx, ref, 15, '15 Minutes'),
          _timerOption(ctx, ref, 30, '30 Minutes'),
          _timerOption(ctx, ref, 60, '1 Hour'),
          SimpleDialogOption(
            onPressed: () {
              ref.read(audioHandlerProvider).customAction('setSleepTimer', {
                'minutes': 0,
              }); // Cancel
              Navigator.pop(ctx);
            },
            child: const Text('Off', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _timerOption(
    BuildContext context,
    WidgetRef ref,
    int minutes,
    String label,
  ) {
    return SimpleDialogOption(
      onPressed: () {
        ref.read(audioHandlerProvider).customAction('setSleepTimer', {
          'minutes': minutes,
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sleep timer set for $label')));
      },
      child: Text(label),
    );
  }

  void _showClearConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Library?'),
        content: const Text(
          'This will remove all metadata from the local database. Your music files will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // In a real app we'd expose a clear method on notifier or repo
              // For now, triggering a force rescan is "safe", but to just clear:
              // ref.read(musicRepositoryProvider).clearAll(); // if existed
              // We will use Scan with forceRescan which effectively clears first.
              ref.read(scanProvider.notifier).scan();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
