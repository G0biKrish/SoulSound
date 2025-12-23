import 'package:flutter/material.dart';

class StreakIcon extends StatelessWidget {
  final int count;

  const StreakIcon({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.local_fire_department_rounded,
          color: Colors.orangeAccent,
          size: 16,
        ),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class BurningFireIcon extends StatefulWidget {
  final int count;

  const BurningFireIcon({super.key, required this.count});

  @override
  State<BurningFireIcon> createState() => _BurningFireIconState();
}

class _BurningFireIconState extends State<BurningFireIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.deepOrange,
      end: Colors.orangeAccent,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Icon(
                Icons.local_fire_department_rounded,
                color: _colorAnimation.value,
                size: 18,
                shadows: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.6),
                    blurRadius: 10 * _controller.value,
                    spreadRadius: 2,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        Text(
          '${widget.count}',
          style: const TextStyle(
            color: Colors.deepOrangeAccent,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.redAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
