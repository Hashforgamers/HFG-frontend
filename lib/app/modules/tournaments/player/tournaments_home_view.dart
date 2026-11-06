import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../data/tournament_api.dart';
import '../data/tournament_models.dart';
import '../ui/tournament_theme.dart';
import '../ui/tournament_widgets.dart';

/// The Tournaments tab: discover community tournaments.
class TournamentsHomeView extends StatefulWidget {
  const TournamentsHomeView({super.key});

  @override
  State<TournamentsHomeView> createState() => _TournamentsHomeViewState();
}

class _TournamentsHomeViewState extends State<TournamentsHomeView> {
  static const _views = {
    'upcoming': 'Upcoming',
    'live': 'Live',
    'completed': 'Completed',
  };
  final _api = TournamentApi();
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  String _view = 'upcoming';
  final List<Tournament> _items = [];
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  int _invites = 0;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadInvites();
    _api.refreshIsHost();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) _loadMore();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final req = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _api.list(
        view: _view,
        search: _search.text.trim(),
        sort: _view == 'completed' ? 'recent' : 'soonest',
      );
      if (req != _request || !mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _page = page.page;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (req == _request && mounted) setState(() => _error = e);
    } finally {
      if (req == _request && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || _loading) return;
    final req = _request;
    setState(() => _loadingMore = true);
    try {
      final page = await _api.list(
        view: _view,
        search: _search.text.trim(),
        page: _page + 1,
        sort: _view == 'completed' ? 'recent' : 'soonest',
      );
      if (req != _request || !mounted) return;
      setState(() {
        _items.addAll(page.items);
        _page = page.page;
        _hasMore = page.hasMore;
      });
    } catch (_) {
      // Keep what is shown; the next scroll retries.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _loadInvites() async {
    try {
      if (!await _api.isSignedIn) return;
      final page = await _api.myInvitations();
      if (mounted) {
        setState(() => _invites = page.items.where((i) => i.canRespond).length);
      }
    } catch (_) {}
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CT.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: CT.primary,
          backgroundColor: CT.surfaceHigh,
          onRefresh: () async {
            await Future.wait([_load(), _loadInvites()]);
          },
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header()),
              if (_invites > 0) SliverToBoxAdapter(child: _inviteBanner()),
              SliverToBoxAdapter(
                child: ValueListenableBuilder<bool?>(
                  valueListenable: TournamentApi.isHost,
                  builder: (_, host, _) => switch (host) {
                    true => _hostShortcut(),
                    false => _hostHero(),
                    null => const SizedBox.shrink(),
                  },
                ),
              ),
              SliverToBoxAdapter(child: _filters()),
              ..._body(),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 14, 12, 4),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PLAY · COMPETE · WIN', style: CT.mono(10.5, color: CT.muted, w: FontWeight.w800)),
              const SizedBox(height: 4),
              Text.rich(TextSpan(children: [
                TextSpan(text: 'Compete on ', style: CT.display(26)),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GradientText('HASH', style: CT.display(26)),
                ),
              ])),
            ],
          ),
        ),
        _roundAction(Icons.sports_esports_rounded, 'My tournaments',
            () => Get.toNamed(AppRoutes.MY_TOURNAMENTS), badge: _invites),
      ],
    ),
  );

  Widget _roundAction(IconData icon, String label, VoidCallback onTap, {int badge = 0}) => Tooltip(
    message: label,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.06),
          shape: const CircleBorder(side: BorderSide(color: CT.outline)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(width: 46, height: 46, child: Icon(icon, color: Colors.white, size: 22)),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(color: CT.primary, shape: BoxShape.circle),
              child: Text('$badge', style: CT.headline(10, color: Colors.white, w: FontWeight.w800)),
            ),
          ),
      ],
    ),
  );

  /// For existing hosts: a compact way back to their tournaments.
  Widget _hostShortcut() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () async {
          await Get.toNamed(AppRoutes.HOST_DASHBOARD);
          _load();
        },
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: CT.card(borderColor: CT.outline),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Your tournaments', style: CT.headline(15, w: FontWeight.w800)),
                  Text('Manage entries, matches and results', style: CT.body(12.5)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: CT.onSurfaceVariant),
            ],
          ),
        ),
      ),
    ),
  );

  /// Host promo, styled like the home "Become a tournament host" card.
  Widget _hostHero() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
    child: GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.HOST_DASHBOARD),
      child: Container(
        height: 132,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: CT.outline,
        ),
        padding: const EdgeInsets.all(1.2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/host_program_hero.jpg', fit: BoxFit.cover, alignment: const Alignment(1, -0.1)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B0D12), Color(0xF00B0D12), Color(0x330B0D12)],
                    stops: [0, 0.5, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('HOST PROGRAM', style: CT.mono(10, color: CT.onSurfaceVariant, w: FontWeight.w800)),
                    Text('Run your own\ntournament', style: CT.display(20)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Start hosting', style: CT.headline(12.5, color: Colors.black, w: FontWeight.w800)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.black),
                      ]),
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

  Widget _inviteBanner() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: GestureDetector(
      onTap: () async {
        await Get.toNamed(AppRoutes.MY_TOURNAMENTS, arguments: {'tab': 'invites'});
        _loadInvites();
      },
      child: TPanel(
        border: CT.outline,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(color: Color(0x1FFFFFFF), shape: BoxShape.circle),
              child: const Icon(Icons.mail_rounded, color: Colors.white, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_invites == 1 ? 'You have a team invite' : 'You have $_invites team invites',
                    style: CT.headline(14.5, w: FontWeight.w700)),
                Text('Tap to accept or decline', style: CT.body(12)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: CT.onSurfaceVariant),
          ],
        ),
      ),
    ),
  );

  Widget _filters() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Column(
      children: [
        TextField(
          controller: _search,
          onChanged: _onSearch,
          textInputAction: TextInputAction.search,
          style: CT.body(14.5, color: CT.onSurface),
          decoration: tInput('Search tournaments or games').copyWith(
            prefixIcon: const Icon(Icons.search_rounded, color: CT.muted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: CT.outline)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: CT.outline)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: CT.primary)),
          ),
        ),
        const SizedBox(height: 12),
        TSegments(
          options: _views,
          value: _view,
          onChanged: (v) {
            if (_view == v) return;
            setState(() => _view = v);
            _load();
          },
        ),
      ],
    ),
  );

  Widget _howItWorks() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: TPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How it works', style: CT.headline(15, w: FontWeight.w800)),
          const SizedBox(height: 12),
          for (final (i, step) in const [
            ('Join or host', 'Pick a tournament, or create one for your squad in minutes.'),
            ('Team up & check in', 'Invite friends, then check in before the first match.'),
            ('Play & report', 'Play in-game, then submit scores with a screenshot.'),
            ('Win prizes', 'Winnings go straight to your Hash wallet.'),
          ].indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: Color(0x1FFFFFFF), shape: BoxShape.circle),
                  child: Text('${i + 1}', style: CT.headline(12, color: Colors.white, w: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(step.$1, style: CT.headline(14, w: FontWeight.w700)),
                    Text(step.$2, style: CT.body(12.5)),
                  ]),
                ),
              ]),
            ),
        ],
      ),
    ),
  );

  List<Widget> _body() {
    if (_loading && _items.isEmpty) {
      return const [SliverToBoxAdapter(child: TLoading())];
    }
    if (_error != null && _items.isEmpty) {
      return [SliverToBoxAdapter(child: TMessage.error(_error!, _load))];
    }
    if (_items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: TMessage(
            icon: Icons.emoji_events_rounded,
            title: _search.text.isEmpty
                ? 'No ${_views[_view]!.toLowerCase()} tournaments yet'
                : 'Nothing matches "${_search.text.trim()}"',
            subtitle: _view == 'upcoming'
                ? 'Be the first. Host one and invite your squad.'
                : 'Check the upcoming tab for what\'s next.',
            actionLabel: _view == 'upcoming' ? 'Host a tournament' : null,
            onAction: () => Get.toNamed(AppRoutes.HOST_DASHBOARD),
          ),
        ),
        SliverToBoxAdapter(child: _howItWorks()),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        sliver: SliverList.builder(
          itemCount: _items.length + (_loadingMore ? 1 : 0),
          itemBuilder: (_, i) {
            if (i >= _items.length) return const TLoading();
            final t = _items[i];
            return TournamentCard(
              t,
              badge: t.isFeatured
                  ? const TPill('Featured', icon: Icons.star_rounded)
                  : null,
              onTap: () => openTournament(t.id),
            );
          },
        ),
      ),
    ];
  }
}

/// Single entry point used across the app to open a tournament.
Future<void> openTournament(String id, {String? inviteCode}) async {
  await Get.toNamed(
    AppRoutes.TOURNAMENT_DETAIL,
    arguments: {'id': id, 'invite_code': ?inviteCode},
    preventDuplicates: false,
  );
}
