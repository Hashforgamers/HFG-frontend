import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BounceTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const BounceTap({super.key, required this.child, this.onTap});

  @override
  State<BounceTap> createState() => _BounceTapState();
}

class _BounceTapState extends State<BounceTap> {
  double _scale = 1.0;

  void _shrink() {
    HapticFeedback.lightImpact();
    setState(() => _scale = 0.95);
  }

  void _reset() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _shrink(),
      onTapUp: (_) => _reset(),
      onTapCancel: _reset,
      onPanEnd: (_) => _reset(), // ensures bounce back after drag + lift
      behavior: HitTestBehavior.translucent,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
