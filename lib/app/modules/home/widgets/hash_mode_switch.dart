import 'package:hash/app/modules/hash_store/widgets/neon_switch.dart';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:just_audio/just_audio.dart';

/// Hash Hub / Hash Live mode switch: two side-by-side cards with an icon,
/// title and subtitle. The selected card lights up in its accent colour
/// with a glow and an indicator bar underneath.
class HashModeSwitch extends StatefulWidget {
  const HashModeSwitch({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final FutureOr<void> Function(int) onChanged;

  @override
  State<HashModeSwitch> createState() => _HashModeSwitchState();
}

class _ModeOption {
  const _ModeOption(this.title, this.subtitle, this.icon, this.accent);
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
}

class _HashModeSwitchState extends State<HashModeSwitch> {
  static const _options = [
    _ModeOption(
      'Hash Hub',
      'Play • Compete • Community',
      Icons.sports_esports_rounded,
      Color(0xFF30D158),
    ),
    _ModeOption(
      'Hash Live',
      'Watch • Play • Support',
      Icons.sensors_rounded,
      Color(0xFFFF375F),
    ),
  ];

  late int _selected = widget.selectedIndex;
  bool _busy = false;
  AudioPlayer? _tap;
  bool _tapReady = false;

  @override
  void didUpdateWidget(HashModeSwitch old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      _selected = widget.selectedIndex;
    }
  }

  @override
  void dispose() {
    _tap?.dispose();
    super.dispose();
  }

  Future<void> _playTap() async {
    try {
      final p = _tap ??= AudioPlayer();
      if (!_tapReady) {
        await p.setAsset('assets/audio/sfx/toggle-click.mp3');
        await p.setVolume(0.8);
        _tapReady = true;
      }
      await p.seek(Duration.zero);
      unawaited(p.play());
    } catch (_) {}
  }

  Future<void> _select(int index) async {
    if (_busy || index == _selected) return;
    _busy = true;
    unawaited(_playTap());
    Haptics.selection();
    setState(() => _selected = index);
    // Let the highlight settle before the mode switch navigates.
    await Future.delayed(const Duration(milliseconds: 220));
    try {
      await widget.onChanged(index);
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const ShapeDecoration(
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(34)),
          side: BorderSide(color: Color(0x2600DC00), width: 0.8),
        ),
        // see-through so the cards' frost picks up the header behind it
        color: Color(0x330E0F10),
      ),
      child: NeonSwitchFx(
        index: _selected,
        count: _options.length,
        child: Row(
          children: [
            for (var i = 0; i < _options.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: _card(i)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(int i) {
    final o = _options[i];
    final on = i == _selected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _select(i),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Same build as the home chat button: a brand-gradient rim around
          // a frosted pane. The selected card adds its accent tint and glow.
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(_rim),
            decoration: ShapeDecoration(
              shape: _shape(30),
              gradient: LinearGradient(
                colors: [
                  for (final c in HomeTokens.brandGradient.colors)
                    c.withValues(alpha: on ? 0.85 : 0.4),
                ],
              ),
              shadows: on
                  ? [
                      BoxShadow(
                        color: o.accent.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: -4,
                      ),
                    ]
                  : const [],
            ),
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: _shape(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  height: 46 - _rim * 2,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        on
                            ? o.accent.withValues(alpha: 0.32)
                            : Colors.white.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Faint watermark art on the right.
                      Positioned(
                        right: -14,
                        top: -8,
                        bottom: -8,
                        child: Icon(
                          o.icon,
                          size: 50,
                          color: Colors.white.withValues(
                            alpha: on ? 0.08 : 0.03,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          NeonFlip(
                            slot: i,
                            child: Icon(
                              o.icon,
                              size: 22,
                              color: on ? Colors.white : o.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  o.title,
                                  maxLines: 1,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    o.subtitle,
                                    maxLines: 1,
                                    style: GoogleFonts.inter(
                                      color: on
                                          ? Colors.white.withValues(alpha: 0.82)
                                          : const Color(0x99EBEBF5),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _rim = 1.0; // same rim as the chat button
  static ContinuousRectangleBorder _shape(double r) =>
      ContinuousRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(r)),
      );
}
