import 'dart:async';
import 'package:flutter/material.dart';
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
  static const containerStart = Color(0xFF1C1C1C);
  static const containerEnd = Color(0xFF171717);
  static const darkShadow = Color(0x66000000);
  static const activeStart = Color(0xFF000000);
  static const activeEnd = Color(0xFF000000);
  static const inactiveText = Color(0xFF8B8B8B);
  static const activeText = Color(0xFFF5FFF8);

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
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [containerStart, containerEnd],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: darkShadow,
            offset: Offset(5, 6),
            blurRadius: 14,
            spreadRadius: -2,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / widget.options.length;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: width * selectedIndex,
                child: Container(
                  width: width,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
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
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 1,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: List.generate(widget.options.length, (index) {
                  final isSelected = selectedIndex == index;
                  return Expanded(
                    child: GestureDetector(
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
                        child: Text(
                          widget.options[index],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? activeText : inactiveText,
                            fontSize: 13,
                          ),
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
      topLeft.dx + 4 + (tabWidth * index),
      topLeft.dy + 4,
      tabWidth,
      40,
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
