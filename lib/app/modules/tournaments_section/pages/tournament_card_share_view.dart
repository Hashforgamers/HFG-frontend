import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:hash/app/modules/tournaments_section/models/tournament_model.dart';
import 'package:hash/utils/widgets/hash_wordmark.dart';

class TournamentCardShareView extends StatefulWidget {
  const TournamentCardShareView({super.key, required this.tournament});

  final TournamentModel tournament;

  @override
  State<TournamentCardShareView> createState() =>
      _TournamentCardShareViewState();
}

class _TournamentCardShareViewState extends State<TournamentCardShareView> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Share tournament',
          style: GoogleFonts.orbitron(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          RepaintBoundary(
            key: _cardKey,
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: _ShareCard(tournament: widget.tournament),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Ready for Instagram, WhatsApp, Discord, and more.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: FilledButton.icon(
            onPressed: _sharing ? null : _share,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: const Color(0xFFFFA43A),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                : const Icon(Icons.ios_share_rounded),
            label: Text(
              _sharing ? 'Creating share card…' : 'Share tournament card',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || boundary.debugNeedsPaint) {
        await WidgetsBinding.instance.endOfFrame;
      }
      final readyBoundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (readyBoundary == null || readyBoundary.debugNeedsPaint) {
        throw StateError('Share card is not ready');
      }
      final image = await readyBoundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not render share card');

      final directory = await getTemporaryDirectory();
      final safeId = widget.tournament.id.replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]'),
        '_',
      );
      final file = File('${directory.path}/hash-tournament-$safeId.png');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      final tournament = widget.tournament;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          subject: '${tournament.title} — HASH Tournament',
          text:
              '🔥 ${tournament.title}\nPlay. Compete. Win on HASH.\n'
              'https://hashforgamers.com/tournaments/${tournament.id}\n\n'
              '#HASH #Esports #GamingTournament',
          sharePositionOrigin: _shareOrigin(),
        ),
      );
    } catch (_) {
      if (mounted) {
        Get.snackbar(
          'Could not share card',
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
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.tournament});

  final TournamentModel tournament;

  @override
  Widget build(BuildContext context) {
    final image = tournament.banner.isNotEmpty
        ? tournament.banner
        : tournament.imageUrl;
    final date = tournament.startDate == null
        ? 'DATE ANNOUNCING SOON'
        : DateFormat('EEE, d MMM · h:mm a').format(tournament.startDate!);
    final isNetwork = image.startsWith('http');

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          isNetwork
              ? Image.network(image, fit: BoxFit.cover)
              : Image.asset(image, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black12, Colors.transparent, Colors.black],
                stops: [0, .38, 1],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            top: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const HashWordmark(fontSize: 19),
                Text(
                  tournament.source == 'community'
                      ? 'COMMUNITY CUP'
                      : 'CAFE TOURNAMENT',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFFC34D),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tournament.game.isNotEmpty)
                  Text(
                    tournament.game.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFFA43A),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                const SizedBox(height: 7),
                Text(
                  tournament.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  date.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Fact(label: 'ENTRY', value: tournament.entryFee),
                    const SizedBox(width: 22),
                    _Fact(label: 'PRIZE', value: tournament.prizePool),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA43A),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    'REGISTER ON HASH',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
