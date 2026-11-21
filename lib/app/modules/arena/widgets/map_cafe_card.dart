import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';

/// Cafe card for the Squad Up map carousel.
///
/// Everything shown is read from the `getAllGamingCafe` payload; any field
/// the API leaves empty is simply not rendered, so sparse cafes still look
/// finished rather than full of placeholders.
class MapCafeCard extends StatelessWidget {
  const MapCafeCard({
    super.key,
    required this.cafe,
    required this.name,
    required this.imageUrl,
    required this.isOpen,
    required this.distance,
    required this.onTap,
    required this.onDirections,
    required this.onOpenMaps,
  });

  final Map<String, dynamic> cafe;
  final String name;
  final String imageUrl;
  final bool isOpen;

  /// Resolves to `{'distance': '1.2 km', 'duration': '6 mins'}`.
  final Future<Map<String, String>> distance;
  final VoidCallback onTap;

  /// Null when the cafe has no coordinates.
  final VoidCallback? onDirections;
  final VoidCallback? onOpenMaps;

  static const _green = HomeTokens.green;
  static const _red = Color(0xFFFF5252);

  // ── Payload readers ──────────────────────────────────────────────────────

  String? get _area {
    final address = cafe['address'];
    if (address is! Map) return null;
    String clean(dynamic v) => (v ?? '').toString().trim();
    // addressLine2 usually ends with the locality ("…, Borivali").
    final line2 = clean(address['addressLine2']);
    final locality = line2.isEmpty
        ? clean(address['city'])
        : line2
              .split(',')
              .map((p) => p.trim())
              .lastWhere((p) => p.isNotEmpty, orElse: () => '');
    final state = clean(address['state']);
    final parts = [locality, state].where((p) => p.isNotEmpty).toSet();
    return parts.isEmpty ? null : parts.join(', ');
  }

  static TimeOfDay? _parseTime(dynamic raw) {
    final parts = (raw ?? '').toString().split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h % 24, minute: m);
  }

  static String _clock(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return t.minute == 0
        ? '$h $suffix'
        : '$h:${t.minute.toString().padLeft(2, '0')} $suffix';
  }

  /// "till 10 PM" when open, "opens 9 AM" when closed, "24 hrs" when the
  /// vendor uses the same start and end time.
  String? get _hoursHint {
    final open = _parseTime(cafe['opening_time']);
    final close = _parseTime(cafe['closing_time']);
    if (open == null || close == null) return null;
    if (open == close) return '24 hrs';
    return isOpen ? 'till ${_clock(close)}' : 'opens ${_clock(open)}';
  }

  bool get _isVerified {
    final status = (cafe['status'] ?? '').toString().toLowerCase();
    return status == 'verified' || status == 'active' || status == 'approved';
  }

  int get _photoCount {
    final images = cafe['images'];
    return images is List ? images.length : 0;
  }

  List<_Feature> get _features {
    final out = <_Feature>[];
    final payments = cafe['payment_methods'];
    if (payments is Map) {
      if (payments['Hash'] == true) {
        out.add(const _Feature(Icons.bolt_rounded, 'Hash Pay', gold: true));
      }
      if (payments['Pay at Cafe'] == true) {
        out.add(const _Feature(Icons.storefront_rounded, 'Pay at cafe'));
      }
    }
    // Vendors sometimes tick "24/7" while listing fixed hours; the hours are
    // what the status pill uses, so drop the contradicting chip.
    final open = _parseTime(cafe['opening_time']);
    final close = _parseTime(cafe['closing_time']);
    final fixedHours = open != null && close != null && open != close;
    final amenities = cafe['amenities'];
    if (amenities is List) {
      for (final a in amenities) {
        final raw = a is Map ? (a['name'] ?? '').toString() : a.toString();
        if (fixedHours && raw.trim() == '24/7') continue;
        if (a is Map && a['available'] == true) {
          final label = _prettyAmenity((a['name'] ?? '').toString());
          if (label.isNotEmpty) out.add(_Feature(_amenityIcon(label), label));
        } else if (a is String && a.trim().isNotEmpty) {
          final label = _prettyAmenity(a);
          out.add(_Feature(_amenityIcon(label), label));
        }
      }
    }
    return out;
  }

  static String _prettyAmenity(String raw) {
    final t = raw.trim().replaceAll('_', ' ');
    if (t.isEmpty) return '';
    if (t == '24/7') return 'Open 24/7';
    if (t.toLowerCase() == 'air conditioner') return 'AC';
    return t
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static IconData _amenityIcon(String label) {
    final l = label.toLowerCase();
    if (l == 'ac' || l.contains('air')) return Icons.ac_unit_rounded;
    if (l.contains('park')) return Icons.local_parking_rounded;
    if (l.contains('wash') || l.contains('toilet')) return Icons.wc_rounded;
    if (l.contains('seat')) return Icons.event_seat_rounded;
    if (l.contains('sound') || l.contains('audio')) {
      return Icons.speaker_rounded;
    }
    if (l.contains('24')) return Icons.schedule_rounded;
    if (l.contains('food') || l.contains('snack')) {
      return Icons.fastfood_rounded;
    }
    if (l.contains('wifi') || l.contains('internet')) return Icons.wifi_rounded;
    return Icons.check_circle_rounded;
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final statusColor = isOpen ? _green : _red;
    final hint = _hoursHint;
    final area = _area;
    final features = _features;

    return Semantics(
      button: true,
      label: '$name, ${isOpen ? 'open' : 'closed'}. Opens cafe details.',
      child: Material(
        color: HomeTokens.surface,
        borderRadius: BorderRadius.circular(HomeTokens.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HomeTokens.radius),
              border: Border.all(color: HomeTokens.hairline),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      const ColoredBox(color: HomeTokens.surface),
                  errorWidget: (_, _, _) => const _ImageFallback(),
                ),
                // Heavy bottom fade: the text sits on near-solid ink, the
                // top of the photo stays visible.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.3, 0.62, 1],
                      colors: [
                        Color(0x66000000),
                        Color(0x22000000),
                        Color(0xE00B0D12),
                        Color(0xFA0B0D12),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _GlassPill(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOpen ? 'Open' : 'Closed',
                            style: _pillText(statusColor),
                          ),
                          if (hint != null) ...[
                            Text(' · ', style: _pillText(Colors.white54)),
                            Text(hint, style: _pillText(Colors.white)),
                          ],
                        ],
                      ),
                      const Spacer(),
                      if (_isVerified) ...[
                        _GlassPill(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              color: _green,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text('Verified', style: _pillText(Colors.white)),
                          ],
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (_photoCount > 1)
                        _GlassPill(
                          children: [
                            const Icon(
                              Icons.photo_library_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_photoCount',
                              style: _pillText(Colors.white),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HomeTokens.title(18),
                      ),
                      const SizedBox(height: 4),
                      _MetaLine(area: area, distance: distance),
                      if (features.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _FeatureRow(features: features),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _CardButton(
                              primary: true,
                              icon: Icons.directions_rounded,
                              label: 'Directions',
                              onTap: onDirections,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CardButton(
                              icon: Icons.map_outlined,
                              label: 'Open in Maps',
                              onTap: onOpenMaps,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static TextStyle _pillText(Color color) => GoogleFonts.inter(
    color: color,
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
  );
}

class _Feature {
  const _Feature(this.icon, this.label, {this.gold = false});

  final IconData icon;
  final String label;

  /// Money-related features use the reward colour, as on home.
  final bool gold;
}

/// Area, distance and drive time on one line. Distance resolves async; the
/// area shows immediately.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.area, required this.distance});

  final String? area;
  final Future<Map<String, String>> distance;

  @override
  Widget build(BuildContext context) {
    final style = HomeTokens.body(HomeTokens.textSecondary, size: 12.5);
    return FutureBuilder<Map<String, String>>(
      future: distance,
      builder: (_, snap) {
        String? valid(String? v) =>
            (v == null || v.trim().isEmpty || v == '--') ? null : v;
        final dist = valid(snap.data?['distance']);
        final dur = valid(snap.data?['duration']);
        final parts = [area, dist, dur].whereType<String>().toList();
        if (parts.isEmpty) return const SizedBox.shrink();
        return Row(
          children: [
            const Icon(Icons.place_rounded, color: HomeTokens.green, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                parts.join('  ·  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Up to three feature chips, then a "+N" chip for the rest.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.features});

  final List<_Feature> features;

  @override
  Widget build(BuildContext context) {
    const maxShown = 3;
    final shown = features.take(maxShown).toList();
    final extra = features.length - shown.length;
    return SizedBox(
      height: 24,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final f in shown) ...[
            _chip(f.icon, f.label, f.gold ? HomeTokens.gold : HomeTokens.green),
            const SizedBox(width: 6),
          ],
          if (extra > 0) _chip(null, '+$extra', HomeTokens.textSecondary),
        ],
      ),
    );
  }

  Widget _chip(IconData? icon, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: HomeTokens.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: accent, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              color: HomeTokens.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = primary ? Colors.black : HomeTokens.textPrimary;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: primary
              ? const LinearGradient(
                  colors: [HomeTokens.greenBright, HomeTokens.green],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: primary ? null : Colors.white.withValues(alpha: 0.07),
          border: primary ? null : Border.all(color: HomeTokens.hairline),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: 17),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: fg,
                      fontSize: 12.5,
                      fontWeight: primary ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2130), Color(0xFF07140A)],
        ),
      ),
      child: Align(
        alignment: Alignment(0, -0.45),
        child: Icon(
          Icons.sports_esports_rounded,
          color: HomeTokens.green,
          size: 40,
        ),
      ),
    );
  }
}
