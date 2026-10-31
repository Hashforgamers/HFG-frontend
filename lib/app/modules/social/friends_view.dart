import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:hash/utils/widgets/home_section_title.dart';

import '../chat/models/chat_user_model.dart';
import '../chat/services/chat_service.dart';
import '../chat/views/chat_room_view.dart';
import 'friend_service.dart';

/// Where a player stands relative to the signed-in user. Every row on this
/// screen shows exactly one of these, so it's always clear who is already a
/// friend, who is waiting on whom, and who can be added.
enum _Relation { friend, incoming, outgoing, none }

class FriendsView extends StatefulWidget {
  const FriendsView({
    super.key,
    this.initialTab = 0,
    this.autofocusSearch = false,
    this.onPlayerSelected,
  });

  /// 0 = Friends, 1 = Requests, 2 = Discover (all players).
  final int initialTab;
  final bool autofocusSearch;
  final ValueChanged<Map<String, dynamic>>? onPlayerSelected;

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView>
    with SingleTickerProviderStateMixin {
  final FriendService _friends = FriendService();
  final TextEditingController _search = TextEditingController();
  late final TabController _tabs = TabController(
    length: 3,
    vsync: this,
    initialIndex: widget.initialTab.clamp(0, 2),
  );
  late final Stream<List<FriendRelationship>> _relationshipStream = _friends
      .watchRelationships();

  // Fetched once per visit: building these in build() re-read every player
  // on each keystroke in the search box.
  late Future<List<Map<String, dynamic>>> _allPlayers = _friends.allPlayers();
  final Map<String, Future<Map<String, dynamic>?>> _profiles = {};

  /// Player uids with a request/accept/remove in flight, to disable their
  /// buttons and show progress instead of allowing double taps.
  final Set<String> _busy = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  String get _me => _friends.currentUid ?? '';

  Future<Map<String, dynamic>?> _profile(String uid) =>
      _profiles.putIfAbsent(uid, () => _friends.userProfile(uid));

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _run(
    String uid,
    Future<void> Function() action, {
    String? success,
  }) async {
    if (_busy.contains(uid)) return;
    setState(() => _busy.add(uid));
    try {
      await action();
      if (success != null) _toast(success);
    } catch (_) {
      _toast('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy.remove(uid));
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          backgroundColor: HomeTokens.surface,
        ),
      );
  }

  Future<void> _confirmRemove(
    FriendRelationship relationship,
    String name,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HomeTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HomeTokens.radius),
        ),
        title: Text('Remove $name?', style: HomeTokens.title(18)),
        content: Text(
          'You\'ll need to send a new request to be friends again.',
          style: HomeTokens.body(HomeTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF5252),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(
      relationship.otherUid(_me),
      () => _friends.remove(relationship),
      success: '$name removed from friends',
    );
  }

  void _selectPlayer(Map<String, dynamic> profile) {
    final callback = widget.onPlayerSelected;
    if (callback == null) return;
    Navigator.of(context).pop();
    callback(profile);
  }

  Future<void> _message(Map<String, dynamic> profile) async {
    final user = ChatUserModel.fromMap(profile);
    if (user.uid.isEmpty) return;
    final chat = Get.isRegistered<ChatService>()
        ? Get.find<ChatService>()
        : Get.put(ChatService(), permanent: true);
    final roomId = await chat.getOrCreateDirectRoom(otherUser: user);
    Get.to(() => ChatRoomView(roomId: roomId));
  }

  // ── Layout ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<FriendRelationship>>(
          stream: _relationshipStream,
          builder: (context, snapshot) {
            final all = snapshot.data ?? const <FriendRelationship>[];
            final friends = all.where((r) => r.status == 'accepted').toList();
            final incoming = all.where((r) => r.isIncoming(_me)).toList();
            final outgoing = all.where((r) => r.isOutgoing(_me)).toList();
            final loading =
                snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData;
            return Column(
              children: [
                _header(friends.length),
                _tabBar(friends: friends.length, requests: incoming.length),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      loading ? _loader() : _friendsTab(friends),
                      loading ? _loader() : _requestsTab(incoming, outgoing),
                      _discoverTab(all),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(int friendCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          HomeIconAction(
            icon: Icons.arrow_back_rounded,
            label: 'Back',
            size: 44,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: HomeSectionTitle(
              eyebrow: friendCount == 1 ? '1 friend' : '$friendCount friends',
              title: 'Your ',
              accent: 'Squad',
            ),
          ),
          HomeIconAction(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Find players',
            size: 44,
            onTap: () => _tabs.animateTo(2),
          ),
        ],
      ),
    );
  }

  Widget _tabBar({required int friends, required int requests}) {
    Widget tab(int index, String label, int? count, {bool alert = false}) {
      final selected = _tabs.index == index;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: count == null ? label : '$label, $count',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _tabs.animateTo(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? HomeTokens.green.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? HomeTokens.green.withValues(alpha: 0.55)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: selected
                          ? HomeTokens.green
                          : HomeTokens.textSecondary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  if (count != null && count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        // A pending incoming request is the one thing here
                        // that needs the user's action, so it gets colour.
                        color: alert
                            ? HomeTokens.gold
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: alert ? Colors.black : HomeTokens.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: HomeTokens.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: HomeTokens.hairline),
        ),
        child: Row(
          children: [
            tab(0, 'Friends', friends),
            tab(1, 'Requests', requests, alert: true),
            tab(2, 'Discover', null),
          ],
        ),
      ),
    );
  }

  // ── Friends ───────────────────────────────────────────────────────────────

  Widget _friendsTab(List<FriendRelationship> friends) {
    if (friends.isEmpty) {
      return _emptyState(
        icon: Icons.groups_rounded,
        title: 'No friends yet',
        body:
            'Add players you game with to see them here and message them '
            'in one tap.',
        actionLabel: 'Find players',
        onAction: () => _tabs.animateTo(2),
      );
    }
    return ListView.builder(
      padding: _listPadding,
      itemCount: friends.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return _sectionLabel('Friends', friends.length, HomeTokens.green);
        }
        final relationship = friends[i - 1];
        final uid = relationship.otherUid(_me);
        return _ProfileLoader(
          future: _profile(uid),
          builder: (profile) => _PlayerRow(
            profile: profile,
            relation: _Relation.friend,
            onTap: () => _selectPlayer(profile),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RoundAction(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Message',
                  onTap: () => _message(profile),
                ),
                _MoreMenu(
                  onRemove: () =>
                      _confirmRemove(relationship, _nameOf(profile)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Requests ──────────────────────────────────────────────────────────────

  Widget _requestsTab(
    List<FriendRelationship> incoming,
    List<FriendRelationship> outgoing,
  ) {
    if (incoming.isEmpty && outgoing.isEmpty) {
      return _emptyState(
        icon: Icons.mark_email_read_rounded,
        title: 'No pending requests',
        body:
            'Requests you receive and send show up here until they\'re '
            'answered.',
        actionLabel: 'Find players',
        onAction: () => _tabs.animateTo(2),
      );
    }
    final rows = <Widget>[
      if (incoming.isNotEmpty) ...[
        _sectionLabel('Received', incoming.length, HomeTokens.gold),
        for (final r in incoming) _incomingRow(r),
      ],
      if (outgoing.isNotEmpty) ...[
        if (incoming.isNotEmpty) const SizedBox(height: 14),
        _sectionLabel('Sent', outgoing.length, HomeTokens.textTertiary),
        for (final r in outgoing) _outgoingRow(r),
      ],
    ];
    return ListView(padding: _listPadding, children: rows);
  }

  Widget _incomingRow(FriendRelationship relationship) {
    final uid = relationship.otherUid(_me);
    final busy = _busy.contains(uid);
    return _ProfileLoader(
      future: _profile(uid),
      builder: (profile) => _PlayerRow(
        profile: profile,
        relation: _Relation.incoming,
        onTap: () => _selectPlayer(profile),
        trailing: busy
            ? const _Spinner()
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RoundAction(
                    icon: Icons.close_rounded,
                    label: 'Decline',
                    onTap: () => _run(
                      uid,
                      () => _friends.remove(relationship),
                      success: 'Request declined',
                    ),
                  ),
                  const SizedBox(width: 6),
                  _PillButton(
                    label: 'Accept',
                    icon: Icons.check_rounded,
                    onTap: () => _run(
                      uid,
                      () => _friends.accept(relationship),
                      success: 'You and ${_nameOf(profile)} are now friends',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _outgoingRow(FriendRelationship relationship) {
    final uid = relationship.otherUid(_me);
    final busy = _busy.contains(uid);
    return _ProfileLoader(
      future: _profile(uid),
      builder: (profile) => _PlayerRow(
        profile: profile,
        relation: _Relation.outgoing,
        onTap: () => _selectPlayer(profile),
        trailing: busy
            ? const _Spinner()
            : _PillButton(
                label: 'Cancel',
                subtle: true,
                onTap: () => _run(
                  uid,
                  () => _friends.remove(relationship),
                  success: 'Request cancelled',
                ),
              ),
      ),
    );
  }

  // ── Discover ──────────────────────────────────────────────────────────────

  Widget _discoverTab(List<FriendRelationship> relationships) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: HomeTokens.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HomeTokens.hairline),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: HomeTokens.green,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _search,
                    autofocus: widget.autofocusSearch,
                    cursorColor: HomeTokens.green,
                    style: HomeTokens.body(HomeTokens.textPrimary, size: 14),
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Search players by name or username',
                      hintStyle: HomeTokens.body(
                        HomeTokens.textTertiary,
                        size: 14,
                      ),
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: HomeTokens.textTertiary,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _allPlayers,
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _loader();
              }
              if (snapshot.hasError) {
                return _emptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Couldn\'t load players',
                  body: 'Check your connection and try again.',
                  actionLabel: 'Retry',
                  onAction: () =>
                      setState(() => _allPlayers = _friends.allPlayers()),
                );
              }
              final players = (snapshot.data ?? const []).where((p) {
                final text = '${p['display_name'] ?? ''} ${p['username'] ?? ''}'
                    .toLowerCase();
                return text.contains(_query);
              }).toList();
              if (players.isEmpty) {
                return _emptyState(
                  icon: Icons.person_search_rounded,
                  title: _query.isEmpty ? 'No players yet' : 'No matches',
                  body: _query.isEmpty
                      ? 'Players will show up here as they join Hash.'
                      : 'No player matches "${_search.text.trim()}".',
                );
              }
              return ListView.builder(
                padding: _listPadding.copyWith(top: 0),
                itemCount: players.length,
                itemBuilder: (_, i) => _discoverRow(players[i], relationships),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _discoverRow(
    Map<String, dynamic> player,
    List<FriendRelationship> relationships,
  ) {
    final uid = (player['uid'] ?? player['firebase_uid'] ?? '').toString();
    final relationship = relationships
        .where((r) => r.users.contains(uid))
        .firstOrNull;
    final relation = relationship == null
        ? _Relation.none
        : relationship.status == 'accepted'
        ? _Relation.friend
        : relationship.isIncoming(_me)
        ? _Relation.incoming
        : _Relation.outgoing;
    final busy = _busy.contains(uid);

    final Widget trailing;
    if (busy) {
      trailing = const _Spinner();
    } else {
      switch (relation) {
        case _Relation.friend:
          trailing = _RoundAction(
            icon: Icons.chat_bubble_rounded,
            label: 'Message',
            onTap: () => _message(player),
          );
        case _Relation.incoming:
          trailing = _PillButton(
            label: 'Accept',
            icon: Icons.check_rounded,
            onTap: () => _run(
              uid,
              () => _friends.accept(relationship!),
              success: 'You and ${_nameOf(player)} are now friends',
            ),
          );
        case _Relation.outgoing:
          trailing = _PillButton(
            label: 'Cancel',
            subtle: true,
            onTap: () => _run(
              uid,
              () => _friends.remove(relationship!),
              success: 'Request cancelled',
            ),
          );
        case _Relation.none:
          trailing = _PillButton(
            label: 'Add',
            icon: Icons.person_add_alt_1_rounded,
            onTap: () => _run(
              uid,
              () => _friends.sendRequest(uid),
              success: 'Friend request sent to ${_nameOf(player)}',
            ),
          );
      }
    }

    return _PlayerRow(
      profile: player,
      relation: relation,
      onTap: () => _selectPlayer(player),
      trailing: trailing,
    );
  }

  // ── Shared bits ───────────────────────────────────────────────────────────

  EdgeInsets get _listPadding =>
      EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.paddingOf(context).bottom);

  Widget _sectionLabel(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: HomeEyebrow('$label · $count', color: color),
    );
  }

  Widget _loader() => const Center(
    child: SizedBox(
      width: 26,
      height: 26,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: HomeTokens.green,
      ),
    ),
  );

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String body,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        HomeCard(
          accent: HomeTokens.green,
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: HomeTokens.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: HomeTokens.green, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: HomeTokens.title(19),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: HomeTokens.body(HomeTokens.textSecondary),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                HomeCta(label: actionLabel, height: 46, onTap: onAction),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _nameOf(Map<String, dynamic>? profile) =>
      (profile?['display_name'] ?? profile?['username'] ?? 'Player').toString();
}

/// Resolves a player's profile, showing a skeleton row until it arrives.
/// Missing profiles (deleted accounts) render nothing.
class _ProfileLoader extends StatelessWidget {
  const _ProfileLoader({required this.future, required this.builder});

  final Future<Map<String, dynamic>?> future;
  final Widget Function(Map<String, dynamic> profile) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _SkeletonRow();
        }
        final profile = snap.data;
        if (profile == null) return const SizedBox.shrink();
        return builder(profile);
      },
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.profile,
    required this.relation,
    required this.trailing,
    this.onTap,
  });

  final Map<String, dynamic> profile;
  final _Relation relation;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final user = ChatUserModel.fromMap(profile);
    final name = user.displayName.trim().isEmpty ? 'Player' : user.displayName;
    final handle = user.username.trim();
    final games = (profile['games'] as List?)
        ?.map((g) => g.toString())
        .where((g) => g.trim().isNotEmpty)
        .join(' · ');
    final subtitle = [
      if (handle.isNotEmpty) '@$handle',
      if (games != null && games.isNotEmpty) games,
    ].join('  ·  ');

    final highlight = switch (relation) {
      _Relation.friend => HomeTokens.green,
      _Relation.incoming => HomeTokens.gold,
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: HomeTokens.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    highlight?.withValues(alpha: 0.35) ?? HomeTokens.hairline,
              ),
            ),
            child: Row(
              children: [
                _Avatar(
                  name: name,
                  photo: user.photoUrl,
                  online: user.isOnline,
                  ring: highlight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: HomeTokens.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _RelationTag(relation: relation),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.isOnline
                            ? (subtitle.isEmpty
                                  ? 'Online now'
                                  : 'Online  ·  $subtitle')
                            : (subtitle.isEmpty ? 'Hash player' : subtitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HomeTokens.body(
                          user.isOnline
                              ? HomeTokens.green
                              : HomeTokens.textTertiary,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small status label beside a player's name.
class _RelationTag extends StatelessWidget {
  const _RelationTag({required this.relation});

  final _Relation relation;

  @override
  Widget build(BuildContext context) {
    final (String label, IconData icon, Color color)? spec = switch (relation) {
      _Relation.friend => (
        'Friend',
        Icons.check_circle_rounded,
        HomeTokens.green,
      ),
      _Relation.incoming => (
        'Wants to connect',
        Icons.mark_email_unread_rounded,
        HomeTokens.gold,
      ),
      _Relation.outgoing => (
        'Requested',
        Icons.schedule_rounded,
        HomeTokens.textSecondary,
      ),
      _Relation.none => null,
    };
    if (spec == null) return const SizedBox.shrink();
    final (label, icon, color) = spec;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.photo,
    required this.online,
    this.ring,
  });

  final String name;
  final String photo;
  final bool online;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    const size = 46.0;
    final initial = name.trim().isEmpty ? 'P' : name.trim()[0].toUpperCase();
    final fallback = Center(
      child: Text(
        initial,
        style: GoogleFonts.inter(
          color: HomeTokens.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ring ?? HomeTokens.hairline,
                width: ring == null ? 1 : 2,
              ),
            ),
            child: ClipOval(
              child: ColoredBox(
                color: const Color(0xFF1E2430),
                child: photo.trim().isEmpty
                    ? fallback
                    : Image.network(
                        photo.trim(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => fallback,
                      ),
              ),
            ),
          ),
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: HomeTokens.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: HomeTokens.surface, width: 2.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.subtle = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  /// Neutral outline for secondary actions like "Cancel".
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final fg = subtle ? HomeTokens.textSecondary : Colors.black;
    return Semantics(
      button: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: subtle
              ? null
              : const LinearGradient(
                  colors: [HomeTokens.greenBright, HomeTokens.green],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
          border: subtle ? Border.all(color: HomeTokens.hairline) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: fg, size: 16),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: fg,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.white.withValues(alpha: 0.06),
          shape: const CircleBorder(
            side: BorderSide(color: HomeTokens.hairline),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(icon, color: HomeTokens.textPrimary, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.onRemove});

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More',
      color: HomeTokens.surface,
      icon: const Icon(
        Icons.more_vert_rounded,
        color: HomeTokens.textTertiary,
        size: 20,
      ),
      onSelected: (action) {
        if (action == 'remove') onRemove();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              const Icon(
                Icons.person_remove_rounded,
                color: Color(0xFFFF5252),
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'Remove friend',
                style: HomeTokens.body(HomeTokens.textPrimary, size: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 14),
    child: SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: HomeTokens.green),
    ),
  );
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HomeTokens.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: HomeTokens.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [bar(120, 12), const SizedBox(height: 8), bar(80, 10)],
            ),
          ],
        ),
      ),
    );
  }
}
