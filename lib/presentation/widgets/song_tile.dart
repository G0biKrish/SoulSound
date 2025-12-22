import 'package:flutter/material.dart';
import 'artwork_widget.dart';
import '../../domain/entities/song.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final Widget? trailing;

  const SongTile(
      {super.key, required this.song, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ArtworkWidget(
        mediaId: song.mediaId,
        artworkPath: song.artworkPath,
        width: 50,
        height: 50,
        borderRadius: 8,
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      trailing: trailing ??
          Text(
            _formatDuration(song.duration),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
      onTap: onTap,
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
