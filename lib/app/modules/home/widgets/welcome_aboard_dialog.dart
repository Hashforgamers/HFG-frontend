import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hash/core/localization/app_region.dart';

class WelcomeAboardDialog extends StatefulWidget {
  /// Performs the claim. Returns `true` only when the bonus was actually
  /// credited, `false` on failure so the dialog can stay open for a retry.
  final Future<bool> Function() onClaim;

  /// Bonus amount (in ₹) shown in the copy. Kept in sync with the value the
  /// claim actually credits.
  final int amountRupees;

  const WelcomeAboardDialog({
    super.key,
    required this.onClaim,
    required this.amountRupees,
  });

  @override
  State<WelcomeAboardDialog> createState() => _WelcomeAboardDialogState();
}

class _WelcomeAboardDialogState extends State<WelcomeAboardDialog> {
  bool _claiming = false;
  bool _failed = false;

  Future<void> _handleClaim() async {
    if (_claiming) return;
    setState(() {
      _claiming = true;
      _failed = false;
    });

    final claimed = await widget.onClaim();
    if (!mounted) return;

    if (claimed) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _claiming = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: SweepGradient(
            center: Alignment.center,
            startAngle: 0.0,
            endAngle: 6.28319,
            colors: [
              Color(0xFF1541A3),
              Color(0xFF070C29),
              Color(0xFF040309),
              Color(0xFF060A22),
              Color(0xFF8320C3),
              Color(0xFF1541A3),
            ],
            stops: [0.22, 0.28, 0.66, 0.73, 0.97, 1.0],
            transform: GradientRotation(-1),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 50,
              left: 20,
              child: Transform.rotate(
                angle: 0.4,
                child: Image.asset(
                  'assets/welcome_aboard_images/dollar.png',
                  width: 62,
                ),
              ),
            ),
            Positioned(
              top: 5,
              right: -70,
              child: Transform(
                transform: Matrix4.identity()..scale(-1.0, 1.0),
                child: Image.asset(
                  'assets/welcome_aboard_images/dollar.png',
                  width: 82,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Positioned(
              top: 280,
              right: -30,
              child: Transform.rotate(
                angle: 0.4,
                child: Image.asset(
                  'assets/welcome_aboard_images/dollar.png',
                  width: 72,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              right: -80,
              child: Transform(
                transform: Matrix4.identity()..scale(-1.0, 1.0),
                child: Image.asset(
                  'assets/welcome_aboard_images/dollar.png',
                  width: 62,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              right: 150,
              child: Transform.rotate(
                angle: 0.4,
                child: Image.asset(
                  'assets/welcome_aboard_images/dollar.png',
                  width: 62,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 20,
              child: Image.asset(
                'assets/welcome_aboard_images/dollar.png',
                width: 52,
                fit: BoxFit.fill,
              ),
            ),
            Positioned(
              bottom: 170,
              left: -20,
              child: Transform.rotate(
                angle: 0.4,
                child: Image.asset(
                  'assets/welcome_aboard_images/dollar.png',
                  width: 62,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Positioned(
              top: -20,
              left: 180,
              child: Transform(
                transform: Matrix4.identity()
                  ..scale(-1.0, 1.0)
                  ..rotateZ(-0.3),
                child: Image.asset(
                  'assets/welcome_aboard_images/lightning_bolt.png',
                  height: 82,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 110,
              right: -30,
              child: Transform.rotate(
                angle: 0.3,
                child: Image.asset(
                  'assets/welcome_aboard_images/lightning_bolt.png',
                  height: 85,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 250,
              right: -100,
              child: Transform(
                transform: Matrix4.identity()
                  ..scale(-1.0, 1.0)
                  ..rotateZ(0.4),
                child: Image.asset(
                  'assets/welcome_aboard_images/lightning_bolt.png',
                  height: 82,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              right: -75,
              child: Transform(
                transform: Matrix4.identity()
                  ..scale(-1.0, 1.0)
                  ..rotateZ(0.4),
                child: Image.asset(
                  'assets/welcome_aboard_images/lightning_bolt.png',
                  height: 82,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 115,
              left: 55,
              child: Image.asset(
                'assets/welcome_aboard_images/lightning_bolt.png',
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 220,
              left: 5,
              child: Image.asset(
                'assets/welcome_aboard_images/lightning_bolt.png',
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Welcome Aboard!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Image.asset(
                    'assets/welcome_aboard_images/gift_box.png',
                    height: 160,
                    fit: BoxFit.fill,
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'You\'ve unlocked ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' ${Money.symbol}${widget.amountRupees} bonus crate! 🎁',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xff00DC00),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Use it to book your favourite cafe today!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_failed) ...[
                    const SizedBox(height: 16),
                    const Text(
                      "Couldn't claim right now.\nCheck your connection and try again.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xffFF6B6B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: _claiming ? null : _handleClaim,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Stack(
                        children: [
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 280,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  width: 1.5,
                                  style: BorderStyle.solid,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: _claiming
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xff00DC00),
                                            ),
                                      ),
                                    )
                                  : ShaderMask(
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                            colors: [
                                              Color(0xff00DC00),
                                              Color(0xff00DC00),
                                              Color(0xff00DC00),
                                            ],
                                          ).createShader(bounds),
                                      child: Text(
                                        _failed ? 'Try Again' : 'Claim Now',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_failed) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _claiming
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Text(
                          'Maybe later',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
