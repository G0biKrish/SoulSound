import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class ArtworkWidget extends StatelessWidget {
  final int mediaId;
  final String? artworkPath;
  final double width;
  final double height;
  final double borderRadius;

  const ArtworkWidget({
    super.key,
    required this.mediaId,
    this.artworkPath,
    required this.width,
    required this.height,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (artworkPath != null) {
      final file = File(artworkPath!);
      // We don't check existSync synchronously in build usually, but for local files it's okayish.
      // Better to just let Image.file fail and use errorBuilder.
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final cacheSize = (width > height ? width : height) * devicePixelRatio;

      return Image.file(
        file,
        fit: BoxFit.cover,
        width: width,
        height: height,
        cacheWidth: cacheSize.toInt(),
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _buildQueryArtwork(context),
      );
    }
    return _buildQueryArtwork(context);
  }

  Widget _buildQueryArtwork(BuildContext context) {
    return QueryArtworkWidget(
      id: mediaId,
      type: ArtworkType.AUDIO,
      artworkWidth: width,
      artworkHeight: height,
      keepOldArtwork: true,
      nullArtworkWidget: _buildFallback(context),
      errorBuilder: (_, __, ___) => _buildFallback(context),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Image.asset(
      'assets/images/android/main_screen_logo.png',
      fit: BoxFit.cover,
      width: width,
      height: height,
    );
  }
}
