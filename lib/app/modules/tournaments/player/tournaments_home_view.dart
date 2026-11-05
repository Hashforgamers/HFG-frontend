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
    padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
    child: Row(
      children: [
        Expanded(child: Text('Tournaments', style: CT.display(26))),
        IconButton(
          tooltip: 'My tournaments',
          onPressed: () => Get.toNamed(AppRoutes.MY_TOURNAMENTS),
          icon: const Icon(Icons.sports_esports_rounded, color: CT.onSurface),
        ),
        TextButton.icon(
          onPressed: () => Get.toNamed(AppRoutes.HOST_DASHBOARD),
          icon: const Icon(
            Icons.add_circle_outline_rounded,
            color: CT.primary,
            size: 18,
          ),
          label: Text('Host', style: CT.headline(14, color: CT.primary)),
        ),
      ],
    ),
  );

  Widget _inviteBanner() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
    child: GestureDetector(
      onTap: () async {
        await Get.toNamed(
          AppRoutes.MY_TOURNAMENTS,
          arguments: {'tab': 'invites'},
        );
        _loadInvites();
      },
      child: TPanel(
        border: CT.primary.withValues(alpha: 0.6),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.mail_rounded, color: CT.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _invites == 1
                    ? 'You have a team invite'
                    : 'You have $_invites team invites',
                style: CT.headline(14),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: CT.onSurfaceVariant),
          ],
        ),
      ),
    ),
  );

  Widget _filters() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Column(
      children: [
        TextField(
          controller: _search,
          onChanged: _onSearch,
          textInputAction: TextInputAction.search,
          style: CT.body(14, color: CT.onSurface),
          decoration: tInput('Search tournaments or games').copyWith(
            prefixIcon: const Icon(Icons.search_rounded, color: CT.muted),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final e in _views.entries) ...[
              ChoiceChip(
                label: Text(e.value),
                selected: _view == e.key,
                onSelected: (_) {
                  if (_view == e.key) return;
                  setState(() => _view = e.key);
                  _load();
                },
                showCheckmark: false,
                labelStyle: CT.body(
                  13,
                  color: _view == e.key ? Colors.black : CT.onSurface,
                  w: FontWeight.w600,
                ),
                selectedColor: CT.primary,
                backgroundColor: CT.surface,
                side: BorderSide(
                  color: _view == e.key ? CT.primary : CT.outline,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ],
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
            icon: Icons.emoji_events_outlined,
            title: _search.text.isEmpty
                ? 'No ${_views[_view]!.toLowerCase()} tournaments'
                : 'Nothing matches "${_search.text.trim()}"',
            subtitle: 'Host your own and invite your squad.',
            actionLabel: 'Host a tournament',
            onAction: () => Get.toNamed(AppRoutes.HOST_DASHBOARD),
          ),
        ),
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
