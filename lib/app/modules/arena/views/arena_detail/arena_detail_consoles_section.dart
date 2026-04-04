import 'dart:convert';

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

  String _prettyJson(dynamic value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

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
          height: 86,
          child: Obx(() {
            if (isLoading.value) {
              return const Center(child: AppLinearLoader());
            }

            // Build unique console types from every usable source field.
            final seen = <String>{};
            final types = <String>[];
            final summaries = <Map<String, dynamic>>[];
            debugPrint(
              'Available consoles raw games ->\n${_prettyJson(games.toList())}',
            );
            for (final g in games) {
              if (g is! Map) continue;
              final game = Map<String, dynamic>.from(g);
              final consoles = game['consoles'];
              final rawConsoleValues = <String>[];

              void collectRawConsole(dynamic value) {
                final raw = value?.toString() ?? '';
                final normalized = _normalizeConsoleType(raw);
                if (normalized.isEmpty) return;
                rawConsoleValues.add(raw);
                if (seen.add(normalized)) {
                  types.add(normalized);
                }
              }

              if (consoles is List) {
                for (final c in consoles) {
                  if (c is! Map) continue;
                  final console = Map<String, dynamic>.from(c);
                  if (!_isConsoleAvailable(console)) continue;
                  collectRawConsole(
                    console['console_display_name'] ??
                        console['console_slug'] ??
                        console['console_type'] ??
                        console['consoleType'] ??
                        console['type'],
                  );
                }
              }

              final hasExplicitConsoleInventory =
                  consoles is List && consoles.isNotEmpty;
              if (!hasExplicitConsoleInventory &&
                  rawConsoleValues.isEmpty &&
                  _isGameAvailable(game)) {
                collectRawConsole(game['console_display_name']);
                collectRawConsole(game['console_slug']);
                collectRawConsole(game['console_type']);
                collectRawConsole(game['game_platform']);
              }

              summaries.add({
                'game_name':
                    game['game_name'] ??
                    game['name'] ??
                    game['title'] ??
                    'Unknown',
                'game_type':
                    game['game_type'] ??
                    game['gameType'] ??
                    game['game_platform'] ??
                    game['platform_type'] ??
                    game['console_type'] ??
                    game['platform'],
                'console_types': rawConsoleValues,
                'consoles': game['consoles'],
                'available': _isGameAvailable(game),
              });
            }

            debugPrint(
              'Available consoles summary ->\n${_prettyJson(summaries)}',
            );
            debugPrint('Available console types ->\n${_prettyJson(types)}');

            if (types.isEmpty) {
              return Center(
                child: Text(
                  'No consoles available right now',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: types.length,
              separatorBuilder: (_, index) => const SizedBox(width: 0),
              itemBuilder: (context, index) {
                return _consoleIcon(types[index]);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _consoleIcon(String consoleType) {
    final imageUrl = _getConsoleIcon(consoleType);
    final iconData = _getConsoleFallbackIcon(consoleType);
    final label = _getConsoleLabel(consoleType);
    final accentColor = _getConsoleAccentColor(consoleType);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withValues(alpha: 0.28),
                  accentColor.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(color: accentColor.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              borderRadius: BorderRadius.circular(12),
            ),
            child: imageUrl != null
                ? Padding(
                    padding: const EdgeInsets.all(9),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, error, stackTrace) =>
                          _buildFallbackIcon(iconData, accentColor),
                    ),
                  )
                : _buildFallbackIcon(iconData, accentColor),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 62,
            child: _ConsoleMarqueeText(
              text: label,
              blankSpace: 18,
              velocity: 14,
              pause: const Duration(milliseconds: 1200),
              fadeFraction: 0.14,
              style: GoogleFonts.inter(
                fontSize: 9,
                height: 1.1,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon(IconData iconData, Color accentColor) {
    return Center(child: Icon(iconData, color: accentColor, size: 24));
  }

  bool _isConsoleAvailable(Map<String, dynamic> console) {
    final bookable = console['bookable'] == true;
    final inventory = _toInt(
      console['inventory_count'] ??
          console['available_slot'] ??
          console['available_slots'] ??
          console['available_count'] ??
          console['count'] ??
          console['quantity'],
    );
    final hasBookingLink =
        console['booking_game_id'] != null ||
        console['available_game_id'] != null ||
        console['vendor_game_id'] != null;
    final hasPrice =
        (console['price_per_hour'] is num &&
            (console['price_per_hour'] as num) > 0) ||
        (console['default_price'] is num &&
            (console['default_price'] as num) > 0);
    final hasIdentity =
        console['id'] != null ||
        (console['model_number']?.toString().trim().isNotEmpty ?? false) ||
        (console['console_number']?.toString().trim().isNotEmpty ?? false);
    return bookable ||
        inventory > 0 ||
        hasBookingLink ||
        hasPrice ||
        hasIdentity;
  }

  bool _isGameAvailable(Map<String, dynamic> game) {
    final directAvailability = _toInt(
      game['available_slot'] ??
          game['available_slots'] ??
          game['available_count'] ??
          game['count'] ??
          game['quantity'] ??
          game['inventory_count'] ??
          game['total_slots'],
    );
    if (directAvailability > 0) {
      return true;
    }

    final consoles = game['consoles'];
    if (consoles is List) {
      return consoles.whereType<Map>().any(
        (console) => _isConsoleAvailable(Map<String, dynamic>.from(console)),
      );
    }

    return false;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _normalizeConsoleType(String consoleName) {
    final lower = consoleName
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
    if (lower.isEmpty) return '';
    if (lower.contains('xbox')) return 'xbox';
    if (lower.contains('playstation') || lower.contains('ps')) return 'ps5';
    if (lower.contains('vr') || lower.contains('virtual')) return 'vr_headset';
    if (lower.contains('nintendo') || lower.contains('switch')) {
      return 'nintendo_switch';
    }
    if (lower.contains('steam') || lower.contains('deck')) return 'steam_deck';
    if (lower.contains('arcade')) return 'arcade_cabinet';
    if (lower.contains('racing') || lower.contains('rig')) return 'racing_rig';
    if (lower.contains('simulator')) return 'simulator';
    if (lower.contains('private') && lower.contains('room')) {
      return 'private_room';
    }
    if (lower.contains('vip') && lower.contains('room')) return 'vip_room';
    if (lower.contains('bootcamp') && lower.contains('room')) {
      return 'bootcamp_room';
    }
    if (lower.contains('pc') || lower.contains('computer')) return 'pc';
    return lower;
  }

  String _getConsoleLabel(String consoleName) {
    switch (_normalizeConsoleType(consoleName)) {
      case 'pc':
        return 'PC';
      case 'xbox':
        return 'Xbox';
      case 'ps5':
        return 'PS5';
      case 'vr_headset':
        return 'VR Headset';
      case 'nintendo_switch':
        return 'Nintendo Switch';
      case 'steam_deck':
        return 'Steam Deck';
      case 'arcade_cabinet':
        return 'Arcade Cabinet';
      case 'racing_rig':
        return 'Racing Rig';
      case 'simulator':
        return 'Simulator';
      case 'private_room':
        return 'Private Room';
      case 'vip_room':
        return 'VIP Room';
      case 'bootcamp_room':
        return 'Bootcamp Room';
      default:
        return consoleName;
    }
  }

  String? _getConsoleIcon(String consoleName) {
    switch (_normalizeConsoleType(consoleName)) {
      case 'pc':
        return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075080/pc_ah5ulv.png';
      case 'xbox':
        return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075086/xbox_fmz0bn.png';
      case 'ps5':
        return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075082/ps_krf4kw.png';
      case 'vr_headset':
        return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075086/vr_rzqkbq.png';
      case 'nintendo_switch':
        return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/gaming-pad-01_byibeu.png';
      case 'vip_room':
        return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/crown_mzzqhy.png';
      default:
        return null;
    }
  }

  Color _getConsoleAccentColor(String consoleName) {
    switch (_normalizeConsoleType(consoleName)) {
      case 'pc':
        return const Color(0xFF42A5F5);
      case 'xbox':
        return const Color(0xFF4CAF50);
      case 'ps5':
        return const Color(0xFF3D5AFE);
      case 'vr_headset':
        return const Color(0xFFAB47BC);
      case 'nintendo_switch':
        return const Color(0xFFFF5252);
      case 'steam_deck':
        return const Color(0xFF00BCD4);
      case 'arcade_cabinet':
        return const Color(0xFFFF7043);
      case 'racing_rig':
        return const Color(0xFFFFB300);
      case 'simulator':
        return const Color(0xFF7E57C2);
      case 'private_room':
        return const Color(0xFF26A69A);
      case 'vip_room':
        return const Color(0xFFFFD54F);
      case 'bootcamp_room':
        return const Color(0xFFEC407A);
      default:
        return const Color(0xFF90A4AE);
    }
  }

  IconData _getConsoleFallbackIcon(String consoleName) {
    switch (_normalizeConsoleType(consoleName)) {
      case 'steam_deck':
        return Icons.sports_esports_outlined;
      case 'arcade_cabinet':
        return Icons.videogame_asset_outlined;
      case 'racing_rig':
        return Icons.sports_motorsports_outlined;
      case 'simulator':
        return Icons.rocket_launch_outlined;
      case 'private_room':
        return Icons.meeting_room_outlined;
      case 'vip_room':
        return Icons.workspace_premium_outlined;
      case 'bootcamp_room':
        return Icons.groups_2_outlined;
      default:
        return Icons.sports_esports_outlined;
    }
  }
}

class _ConsoleMarqueeText extends StatefulWidget {
  const _ConsoleMarqueeText({
    required this.text,
    required this.style,
    this.blankSpace = 16,
    this.velocity = 24,
    this.pause = const Duration(milliseconds: 900),
    this.fadeFraction = 0.12,
  });

  final String text;
  final TextStyle style;
  final double blankSpace;
  final double velocity;
  final Duration pause;
  final double fadeFraction;

  @override
  State<_ConsoleMarqueeText> createState() => _ConsoleMarqueeTextState();
}

class _ConsoleMarqueeTextState extends State<_ConsoleMarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Duration? _activeDuration;
  int _animationGeneration = 0;
  bool _waitingForRestart = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      _waitingForRestart = true;
      final generation = _animationGeneration;
      Future<void>.delayed(widget.pause, () {
        if (!mounted || generation != _animationGeneration) return;
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
      _animationGeneration++;
      _waitingForRestart = false;
      _controller
        ..stop()
        ..duration = duration
        ..forward(from: 0);
      return;
    }

    if (_controller.isAnimating || _waitingForRestart) return;

    _animationGeneration++;
    _controller
      ..duration = duration
      ..forward(from: 0);
  }

  void _stopAnimation() {
    _animationGeneration++;
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

  Widget _buildStaticText() {
    return Text(
      widget.text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: widget.style,
    );
  }

  Widget _buildScrollingText(double distance) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: _buildFadedChild(
            ClipRect(
              child: SizedBox(
                height: 12,
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
          ),
        );
      },
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
          return _buildStaticText();
        }

        final distance = textWidth + widget.blankSpace;
        final seconds = distance / widget.velocity;
        _startAnimation(Duration(milliseconds: (seconds * 1000).round()));
        return _buildScrollingText(distance);
      },
    );
  }
}
