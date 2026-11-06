import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/utils/haptics.dart';

/// Trending short card in an Apple poster style: 9:16 thumbnail with
/// continuous corners, a frosted channel chip on top, the title over a soft
/// scrim and a frosted "Watch" capsule.
class ShortCard extends StatefulWidget {
  const ShortCard({
    super.key,
    required this.thumbnail,
    required this.title,
    required this.channelName,
    required this.channelImage,
    required this.onTap,
    this.width = 138,
    this.height = 236,
  });

  final String thumbnail;
  final String title;
  final String channelName;
  final String channelImage;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  State<ShortCard> createState() => _ShortCardState();
}

class _ShortCardState extends State<ShortCard> {
  bool _pressed = false;

  TextStyle _text(double size, Color color, {FontWeight? weight}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        letterSpacing: -0.15,
        height: 1.22,
      );

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  void _open() {
    Haptics.selection();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: _open,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          width: widget.width,
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: const ShapeDecoration(
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(40)),
              side: BorderSide(color: Color(0x5900DC00), width: 0.8),
            ),
            color: Color(0xFF1C1C1E),
            shadows: [
              BoxShadow(
                color: Color(0x59000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color(0x2E00DC00),
                blurRadius: 14,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: widget.thumbnail,
                fit: BoxFit.cover,
                memCacheWidth: (widget.width * 3).round(),
                placeholder: (_, _) =>
                    const ColoredBox(color: Color(0xFF2C2C2E)),
                errorWidget: (_, _, _) => const ColoredBox(
                  color: Color(0xFF2C2C2E),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_outline_rounded,
                      color: Colors.white38,
                      size: 36,
                    ),
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x80000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0xE6000000),
                    ],
                    stops: [0, 0.25, 0.45, 1],
                  ),
                ),
              ),
              Positioned(top: 8, left: 8, right: 8, child: _channelChip()),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _text(13, Colors.white, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    _watchButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _channelChip() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(3, 3, 9, 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x33FFFFFF), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: widget.channelImage,
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        const ColoredBox(color: Color(0xFF3A3A3C)),
                    errorWidget: (_, _, _) => const ColoredBox(
                      color: Color(0xFF3A3A3C),
                      child: Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.channelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(11, Colors.white, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _watchButton() {
    return GestureDetector(
      onTap: _open,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x40FFFFFF), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 3),
                Text(
                  'Watch',
                  style: _text(13, Colors.white, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
