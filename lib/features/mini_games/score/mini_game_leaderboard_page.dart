import '../ludo/ludo_game_screen.dart';
import '../ludo/ludo_score_service.dart';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/chat/views/chat_room_view.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/features/mini_games/flappy_birds/Layouts/Pages/page_start_screen.dart';
import 'package:hash/features/mini_games/html_games/services/html_mini_game_catalog_service.dart';
import 'package:hash/features/mini_games/pacman/HomePage.dart';
import 'package:hash/features/mini_games/plant_vs_zombies/Screens/home_page.dart';

import '../../../../features/mini_games/fruit_ninja/fruit_ninja_screen.dart';
import 'mini_game_leaderboard_service.dart';
import 'mini_game_score_service.dart';

class MiniGameLeaderboardPage extends StatefulWidget {
  final MiniGameScoreService scoreService;
  final MiniGameLeaderboardService leaderboardService;

  const MiniGameLeaderboardPage({
    super.key,
    required this.scoreService,
    required this.leaderboardService,
  });

  @override
  State<MiniGameLeaderboardPage> createState() =>
      _MiniGameLeaderboardPageState();
}

class _MiniGameLeaderboardPageState extends State<MiniGameLeaderboardPage> {
  // Brand palette — Hash green, replacing the old amber theme.
  static const Color _green = Color(0xFF00DC00);
  static const Color _gold = Color(0xFFFFC857);
  static const Color _silver = Color(0xFFC7D2E0);
  static const Color _bronze = Color(0xFFD8975A);
  static const Color _panel = Color(0xFF12160F);

  late final ChatService _chatService;
  late final SegmentSdkService _segmentService;
  late final FbEventsService _fbEventsService;
  String _selectedGameId = MiniGameLeaderboardService.overallGameId;
  bool _openingChat = false;

  String get _leaderboardLobbyRoomId {
    return _selectedGameId == MiniGameLeaderboardService.overallGameId
        ? 'mini_games_lounge'
        : 'mini_games_$_selectedGameId';
  }

  late final List<MapEntry<String, String>> _gameOptions = [
    const MapEntry(MiniGameLeaderboardService.overallGameId, 'Overall'),
    const MapEntry('ludo', 'Ludo'),
    const MapEntry('fruit_cutting', 'Fruit Cutting'),
    const MapEntry('plant_vs_zombie', 'Plant Vs Zombie'),
    const MapEntry('pac_man', 'Pac Man'),
    const MapEntry('laggy_bird', 'Laggy Bird'),
    ...HtmlMiniGameCatalogService.games.map(
      (game) => MapEntry(game.gameId, game.name),
    ),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(LudoScoreService.instance.sync());
    _chatService = Get.find<ChatService>();
    _segmentService = locator<SegmentSdkService>();
    _fbEventsService = locator<FbEventsService>();
    unawaited(
      _trackLeaderboardEvent('Arcade Leaderboard Viewed', {
        'selected_board': _selectedGameId,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        ),
        title: Text(
          'Arcade Leaderboard',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Open leaderboard chat',
            onPressed: _openingChat ? null : () => _openLeaderboardChat(),
            icon: const Icon(Icons.forum_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF06240F), Color(0xFF0A0F0A), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<LeaderboardEntry>>(
            stream: widget.leaderboardService.leaderboardStream(limit: 80),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLinearLoader.screen();
              }

              final allEntries = snapshot.data ?? [];
              final entries = widget.leaderboardService.rankEntriesForGame(
                allEntries,
                gameId: _selectedGameId,
              );

              if (allEntries.isEmpty) return _emptyState();

              final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
              final rest = entries.length > 3
                  ? entries.sublist(3)
                  : <LeaderboardEntry>[];
              final myIndex = entries.indexWhere(
                (entry) => entry.userId == currentUid,
              );
              final myEntry = myIndex >= 0 ? entries[myIndex] : null;
              final myRank = myIndex >= 0 ? myIndex + 1 : null;
              final nextTarget = myIndex > 0 ? entries[myIndex - 1] : null;
              final topScore = entries.isEmpty
                  ? 0
                  : _displayScore(entries.first);

              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildFilterStrip(),
                  const SizedBox(height: 14),
                  _buildTopPlayersHero(
                    entries: entries,
                    myEntry: myEntry,
                    myRank: myRank,
                  ),
                  const SizedBox(height: 16),
                  _buildHeroBoardCard(
                    context: context,
                    entries: entries,
                    myRank: myRank,
                    myEntry: myEntry,
                    topScore: topScore,
                    playerCount: entries.length,
                  ),
                  const SizedBox(height: 12),
                  _buildPulseCard(entries: entries, myRank: myRank),
                  if (myEntry != null && nextTarget != null) ...[
                    const SizedBox(height: 12),
                    _nextTargetCard(
                      context: context,
                      myEntry: myEntry,
                      nextTarget: nextTarget,
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (rest.isNotEmpty) ...[
                    Text(
                      'Challengers',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...rest.asMap().entries.map(
                      (entry) => _leaderboardTile(
                        context: context,
                        rank: entry.key + 4,
                        data: entry.value,
                        topScore: topScore,
                        isCurrentUser: entry.value.userId == currentUid,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopPlayersHero({
    required List<LeaderboardEntry> entries,
    required LeaderboardEntry? myEntry,
    required int? myRank,
  }) {
    final top3 = entries.take(3).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C2A16), Color(0xFF101210)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _green.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entries.isEmpty ? 'Arcade Board' : 'Top Players',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entries.isEmpty
                          ? 'No ranked runs yet.'
                          : 'The current board leaders and crown holders.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (myRank != null) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _green.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'Your Rank #$myRank',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: _green,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          if (entries.isEmpty)
            _emptyFilteredState()
          else
            _podium(top3, highlightUserId: myEntry?.userId),
        ],
      ),
    );
  }

  Widget _buildHeroBoardCard({
    required BuildContext context,
    required List<LeaderboardEntry> entries,
    required LeaderboardEntry? myEntry,
    required int? myRank,
    required int topScore,
    required int playerCount,
  }) {
    final leader = entries.isEmpty ? null : entries.first;
    final myScore = myEntry != null
        ? _displayScore(myEntry)
        : _selectedGameId == MiniGameLeaderboardService.overallGameId
        ? widget.scoreService.totalScore
        : widget.scoreService.bestScore(_selectedGameId);
    final isLeader = myRank == 1 && myEntry != null;
    final gap = leader == null ? 0 : (topScore - myScore).clamp(0, 999999);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E3B20), Color(0xFF14181A), Color(0xFF0B0D0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _green.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -10,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _green.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            left: -16,
            bottom: -34,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _selectedGameId ==
                              MiniGameLeaderboardService.overallGameId
                          ? 'ALL GAMES'
                          : _selectedGameLabel().toUpperCase(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Top 3 capped',
                      style: GoogleFonts.inter(
                        color: _green,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                isLeader
                    ? 'You are controlling this board.'
                    : leader == null
                    ? 'No one owns this board yet.'
                    : '${leader.displayName} is the player to beat.',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                leader == null
                    ? 'Set the first benchmark and pull everyone into chase mode.'
                    : isLeader
                    ? 'Hold the line, defend the crown, and keep pressure on the rest of the lobby.'
                    : gap == 0
                    ? 'You are in striking distance. Push one more strong run.'
                    : '$gap pts separate you from the current crown.',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _heroMetric(
                      label: 'Your Rank',
                      value: myRank == null ? 'Unranked' : '#$myRank',
                      accent: _silver,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _heroMetric(
                      label: 'Your Score',
                      value: '$myScore',
                      accent: _green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _heroMetric(
                      label: 'Top Score',
                      value: leader == null ? '--' : '$topScore',
                      accent: _gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: _gold,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rewards · #1 100 · #2 75 · #3 50 · #4–100 get 1 HashCoin',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (_selectedGameId ==
                            MiniGameLeaderboardService.overallGameId) {
                          if (myEntry != null) {
                            _openBestGame(context, myEntry);
                          } else {
                            _openSelectedGame(context);
                          }
                          return;
                        }
                        _openSelectedGame(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        isLeader ? 'Defend Crown' : 'Play Now',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: _chatService.streamUnreadCountForRoom(
                        _leaderboardLobbyRoomId,
                      ),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data ?? 0;
                        return OutlinedButton(
                          onPressed: _openingChat
                              ? null
                              : () => _openLeaderboardChat(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: unreadCount > 0
                                  ? const Color(
                                      0xFF42D7FF,
                                    ).withValues(alpha: 0.45)
                                  : Colors.white.withValues(alpha: 0.12),
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(Icons.forum_rounded),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: -8,
                                      top: -8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 2,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF42D7FF),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF42D7FF,
                                              ).withValues(alpha: 0.35),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            unreadCount > 99
                                                ? '99+'
                                                : '$unreadCount',
                                            style: GoogleFonts.inter(
                                              color: Colors.black,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _openingChat
                                      ? 'Opening...'
                                      : unreadCount > 0
                                      ? 'Open Lobby ($unreadCount)'
                                      : 'Open Lobby',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Active board size: $playerCount players',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterStrip() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _gameOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = _gameOptions[index];
          final selected = option.key == _selectedGameId;
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              if (_selectedGameId == option.key) return;
              setState(() => _selectedGameId = option.key);
              unawaited(
                _trackLeaderboardEvent('Arcade Leaderboard Filter Selected', {
                  'selected_board': option.key,
                  'selected_board_label': option.value,
                }),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? _green : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? _green
                      : Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _green.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                option.value,
                style: GoogleFonts.inter(
                  color: selected ? Colors.black : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPulseCard({
    required List<LeaderboardEntry> entries,
    required int? myRank,
  }) {
    final leader = entries.isEmpty ? null : entries.first;
    final playerCount = entries.length;
    final percentile = myRank == null || playerCount == 0
        ? 0
        : (((playerCount - myRank + 1) / playerCount) * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              color: _green,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              leader == null
                  ? 'Be the first to set the pace on this board.'
                  : '${leader.displayName} is setting the pace in ${_primaryGame(leader.scores)}.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
          if (percentile > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    color: _green,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$percentile%',
                    style: GoogleFonts.inter(
                      color: _green,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sports_esports_rounded,
            color: Colors.white38,
            size: 50,
          ),
          const SizedBox(height: 12),
          Text(
            'No scores yet.\nStart a mini game and claim rank #1.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _emptyFilteredState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty_rounded, color: Colors.white54),
          const SizedBox(height: 10),
          Text(
            'No scores in ${_selectedGameLabel()} yet.',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to set the benchmark.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _podium(List<LeaderboardEntry> entries, {String? highlightUserId}) {
    const rankHeights = {1: 216.0, 2: 188.0, 3: 168.0};
    const order = [1, 0, 2];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: order.map((idx) {
        final rank = idx + 1;
        final data = idx < entries.length ? entries[idx] : null;
        return Expanded(
          child: _pillarCard(
            rank: rank,
            data: data,
            height: rankHeights[rank] ?? 150,
            isHighlighted: data?.userId == highlightUserId,
          ),
        );
      }).toList(),
    );
  }

  Widget _pillarCard({
    required int rank,
    required double height,
    LeaderboardEntry? data,
    bool isHighlighted = false,
  }) {
    final medal = _rankColor(rank);
    final avatarR = rank == 1 ? 30.0 : 24.0;
    final hasImg = (data?.avatarUrl ?? '').trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [medal.withValues(alpha: 0.24), _panel],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted ? _green : medal.withValues(alpha: 0.45),
          width: isHighlighted ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isHighlighted ? _green : medal).withValues(
              alpha: rank == 1 ? 0.34 : 0.18,
            ),
            blurRadius: rank == 1 ? 22 : 13,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Crown for the champion, medal ribbon for the rest.
          Icon(
            rank == 1
                ? Icons.emoji_events_rounded
                : Icons.military_tech_rounded,
            color: medal,
            size: rank == 1 ? 26 : 20,
          ),
          // Avatar inside a medal-colored ring.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [medal, medal.withValues(alpha: 0.35)],
                  ),
                ),
                child: CircleAvatar(
                  radius: avatarR,
                  backgroundColor: const Color(0xFF1C201A),
                  backgroundImage: hasImg
                      ? NetworkImage((data!.avatarUrl ?? '').trim())
                      : null,
                  child: hasImg
                      ? null
                      : Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: avatarR,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data?.displayName ?? 'Empty',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              if (isHighlighted)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'YOU',
                    style: GoogleFonts.inter(
                      color: _green,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          // Score chip above a circular rank medal.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  data != null ? '${_displayScore(data)}' : '--',
                  style: GoogleFonts.orbitron(
                    color: medal,
                    fontSize: rank == 1 ? 15 : 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(shape: BoxShape.circle, color: medal),
                child: Center(
                  child: Text(
                    '$rank',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _leaderboardTile({
    required BuildContext context,
    required int rank,
    required LeaderboardEntry data,
    required int topScore,
    required bool isCurrentUser,
  }) {
    final accent = _rankColor(rank);
    final visibleScore = _displayScore(data);
    final progress = topScore <= 0
        ? 0.0
        : (visibleScore / topScore).clamp(0, 1).toDouble();
    final subtitle = _selectedGameId == MiniGameLeaderboardService.overallGameId
        ? 'Main: ${_primaryGame(data.scores)}'
        : 'Total: ${data.totalScore} pts';

    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () => _showPlayerSheet(
        context: context,
        rank: rank,
        data: data,
        topScore: topScore,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentUser ? _green.withValues(alpha: 0.12) : _panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrentUser
                ? _green.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.07),
            width: isCurrentUser ? 1.1 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white12,
              backgroundImage: (data.avatarUrl ?? '').trim().isNotEmpty
                  ? NetworkImage((data.avatarUrl ?? '').trim())
                  : null,
              child: (data.avatarUrl ?? '').trim().isNotEmpty
                  ? null
                  : const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.displayName,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'YOU',
                            style: GoogleFonts.inter(
                              color: _green,
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _green.withValues(alpha: 0.8),
                      ),
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isCurrentUser)
                  IconButton(
                    onPressed: () => _openDirectChatWithEntry(data),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      minimumSize: const Size(34, 34),
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '$visibleScore pts',
                  style: GoogleFonts.orbitron(
                    color: _gold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedGameId != MiniGameLeaderboardService.overallGameId)
                  Text(
                    '${data.totalScore} total',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nextTargetCard({
    required BuildContext context,
    required LeaderboardEntry myEntry,
    required LeaderboardEntry nextTarget,
  }) {
    final gap = (_displayScore(nextTarget) - _displayScore(myEntry)).clamp(
      1,
      999999,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFFF9E44),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Beat ${nextTarget.displayName} by $gap pts',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                _selectedGameId == MiniGameLeaderboardService.overallGameId
                ? _openBestGame(context, myEntry)
                : _openSelectedGame(context),
            child: Text(
              'Play',
              style: GoogleFonts.inter(
                color: _green,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBestGame(
    BuildContext context,
    LeaderboardEntry myEntry,
  ) async {
    final gameKey = myEntry.scores.isEmpty
        ? ''
        : (myEntry.scores.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;

    unawaited(
      _trackLeaderboardEvent('Arcade Leaderboard Play Tapped', {
        'selected_board': _selectedGameId,
        'launch_mode': 'best_game',
        'target_game_id': gameKey,
      }),
    );
    await _openGameByKey(context, gameKey);
  }

  Future<void> _openSelectedGame(BuildContext context) async {
    unawaited(
      _trackLeaderboardEvent('Arcade Leaderboard Play Tapped', {
        'selected_board': _selectedGameId,
        'launch_mode': 'selected_board',
        'target_game_id': _selectedGameId,
      }),
    );
    await _openGameByKey(context, _selectedGameId);
  }

  Future<void> _openGameByKey(BuildContext context, String gameKey) async {
    Widget? target;
    switch (gameKey) {
      case 'ludo':
        target = const LudoGameScreen();
        break;
      case 'fruit_cutting':
        target = FruitCuttingScreen();
        break;
      case 'plant_vs_zombie':
        target = PlantVsZombie();
        break;
      case 'pac_man':
        target = PacManHome();
        break;
      case 'laggy_bird':
        target = const FlappyBirds();
        break;
    }

    if (target != null) {
      await Get.to(() => target!);
      return;
    }

    Navigator.pop(context);
  }

  Future<void> _showPlayerSheet({
    required BuildContext context,
    required int rank,
    required LeaderboardEntry data,
    required int topScore,
  }) async {
    unawaited(
      _trackLeaderboardEvent('Arcade Leaderboard Player Sheet Viewed', {
        'selected_board': _selectedGameId,
        'rank': rank,
        'target_user_id': data.userId,
      }),
    );
    final sortedScores = data.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final gapToTop = rank == 1
        ? 0
        : (topScore - _displayScore(data)).clamp(0, 999999);
    final isCurrentUser = data.userId == FirebaseAuth.instance.currentUser?.uid;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF12160F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white12,
                      backgroundImage: (data.avatarUrl ?? '').trim().isNotEmpty
                          ? NetworkImage((data.avatarUrl ?? '').trim())
                          : null,
                      child: (data.avatarUrl ?? '').trim().isNotEmpty
                          ? null
                          : const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${data.displayName}  •  Rank #$rank',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${_displayScore(data)} pts',
                      style: GoogleFonts.orbitron(
                        color: const Color(0xFFFFC65C),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  gapToTop == 0
                      ? 'Top player right now'
                      : '$gapToTop pts behind #1',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ...sortedScores
                    .take(4)
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                MiniGameLeaderboardService.readableGameName(
                                  entry.key,
                                ),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              '${entry.value}',
                              style: GoogleFonts.inter(
                                color: _gold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _openLeaderboardChat();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.forum_rounded),
                        label: const Text('Lobby Chat'),
                      ),
                    ),
                    if (!isCurrentUser) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _openDirectChatWithEntry(data);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.chat_bubble_rounded),
                          label: const Text('Message'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLeaderboardChat() async {
    if (_openingChat) return;

    setState(() => _openingChat = true);
    try {
      final roomId = await widget.leaderboardService.ensureLeaderboardChatRoom(
        gameId: _selectedGameId == MiniGameLeaderboardService.overallGameId
            ? null
            : _selectedGameId,
      );
      unawaited(
        _trackLeaderboardEvent('Arcade Leaderboard Chat Opened', {
          'selected_board': _selectedGameId,
          'room_id': roomId,
        }),
      );
      if (!mounted) return;
      await Get.to(() => ChatRoomView(roomId: roomId));
    } catch (e) {
      Get.snackbar(
        'Leaderboard chat',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1A1A1A),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _openingChat = false);
      }
    }
  }

  Future<void> _openDirectChatWithEntry(LeaderboardEntry entry) async {
    try {
      final roomId = await _chatService.getOrCreateDirectRoom(
        otherUser: ChatUserModel(
          uid: entry.userId,
          displayName: entry.displayName,
          username: '',
          email: '',
          phoneNumber: '',
          photoUrl: entry.avatarUrl ?? '',
          isOnline: false,
          updatedAt: DateTime.now(),
          lastSeenAt: null,
        ),
      );
      unawaited(
        _trackLeaderboardEvent('Arcade Leaderboard Direct Chat Opened', {
          'selected_board': _selectedGameId,
          'target_user_id': entry.userId,
          'room_id': roomId,
        }),
      );
      if (!mounted) return;
      await Get.to(() => ChatRoomView(roomId: roomId));
    } catch (e) {
      Get.snackbar(
        'Direct chat',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1A1A1A),
        colorText: Colors.white,
      );
    }
  }

  int _displayScore(LeaderboardEntry entry) {
    if (_selectedGameId == MiniGameLeaderboardService.overallGameId) {
      return entry.totalScore;
    }
    return entry.scores[_selectedGameId] ?? 0;
  }

  String _selectedGameLabel() {
    return _gameOptions
        .firstWhere(
          (entry) => entry.key == _selectedGameId,
          orElse: () => const MapEntry('overall', 'Overall'),
        )
        .value;
  }

  String _primaryGame(Map<String, int> scores) {
    if (scores.isEmpty) return 'Rookie';
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return MiniGameLeaderboardService.readableGameName(sorted.first.key);
  }

  Color _rankColor(int rank) {
    if (rank == 1) return _gold;
    if (rank == 2) return _silver;
    if (rank == 3) return _bronze;
    return const Color(0xFF6B7280);
  }

  Future<void> _trackLeaderboardEvent(
    String name,
    Map<String, dynamic> payload,
  ) async {
    final eventPayload = <String, dynamic>{
      'leaderboard_type': 'mini_games_arcade',
      ...payload,
    };
    await _segmentService.onCustomEvent(name, eventPayload);
    await _fbEventsService.onCustomEvent(name, eventPayload);
  }
}
