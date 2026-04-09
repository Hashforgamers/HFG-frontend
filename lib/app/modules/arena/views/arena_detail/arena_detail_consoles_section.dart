import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/utils/widgets/loader.dart';

class ArenaDetailConsolesSection extends StatelessWidget {
  final RxBool isLoading;
  final RxList<dynamic> games;

  const ArenaDetailConsolesSection({
    super.key,
    required this.isLoading,
    required this.games,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Consoles',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 78,
          child: Obx(() {
            if (isLoading.value) {
              return const Center(child: AppLinearLoader());
            }

            final seen = <String>{};
            final types = <Map<String, String>>[];
            for (final g in games) {
              if (g is! Map) continue;
              final parentAvailableValue =
                  g['available'] ??
                  g['is_available'] ??
                  g['isAvailable'] ??
                  g['bookable'];
              final parentCountValue =
                  g['count'] ??
                  g['available_slot'] ??
                  g['available_slots'] ??
                  g['total_slots'];
              final parentIsAvailable = _truthy(parentAvailableValue);
              final parentAvailableCount = _asInt(parentCountValue);
              final consoles = g['consoles'];
              if (consoles is List && consoles.isNotEmpty) {
                for (final c in consoles) {
                  if (c is! Map) continue;
                  final availableValue =
                      c['available'] ??
                      c['is_available'] ??
                      c['isAvailable'] ??
                      c['bookable'];
                  final countValue =
                      c['inventory_count'] ??
                      c['available_slot'] ??
                      c['available_slots'] ??
                      c['count'] ??
                      c['total_slots'];
                  final isAvailable = availableValue == null
                      ? parentIsAvailable
                      : _truthy(availableValue);
                  final availableCount = countValue == null
                      ? parentAvailableCount
                      : _asInt(countValue);
                  if (!isAvailable || availableCount <= 0) continue;
                  final key =
                      (c['console_type'] ??
                              c['console_slug'] ??
                              c['console_display_name'] ??
                              '')
                          .toString()
                          .trim()
                          .toLowerCase();
                  final label =
                      (c['console_display_name'] ??
                              c['console_slug'] ??
                              c['console_type'] ??
                              '')
                          .toString()
                          .trim();
                  if (key.isEmpty || label.isEmpty) continue;
                  if (seen.add(key)) {
                    types.add({'key': key, 'label': label});
                  }
                }
              } else {
                final availableValue =
                    g['available'] ??
                    g['is_available'] ??
                    g['isAvailable'] ??
                    g['bookable'];
                final countValue =
                    g['count'] ??
                    g['available_slot'] ??
                    g['available_slots'] ??
                    g['total_slots'];
                final isAvailable = _truthy(availableValue);
                final availableCount = _asInt(countValue);
                if (!isAvailable || availableCount <= 0) continue;
                final key =
                    (g['console_display_name'] ??
                            g['console_slug'] ??
                            g['game_platform'] ??
                            '')
                        .toString()
                        .trim()
                        .toLowerCase();
                final label =
                    (g['console_display_name'] ??
                            g['console_slug'] ??
                            g['game_platform'] ??
                            '')
                        .toString()
                        .trim();
                if (key.isEmpty || label.isEmpty) continue;
                if (seen.add(key)) {
                  types.add({'key': key, 'label': label});
                }
              }
            }

            if (types.isEmpty) {
              return ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _consoleIcon('PC'),
                  _consoleIcon('XBOX'),
                  _consoleIcon('PS5'),
                  _consoleIcon('VR'),
                ],
              );
            }

            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 0),
              itemBuilder: (context, index) {
                final name = types[index]['label'] ?? '';
                return _consoleIcon(name);
              },
            );
          }),
        ),
      ],
    );
  }

  bool _truthy(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'open';
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Widget _consoleIcon(String label) {
    final fallbackIcon = _getConsoleFallbackIcon(label);
    final accent = _getConsoleAccentColor(label);
    final imageUrl = _getConsoleImage(label);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.28),
                  accent.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(color: accent.withValues(alpha: 0.38)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: imageUrl.isEmpty
                  ? Icon(fallbackIcon, color: accent, size: 22)
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(fallbackIcon, color: accent, size: 22),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            height: 16,
            child: _ConsoleMarqueeText(
              text: label,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _getConsoleImage(String consoleName) {
    final lower = consoleName.toLowerCase();
    if (lower.contains('xbox')) {
      return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075086/xbox_fmz0bn.png';
    }
    if (lower.contains('playstation') || lower.contains('ps')) {
      return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075082/ps_krf4kw.png';
    }
    if (lower.contains('vr')) {
      return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075086/vr_rzqkbq.png';
    }
    if (lower.contains('switch') || lower.contains('nintendo')) {
      return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/gaming-pad-01_byibeu.png';
    }
    if (lower.contains('vip') && lower.contains('room')) {
      return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/crown_mzzqhy.png';
    }
    if (lower.contains('pc')) {
      return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075080/pc_ah5ulv.png';
    }
    return '';
  }

  IconData _getConsoleFallbackIcon(String consoleName) {
    final lower = consoleName.toLowerCase();
    if (lower.contains('xbox')) {
      return Icons.gamepad_rounded;
    }
    if (lower.contains('playstation') || lower.contains('ps')) {
      return Icons.sports_esports_rounded;
    }
    if (lower.contains('vr')) {
      return Icons.view_in_ar_rounded;
    }
    if (lower.contains('switch') || lower.contains('nintendo')) {
      return Icons.gamepad_rounded;
    }
    if (lower.contains('steam') || lower.contains('deck')) {
      return Icons.sports_esports_outlined;
    }
    if (lower.contains('arcade')) {
      return Icons.videogame_asset_outlined;
    }
    if (lower.contains('racing') || lower.contains('rig')) {
      return Icons.sports_motorsports_outlined;
    }
    if (lower.contains('simulator')) {
      return Icons.rocket_launch_outlined;
    }
    if (lower.contains('private') && lower.contains('room')) {
      return Icons.meeting_room_outlined;
    }
    if (lower.contains('vip') && lower.contains('room')) {
      return Icons.workspace_premium_outlined;
    }
    if (lower.contains('bootcamp') && lower.contains('room')) {
      return Icons.groups_2_outlined;
    }
    return Icons.desktop_windows_rounded;
  }

  Color _getConsoleAccentColor(String consoleName) {
    final lower = consoleName.toLowerCase();
    if (lower.contains('xbox')) {
      return const Color(0xFF2EBE60);
    }
    if (lower.contains('playstation') || lower.contains('ps')) {
      return const Color(0xFF2F6BFF);
    }
    if (lower.contains('vr')) {
      return const Color(0xFF9B5CFF);
    }
    if (lower.contains('switch') || lower.contains('nintendo')) {
      return const Color(0xFFFF4D6D);
    }
    if (lower.contains('steam') || lower.contains('deck')) {
      return const Color(0xFF66D9FF);
    }
    if (lower.contains('arcade')) {
      return const Color(0xFFFF8A3D);
    }
    if (lower.contains('racing') || lower.contains('rig')) {
      return const Color(0xFFFFC14D);
    }
    if (lower.contains('simulator')) {
      return const Color(0xFF7CF5C8);
    }
    if (lower.contains('private') && lower.contains('room')) {
      return const Color(0xFFFF7A59);
    }
    if (lower.contains('vip') && lower.contains('room')) {
      return const Color(0xFFFFD34D);
    }
    if (lower.contains('bootcamp') && lower.contains('room')) {
      return const Color(0xFF8B7CFF);
    }
    return const Color(0xFF00C2FF);
  }
}

class _ConsoleMarqueeText extends StatefulWidget {
  const _ConsoleMarqueeText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_ConsoleMarqueeText> createState() => _ConsoleMarqueeTextState();
}

class _ConsoleMarqueeTextState extends State<_ConsoleMarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
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
    if (_controller.duration != duration || !_controller.isAnimating) {
      _controller.duration = duration;
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final textWidth = _measureTextWidth(widget.text, widget.style);

        if (textWidth <= maxWidth) {
          _controller.stop();
          return Center(
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          );
        }

        const blankSpace = 18.0;
        const velocity = 24.0;
        final distance = textWidth + blankSpace;
        final seconds = distance / velocity;
        _startAnimation(Duration(milliseconds: (seconds * 1000).round()));

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: maxWidth,
            maxWidth: double.infinity,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, _) {
                final offset = -distance * _controller.value;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.text, style: widget.style),
                      const SizedBox(width: blankSpace),
                      Text(widget.text, style: widget.style),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
