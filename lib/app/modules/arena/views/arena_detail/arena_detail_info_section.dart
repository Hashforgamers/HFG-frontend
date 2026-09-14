import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';

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

    final closed = _isClosed(normalizedHours);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name and status read together: whether the venue is open is the
        // first thing anyone wants, and it used to sit in a separate card
        // below the address.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(title, style: HomeTokens.title(22))),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: _StatusPill(
                color: accentColor,
                label: closed ? 'Closed' : 'Open now',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // One card instead of two stacked ones: the address and the hours are
        // the same kind of information and were competing for attention.
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: HomeTokens.surface,
            borderRadius: BorderRadius.circular(HomeTokens.radius),
            border: Border.all(color: HomeTokens.hairline),
          ),
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.place_rounded,
                accent: HomeTokens.green,
                label: 'Location',
                value: address,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              _InfoRow(
                icon: Icons.schedule_rounded,
                accent: accentColor,
                label: timingLabel,
                value: normalizedHours,
                trailing: timingBadge,
              ),
            ],
          ),
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
      return 'Open 24 hours';
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

  /// True when start and end are the same time, which vendors use to mean
  /// "open round the clock" but which renders as an empty-looking range.
  bool _isSameStartAndEnd(String value) {
    final match = RegExp(
      r'^\s*(.+?)\s*-\s*(.+?)\s*$',
    ).firstMatch(value.toLowerCase());
    if (match == null) return false;
    final start = match.group(1)?.trim();
    final end = match.group(2)?.trim();
    return start != null && start.isNotEmpty && start == end;
  }

  bool _isAllDay(String value) {
    final lower = value.toLowerCase();
    if (_isSameStartAndEnd(lower)) return true;
    return lower.contains('open 24 hours') ||
        lower.contains('24/7') ||
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
    // Open and closed are the only states worth colouring. The badge text
    // already distinguishes all-day from limited hours, so a third colour only
    // competed with the page's accent - and gold belongs to rewards.
    if (_isClosed(value)) return const Color(0xFFFF5252);
    return HomeTokens.green;
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label.toUpperCase(), style: HomeTokens.eyebrow(color)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: HomeTokens.eyebrow(HomeTokens.textTertiary)),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(trailing!, style: HomeTokens.eyebrow(accent)),
          ),
        ],
      ],
    );
  }
}
