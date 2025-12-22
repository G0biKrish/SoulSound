import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'artwork_widget.dart';

class RotatingAlbumArt extends StatefulWidget {
  final int mediaId;
  final String? artworkPath;
  final double size;
  final bool isPlaying;
  final Duration currentPosition;

  const RotatingAlbumArt({
    super.key,
    required this.mediaId,
    this.artworkPath,
    required this.size,
    required this.isPlaying,
    required this.currentPosition,
  });

  @override
  State<RotatingAlbumArt> createState() => _RotatingAlbumArtState();
}

class _RotatingAlbumArtState extends State<RotatingAlbumArt>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _currentRotation = 0.0;

  // To handle smooth interpolation we track the last known reliable position and time
  late Duration _lastKnownPosition;
  late DateTime _lastUpdateTime;

  // Constants
  // 1 rotation every 10 seconds seems like a good "Vinyl" speed (6 RPM is slow, maybe 10s is fine)
  // LP is 33 RPM approx 1.8s per rotation.
  // Let's go with something visually pleasing: 10 seconds per rotation.
  static const double _radiansPerMillisecond = (2 * pi) / 10000;

  @override
  void initState() {
    super.initState();
    _lastKnownPosition = widget.currentPosition;
    _lastUpdateTime = DateTime.now();
    _currentRotation = _calculateTargetRotation(_lastKnownPosition);

    _ticker = createTicker(_onTick);
    _ticker
        .start(); // Always run ticker to handle seek animations even if paused
  }

  @override
  void didUpdateWidget(RotatingAlbumArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update reference point on new position updates
    _lastKnownPosition = widget.currentPosition;
    _lastUpdateTime = DateTime.now();
  }

  double _calculateTargetRotation(Duration position) {
    return position.inMilliseconds * _radiansPerMillisecond;
  }

  void _onTick(Duration elapsed) {
    final now = DateTime.now();

    // 1. Calculate where we 'optimally' should be right now
    Duration estimatedCurrentPosition = _lastKnownPosition;
    if (widget.isPlaying) {
      final sinceUpdate = now.difference(_lastUpdateTime);
      estimatedCurrentPosition += sinceUpdate;
    }

    final double targetRotation =
        _calculateTargetRotation(estimatedCurrentPosition);

    // 2. Smoothly interpolate current visual rotation towards target

    // Optimization: If the target is way too far (e.g. 100 turns away due to a 10 min seek),
    // we don't want to spin 100 times. We just want a "spin for a sec" effect.
    // We shift _currentRotation in multiples of 2*PI so the visual phase is unchanged,
    // but the physics difference (error) becomes manageable (e.g. max 2 turns).

    const double twoPi = 2 * pi;
    // Keep the error between -2 turns and +2 turns (approx)
    while (targetRotation - _currentRotation > 2 * twoPi) {
      _currentRotation += twoPi;
    }
    while (targetRotation - _currentRotation < -2 * twoPi) {
      _currentRotation -= twoPi;
    }

    double error = targetRotation - _currentRotation;

    // We dampen the error to create the "Spin" effect.
    // 0.1 means we close 10% of the gap per frame.
    // At 60fps, this closes ~99% of the gap in ~0.7 seconds.
    // However, for HUGE seeks, we might want to cap the speed to avoid aliasing.
    // Max speed: 0.3 radians per frame (~17 degrees).

    double variableK = 0.03; // Looser spring for smoother transition

    double delta = error * variableK;

    // Reduced max speed to avoid "teleporting" look and chaotic spinning
    // 0.1 rad/frame is ~5.7 degrees per frame
    double maxSpeed = 0.1;
    if (delta > maxSpeed) delta = maxSpeed;
    if (delta < -maxSpeed) delta = -maxSpeed;

    setState(() {
      _currentRotation += delta;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _currentRotation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ArtworkWidget(
              mediaId: widget.mediaId,
              artworkPath: widget.artworkPath,
              width: widget.size,
              height: widget.size,
              borderRadius: widget.size / 2,
            ),
            // Inner "hole" / CD / Vinyl center
            Container(
              width: widget.size * 0.15,
              height: widget.size * 0.15,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade800, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
