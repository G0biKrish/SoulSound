import 'dart:async';
import 'package:flutter/material.dart';

class SoulLand extends StatefulWidget {
  final Widget child;
  final Widget? icon; // Icon to show in the "Pill" state
  final Duration autoCloseDuration;
  final VoidCallback? onClosed;

  const SoulLand({
    super.key,
    required this.child,
    this.icon,
    this.autoCloseDuration = const Duration(seconds: 5),
    this.onClosed,
  });

  @override
  State<SoulLand> createState() => _SoulLandState();
}

class _SoulLandState extends State<SoulLand>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  Timer? _dismissTimer;
  late AnimationController _borderController;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Start: Show "Pill" first, then expand
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _expand();
      });
    });
  }

  void _expand() {
    setState(() {
      _isExpanded = true; // Expands from Pill to Overlay
    });
    _resetDismissTimer();
  }

  void _collapseAndClose() {
    _dismissTimer?.cancel();

    // Step 1: Shrink back to Pill
    setState(() {
      _isExpanded = false;
    });

    // Step 2: Wait for shrink animation to finish, pause briefly as Pill, then hide
    Future.delayed(const Duration(milliseconds: 700), () {
      if (widget.onClosed != null) {
        widget.onClosed!();
      } else {
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  void _resetDismissTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(widget.autoCloseDuration, _collapseAndClose);
  }

  @override
  void dispose() {
    _borderController.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final primary = Theme.of(context).colorScheme.primary;
    final tertiary = Theme.of(context).colorScheme.tertiary;

    // Collapsed: 48x48 Circle (Pill). Expanded: Width - 32
    final width = _isExpanded ? screenWidth - 32 : 48.0;
    final height = _isExpanded ? null : 48.0;

    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _resetDismissTimer(),
        onPanDown: (_) => _resetDismissTimer(),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack, // Fluid expansion/contraction
          alignment: Alignment.topCenter,
          child: AnimatedBuilder(
            animation: _borderController,
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.only(top: 10),
                width: width,
                height: height,
                constraints: _isExpanded
                    ? const BoxConstraints(minHeight: 48)
                    : const BoxConstraints(maxHeight: 48, maxWidth: 48),

                padding: const EdgeInsets.all(1.5), // Border width
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                      _isExpanded ? 15 : 50), // Reduced roundness when expanded
                  gradient: SweepGradient(
                    colors: [primary, tertiary, primary],
                    stops: const [0.0, 0.5, 1.0],
                    transform:
                        GradientRotation(_borderController.value * 2 * 3.14159),
                  ),
                  boxShadow: [
                    if (_isExpanded)
                      BoxShadow(
                        color: primary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: Container(
                  padding: _isExpanded
                      ? const EdgeInsets.symmetric(horizontal: 24)
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(_isExpanded ? 13 : 48),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isExpanded
                        ? SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Material(
                              type: MaterialType.transparency,
                              child: Listener(
                                  onPointerDown: (_) => _resetDismissTimer(),
                                  child: widget.child),
                            ))
                        : (widget.icon ?? const SizedBox()),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
