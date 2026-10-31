import 'package:hash/features/mini_games/score/leader_marquee.dart';
import '../ludo/ludo_game_screen.dart';
import 'package:hash/core/utils/app_snackbar.dart';
import '../snakes_ladders/snl_game_screen.dart';
import '../ludo/ludo_score_service.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:hash/features/mini_games/wordly/wordly_screen.dart';
import 'package:hash/features/mini_games/html_games/services/html_mini_game_catalog_service.dart';
import 'package:hash/features/mini_games/html_games/super_over_analytics.dart';
import 'package:hash/features/mini_games/html_games/views/html_game_player_screen.dart';
import 'package:hash/features/mini_games/pacman/HomePage.dart';
import 'package:hash/features/mini_games/plant_vs_zombies/Screens/home_page.dart';
import 'package:hash/features/mini_games/road_rumble/road_rumble_screen.dart';
import 'package:hash/features/mini_games/arrow_escape/arrow_escape_screen.dart';

import '../../../../features/mini_games/fruit_ninja/fruit_ninja_screen.dart';
import 'mini_game_leaderboard_service.dart';
import 'mini_game_score_service.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';
import '../ludo/widgets/ludo_seat_token.dart';
import 'package:hash/features/mini_games/arcade_analytics.dart';

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

  // Board paging: the first page is live (podium updates as scores land),
  // later pages load once as the list nears its end, so every rank is
  // reachable with no cap. [_boardToken] drops results that arrive after
  // the user has switched boards.
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<LeaderboardPage>? _firstPageSub;
  List<LeaderboardEntry> _livePage = const [];
  final List<LeaderboardEntry> _olderPages = [];
  DocumentSnapshot? _cursor;
  bool _hasMore = false;
  bool _loadingBoard = true;
  bool _loadingMore = false;
  Object? _boardError;
  LeaderboardStanding? _standing;
  int _boardToken = 0;
  late final SegmentSdkService _segmentService;
  late final FbEventsService _fbEventsService;
  String _selectedGameId = MiniGameLeaderboardService.overallGameId;
  bool _openingChat = false;
  bool _challenging = false;
  // one challenge per game per visit, so the chat isn't spammed
  final Set<String> _challengedGames = <String>{};

  String get _leaderboardLobbyRoomId {
    return MiniGameLeaderboardService.isTotalBoard(_selectedGameId)
        ? 'mini_games_lounge'
        : 'mini_games_$_selectedGameId';
  }

  late final List<MapEntry<String, String>> _gameOptions = [
    const MapEntry(MiniGameLeaderboardService.overallGameId, 'Overall'),
    const MapEntry(MiniGameLeaderboardService.weeklyGameId, 'This Week'),
    const MapEntry('ludo', 'Ludo'),
    const MapEntry('snakes_ladders', 'Snakes & Ladders'),
    const MapEntry('fruit_cutting', 'Fruit Cutting'),
    const MapEntry('plant_vs_zombie', 'Plant Vs Zombie'),
    const MapEntry('pac_man', 'Pac Man'),
    const MapEntry('laggy_bird', 'Laggy Bird'),
    const MapEntry('wordly', 'Wordly'),
    const MapEntry('road_rumble', 'Road Rumble'),
    const MapEntry('arrow_escape', 'Arrow Escape'),
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
    _scrollController.addListener(_onScroll);
    _loadBoard();
    unawaited(
      _trackLeaderboardEvent('Arcade Leaderboard Viewed', {
        'selected_board': _selectedGameId,
      }),
    );
  }

  @override
  void dispose() {
    _firstPageSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// (Re)starts the selected board from its first page. A pull-to-refresh
  /// ([keepRows]) leaves the current rows up until the fresh page arrives.
  Future<void> _loadBoard({bool keepRows = false}) async {
    final token = ++_boardToken;
    final gameId = _selectedGameId;
    await _firstPageSub?.cancel();
    if (!mounted || token != _boardToken) return;
    var resetPending = keepRows;
    if (!keepRows) {
      setState(() {
        _livePage = const [];
        _olderPages.clear();
        _cursor = null;
        _hasMore = false;
        _loadingBoard = true;
        _loadingMore = false;
        _boardError = null;
        _standing = null;
      });
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    }

    final firstPage = Completer<void>();
    _firstPageSub = widget.leaderboardService
        .boardFirstPageStream(gameId)
        .listen(
          (page) {
            if (!mounted || token != _boardToken) return;
            setState(() {
              if (resetPending) {
                resetPending = false;
                _olderPages.clear();
                _loadingMore = false;
              }
              _livePage = page.entries;
              // Until older pages load, the live page owns the cursor.
              if (_olderPages.isEmpty) {
                _cursor = page.lastDoc;
                _hasMore = page.hasMore;
              }
              _loadingBoard = false;
              _boardError = null;
            });
            if (!firstPage.isCompleted) firstPage.complete();
          },
          onError: (Object e) {
            debugPrint('Leaderboard page failed: $e');
            if (!mounted || token != _boardToken) return;
            setState(() {
              _loadingBoard = false;
              _boardError = e;
            });
            if (!firstPage.isCompleted) firstPage.complete();
          },
        );
    unawaited(_loadStanding(token, gameId));
    await firstPage.future;
  }

  Future<void> _loadStanding(int token, String gameId) async {
    try {
      final standing = await widget.leaderboardService.fetchStanding(gameId);
      if (!mounted || token != _boardToken) return;
      setState(() => _standing = standing);
    } catch (e) {
      debugPrint('Leaderboard standing failed: $e');
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) _loadMore();
  }

  Future<void> _loadMore() async {
    final cursor = _cursor;
    if (_loadingMore || !_hasMore || cursor == null || _loadingBoard) return;
    final token = _boardToken;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.leaderboardService.fetchBoardPage(
        _selectedGameId,
        after: cursor,
      );
      if (!mounted || token != _boardToken) return;
      setState(() {
        _olderPages.addAll(page.entries);
        _cursor = page.lastDoc ?? _cursor;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      debugPrint('Leaderboard next page failed: $e');
      if (!mounted || token != _boardToken) return;
      // Leave _hasMore set so scrolling again retries.
      setState(() => _loadingMore = false);
    }
  }

  /// Live page plus loaded older pages, best first. A player can move from
  /// an older page into the live one, so the live copy wins on duplicates.
  List<LeaderboardEntry> _mergedEntries() {
    final liveIds = {for (final e in _livePage) e.userId};
    final merged = [
      ..._livePage,
      ..._olderPages.where((e) => !liveIds.contains(e.userId)),
    ];
    merged.sort((a, b) => _displayScore(b).compareTo(_displayScore(a)));
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Warm.bg,
      body: Stack(
        children: [
          const GameBackground(colors: (_Warm.bgTop, _Warm.bg)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  child: Row(
                    children: [
                      GameIconButton(
                        colors: GameColors.coral,
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Back',
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(child: GameText('LEADERBOARD', size: 24)),
                      Builder(
                        builder: (btn) => GameIconButton(
                          icon: Icons.ios_share_rounded,
                          tooltip: 'Share leaderboard',
                          colors: GameColors.orange,
                          onPressed: () => _share(btn),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                                colors: GameColors.pink,
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
                Expanded(child: _buildBoard(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(BuildContext context) {
    if (_loadingBoard) return const AppLinearLoader.screen();
    if (_boardError != null && _livePage.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Couldn\'t load the leaderboard.',
                textAlign: TextAlign.center,
                style: gameFont(15, _Warm.soft),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 140,
                child: GameButton(
                  label: 'Retry',
                  tone: GameButtonTone.green,
                  height: 46,
                  onPressed: _loadBoard,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final entries = _mergedEntries();
    if (entries.isEmpty &&
        MiniGameLeaderboardService.isTotalBoard(_selectedGameId)) {
      return _emptyState();
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final myIndex = entries.indexWhere((e) => e.userId == currentUid);
    // Loaded rows are the freshest source; the standing covers players who
    // are further down than the pages loaded so far.
    final standing = _standing;
    final myEntry = myIndex >= 0 ? entries[myIndex] : standing?.me;
    final myRank = myIndex >= 0 ? myIndex + 1 : standing?.rank;
    final nextTarget = myIndex > 0
        ? entries[myIndex - 1]
        : myIndex == 0
        ? null
        : standing?.nextTarget;
    final topScore = entries.isEmpty ? 0 : _displayScore(entries.first);
    final players = standing?.players ?? entries.length;
    final rest = entries.length > 3 ? entries.sublist(3) : <LeaderboardEntry>[];

    final header = <Widget>[
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
        players: players,
      ),
      if (rest.isNotEmpty) ...[
        const SizedBox(height: 18),
        const GameText('CHALLENGERS', size: 18),
        const SizedBox(height: 10),
      ],
    ];
    final showFooter = _hasMore || _loadingMore;

    return RefreshIndicator(
      color: GameColors.pink.$1,
      onRefresh: () => _loadBoard(keepRows: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        itemCount: header.length + rest.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < header.length) return header[index];
          final i = index - header.length;
          if (i < rest.length) {
            final entry = rest[i];
            return _leaderboardTile(
              context: context,
              rank: i + 4,
              data: entry,
              topScore: topScore,
              isCurrentUser: entry.userId == currentUid,
            );
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: AppLinearLoader()),
          );
        },
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
              _loadBoard();
              if (option.key == SuperOverAnalytics.gameId) {
                SuperOverAnalytics.leaderboardViewed(source: 'leaderboard');
              }
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
                  color: selected ? GameColors.outline : _Warm.trayEdge,
                  width: 2.5,
                ),
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [GameColors.pink.$1, GameColors.pink.$2],
                      )
                    : null,
                color: selected ? null : _Warm.socket,
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
                  : Text(option.value, style: gameFont(15, _Warm.soft)),
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
      bodyColors: (_Warm.bodyTop, _Warm.bodyBottom),
      lipColor: _Warm.lip,
      headerColors: GameColors.orange,
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
        edge: _Warm.trayEdge,
        fill: _Warm.tray,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            GameText(value, size: 20, color: color),
            const SizedBox(height: 2),
            Text(label, style: gameFont(11.5, _Warm.soft)),
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
      bodyColors: (_Warm.bodyTop, _Warm.bodyBottom),
      lipColor: _Warm.lip,
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
                GameColors.pink.$1,
              ),
              const SizedBox(width: 8),
              stat('Top score', '$topScore', GameColors.orange.$1),
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
                          MiniGameLeaderboardService.isTotalBoard(
                            _selectedGameId,
                          )
                      ? _openBestGame(context, myEntry)
                      : _openSelectedGame(context),
                ),
              ),
            ],
          ),
          if (myEntry != null && _challengeTarget(myEntry) != null) ...[
            const SizedBox(height: 10),
            Builder(
              builder: (context) {
                final target = _challengeTarget(myEntry)!;
                final sent = _challengedGames.contains(target.gameId);
                return GameButton(
                  label: sent
                      ? 'Challenge posted in chat'
                      : (_challenging
                            ? 'Posting…'
                            : 'Challenge the chat to beat ${target.score}'),
                  subtitle: sent
                      ? null
                      : '${target.gameName} · posts in leaderboard chat',
                  icon: sent ? Icons.check_rounded : Icons.emoji_events_rounded,
                  tone: sent || _challenging
                      ? GameButtonTone.grey
                      : GameButtonTone.yellow,
                  height: 54,
                  onPressed: sent || _challenging
                      ? null
                      : () => _sendScoreChallenge(target),
                );
              },
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '$players players on the ${_selectedGameLabel()} board',
            style: gameFont(12, _Warm.soft),
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
          bodyColors: (_Warm.bodyTop, _Warm.bodyBottom),
          lipColor: _Warm.lip,
          headerColors: GameColors.coral,
          header: const Center(child: GameText('NO SCORES YET', size: 22)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Play any mini game to put the first score on the board.',
                textAlign: TextAlign.center,
                style: gameFont(14, _Warm.soft),
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
        style: gameFont(14, _Warm.soft),
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
    final subtitle = MiniGameLeaderboardService.isTotalBoard(_selectedGameId)
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
            color: isCurrentUser ? GameColors.pink.$2 : GameColors.outline,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13.5),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_Warm.bodyTop, _Warm.bodyBottom],
              ),
            ),
            child: Row(
              children: [
                // Wider slot once ranks reach three digits (uncapped board);
                // anything longer scales down rather than wrapping.
                SizedBox(
                  width: rank >= 100 ? 50 : 38,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: GameText('#$rank', size: 16, color: _Warm.soft),
                  ),
                ),
                LudoSeatToken(
                  color: isCurrentUser
                      ? GameColors.pink.$1
                      : GameColors.coral.$1,
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
                      Text(subtitle, style: gameFont(11.5, _Warm.soft)),
                    ],
                  ),
                ),
                GameText(
                  '${_displayScore(data)}',
                  size: 17,
                  color: GameColors.orange.$1,
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
        target = const PacManHome();
        break;
      case 'laggy_bird':
        target = const FlappyBirds();
        break;
      case 'wordly':
        target = const WordlyGame();
        break;
      case 'road_rumble':
        target = const RoadRumbleScreen();
        break;
      case 'arrow_escape':
        target = const ArrowEscapeScreen();
        break;
    }

    if (target != null) {
      ArcadeAnalytics.from('leaderboard');
      await Get.to(() => target!);
      return;
    }

    // HTML games (Super Over) open in the web-view player
    final htmlGame = HtmlMiniGameCatalogService.games
        .where((game) => game.gameId == gameKey)
        .firstOrNull;
    if (htmlGame != null) {
      await HtmlGamePlayerScreen.open(htmlGame, source: 'leaderboard');
      return;
    }

    if (!context.mounted) return;
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

  /// The game and score a challenge from this board would be about: the
  /// selected game, or on the total boards the player's best game.
  ({String gameId, String gameName, int score})? _challengeTarget(
    LeaderboardEntry myEntry,
  ) {
    String gameId;
    if (MiniGameLeaderboardService.isTotalBoard(_selectedGameId)) {
      if (myEntry.scores.isEmpty) return null;
      gameId =
          (myEntry.scores.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;
    } else {
      gameId = _selectedGameId;
    }
    final score = myEntry.scores[gameId] ?? 0;
    if (score <= 0) return null;
    return (
      gameId: gameId,
      gameName: MiniGameLeaderboardService.readableGameName(gameId),
      score: score,
    );
  }

  Future<void> _sendScoreChallenge(
    ({String gameId, String gameName, int score}) target,
  ) async {
    if (_challenging) return;
    setState(() => _challenging = true);
    try {
      await _chatService.sendScoreChallenge(
        gameId: target.gameId,
        gameName: target.gameName,
        score: target.score,
      );
      unawaited(
        _trackLeaderboardEvent('Arcade Score Challenge Sent', {
          'selected_board': _selectedGameId,
          'target_game_id': target.gameId,
          'score': target.score,
        }),
      );
      if (mounted) setState(() => _challengedGames.add(target.gameId));
    } catch (e) {
      AppSnackbar.show(
        'Score challenge',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1A1A1A),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _challenging = false);
    }
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
      AppSnackbar.show(
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
      AppSnackbar.show(
        'Direct chat',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1A1A1A),
        colorText: Colors.white,
      );
    }
  }

  int _displayScore(LeaderboardEntry entry) {
    if (MiniGameLeaderboardService.isTotalBoard(_selectedGameId)) {
      return entry.totalScore;
    }
    return entry.scores[_selectedGameId] ?? 0;
  }

  void _share(BuildContext anchor) {
    final entries = _mergedEntries();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final i = entries.indexWhere((e) => e.userId == uid);
    final me = i >= 0 ? entries[i] : _standing?.me;
    unawaited(
      _trackLeaderboardEvent('Arcade Leaderboard Shared', {
        'selected_board': _selectedGameId,
      }),
    );
    unawaited(
      shareArcadeLeaderboard(
        anchor,
        top: entries,
        myRank: i >= 0 ? i + 1 : _standing?.rank,
        myScore: me == null ? null : _displayScore(me),
        scoreOf: _displayScore,
        board: _selectedGameId == MiniGameLeaderboardService.overallGameId
            ? 'Hash Arcade'
            : _selectedGameLabel(),
      ),
    );
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

/// The leaderboard's colours: the arcade panels re-skinned in the website's
/// warm pink-to-orange, same shapes. Medals stay gold, silver and bronze.
abstract final class _Warm {
  static const bgTop = Color(0xFF4A1530);
  static const bg = Color(0xFF1A0812);
  static const bodyTop = Color(0xFF7A2450);
  static const bodyBottom = Color(0xFF4E1636);
  static const lip = Color(0xFF2E0C20);
  static const trayEdge = Color(0xFF2A0A1C);
  static const socket = Color(0xFF1E0814);
  static const tray = Color(0xFF240A19);
  static const soft = Color(0xFFFFD3E2);
}
