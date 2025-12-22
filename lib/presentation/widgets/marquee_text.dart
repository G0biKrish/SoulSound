import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double velocity; // Pixels per second
  final double pauseDuration; // Pause at end/start

  const MarqueeText(
    this.text, {
    super.key,
    this.style,
    this.velocity = 30.0,
    this.pauseDuration = 1.5,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    while (mounted) {
      if (!_scrollController.hasClients) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) {
        // Text fits, no need to scroll
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }

      // Check if text fits perfectly (redundant but safe)

      // Wait at start
      await Future.delayed(Duration(seconds: widget.pauseDuration.toInt()));
      if (!mounted) break;

      // Scroll to end
      final duration =
          Duration(milliseconds: (maxScroll / widget.velocity * 1000).toInt());
      await _scrollController.animateTo(
        maxScroll,
        duration: duration,
        curve: Curves.linear,
      );
      if (!mounted) break;

      // Wait at end
      await Future.delayed(Duration(seconds: widget.pauseDuration.toInt()));
      if (!mounted) break;

      // Scroll back (or jump to start? Usually Marquee loops. Let's scroll back for smoother reading or Jump?)
      // Music players usually scroll continuously or ping-pong.
      // Let's Jump back to start for standard marquee loop, or PingPong.
      // Ping pong matches "exceeds space" behavior nicely.

      await _scrollController.animateTo(
        0.0,
        duration: duration, // Same speed back? or faster? Or jump?
        // Let's jump for classic marquee, or scroll back for ping-pong.
        // Let's do jump to 0.0 with fade? No, simple animate back looks elegant.
        curve: Curves.linear,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Update if text changes
  @override
  void didUpdateWidget(MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(), // Disable user scroll
      child: Text(
        widget.text,
        style: widget.style,
      ),
    );
  }
}
