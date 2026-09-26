import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:lottie/lottie.dart';

/// Café rail card in an Apple "Today card" style: full-bleed photo with
/// continuous corners, frosted status pills on top and a frosted info bar
/// with name, distance, console platforms and a capsule Book button.
class CafeCard extends StatefulWidget {
  const CafeCard({
    super.key,
    required this.width,
    required this.name,
    required this.imageUrl,
    required this.isOpen,
    required this.distanceLabel,
    required this.fillingFast,
    required this.onTap,
  });

  final double width;
  final String name;
  final String imageUrl;
  final bool isOpen;

  /// e.g. "3.2 km · ~10 min" or "-- km".
  final String distanceLabel;
  final bool fillingFast;
  final VoidCallback onTap;

  static const _padIcon =
      'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/gaming-pad-02_hvvehr.png';
  static const _platforms = [
    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075082/ps_krf4kw.png',
    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075086/xbox_fmz0bn.png',
    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075080/pc_ah5ulv.png',
  ];

  @override
  State<CafeCard> createState() => _CafeCardState();
}

class _CafeCardState extends State<CafeCard> {
  static const _green = Color(0xFF30D158);
  static const _red = Color(0xFFFF453A);
  static const _secondary = Color(0xB3EBEBF5); // 70%
  bool _pressed = false;

  TextStyle _text(double size, Color color, {FontWeight? weight}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        letterSpacing: size >= 16 ? -0.35 : -0.1,
        height: 1.2,
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
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          width: widget.width,
          clipBehavior: Clip.antiAlias,
          decoration: const ShapeDecoration(
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(44)),
              side: BorderSide(color: Color(0x5900DC00), width: 0.8),
            ),
            color: Color(0xFF1C1C1E),
            shadows: [
              BoxShadow(
                color: Color(0x59000000),
                blurRadius: 18,
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
                imageUrl: widget.imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: (widget.width * 2.5).round(),
                placeholder: (_, _) =>
                    const ColoredBox(color: Color(0xFF2C2C2E)),
                errorWidget: (_, _, _) => const ColoredBox(
                  color: Color(0xFF2C2C2E),
                  child: Center(
                    child: Icon(
                      Icons.storefront_rounded,
                      color: Colors.white38,
                      size: 48,
                    ),
                  ),
                ),
              ),
              // Scrims so text stays legible on bright photos.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0xB3000000),
                    ],
                    stops: [0, 0.3, 0.5, 1],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    _glassPill(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: widget.isOpen ? _green : _red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.isOpen ? 'Open' : 'Closed',
                            style: _text(
                              12,
                              Colors.white,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (widget.fillingFast)
                      _glassPill(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: Lottie.asset(
                                'assets/fire.json',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Filling Fast',
                              style: _text(
                                12,
                                const Color(0xFFFFD60A),
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(left: 0, right: 0, bottom: 0, child: _infoBar()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withValues(alpha: 0.55),
            border: const Border(
              top: BorderSide(color: Color(0x1FFFFFFF), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(17, Colors.white, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          size: 12,
                          color: _secondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.distanceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _text(12.5, _secondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _netIcon(CafeCard._padIcon, 14),
                        const SizedBox(width: 5),
                        Text(
                          'Consoles',
                          style: _text(12, _secondary, weight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        for (final icon in CafeCard._platforms) ...[
                          Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(4),
                            decoration: const ShapeDecoration(
                              shape: ContinuousRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              color: Color(0x33787880),
                            ),
                            child: _netIcon(icon, 16),
                          ),
                          const SizedBox(width: 5),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _open,
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: const ShapeDecoration(
                    shape: StadiumBorder(),
                    color: _green,
                  ),
                  child: Text(
                    'Book Now',
                    style: _text(14, Colors.black, weight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassPill(Widget child) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x33FFFFFF), width: 0.5),
        ),
        child: child,
      ),
    ),
  );

  Widget _netIcon(String url, double size) => CachedNetworkImage(
    imageUrl: url,
    width: size,
    height: size,
    fit: BoxFit.contain,
    placeholder: (_, _) => SizedBox(width: size, height: size),
    errorWidget: (_, _, _) => SizedBox(width: size, height: size),
  );
}
