import 'dart:math';
import 'package:flutter/material.dart';

class WaveformSeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration>? onChangeEnd;

  const WaveformSeekBar({
    super.key,
    required this.duration,
    required this.position,
    this.onChangeEnd,
  });

  @override
  State<WaveformSeekBar> createState() => _WaveformSeekBarState();
}

class _WaveformSeekBarState extends State<WaveformSeekBar> {
  // We'll cache the random bar heights so they don't jitter on rebuild
  List<double>? _barHeights;
  // Drag handling
  double? _dragValue; // In fraction 0.0 to 1.0

  @override
  Widget build(BuildContext context) {
    // Current progress fraction (0.0 to 1.0)
    double currentProgress;
    if (_dragValue != null) {
      currentProgress = _dragValue!;
    } else {
      final totalMs = widget.duration.inMilliseconds;
      final posMs = widget.position.inMilliseconds;
      if (totalMs > 0) {
        currentProgress = (posMs / totalMs).clamp(0.0, 1.0);
      } else {
        currentProgress = 0.0;
      }
    }

    return Row(
      children: [
        // Current Time
        Text(
          _formatDuration(_dragValue != null
              ? Duration(
                  milliseconds:
                      (_dragValue! * widget.duration.inMilliseconds).round())
              : widget.position),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        // Waveform
        Expanded(
          child: SizedBox(
            height: 60, // Fixed height for bars
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                // Generate bars
                final barCount = (width / 6).floor();
                if (_barHeights == null || _barHeights!.length != barCount) {
                  _barHeights = List.generate(barCount, (index) {
                    final random = Random(index);
                    final base = 0.2 + random.nextDouble() * 0.8;
                    // Taper ends to look like a natural waveform
                    final x = index / barCount;
                    final curve = sin(x * pi);
                    return base * curve;
                  });
                }

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) =>
                      _onDragStart(details, width),
                  onHorizontalDragUpdate: (details) =>
                      _onDragUpdate(details, width),
                  onHorizontalDragEnd: (details) => _onDragEnd(details, width),
                  onTapUp: (details) => _onTapUp(details, width),
                  child: CustomPaint(
                    size: Size(width, 60),
                    painter: _WaveformPainter(
                      barHeights: _barHeights!,
                      progress: currentProgress,
                      playedColor: Theme.of(context).colorScheme.onSurface,
                      unplayedColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Total Time
        Text(
          _formatDuration(widget.duration),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _updateDragValue(double dx, double width) {
    final fraction = (dx / width).clamp(0.0, 1.0);
    setState(() {
      _dragValue = fraction;
    });
  }

  void _onDragStart(DragStartDetails details, double width) {
    _updateDragValue(details.localPosition.dx, width);
  }

  void _onDragUpdate(DragUpdateDetails details, double width) {
    _updateDragValue(details.localPosition.dx, width);
  }

  void _onDragEnd(DragEndDetails details, double width) {
    if (_dragValue != null) {
      widget.onChangeEnd?.call(Duration(
          milliseconds:
              (_dragValue! * widget.duration.inMilliseconds).round()));
      setState(() {
        _dragValue = null;
      });
    }
  }

  void _onTapUp(TapUpDetails details, double width) {
    final fraction = (details.localPosition.dx / width).clamp(0.0, 1.0);
    widget.onChangeEnd?.call(Duration(
        milliseconds: (fraction * widget.duration.inMilliseconds).round()));
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> barHeights;
  final double progress; // 0.0 to 1.0
  final Color playedColor;
  final Color unplayedColor;

  _WaveformPainter({
    required this.barHeights,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;

    final totalBars = barHeights.length;
    // Calculate precise gap and width if possible, or assume fixed
    // Let's fit them exactly
    // gap ratio. say bar width is w, gap is g. w = 2g?
    // total width = n*w + (n-1)*g
    // let's say width is 4px, gap 2px.

    // Simpler: divide width by totalBars.
    final stepWidth = size.width / totalBars;
    final barWidth = stepWidth * 0.6; // 60% of slot is bar

    final centerY = size.height / 2;

    for (int i = 0; i < totalBars; i++) {
      final barHeightFraction = barHeights[i];
      final actualBarHeight = barHeightFraction * size.height;

      final x = i * stepWidth + (stepWidth / 2); // center bar in slot

      // Determine color based on progress
      // Current x position normalized
      final normalizedX = x / size.width;
      if (normalizedX <= progress) {
        paint.color = playedColor;
      } else {
        paint.color = unplayedColor;
      }

      paint.strokeWidth = barWidth;

      final p1 = Offset(x, centerY - actualBarHeight / 2);
      final p2 = Offset(x, centerY + actualBarHeight / 2);

      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.barHeights != barHeights;
  }
}
