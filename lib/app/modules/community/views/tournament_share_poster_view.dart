import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hash/utils/widgets/hash_wordmark.dart';

import '../models/tournament.dart';
import 'community_theme.dart';
import 'tournaments_view.dart' show ctAmount, ctCurrency;

class TournamentSharePosterView extends StatefulWidget {
  final Tournament tournament;

  const TournamentSharePosterView({super.key, required this.tournament});

  @override
  State<TournamentSharePosterView> createState() =>
      _TournamentSharePosterViewState();
}

class _TournamentSharePosterViewState extends State<TournamentSharePosterView> {
  final GlobalKey _posterKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CT.bg,
      appBar: AppBar(
        backgroundColor: CT.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Share tournament', style: CT.headline(18)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'POSTER PREVIEW · 4:5',
            style: CT.mono(9, color: CT.primaryBright),
          ),
          const SizedBox(height: 10),
          RepaintBoundary(
            key: _posterKey,
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: _TournamentPoster(tournament: widget.tournament),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Optimized for Instagram, WhatsApp, Discord, and other social apps.',
            textAlign: TextAlign.center,
            style: CT.body(11.5),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _sharing ? null : _sharePoster,
              style: ElevatedButton.styleFrom(
                backgroundColor: CT.primary,
                disabledBackgroundColor: CT.surfaceHigh,
                foregroundColor: Colors.black,
                disabledForegroundColor: CT.muted,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: _sharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.ios_share_rounded, size: 19),
              label: Text(
                _sharing ? 'Creating poster…' : 'Share publicity poster',
                style: CT.headline(14, color: Colors.black),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sharePoster() async {
    setState(() => _sharing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _posterKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Poster is not ready');
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Could not render poster');

      final directory = await getTemporaryDirectory();
      final safeId = widget.tournament.id.replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]'),
        '_',
      );
      final file = File('${directory.path}/hash-tournament-$safeId.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      final t = widget.tournament;
      final link = 'https://hashforgamers.com/tournaments/${t.id}';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text:
              '🔥 ${t.title}\n'
              'Think you can win it? Register on HASH.\n$link\n\n'
              '#HASH #Esports #GamingTournament #PlayToWin',
          subject: '${t.title} — HASH Tournament',
          sharePositionOrigin: _shareOrigin(),
        ),
      );
    } catch (_) {
      if (mounted) {
        Get.snackbar(
          'Could not share poster',
          'Please try again in a moment.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Rect? _shareOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

class _TournamentPoster extends StatelessWidget {
  final Tournament tournament;

  const _TournamentPoster({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final currency = ctCurrency(tournament.currency);
    final openSlots =
        (tournament.maxPlayers - tournament.registeredPlayersCount).clamp(
          0,
          tournament.maxPlayers,
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _posterImage(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .35, .68, 1],
                colors: [
                  Color(0x33000000),
                  Color(0x22000000),
                  Color(0xE6000000),
                  Color(0xFF000000),
                ],
              ),
            ),
          ),
          Positioned(
            top: -55,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: CT.glow(CT.secondary, blur: 90, opacity: .9),
              ),
            ),
          ),
          Positioned(
            left: -70,
            bottom: 35,
            child: Transform.rotate(
              angle: -.16,
              child: Container(width: 250, height: 5, color: CT.primary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const HashWordmark(fontSize: 16, letterSpacing: 3),
                    const Spacer(),
                    Text(
                      'TOURNAMENT DROP',
                      style: CT.mono(8, color: CT.primaryBright),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  tournament.game.toUpperCase(),
                  style: CT.mono(9, color: CT.primaryBright),
                ),
                const SizedBox(height: 6),
                Text(
                  tournament.title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CT.display(27),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _PosterStat(
                        label: 'PRIZE POOL',
                        value: '$currency${ctAmount(tournament.prizePool)}',
                        color: CT.primaryBright,
                        large: true,
                      ),
                    ),
                    _PosterStat(
                      label: 'ENTRY',
                      value: tournament.isFree
                          ? 'FREE'
                          : '$currency${ctAmount(tournament.entryFee)}',
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Container(height: 1, color: const Color(0x55FFFFFF)),
                const SizedBox(height: 11),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _date(tournament.tournamentStartAt),
                      style: CT.body(10.5),
                    ),
                    const Spacer(),
                    Text(
                      openSlots == 0 ? 'SLOTS FULL' : '$openSlots SLOTS LEFT',
                      style: CT.mono(
                        8,
                        color: openSlots == 0 ? CT.error : CT.primaryBright,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: CT.primary,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'REGISTER ON ',
                        style: CT.headline(10, color: Colors.black),
                      ),
                      const HashWordmark(
                        fontSize: 8,
                        letterSpacing: 1.2,
                        color: Colors.black,
                        accentColor: Colors.black,
                      ),
                      Text('  →', style: CT.headline(10, color: Colors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'HOST. HYPE. EARN.  ·  hashforgamers.com',
                    style: CT.mono(6.5, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _posterImage() {
    final url = tournament.bannerUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImage(),
      );
    }
    return _fallbackImage();
  }

  Widget _fallbackImage() => Image.asset(
    'assets/hash_store_images/tournament_banner.png',
    fit: BoxFit.cover,
  );

  static String _date(DateTime? value) {
    if (value == null) return 'DATE ANNOUNCING SOON';
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final date = value.toLocal();
    return '${date.day} ${months[date.month - 1]} · ${_time(date)}';
  }

  static String _time(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour < 12 ? 'AM' : 'PM'}';
  }
}

class _PosterStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool large;

  const _PosterStat({
    required this.label,
    required this.value,
    this.color = Colors.white,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CT.mono(7, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(value, style: CT.display(large ? 23 : 16, color: color)),
      ],
    );
  }
}
