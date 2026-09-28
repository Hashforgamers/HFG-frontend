import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:hash/utils/widgets/home_section_title.dart';
import 'package:hash/utils/widgets/loader.dart';

class ArenaDetailConsolesSection extends StatelessWidget {
  final RxBool isLoading;
  final RxList<dynamic> games;
  final ValueChanged<String>? onConsoleTap;

  const ArenaDetailConsolesSection({
    super.key,
    required this.isLoading,
    required this.games,
    this.onConsoleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionTitle(title: 'Choose your ', accent: 'Setup'),
        const SizedBox(height: 4),
        Text(
          'Tap a console to start booking',
          style: HomeTokens.body(HomeTokens.textTertiary, size: 12.5),
        ),
        const SizedBox(height: 14),
        Obx(() {
          if (isLoading.value) {
            return const SizedBox(
              height: 72,
              child: Center(child: AppLinearLoader()),
            );
          }
          var types = _consoleTypes();
          if (types.isEmpty) {
            types = const [
              {'key': 'pc', 'label': 'PC'},
              {'key': 'ps5', 'label': 'PS5'},
              {'key': 'xbox', 'label': 'XBOX'},
              {'key': 'vr_headset', 'label': 'VR'},
            ];
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final width = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final t in types)
                    SizedBox(
                      width: width,
                      child: _consoleTile(
                        t['label'] ?? '',
                        consoleType: t['key'] ?? '',
                      ),
                    ),
                ],
              );
            },
          );
        }),
      ],
    );
  }

  List<Map<String, String>> _consoleTypes() {
    final seen = <String>{};
    final types = <Map<String, String>>[];
    for (final g in games) {
      if (g is! Map) continue;
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
              ? true
              : _truthy(availableValue);
          final availableCount = countValue == null ? 1 : _asInt(countValue);
          if (!isAvailable || availableCount <= 0) continue;
          final rawLabel =
              (c['console_display_name'] ??
                      c['console_slug'] ??
                      c['console_type'] ??
                      c['consoleType'] ??
                      c['type'] ??
                      '')
                  .toString()
                  .trim();
          final key = _normalizeConsoleType(rawLabel);
          final label = _consoleDisplayLabel(rawLabel);
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
        final availableCount = countValue == null
            ? (isAvailable ? 1 : 0)
            : _asInt(countValue);
        if (!isAvailable || availableCount <= 0) continue;
        final rawLabel =
            (g['console_display_name'] ??
                    g['console_slug'] ??
                    g['console_type'] ??
                    g['consoleType'] ??
                    g['type'] ??
                    g['game_platform'] ??
                    '')
                .toString()
                .trim();
        final key = _normalizeConsoleType(rawLabel);
        final label = _consoleDisplayLabel(rawLabel);
        if (key.isEmpty || label.isEmpty) continue;
        if (seen.add(key)) {
          types.add({'key': key, 'label': label});
        }
      }
    }
    return types;
  }

  Widget _consoleTile(String label, {required String consoleType}) {
    final fallbackIcon = _getConsoleFallbackIcon(label);
    final imageUrl = _getConsoleImage(label);
    return HomeCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      onTap: onConsoleTap == null ? null : () => onConsoleTap!(consoleType),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: HomeTokens.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: HomeTokens.green.withValues(alpha: 0.22),
              ),
            ),
            child: imageUrl.isEmpty
                ? Icon(fallbackIcon, color: HomeTokens.green, size: 22)
                : Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        Icon(fallbackIcon, color: HomeTokens.green, size: 22),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: HomeTokens.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text('Book now', style: HomeTokens.eyebrow(HomeTokens.green)),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: HomeTokens.textTertiary,
            size: 20,
          ),
        ],
      ),
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

  String _normalizeConsoleType(String consoleName) {
    final name = consoleName
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
    if (name.isEmpty) return '';
    if (name.contains('playstation 3') ||
        RegExp(r'\bps\s*3\b').hasMatch(name)) {
      return 'ps3';
    }
    if (name.contains('playstation 4') ||
        RegExp(r'\bps\s*4\b').hasMatch(name)) {
      return 'ps4';
    }
    if (name.contains('playstation 5') ||
        RegExp(r'\bps\s*5\b').hasMatch(name)) {
      return 'ps5';
    }
    if (name.contains('playstation') || RegExp(r'\bps\b').hasMatch(name)) {
      return 'playstation';
    }
    if (name.contains('xbox')) return 'xbox';
    if (name.contains('vr') || name.contains('virtual')) return 'vr_headset';
    if (name.contains('nintendo') || name.contains('switch')) {
      return 'nintendo_switch';
    }
    if (name.contains('steam') || name.contains('deck')) return 'steam_deck';
    if (name.contains('arcade')) return 'arcade_cabinet';
    if (name.contains('racing') || name.contains('rig')) return 'racing_rig';
    if (name.contains('simulator')) return 'simulator';
    if (name.contains('private') && name.contains('room')) {
      return 'private_room';
    }
    if (name.contains('vip') && name.contains('room')) return 'vip_room';
    if (name.contains('bootcamp') && name.contains('room')) {
      return 'bootcamp_room';
    }
    if (name.contains('pc') || name.contains('computer')) return 'pc';
    return name.replaceAll(' ', '_');
  }

  String _consoleDisplayLabel(String consoleName) {
    switch (_normalizeConsoleType(consoleName)) {
      case 'ps3':
        return 'PS3';
      case 'ps4':
        return 'PS4';
      case 'ps5':
        return 'PS5';
      case 'playstation':
        return 'PLAYSTATION';
      case 'xbox':
        return 'XBOX';
      case 'vr_headset':
        return 'VR';
      case 'nintendo_switch':
        return 'NINTENDO SWITCH';
      case 'steam_deck':
        return 'STEAM DECK';
      case 'arcade_cabinet':
        return 'ARCADE CABINET';
      case 'racing_rig':
        return 'RACING RIG';
      case 'simulator':
        return 'SIMULATOR';
      case 'private_room':
        return 'PRIVATE ROOM';
      case 'vip_room':
        return 'VIP ROOM';
      case 'bootcamp_room':
        return 'BOOTCAMP ROOM';
      case 'pc':
        return 'PC';
      default:
        return consoleName.replaceAll('_', ' ').toUpperCase();
    }
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
}
