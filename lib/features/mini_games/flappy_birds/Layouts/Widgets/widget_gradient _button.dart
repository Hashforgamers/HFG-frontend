import 'package:flutter/material.dart';

import '../../Global/functions.dart';

class Button extends StatelessWidget {
  final Icon? icon;
  final double width;
  final double height;
  final String buttonType;
  final VoidCallback onTap; // <-- new

  const Button({
    required this.width,
    required this.height,
    this.icon,
    required this.buttonType,
    required this.onTap, // <-- new
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        width: width,
        height: height,
        margin: EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade500],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        alignment: Alignment.center,
        child: buttonType == "text"
            ? myText("Play", Colors.green, 35)
            : icon,
      ),
      onTap: onTap, // <-- use callback directly
    );
  }
}
