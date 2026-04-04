import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArenaDetailInfoSection extends StatelessWidget {
  final String title;
  final String address;
  final String openingHours;

  const ArenaDetailInfoSection({
    super.key,
    required this.title,
    required this.address,
    required this.openingHours,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedHours = _normalizeOpeningHours(openingHours);
    final accentColor = _timingAccentColor(normalizedHours);
    final timingLabel = _timingLabel(normalizedHours);
    final timingBadge = _timingBadge(normalizedHours);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;
            final cards = [
              _InfoCard(
                icon: Icons.place_rounded,
                title: 'Location',
                value: address,
                accentColor: const Color(0xFF7C4DFF),
                useMarquee: true,
              ),
              _TimingCard(
                accentColor: accentColor,
                badge: timingBadge,
                label: timingLabel,
                value: normalizedHours,
              ),
            ];

            if (isCompact) {
              return Column(
                children: [cards[0], const SizedBox(height: 10), cards[1]],
              );
            }

            return Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ],
            );
          },
        ),
      ],
    );
  }

  String _normalizeOpeningHours(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return 'Timings unavailable';

    final normalized = trimmed
        .replaceAll('to', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (_isAllDay(normalized)) {
      return '12:00 AM - 11:59 PM';
    }

    if (RegExp(r'\b(am|pm)\b', caseSensitive: false).hasMatch(normalized)) {
      return normalized.replaceAllMapped(
        RegExp(r'\b(am|pm)\b', caseSensitive: false),
        (match) => match.group(0)!.toUpperCase(),
      );
    }

    return normalized.replaceAllMapped(
      RegExp(r'(?<!\d)([01]?\d|2[0-4]):([0-5]\d)(?!\d)'),
      (match) =>
          _formatTimeToMeridiem(match.group(1) ?? '', match.group(2) ?? ''),
    );
  }

  bool _isAllDay(String value) {
    final lower = value.toLowerCase();
    return lower.contains('24/7') ||
        lower.contains('24 x 7') ||
        lower.contains('24x7') ||
        lower.contains('00:00 - 24:00') ||
        lower.contains('00:00-24:00') ||
        lower.contains('12:00 am - 11:59 pm') ||
        lower.contains('12:00 am-11:59 pm');
  }

  bool _isClosed(String value) {
    final lower = value.toLowerCase();
    return lower.contains('closed') || lower.contains('unavailable');
  }

  String _timingLabel(String value) {
    if (_isClosed(value)) return 'Currently Closed';
    if (_isAllDay(value)) return 'Open All Day';
    return 'Today\'s Hours';
  }

  String _timingBadge(String value) {
    if (_isClosed(value)) return 'CLOSED';
    if (_isAllDay(value)) return '24/7';
    return 'HOURS';
  }

  Color _timingAccentColor(String value) {
    if (_isClosed(value)) return const Color(0xFFFF5252);
    if (_isAllDay(value)) return const Color(0xFF00DC00);
    return const Color(0xFFFFB300);
  }

  String _formatTimeToMeridiem(String hourText, String minuteText) {
    final hour = int.tryParse(hourText);
    final minute = int.tryParse(minuteText);
    if (hour == null || minute == null) {
      return '$hourText:$minuteText';
    }

    if (hour == 24 && minute == 0) {
      return '12:00 AM';
    }

    final normalizedHour = hour.clamp(0, 23);
    final period = normalizedHour >= 12 ? 'PM' : 'AM';
    final twelveHour = switch (normalizedHour) {
      0 => 12,
      12 => 12,
      _ => normalizedHour % 12,
    };

    return '$twelveHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.accentColor,
    this.useMarquee = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color accentColor;
  final bool useMarquee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (useMarquee)
                  SizedBox(
                    height: 16,
                    child: _DetailMarqueeText(
                      text: value,
                      blankSpace: 24,
                      velocity: 18,
                      pause: const Duration(milliseconds: 1200),
                      fadeFraction: 0.08,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimingCard extends StatelessWidget {
  const _TimingCard({
    required this.accentColor,
    required this.badge,
    required this.label,
    required this.value,
  });

  final Color accentColor;
  final String badge;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.12),
            const Color(0xFF181818),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.schedule_rounded, color: accentColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.inter(
                          color: accentColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailMarqueeText extends StatefulWidget {
  const _DetailMarqueeText({
    required this.text,
    required this.style,
    this.blankSpace = 18,
    this.velocity = 22,
    this.pause = const Duration(milliseconds: 900),
    this.fadeFraction = 0.1,
  });

  final String text;
  final TextStyle style;
  final double blankSpace;
  final double velocity;
  final Duration pause;
  final double fadeFraction;

  @override
  State<_DetailMarqueeText> createState() => _DetailMarqueeTextState();
}

class _DetailMarqueeTextState extends State<_DetailMarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Duration? _activeDuration;
  int _generation = 0;
  bool _waitingForRestart = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      _waitingForRestart = true;
      final generation = _generation;
      Future<void>.delayed(widget.pause, () {
        if (!mounted || generation != _generation) return;
        _waitingForRestart = false;
        _controller.forward(from: 0);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  void _startAnimation(Duration duration) {
    final durationChanged = _activeDuration != duration;
    _activeDuration = duration;

    if (durationChanged) {
      _generation++;
      _waitingForRestart = false;
      _controller
        ..stop()
        ..duration = duration
        ..forward(from: 0);
      return;
    }

    if (_controller.isAnimating || _waitingForRestart) return;

    _generation++;
    _controller
      ..duration = duration
      ..forward(from: 0);
  }

  void _stopAnimation() {
    _generation++;
    _waitingForRestart = false;
    _activeDuration = null;
    _controller
      ..stop()
      ..value = 0;
  }

  Widget _buildFadedChild(Widget child) {
    return ShaderMask(
      shaderCallback: (bounds) {
        final fade = widget.fadeFraction.clamp(0.0, 0.45);
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0, fade, 1 - fade, 1],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final textWidth = _measureTextWidth(widget.text, widget.style);

        if (textWidth <= maxWidth) {
          _stopAnimation();
          return Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          );
        }

        final distance = textWidth + widget.blankSpace;
        final seconds = distance / widget.velocity;
        _startAnimation(Duration(milliseconds: (seconds * 1000).round()));

        return SizedBox(
          width: maxWidth,
          child: _buildFadedChild(
            ClipRect(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  final offset = -distance * _controller.value;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: 0,
                  maxWidth: double.infinity,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.text, style: widget.style),
                      SizedBox(width: widget.blankSpace),
                      Text(widget.text, style: widget.style),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
