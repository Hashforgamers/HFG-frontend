import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/utils/haptics.dart';

/// iOS dark-mode system colours used by the card.
class _Sys {
  static const green = Color(0xFF30D158);
  static const yellow = Color(0xFFFFD60A);
  static const indigo = Color(0xFF5E5CE6);
  static const orange = Color(0xFFFF9F0A);
  static const pink = Color(0xFFFF375F);
  static const label = Colors.white;
  static const secondary = Color(0x99EBEBF5); // 60%
  static const fill = Color(0x29787880); // secondarySystemFill
  static const separator = Color(0x33FFFFFF);
}

/// Home "Your Lobby" card, styled after Apple's HIG: continuous corners,
/// a quiet material surface, clear type hierarchy and one primary action.
/// Shows the active café session when there is one, otherwise a prompt to
/// find a setup, plus quick links to squad up, ranked play and sessions.
class HomeLobbyCard extends StatefulWidget {
  const HomeLobbyCard({
    super.key,
    required this.locked,
    required this.cafeName,
    required this.gameName,
    required this.onPrimary,
    required this.onSquadUp,
    required this.onRanked,
    required this.onSessions,
  });

  /// True when the player has a confirmed/pending booking.
  final bool locked;
  final String cafeName;
  final String gameName;
  final VoidCallback onPrimary;
  final VoidCallback onSquadUp;
  final VoidCallback onRanked;
  final VoidCallback onSessions;

  @override
  State<HomeLobbyCard> createState() => _HomeLobbyCardState();
}

class _HomeLobbyCardState extends State<HomeLobbyCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  TextStyle _text(double size, Color color, {FontWeight? weight}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        letterSpacing: size >= 20 ? -0.5 : (size >= 15 ? -0.3 : -0.1),
        height: 1.25,
      );

  @override
  Widget build(BuildContext context) {
    final locked = widget.locked;
    final accent = locked ? _Sys.yellow : _Sys.green;

    return Container(
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
          Positioned(
            bottom: -110,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x2600DC00), Color(0x0000DC00)],
                  ),
                ),
              ),
            ),
          ),
          // A faint wash of the state colour in the corner.
          Positioned(
            top: -80,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: 0.16),
                      accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(accent),
                const SizedBox(height: 14),
                locked ? _session() : _prompt(),
                const SizedBox(height: 16),
                _primaryButton(accent),
                const SizedBox(height: 16),
                Container(height: 0.5, color: _Sys.separator),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _action(
                        Icons.person_add_alt_1_rounded,
                        'Squad Up',
                        _Sys.indigo,
                        widget.onSquadUp,
                      ),
                    ),
                    Expanded(
                      child: _action(
                        Icons.emoji_events_rounded,
                        'Ranked',
                        _Sys.orange,
                        widget.onRanked,
                      ),
                    ),
                    Expanded(
                      child: _action(
                        Icons.history_rounded,
                        'Sessions',
                        _Sys.pink,
                        widget.onSessions,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(Color accent) {
    return Row(
      children: [
        Text(
          'YOUR LOBBY',
          style: _text(
            12,
            _Sys.secondary,
            weight: FontWeight.w600,
          ).copyWith(letterSpacing: 0.6),
        ),
        const Spacer(),
        FadeTransition(
          opacity: Tween(begin: 0.35, end: 1.0).animate(_pulse),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          widget.locked ? 'Booked' : 'Open',
          style: _text(13, accent, weight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _prompt() {
    return Row(
      children: [
        _glyph(Icons.sports_esports_rounded, _Sys.green, size: 52),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ready to lock in?',
                style: _text(22, _Sys.label, weight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                'Book a café setup, squad up, or jump into ranked.',
                style: _text(14, _Sys.secondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _session() {
    return Row(
      children: [
        _glyph(Icons.storefront_rounded, _Sys.yellow, size: 52),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.cafeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _text(22, _Sys.label, weight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                '${widget.gameName} · Pull up with the squad',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _text(14, _Sys.secondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Rounded "app icon" tile with a tinted fill.
  Widget _glyph(IconData icon, Color color, {double size = 44}) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(size * 0.5)),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.34),
            color.withValues(alpha: 0.14),
          ],
        ),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }

  Widget _primaryButton(Color accent) {
    final locked = widget.locked;
    return _Pressable(
      onTap: () {
        Haptics.selection();
        widget.onPrimary();
      },
      child: Container(
        height: 50,
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          color: accent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              locked ? Icons.play_arrow_rounded : Icons.search_rounded,
              color: Colors.black,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              locked ? 'Open Session' : 'Find a Setup',
              style: _text(16, Colors.black, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, Color color, VoidCallback onTap) {
    return _Pressable(
      onTap: () {
        Haptics.selection();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const ShapeDecoration(
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              color: _Sys.fill,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: _text(12, _Sys.label, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Subtle scale-down on press, like iOS controls.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _down ? 0.75 : 1,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}
