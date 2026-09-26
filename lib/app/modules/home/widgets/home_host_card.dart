import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/utils/haptics.dart';

/// "Earn with HASH" host-program card in the Apple card style used across
/// Home: material surface, continuous corners and a green brand hint.
class HomeHostCard extends StatefulWidget {
  const HomeHostCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<HomeHostCard> createState() => _HomeHostCardState();
}

class _HomeHostCardState extends State<HomeHostCard> {
  static const _green = Color(0xFF30D158);
  static const _brand = Color(0xFF00DC00);
  static const _indigo = Color(0xFF7D7AFF);
  static const _secondary = Color(0x99EBEBF5);
  static const _fill = Color(0x29787880);
  static const _separator = Color(0x33FFFFFF);

  bool _down = false;

  TextStyle _text(double size, Color color, {FontWeight? weight}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        letterSpacing: size >= 20 ? -0.6 : (size >= 15 ? -0.3 : -0.1),
        height: 1.2,
      );

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
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
        scale: _down ? 0.98 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const ShapeDecoration(
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(48)),
              side: BorderSide(color: Color(0x5900DC00), width: 0.8),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF242427), Color(0xFF161618)],
            ),
            shadows: [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Indigo wash top-right, green hint bottom-right.
              Positioned(
                top: -90,
                right: -70,
                child: _glow(_indigo.withValues(alpha: 0.22), 260),
              ),
              Positioned(
                bottom: -110,
                right: -80,
                child: _glow(_brand.withValues(alpha: 0.15), 240),
              ),
              // Oversized faded controller as the card's art.
              Positioned(
                right: -18,
                top: 18,
                child: Icon(
                  Icons.sports_esports_rounded,
                  size: 130,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'HOST PROGRAM',
                      style: _text(
                        12,
                        _secondary,
                        weight: FontWeight.w600,
                      ).copyWith(letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Host. Hype. Earn.',
                      style: _text(28, Colors.white, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create tournaments on HASH and turn your matches into money.',
                      style: _text(14, _secondary),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: const ShapeDecoration(
                        shape: ContinuousRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                        color: _fill,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: ShapeDecoration(
                              shape: const ContinuousRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _green.withValues(alpha: 0.36),
                                  _green.withValues(alpha: 0.12),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.currency_rupee_rounded,
                              color: _green,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Earn up to',
                                  style: _text(12, _secondary),
                                ),
                                Text(
                                  '₹1,00,000',
                                  style: _text(
                                    24,
                                    Colors.white,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 0.5, height: 36, color: _separator),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fact(Icons.emoji_events_rounded, 'Your rules'),
                              const SizedBox(height: 4),
                              _fact(Icons.groups_rounded, 'Your players'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 50,
                      decoration: const ShapeDecoration(
                        shape: StadiumBorder(),
                        color: _green,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_circle_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Become a Host',
                            style: _text(
                              16,
                              Colors.black,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fact(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: _indigo),
      const SizedBox(width: 5),
      Text(label, style: _text(12, Colors.white, weight: FontWeight.w500)),
    ],
  );

  Widget _glow(Color color, double size) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );
}
