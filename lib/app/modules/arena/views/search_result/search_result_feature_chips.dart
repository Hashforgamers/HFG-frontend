import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchResultFeatureChips extends StatelessWidget {
  final List<String> features;
  final int maxToShow;

  const SearchResultFeatureChips({
    super.key,
    required this.features,
    this.maxToShow = 5,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF338125).withValues(alpha: .22),
            const Color(0xFF1A1A1A).withValues(alpha: .22),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF338125).withValues(alpha: .35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF338125).withValues(alpha: .12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(label), size: 14, color: const Color(0xFF7FF16A)),
          const SizedBox(width: 6),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7FF16A),
              letterSpacing: .1,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String s) {
    final t = s.toLowerCase();
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .15)),
      ),
      child: Text(
        '+$count more',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
    );
  }
}
