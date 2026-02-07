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
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 70,
          child: Obx(() {
            if (isLoading.value) {
              return const Center(child: RainbowLoadingBar());
            }

            // Build unique console types from vendor games list
            final seen = <String>{};
            final types = <String>[];
            for (final g in games) {
              if (g is! Map) continue;
              final consoles = g['consoles'];
              if (consoles is List && consoles.isNotEmpty) {
                for (final c in consoles) {
                  if (c is! Map) continue;
                  final raw = (c['console_type'] ?? '').toString();
                  final type = raw.trim().toLowerCase();
                  if (type.isEmpty) continue;
                  if (seen.add(type)) {
                    types.add(raw);
                  }
                }
              } else {
                final raw = (g['game_platform'] ?? '').toString();
                final type = raw.trim().toLowerCase();
                if (type.isEmpty) continue;
                if (seen.add(type)) {
                  types.add(raw);
                }
              }
            }

            if (types.isEmpty) {
              return ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _consoleIcon(
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075080/pc_ah5ulv.png',
                    'PC',
                  ),
                  _consoleIcon(
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075086/xbox_fmz0bn.png',
                    'XBOX',
                  ),
                  _consoleIcon(
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075082/ps_krf4kw.png',
                    'PS5',
                  ),
                  _consoleIcon(
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075086/vr_rzqkbq.png',
                    'VR',
                  ),
                ],
              );
            }

            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 0),
              itemBuilder: (context, index) {
                final String name = types[index].toUpperCase();
                final String iconPath = _getConsoleIcon(types[index]);

                return _consoleIcon(iconPath, name);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _consoleIcon(String path, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xff1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.network(
              path,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getConsoleIcon(String consoleName) {
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
    return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075080/pc_ah5ulv.png';
  }
}
