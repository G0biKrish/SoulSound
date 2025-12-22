import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/music_providers.dart';

class MemoriesScreen extends ConsumerWidget {
  const MemoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(memoriesStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Memories')),
      body: statsAsync.when(
        data: (stats) {
          final duration = stats['totalDuration'] as Duration? ?? Duration.zero;
          final topArtist = stats['topArtist'] as String? ?? '-';
          final topGenre = stats['topGenre'] as String? ?? '-';
          final hours = duration.inHours;
          final minutes = duration.inMinutes.remainder(60);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCard(
                  'Total Duration',
                  '${hours}h ${minutes}m',
                  Icons.timer,
                  Colors.blueAccent,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  'Top Artist',
                  topArtist,
                  Icons.person,
                  Colors.purpleAccent,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  'Top Genre',
                  topGenre,
                  Icons.music_note,
                  Colors.orangeAccent,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Monthly Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Chart Coming Soon',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
