import 'package:flutter/material.dart';

class ControllerButton extends StatelessWidget {
  final IconData icon;
  final Function() onTap;
  static bool _isTapping = false;

  const ControllerButton({required this.icon, required this.onTap});

  static bool get isTapping => _isTapping;   // ✅ add this

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onTapUp: (_) => _isTapping = false,
      onTapDown: (_) {
        _isTapping = true;
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(10.0),
          color: Colors.brown[300],
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
