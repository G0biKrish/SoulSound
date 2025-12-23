import 'package:flutter/material.dart';
import 'artwork_widget.dart';
import '../../domain/entities/song.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final Widget? trailing;
  final Widget? streakWidget;
  final bool isSelected;
  final VoidCallback? onLongPress;

  const SongTile(
      {super.key,
      required this.song,
      required this.onTap,
      this.trailing,
      this.streakWidget,
      this.isSelected = false,
      this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      selectedTileColor:
          Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
      leading: Stack(
        children: [
          ArtworkWidget(
            mediaId: song.mediaId,
            artworkPath: song.artworkPath,
            width: 50,
            height: 50,
            borderRadius: 8,
          ),
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle,
                    color: Colors.white, size: 24),
              ),
            ),
        ],
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (streakWidget != null) ...[
            streakWidget!,
            const SizedBox(width: 8),
          ],
          if (trailing != null)
            trailing!
          else
            Text(
              _formatDuration(song.duration),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
