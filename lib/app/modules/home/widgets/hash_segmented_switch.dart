import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:just_audio/just_audio.dart';

class HashSegmentedSwitch extends StatefulWidget {
  final List<String> options;
  final FutureOr<void> Function(int) onChanged;
  final int initialIndex;

  const HashSegmentedSwitch({
    super.key,
    required this.options,
    required this.onChanged,
    this.initialIndex = 0,
  });

  @override
  State<HashSegmentedSwitch> createState() => _HashSegmentedSwitchState();
}

class _HashSegmentedSwitchState extends State<HashSegmentedSwitch>
    with SingleTickerProviderStateMixin {
  static const darkShadow = Color(0x66000000);
  static const activeStart = Color(0xFF000000);
  static const activeEnd = Color(0xFF000000);
  static const inactiveText = Color(0x99EBEBF5);
  static const activeText = Colors.white;

  // iOS segmented control (dark) with the Home cards' green hint.
  static const _track = Color(0x3D767680);
  static const _thumb = Color(0xFF3A3A3D);
  static const _brand = Color(0xFF00DC00);

  late int selectedIndex;
  bool _isAnimating = false;
  AudioPlayer? _tapAudioPlayer;
  bool _tapAudioReady = false;

  static const String _toggleTapSfxPath = 'assets/audio/sfx/toggle-click.mp3';

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _tapAudioPlayer?.dispose();
    _tapAudioPlayer = null;
    super.dispose();
  }

  Future<void> _prepareTapSound() async {
    final player = _tapAudioPlayer ??= AudioPlayer();
    try {
      await player.setAsset(_toggleTapSfxPath);
      await player.setVolume(0.8);
      _tapAudioReady = true;
    } catch (_) {
      _tapAudioReady = false;
    }
  }

  void _playTapSound() {
    if (!_tapAudioReady) {
      unawaited(_prepareTapSound());
      return;
    }
    final player = _tapAudioPlayer;
    if (player == null) return;
    unawaited(player.seek(Duration.zero));
    unawaited(player.play());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: const ShapeDecoration(
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(26)),
        ),
        color: _track,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / widget.options.length;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: width * selectedIndex,
                top: 0,
                bottom: 0,
                child: Container(
                  width: width,
                  decoration: ShapeDecoration(
                    shape: ContinuousRectangleBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(22)),
                      side: BorderSide(
                        color: _brand.withValues(alpha: 0.45),
                        width: 0.8,
                      ),
                    ),
                    color: _thumb,
                    shadows: [
                      const BoxShadow(
                        color: Color(0x4D000000),
                        offset: Offset(0, 3),
                        blurRadius: 8,
                      ),
                      BoxShadow(
                        color: _brand.withValues(alpha: 0.18),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(widget.options.length, (index) {
                  final isSelected = selectedIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_isAnimating) return;
                        if (selectedIndex == index) return;
                        _playTapSound();
                        Haptics.selection();
                        setState(() {
                          selectedIndex = index;
                        });
                        _playExpandAndNotify(index, width);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.inter(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected ? activeText : inactiveText,
                            fontSize: 14,
                            letterSpacing: -0.2,
                          ),
                          child: Text(widget.options[index]),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _playExpandAndNotify(int index, double tabWidth) async {
    _isAnimating = true;
    final overlay = Overlay.maybeOf(context);
    final box = context.findRenderObject() as RenderBox?;

    if (overlay == null || box == null || !box.hasSize) {
      await widget.onChanged(index);
      _isAnimating = false;
      return;
    }

    final topLeft = box.localToGlobal(Offset.zero);
    final sourceRect = Rect.fromLTWH(
      topLeft.dx + 3 + (tabWidth * index),
      topLeft.dy + 3,
      tabWidth,
      34,
    );
    final targetRect = Rect.fromLTWH(
      0,
      0,
      MediaQuery.sizeOf(context).width,
      MediaQuery.sizeOf(context).height,
    );

    late OverlayEntry entry;
    final animation = CurvedAnimation(
      parent: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 360),
      ),
      curve: Curves.easeInOutCubic,
    );

    entry = OverlayEntry(
      builder: (_) {
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final rect = Rect.lerp(sourceRect, targetRect, animation.value)!;
              final radius = BorderRadius.lerp(
                BorderRadius.circular(24),
                BorderRadius.zero,
                animation.value,
              )!;
              return Stack(
                children: [
                  if (animation.value > 0.15)
                    Opacity(
                      opacity: animation.value * 0.6,
                      child: Container(color: Colors.black),
                    ),
                  Positioned.fromRect(
                    rect: rect,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [activeStart, activeEnd],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: darkShadow,
                            offset: Offset(2, 3),
                            blurRadius: 6,
                            spreadRadius: -3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    overlay.insert(entry);
    final controller = animation.parent as AnimationController;
    await controller.forward();
    await Future.delayed(const Duration(milliseconds: 320));
    await widget.onChanged(index);
    await Future.delayed(const Duration(milliseconds: 420));

    if (entry.mounted) {
      entry.remove();
    }
    controller.dispose();
    _isAnimating = false;
  }
}
