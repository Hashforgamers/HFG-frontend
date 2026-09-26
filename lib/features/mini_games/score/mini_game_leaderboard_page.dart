import '../ludo/ludo_game_screen.dart';
import '../snakes_ladders/snl_game_screen.dart';
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
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';
import '../ludo/widgets/ludo_seat_token.dart';

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
    const MapEntry('snakes_ladders', 'Snakes & Ladders'),
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
      backgroundColor: GameColors.bgBottom,
      body: Stack(
        children: [
          const GameBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  child: Row(
                    children: [
                      GameIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Back',
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(child: GameText('LEADERBOARD', size: 24)),
                      StreamBuilder<int>(
                        stream: _chatService.streamUnreadCountForRoom(
                          _leaderboardLobbyRoomId,
                        ),
                        builder: (context, snapshot) {
                          final unread = snapshot.data ?? 0;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GameIconButton(
                                icon: Icons.forum_rounded,
                                tooltip: 'Open leaderboard chat',
                                colors: GameColors.green,
                                onPressed: _openingChat
                                    ? null
                                    : () => _openLeaderboardChat(),
                              ),
                              if (unread > 0)
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF3B30),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: GameColors.outline,
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      unread > 99 ? '99+' : '$unread',
                                      style: gameFont(11, Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                _buildFilterStrip(),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<List<LeaderboardEntry>>(
                    stream: widget.leaderboardService.leaderboardStream(
                      limit: 80,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const AppLinearLoader.screen();
                      }
                      final allEntries = snapshot.data ?? [];
                      if (allEntries.isEmpty) return _emptyState();

                      final entries = widget.leaderboardService
                          .rankEntriesForGame(
                            allEntries,
                            gameId: _selectedGameId,
                          );
                      final currentUid =
                          FirebaseAuth.instance.currentUser?.uid ?? '';
                      final rest = entries.length > 3
                          ? entries.sublist(3)
                          : <LeaderboardEntry>[];
                      final myIndex = entries.indexWhere(
                        (entry) => entry.userId == currentUid,
                      );
                      final myEntry = myIndex >= 0 ? entries[myIndex] : null;
                      final myRank = myIndex >= 0 ? myIndex + 1 : null;
                      final nextTarget = myIndex > 0
                          ? entries[myIndex - 1]
                          : null;
                      final topScore = entries.isEmpty
                          ? 0
                          : _displayScore(entries.first);

                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        children: [
                          _buildPodiumPanel(
                            context: context,
                            entries: entries,
                            myRank: myRank,
                            topScore: topScore,
                          ),
                          const SizedBox(height: 14),
                          _buildYouPanel(
                            context: context,
                            myEntry: myEntry,
                            myRank: myRank,
                            nextTarget: nextTarget,
                            topScore: topScore,
                            players: entries.length,
                          ),
                          if (rest.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            const GameText('CHALLENGERS', size: 18),
                            const SizedBox(height: 10),
                            for (final (i, entry) in rest.indexed)
                              _leaderboardTile(
                                context: context,
                                rank: i + 4,
                                data: entry,
                                topScore: topScore,
                                isCurrentUser: entry.userId == currentUid,
                              ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterStrip() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _gameOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = _gameOptions[index];
          final selected = option.key == _selectedGameId;
          return GestureDetector(
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
              duration: const Duration(milliseconds: 160),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              margin: EdgeInsets.only(top: selected ? 0 : 3, bottom: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? GameColors.outline : GameColors.trayEdge,
                  width: 2.5,
                ),
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [GameColors.green.$1, GameColors.green.$2],
                      )
                    : null,
                color: selected ? null : GameColors.socket,
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0xFF1B7F24),
                          offset: Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: selected
                  ? GameText(option.value, size: 15)
                  : Text(option.value, style: gameFont(15, GameColors.soft)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPodiumPanel({
    required BuildContext context,
    required List<LeaderboardEntry> entries,
    required int? myRank,
    required int topScore,
  }) {
    final top3 = entries.take(3).toList();
    return GamePanel(
      headerColors: GameColors.yellow,
      header: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 8),
          Expanded(
            child: GameText(
              entries.isEmpty ? 'NO RUNS YET' : 'TOP PLAYERS',
              size: 22,
            ),
          ),
          if (myRank != null) GameBadge(label: 'YOU #$myRank'),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
      child: entries.isEmpty
          ? _emptyFilteredState()
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Classic 2 · 1 · 3 podium order.
                for (final rank in const [2, 1, 3])
                  Expanded(
                    child: rank <= top3.length
                        ? _podiumSpot(
                            context: context,
                            rank: rank,
                            data: top3[rank - 1],
                            topScore: topScore,
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
    );
  }

  Widget _podiumSpot({
    required BuildContext context,
    required int rank,
    required LeaderboardEntry data,
    required int topScore,
  }) {
    final color = _rankColor(rank);
    final pedestal = switch (rank) {
      1 => 78.0,
      2 => 58.0,
      _ => 44.0,
    };
    return GestureDetector(
      onTap: () => _showPlayerSheet(
        context: context,
        rank: rank,
        data: data,
        topScore: topScore,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              LudoSeatToken(
                color: color,
                name: data.displayName,
                photo: data.avatarUrl,
                size: rank == 1 ? 64 : 52,
                glow: rank == 1,
              ),
              if (rank == 1)
                Positioned(
                  top: -20,
                  child: Text('👑', style: TextStyle(fontSize: 30, height: 1)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data.displayName.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: gameFont(14, Colors.white),
          ),
          GameText('${_displayScore(data)}', size: 15, color: color),
          const SizedBox(height: 6),
          // Chunky pedestal.
          Container(
            height: pedestal,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.fromLTRB(2.5, 2.5, 2.5, 6),
            decoration: BoxDecoration(
              color: GameColors.outline,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9.5),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(color, Colors.white, 0.3)!, color],
                ),
              ),
              child: GameText('$rank', size: rank == 1 ? 32 : 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouPanel({
    required BuildContext context,
    required LeaderboardEntry? myEntry,
    required int? myRank,
    required LeaderboardEntry? nextTarget,
    required int topScore,
    required int players,
  }) {
    Widget stat(String label, String value, Color color) => Expanded(
      child: GameTray(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            GameText(value, size: 20, color: color),
            const SizedBox(height: 2),
            Text(label, style: gameFont(11.5, GameColors.soft)),
          ],
        ),
      ),
    );

    final gap = myEntry != null && nextTarget != null
        ? (_displayScore(nextTarget) - _displayScore(myEntry)).clamp(1, 999999)
        : null;
    final line = myEntry == null
        ? 'Play ${_selectedGameLabel()} to get on the board!'
        : nextTarget == null
        ? 'You’re #1. Defend the crown!'
        : 'Beat ${nextTarget.displayName.split(' ').first} by $gap pts';

    return GamePanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              stat(
                'Your rank',
                myRank == null ? '—' : '#$myRank',
                Colors.white,
              ),
              const SizedBox(width: 8),
              stat(
                'Your score',
                myEntry == null ? '0' : '${_displayScore(myEntry)}',
                GameColors.green.$1,
              ),
              const SizedBox(width: 8),
              stat('Top score', '$topScore', GameColors.yellow.$1),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Expanded(child: Text(line, style: gameFont(15, Colors.white))),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: GameButton(
                  label: 'Play',
                  tone: GameButtonTone.green,
                  height: 46,
                  onPressed: () =>
                      myEntry != null &&
                          _selectedGameId ==
                              MiniGameLeaderboardService.overallGameId
                      ? _openBestGame(context, myEntry)
                      : _openSelectedGame(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$players players on the ${_selectedGameLabel()} board',
            style: gameFont(12, GameColors.soft),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GamePanel(
          headerColors: GameColors.purple,
          header: const Center(child: GameText('NO SCORES YET', size: 22)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Play any mini game to put the first score on the board.',
                textAlign: TextAlign.center,
                style: gameFont(14, GameColors.soft),
              ),
              const SizedBox(height: 12),
              GameButton(
                label: 'Play Ludo',
                tone: GameButtonTone.green,
                height: 48,
                onPressed: () => _openGameByKey(context, 'ludo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyFilteredState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        'No ranked runs for ${_selectedGameLabel()} yet. Be the first!',
        textAlign: TextAlign.center,
        style: gameFont(14, GameColors.soft),
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
    final subtitle = _selectedGameId == MiniGameLeaderboardService.overallGameId
        ? 'Main: ${_primaryGame(data.scores)}'
        : 'Total: ${data.totalScore} pts';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _showPlayerSheet(
          context: context,
          rank: rank,
          data: data,
          topScore: topScore,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(2.5, 2.5, 2.5, 5),
          decoration: BoxDecoration(
            color: isCurrentUser ? GameColors.green.$2 : GameColors.outline,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13.5),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [GameColors.bodyTop, GameColors.bodyBottom],
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  child: GameText('#$rank', size: 16, color: GameColors.soft),
                ),
                LudoSeatToken(
                  color: isCurrentUser
                      ? GameColors.green.$1
                      : GameColors.purple.$1,
                  name: data.displayName,
                  photo: data.avatarUrl,
                  size: 40,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCurrentUser ? 'You' : data.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: gameFont(15, Colors.white),
                      ),
                      Text(subtitle, style: gameFont(11.5, GameColors.soft)),
                    ],
                  ),
                ),
                GameText(
                  '${_displayScore(data)}',
                  size: 17,
                  color: GameColors.yellow.$1,
                ),
              ],
            ),
          ),
        ),
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
      case 'snakes_ladders':
        target = const SnlGameScreen();
        break;
      case 'fruit_cutting':
        target = const FruitCuttingScreen();
        break;
      case 'plant_vs_zombie':
        target = const PlantVsZombie();
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
