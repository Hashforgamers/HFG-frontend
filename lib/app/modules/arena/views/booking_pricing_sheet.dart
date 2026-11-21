import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hash/config/app_keys.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'booking_design.dart';

/// Read-only café rates for one platform (standard + game-specific, e.g. GTA 6).
/// Display only: app checkout keeps standard slot pricing, payable amount
/// always comes from the server booking/payment response.
class BookingPricingSheet extends StatefulWidget {
  const BookingPricingSheet({
    super.key,
    required this.vendorId,
    required this.gameId,
  });

  final int vendorId;

  /// Café platform row id (`available_game_id`), not a video-game catalog id.
  final int gameId;

  static Future<void> show(BuildContext context, int vendorId, int gameId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BookingColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BookingPricingSheet(vendorId: vendorId, gameId: gameId),
    );
  }

  @override
  State<BookingPricingSheet> createState() => _BookingPricingSheetState();
}

class _BookingPricingSheetState extends State<BookingPricingSheet> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = locator<RemoteRepoInterface>().fetchVendorPricing(
      widget.vendorId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (context, scroll) => FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return BookingEmptyState(
              icon: Icons.sell_outlined,
              title: 'Pricing unavailable',
              message: 'We could not load this café\'s rates.',
              tone: BookingPillTone.neutral,
              footnote: SizedBox(
                width: 200,
                child: BookingSecondaryButton(
                  label: 'Try again',
                  icon: Icons.refresh_rounded,
                  onPressed: () => setState(_load),
                ),
              ),
            );
          }
          final data = snap.data!;
          final currency = data['currency'] == 'INR' || data['currency'] == null
              ? '₹'
              : '${data['currency']} ';
          final platform = (data['platforms'] as List? ?? const [])
              .whereType<Map>()
              .firstWhere(
                (p) => p['available_game_id'] == widget.gameId,
                orElse: () => const {},
              );
          final standard = platform['standard'] as Map? ?? const {};
          final standardCards = (standard['rate_cards'] as List? ?? const [])
              .whereType<Map>()
              .toList();
          final special = (platform['game_specific'] as List? ?? const [])
              .whereType<Map>()
              .toList();

          return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BookingColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _h('Standard pricing'),
              if (standard['base_slot_price'] != null)
                _row(
                  'Per slot',
                  '$currency${standard['base_slot_price']}',
                  'Before offers, squad/controller adjustments and app fees',
                ),
              for (final c in standardCards) _card(c, currency),
              if (standard.isEmpty)
                _muted('No standard rates for this platform.'),
              const SizedBox(height: 20),
              _h('Game-specific pricing'),
              if (special.isEmpty)
                _muted('No game-specific rates for this platform.'),
              for (final c in special) _card(c, currency),
              const SizedBox(height: 16),
              _muted(
                'App bookings use standard slot pricing. The final amount is '
                'shown at checkout.',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _card(Map card, String currency) {
    final channels = (card['booking_channels'] as List? ?? const []);
    final variant = '${card['game_variant'] ?? ''}'.trim();
    final meta = [
      if (variant.isNotEmpty) variant,
      if (card['model_name'] != null) '${card['model_name']}',
      if (card['screen_size_inches'] != null) '${card['screen_size_inches']}"',
      if (card['controllers_included'] == true) 'controllers included',
    ].join(' · ');
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BookingColors.surfaceHigh,
        borderRadius: BorderRadius.circular(BookingRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${card['name'] ?? 'Rate card'}',
            style: _t(15, FontWeight.w700),
          ),
          if (meta.isNotEmpty) _muted(meta),
          for (final r in (card['rules'] as List? ?? const []).whereType<Map>())
            _row(_ruleLabel(r), _ruleAmount(r, currency), null),
          if (!channels.contains('app'))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Café dashboard bookings only',
                style: _t(12, FontWeight.w600, BookingColors.accentBright),
              ),
            ),
        ],
      ),
    );
  }

  String _ruleLabel(Map r) {
    final minP = r['min_players'], maxP = r['max_players'];
    final minM = r['min_minutes'], maxM = r['max_minutes'];
    final players = minP == maxP ? '$minP player' : '$minP–$maxP players';
    final mins = maxM == null ? '$minM+ min' : '$minM–$maxM min';
    return '$players · $mins';
  }

  String _ruleAmount(Map r, String currency) {
    final unit = (r['unit_minutes'] as num?) ?? 0;
    final per = unit == 0 ? 'session' : (unit == 60 ? 'hr' : '$unit min');
    return '$currency${r['amount']}/$per${r['per_player'] == true ? ' per player' : ''}';
  }

  TextStyle _t(double size, FontWeight w, [Color? c]) => GoogleFonts.inter(
    color: c ?? BookingColors.textPrimary,
    fontSize: size,
    fontWeight: w,
  );

  Widget _h(String s) => Text(s, style: _t(17, FontWeight.w700));

  Widget _muted(String s) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(s, style: _t(12, FontWeight.w500, BookingColors.textMuted)),
  );

  Widget _row(String label, String value, String? hint) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: _t(13, FontWeight.w500))),
            Text(value, style: _t(14, FontWeight.w700)),
          ],
        ),
        if (hint != null) _muted(hint),
      ],
    ),
  );
}

/// Display estimate for one session on a game-specific rate card, per the
/// backend rules: exactly one inclusive rule must match, else null (no
/// fallback to standard). Rounded half-up to 2 decimals.
double? estimateCardAmount(Map card, {required int minutes, int players = 1}) {
  bool inRange(num v, dynamic min, dynamic max) =>
      v >= ((min as num?) ?? 0) && (max == null || v <= (max as num));
  final matches = (card['rules'] as List? ?? const [])
      .whereType<Map>()
      .where(
        (r) =>
            inRange(minutes, r['min_minutes'], r['max_minutes']) &&
            inRange(players, r['min_players'], r['max_players']),
      )
      .toList();
  if (matches.length != 1) return null;
  final r = matches.single;
  var amount = double.tryParse('${r['amount']}');
  if (amount == null) return null;
  if (r['per_player'] == true) amount *= players;
  final unit = (r['unit_minutes'] as num?) ?? 0;
  if (unit != 0) amount *= minutes / unit;
  return (amount * 100 + 1e-9).roundToDouble() / 100;
}

/// Shows "which game will you play?" for a platform that has game-specific
/// cards. Returns the chosen card, `{}` for standard, or null if dismissed.
Future<Map<String, dynamic>?> pickPricingGame(
  BuildContext context, {
  required int vendorId,
  required int gameId,
}) async {
  List<Map> cards;
  try {
    final data = await locator<RemoteRepoInterface>().fetchVendorPricing(
      vendorId,
    );
    final platform = (data['platforms'] as List? ?? const [])
        .whereType<Map>()
        .firstWhere(
          (p) => p['available_game_id'] == gameId,
          orElse: () => const {},
        );
    cards = (platform['game_specific'] as List? ?? const [])
        .whereType<Map>()
        .toList();
  } catch (_) {
    return const {}; // pricing down: continue with standard slot pricing
  }
  if (cards.isEmpty || !context.mounted) return const {};

  TextStyle t(double s, FontWeight w, [Color? c]) => GoogleFonts.inter(
    color: c ?? BookingColors.textPrimary,
    fontSize: s,
    fontWeight: w,
  );
  String from(Map c) {
    final rules = (c['rules'] as List? ?? const []).whereType<Map>();
    if (rules.isEmpty) return '';
    final r = rules.first;
    final unit = (r['unit_minutes'] as num?) ?? 0;
    return 'from ₹${r['amount']}${unit == 0
        ? '/session'
        : unit == 60
        ? '/hr'
        : '/$unit min'}';
  }

  Widget option(
    String title,
    String sub,
    Map<String, dynamic> result, {
    String? coverQuery,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Material(
      color: BookingColors.surfaceHigh,
      borderRadius: BorderRadius.circular(BookingRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(BookingRadius.card),
        onTap: () => Navigator.of(context).pop(result),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _GameCover(query: coverQuery),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t(15, FontWeight.w700)),
                    if (sub.isNotEmpty)
                      Text(
                        sub,
                        style: t(12, FontWeight.w500, BookingColors.textMuted),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: BookingColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    backgroundColor: BookingColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What will you play?', style: t(18, FontWeight.w800)),
            Text(
              'Some games have their own rates at this café.',
              style: t(13, FontWeight.w500, BookingColors.textMuted),
            ),
            option('Any other game', 'Standard pricing', const {}),
            for (final c in cards)
              option(
                '${(c['game_variant'] ?? '').toString().trim().isEmpty ? c['name'] : c['game_variant']}',
                [
                  '${c['name']}',
                  if (c['screen_size_inches'] != null)
                    '${c['screen_size_inches']}"',
                  from(c),
                ].where((e) => e.isNotEmpty).join(' · '),
                Map<String, dynamic>.from(c),
                coverQuery: '${c['game_variant'] ?? c['name']}',
              ),
          ],
        ),
      ),
    ),
  );
}

final _coverCache = <String, Future<String?>>{};

/// Cover art looked up on RAWG by game name (pricing API has no images).
Future<String?> _coverFor(String query) =>
    _coverCache[query.toLowerCase()] ??= () async {
      try {
        final res = await Dio().get(
          'https://api.rawg.io/api/games',
          queryParameters: {
            'key': AppKeys.rawgApiKey,
            'search': query,
            'page_size': 1,
          },
        );
        final results = res.data['results'] as List?;
        return results == null || results.isEmpty
            ? null
            : results.first['background_image'] as String?;
      } catch (_) {
        return null;
      }
    }();

class _GameCover extends StatelessWidget {
  const _GameCover({this.query});
  final String? query;

  @override
  Widget build(BuildContext context) {
    const icon = SizedBox(
      width: 56,
      height: 56,
      child: Icon(
        Icons.sports_esports_rounded,
        color: BookingColors.accentBright,
      ),
    );
    final q = query?.trim() ?? '';
    if (q.isEmpty) return icon;
    return FutureBuilder<String?>(
      future: _coverFor(q),
      builder: (context, snap) {
        final url = snap.data;
        if (url == null) return icon;
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: url,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => icon,
          ),
        );
      },
    );
  }
}
