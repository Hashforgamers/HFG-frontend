import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchResultFeatureChips extends StatelessWidget {
  final List<String> features;
  final int maxToShow;

  const SearchResultFeatureChips({
    super.key,
    required this.features,
    this.maxToShow = 4,
  });

  @override
  Widget build(BuildContext context) {
    final cleaned = features
        .map((f) => f.toString().replaceAll(RegExp(r'[{}]'), '').trim())
        .where((f) => f.isNotEmpty)
        .toSet()
        .toList();
    final visible = cleaned.take(maxToShow).toList();
    final remaining = cleaned.length - visible.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final f in visible) _FeaturePill(label: f),
        if (remaining > 0) _MorePill(count: remaining),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        color: Color(0x3D767680),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(label), size: 14, color: const Color(0xFF30D158)),
          const SizedBox(width: 5),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: -.1,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String s) {
    final t = s.toLowerCase();
    if (t.contains('24/7') || t.contains('24x7')) return Icons.schedule_rounded;
    if (t.contains('park')) return Icons.local_parking_rounded;
    if (t.contains('wash') || t.contains('toilet')) return Icons.wc_rounded;
    if (t.contains('sound') || t.contains('audio'))
      return Icons.speaker_rounded;
    if (t.contains('pc')) return Icons.computer_rounded;
    if (t.contains('ps') || t.contains('playstation')) {
      return Icons.sports_esports_rounded;
    }
    if (t.contains('xbox')) return Icons.sports_esports_rounded;
    if (t.contains('vr')) return Icons.vrpano_rounded;
    if (t.contains('wifi') || t.contains('internet')) return Icons.wifi_rounded;
    if (t.contains('snack') || t.contains('food')) {
      return Icons.fastfood_rounded;
    }
    if (t.contains('ac') || t.contains('air')) return Icons.ac_unit_rounded;
    if (t.contains('tournament') || t.contains('event')) {
      return Icons.emoji_events_rounded;
    }
    if (t.contains('console')) return Icons.sports_esports_rounded;
    return Icons.label_rounded;
  }
}

class _MorePill extends StatelessWidget {
  const _MorePill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        color: Color(0x1F767680),
      ),
      child: Text(
        '+$count more',
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: const Color(0x99EBEBF5),
        ),
      ),
    );
  }
}
