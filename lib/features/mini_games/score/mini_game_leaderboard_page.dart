import '../ludo/ludo_game_screen.dart';
import '../snakes_ladders/snl_game_screen.dart';
import '../ludo/ludo_score_service.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:hash/utils/widgets/home_section_title.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
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
  // Podium metals. Gold is the home palette's reward colour.
  static const Color _silver = Color(0xFFC7D2E0);
  static const Color _bronze = Color(0xFFD8975A);

  late final ChatService _chatService;

  // Board paging: the first page is live (podium updates as scores land),
  // later pages load once as the list nears its end. [_boardToken] drops
  // results that arrive after the user has switched boards.
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
    const MapEntry('wordly', 'Wordly'),
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
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            _buildFilterStrip(),
            const SizedBox(height: 6),
            Expanded(child: _buildBoard(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          HomeIconAction(
            icon: Icons.arrow_back_rounded,
            label: 'Back',
            size: 44,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: HomeSectionTitle(
              eyebrow: 'Hash Arcade',
              title: 'Leader',
              accent: 'board',
            ),
          ),
          StreamBuilder<int>(
            stream: _chatService.streamUnreadCountForRoom(
              _leaderboardLobbyRoomId,
            ),
            builder: (context, snapshot) {
              final unread = snapshot.data ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  HomeIconAction(
                    icon: Icons.forum_rounded,
                    label: 'Open leaderboard chat',
                    size: 44,
                    onTap: _openingChat ? () {} : _openLeaderboardChat,
                  ),
                  if (unread > 0)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: HomeTokens.green,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(BuildContext context) {
    if (_loadingBoard) return const AppLinearLoader.screen();
    if (_boardError != null && _livePage.isEmpty) {
      return _messageState(
        icon: Icons.wifi_off_rounded,
        title: 'Couldn\'t load the leaderboard',
        body: 'Check your connection and try again.',
        actionLabel: 'Retry',
        onAction: _loadBoard,
      );
    }

    final entries = _mergedEntries();
    if (entries.isEmpty &&
        _selectedGameId == MiniGameLeaderboardService.overallGameId) {
      return _messageState(
        icon: Icons.emoji_events_outlined,
        title: 'No scores yet',
        body: 'Play any mini game to put the first score on the board.',
        actionLabel: 'Play Ludo',
        onAction: () => _openGameByKey(context, 'ludo'),
      );
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
        const SizedBox(height: 26),
        Row(
          children: [
            const Expanded(
              child: HomeSectionTitle(title: 'All ', accent: 'Players'),
            ),
            Text(
              '$players ranked',
              style: HomeTokens.body(HomeTokens.textTertiary, size: 12.5),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    ];
    final showFooter = _hasMore || _loadingMore;

    return RefreshIndicator(
      color: HomeTokens.green,
      backgroundColor: HomeTokens.surface,
      onRefresh: () => _loadBoard(keepRows: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          6,
          16,
          28 + MediaQuery.paddingOf(context).bottom,
        ),
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
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: AppLinearLoader()),
          );
        },
      ),
    );
  }

  Widget _buildFilterStrip() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _gameOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = _gameOptions[index];
          final selected = option.key == _selectedGameId;
          return Semantics(
            button: true,
            selected: selected,
            label: '${option.value} leaderboard',
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                if (_selectedGameId == option.key) return;
                setState(() => _selectedGameId = option.key);
                _loadBoard();
                unawaited(
                  _trackLeaderboardEvent('Arcade Leaderboard Filter Selected', {
                    'selected_board': option.key,
                    'selected_board_label': option.value,
                  }),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: selected
                      ? HomeTokens.green.withValues(alpha: 0.14)
                      : HomeTokens.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? HomeTokens.green.withValues(alpha: 0.6)
                        : HomeTokens.hairline,
                  ),
                ),
                child: Text(
                  option.value,
                  style: GoogleFonts.inter(
                    color: selected
                        ? HomeTokens.green
                        : HomeTokens.textSecondary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
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
    return HomeCard(
      accent: HomeTokens.gold,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: HomeTokens.gold,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: HomeEyebrow(
                  entries.isEmpty ? 'No runs yet' : 'Top players',
                  color: HomeTokens.gold,
                ),
              ),
              if (myRank != null)
                _Pill(label: 'You #$myRank', color: HomeTokens.green),
            ],
          ),
          const SizedBox(height: 18),
          if (entries.isEmpty)
            _emptyFilteredState()
          else
            Row(
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
      1 => 64.0,
      2 => 46.0,
      _ => 34.0,
    };
    final isMe = data.userId == FirebaseAuth.instance.currentUser?.uid;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
              _Avatar(
                name: data.displayName,
                photo: data.avatarUrl,
                size: rank == 1 ? 68 : 54,
                ring: color,
                glow: rank == 1,
              ),
              if (rank == 1)
                const Positioned(
                  top: -22,
                  child: Text('👑', style: TextStyle(fontSize: 26, height: 1)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              isMe ? 'You' : data.displayName.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: HomeTokens.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_displayScore(data)}',
            style: GoogleFonts.inter(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: pedestal,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
                bottom: Radius.circular(6),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.32),
                  color.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Text(
              '$rank',
              style: GoogleFonts.inter(
                color: color,
                fontSize: rank == 1 ? 26 : 20,
                fontWeight: FontWeight.w900,
              ),
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
    final myScore = myEntry == null ? 0 : _displayScore(myEntry);
    final targetScore = nextTarget == null ? null : _displayScore(nextTarget);
    final gap = myEntry != null && targetScore != null
        ? (targetScore - myScore).clamp(1, 999999)
        : null;
    final line = myEntry == null
        ? 'Play ${_selectedGameLabel()} to get on the board'
        : nextTarget == null
        ? 'You\'re #1 — defend the crown'
        : '$gap pts to pass ${nextTarget.displayName.split(' ').first}';
    // Progress toward the next player up; full when leading.
    final progress = myEntry == null
        ? 0.0
        : targetScore == null || targetScore <= 0
        ? 1.0
        : (myScore / targetScore).clamp(0.0, 1.0);

    Widget stat(String label, String value, Color color) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: HomeTokens.eyebrow(HomeTokens.textTertiary)),
        ],
      ),
    );
    Widget divider() =>
        Container(width: 1, height: 30, color: HomeTokens.hairline);

    return HomeCard(
      accent: HomeTokens.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeEyebrow('Your standing'),
          const SizedBox(height: 14),
          Row(
            children: [
              stat(
                'Rank',
                myRank == null ? '—' : '#$myRank',
                HomeTokens.textPrimary,
              ),
              divider(),
              stat('Score', '$myScore', HomeTokens.green),
              divider(),
              stat('Top', '$topScore', HomeTokens.gold),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  line,
                  style: GoogleFonts.inter(
                    color: HomeTokens.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (myEntry != null && nextTarget != null)
                Text(
                  '${(progress * 100).round()}%',
                  style: HomeTokens.body(HomeTokens.textTertiary, size: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation(HomeTokens.green),
            ),
          ),
          const SizedBox(height: 16),
          HomeCta(
            label: myEntry == null
                ? 'Play ${_selectedGameLabel()}'
                : 'Play to climb',
            icon: Icons.sports_esports_rounded,
            height: 48,
            onTap: () =>
                myEntry != null &&
                    _selectedGameId == MiniGameLeaderboardService.overallGameId
                ? _openBestGame(context, myEntry)
                : _openSelectedGame(context),
          ),
          const SizedBox(height: 10),
          Text(
            '$players players on the ${_selectedGameLabel()} board',
            textAlign: TextAlign.center,
            style: HomeTokens.body(HomeTokens.textTertiary, size: 12),
          ),
        ],
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: HomeCard(
          accent: HomeTokens.green,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(icon, color: HomeTokens.green, size: 40),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: HomeTokens.title(20),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: HomeTokens.body(HomeTokens.textSecondary),
              ),
              const SizedBox(height: 18),
              HomeCta(label: actionLabel, height: 46, onTap: onAction),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyFilteredState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        'No ranked runs for ${_selectedGameLabel()} yet. Be the first!',
        textAlign: TextAlign.center,
        style: HomeTokens.body(HomeTokens.textSecondary),
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
        ? 'Best at ${_primaryGame(data.scores)}'
        : '${data.totalScore} pts overall';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isCurrentUser
            ? HomeTokens.green.withValues(alpha: 0.08)
            : HomeTokens.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showPlayerSheet(
            context: context,
            rank: rank,
            data: data,
            topScore: topScore,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCurrentUser
                    ? HomeTokens.green.withValues(alpha: 0.5)
                    : HomeTokens.hairline,
              ),
            ),
            child: Row(
              children: [
                // Wider slot once ranks reach three digits (uncapped board);
                // anything longer scales down rather than wrapping.
                SizedBox(
                  width: rank >= 100 ? 44 : 34,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$rank',
                      style: GoogleFonts.inter(
                        color: HomeTokens.textTertiary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                _Avatar(
                  name: data.displayName,
                  photo: data.avatarUrl,
                  size: 40,
                  ring: isCurrentUser ? HomeTokens.green : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCurrentUser ? 'You' : data.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: HomeTokens.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HomeTokens.body(
                          HomeTokens.textTertiary,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_displayScore(data)}',
                  style: GoogleFonts.inter(
                    color: HomeTokens.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
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

    final rankColor = _rankColor(rank);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: HomeTokens.ink,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _Avatar(
                      name: data.displayName,
                      photo: data.avatarUrl,
                      size: 52,
                      ring: rankColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCurrentUser ? 'You' : data.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HomeTokens.title(18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            gapToTop == 0
                                ? 'Top of the ${_selectedGameLabel()} board'
                                : '$gapToTop pts behind #1',
                            style: HomeTokens.body(
                              HomeTokens.textSecondary,
                              size: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _Pill(label: '#$rank', color: rankColor),
                        const SizedBox(height: 6),
                        Text(
                          '${_displayScore(data)} pts',
                          style: GoogleFonts.inter(
                            color: HomeTokens.gold,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (sortedScores.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const HomeEyebrow(
                    'Best games',
                    color: HomeTokens.textTertiary,
                  ),
                  const SizedBox(height: 10),
                  HomeCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        for (final (i, entry) in sortedScores.take(4).indexed)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: i == 0
                                  ? null
                                  : const Border(
                                      top: BorderSide(
                                        color: HomeTokens.hairline,
                                      ),
                                    ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    MiniGameLeaderboardService.readableGameName(
                                      entry.key,
                                    ),
                                    style: HomeTokens.body(
                                      HomeTokens.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${entry.value}',
                                  style: GoogleFonts.inter(
                                    color: HomeTokens.gold,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _SheetButton(
                        icon: Icons.forum_rounded,
                        label: 'Lobby chat',
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _openLeaderboardChat();
                        },
                      ),
                    ),
                    if (!isCurrentUser) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: HomeCta(
                          label: 'Message',
                          icon: Icons.chat_bubble_rounded,
                          height: 48,
                          onTap: () async {
                            Navigator.pop(ctx);
                            await _openDirectChatWithEntry(data);
                          },
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
        backgroundColor: HomeTokens.surface,
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
        backgroundColor: HomeTokens.surface,
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
    if (rank == 1) return HomeTokens.gold;
    if (rank == 2) return _silver;
    if (rank == 3) return _bronze;
    return HomeTokens.textTertiary;
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

/// Player photo, or their initial on a tinted disc when there is no photo.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.photo,
    required this.size,
    this.ring,
    this.glow = false,
  });

  final String name;
  final String? photo;
  final double size;
  final Color? ring;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final url = (photo ?? '').trim();
    final initial = name.trim().isEmpty ? 'P' : name.trim()[0].toUpperCase();
    final ringColor = ring ?? HomeTokens.hairline;
    final fallback = Center(
      child: Text(
        initial,
        style: GoogleFonts.inter(
          color: HomeTokens.textPrimary,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: ring == null ? 1 : 2),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.45),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: ColoredBox(
          color: const Color(0xFF1E2430),
          child: url.isEmpty
              ? fallback
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Secondary action beside a [HomeCta] in the player sheet.
class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Material(
        color: HomeTokens.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HomeTokens.hairline),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: HomeTokens.textPrimary, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: HomeTokens.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
