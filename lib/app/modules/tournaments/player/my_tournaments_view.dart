import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/chat/views/chat_room_view.dart';

import '../data/dispute_chat_auth.dart';
import '../data/tournament_api.dart';
import '../data/tournament_models.dart';
import '../ui/tournament_theme.dart';
import '../ui/tournament_widgets.dart';
import 'tournaments_home_view.dart';

/// Joined tournaments, team invites, disputes and prize payouts.
/// Arguments: `{'tab': 'joined' | 'invites' | 'disputes' | 'payouts'}`.
class MyTournamentsView extends StatelessWidget {
  const MyTournamentsView({super.key});
  static const _tabs = ['joined', 'invites', 'disputes', 'payouts'];

  @override
  Widget build(BuildContext context) {
    final initial = _tabs.indexOf(
      jsonMap(Get.arguments)['tab']?.toString() ?? 'joined',
    );
    return DefaultTabController(
      length: 4,
      initialIndex: initial < 0 ? 0 : initial,
      child: Scaffold(
        backgroundColor: CT.bg,
        appBar: tAppBar(
          'My tournaments',
          bottom: tTabs(const [
            'Joined',
            'Invites',
            'Disputes',
            'Prizes',
          ], scrollable: true),
        ),
        body: const TabBarView(
          children: [
            _JoinedTab(),
            _InvitesTab(),
            _DisputesTab(),
            _PayoutsTab(),
          ],
        ),
      ),
    );
  }
}

/// Load-once list with pull-to-refresh, error and empty states.
class _AsyncList<T> extends StatefulWidget {
  final Future<List<T>> Function() load;
  final Widget Function(T item, VoidCallback reload) item;
  final TMessage empty;
  const _AsyncList({
    required this.load,
    required this.item,
    required this.empty,
  });

  @override
  State<_AsyncList<T>> createState() => _AsyncListState<T>();
}

class _AsyncListState<T> extends State<_AsyncList<T>>
    with AutomaticKeepAliveClientMixin {
  late Future<List<T>> _f = widget.load();
  void _reload() => setState(() => _f = widget.load());

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      color: CT.primary,
      onRefresh: () async {
        _reload();
        await _f.catchError((_) => <T>[]);
      },
      child: FutureBuilder<List<T>>(
        future: _f,
        builder: (_, s) {
          final children = s.connectionState != ConnectionState.done
              ? [const TLoading()]
              : s.hasError
              ? [TMessage.error(s.error!, _reload)]
              : s.data!.isEmpty
              ? [widget.empty]
              : [for (final x in s.data!) widget.item(x, _reload)];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            physics: const AlwaysScrollableScrollPhysics(),
            children: children,
          );
        },
      ),
    );
  }
}

class _JoinedTab extends StatelessWidget {
  const _JoinedTab();
  @override
  Widget build(BuildContext context) => _AsyncList<Tournament>(
    load: () async => (await TournamentApi().myTournaments('joined')).items,
    empty: TMessage(
      icon: Icons.emoji_events_outlined,
      title: 'No tournaments yet',
      subtitle: 'Join one from the Tournaments tab.',
    ),
    item: (t, reload) {
      final reg = Registration(jsonMap(t.raw['registration']));
      return TournamentCard(
        t,
        badge: reg.id.isEmpty
            ? null
            : TPill(reg.statusLabel, color: stateColor(reg.status)),
        onTap: () async {
          await openTournament(t.id);
          reload();
        },
      );
    },
  );
}

class _InvitesTab extends StatefulWidget {
  const _InvitesTab();
  @override
  State<_InvitesTab> createState() => _InvitesTabState();
}

class _InvitesTabState extends State<_InvitesTab> {
  String? _busyId;

  Future<void> _respond(
    TeamInvitation i,
    bool accept,
    VoidCallback reload,
  ) async {
    setState(() => _busyId = i.teamId);
    try {
      await TournamentApi().respondInvitation(
        i.tournamentId,
        i.teamId,
        accept: accept,
      );
      toast(accept ? 'You joined ${i.teamName}.' : 'Invitation declined.');
    } catch (e) {
      toastError(e);
    } finally {
      if (mounted) setState(() => _busyId = null);
      reload();
    }
  }

  @override
  Widget build(BuildContext context) => _AsyncList<TeamInvitation>(
    load: () async => (await TournamentApi().myInvitations()).items,
    empty: const TMessage(
      icon: Icons.mail_outline_rounded,
      title: 'No team invites',
      subtitle: 'When a captain adds you to a team, it shows up here.',
    ),
    item: (i, reload) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(i.teamName, style: CT.headline(16)),
            const SizedBox(height: 2),
            GestureDetector(
              onTap: () => openTournament(i.tournamentId),
              child: Text(
                '${i.tournamentTitle} · as ${i.role}',
                style: CT.body(13, color: CT.primary),
              ),
            ),
            const SizedBox(height: 12),
            if (i.canRespond)
              Row(
                children: [
                  Expanded(
                    child: TButton.secondary(
                      'Decline',
                      onTap: _busyId == null
                          ? () => _respond(i, false, reload)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TButton(
                      'Accept',
                      busy: _busyId == i.teamId,
                      onTap: () => _respond(i, true, reload),
                    ),
                  ),
                ],
              )
            else
              Text(
                'This invite can no longer be answered.',
                style: CT.body(12.5, color: CT.muted),
              ),
          ],
        ),
      ),
    ),
  );
}

class _DisputesTab extends StatelessWidget {
  const _DisputesTab();

  Future<void> _open(Dispute d) async {
    Dispute full = d;
    try {
      full = await TournamentApi().dispute(d.id);
    } catch (_) {}
    await Get.bottomSheet(
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(full.reason, style: CT.display(19))),
                TPill(
                  humanize(full.status),
                  color: full.isOpen ? CT.error : CT.success,
                ),
              ],
            ),
            if (full.tournamentTitle != null)
              Text(
                full.tournamentTitle!,
                style: CT.body(13, color: CT.primary),
              ),
            if (full.description != null) ...[
              const SizedBox(height: 10),
              Text(full.description!, style: CT.body(14)),
            ],
            if (full.deadline != null) ...[
              const SizedBox(height: 8),
              Text(
                'Response due ${fmtDateTime(full.deadline)}',
                style: CT.body(12.5),
              ),
            ],
            if (full.adminComment != null) ...[
              const SizedBox(height: 10),
              TPanel(
                child: Text(
                  'Referee: ${full.adminComment}',
                  style: CT.body(13.5, color: CT.onSurface),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (full.chatReady)
              TButton.secondary(
                'Open dispute chat',
                icon: Icons.chat_rounded,
                onTap: () async {
                  try {
                    final s = await DisputeChatAuth().authenticate();
                    Get.back();
                    Get.to(
                      () => ChatRoomView(
                        roomId: full.chatRoomId!,
                        roomCollection: 'communityDisputeRooms',
                        chatService: s.chatService,
                      ),
                    );
                  } catch (_) {
                    toast(
                      'Dispute chat is unavailable right now.',
                      error: true,
                    );
                  }
                },
              ),
            const SizedBox(height: 10),
            TButton(
              'View tournament',
              onTap: () {
                Get.back();
                openTournament(full.tournamentId);
              },
            ),
          ],
        ),
      ),
      backgroundColor: CT.surfaceLow,
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) => _AsyncList<Dispute>(
    load: () async => (await TournamentApi().myDisputes()).items,
    empty: const TMessage(
      icon: Icons.gavel_rounded,
      title: 'No disputes',
      subtitle: 'Disputes you raise or are part of appear here.',
    ),
    item: (d, _) => GestureDetector(
      onTap: () => _open(d),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: CT.card(),
        child: Row(
          children: [
            Icon(Icons.gavel_rounded, color: d.isOpen ? CT.error : CT.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.reason, style: CT.headline(14)),
                  Text(
                    d.tournamentTitle ?? fmtDateTime(d.createdAt),
                    style: CT.body(12.5),
                  ),
                ],
              ),
            ),
            TPill(humanize(d.status), color: d.isOpen ? CT.error : CT.success),
          ],
        ),
      ),
    ),
  );
}

class _PayoutsTab extends StatelessWidget {
  const _PayoutsTab();
  @override
  Widget build(BuildContext context) => _AsyncList<Payout>(
    load: () async => (await TournamentApi().myPayouts()).items,
    empty: const TMessage(
      icon: Icons.account_balance_wallet_outlined,
      title: 'No prizes yet',
      subtitle: 'Tournament winnings are paid into your Hash wallet.',
    ),
    item: (p, _) => Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: CT.card(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: CT.primary.withValues(alpha: 0.15),
            child: Text(
              p.rank == null ? '★' : '#${p.rank}',
              style: CT.headline(13, color: CT.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.tournamentTitle ?? 'Tournament prize',
                  style: CT.headline(14),
                ),
                Text(
                  p.statusLabel,
                  style: CT.body(12.5, color: stateColor(p.status)),
                ),
              ],
            ),
          ),
          Text(
            money(p.amount, p.currency),
            style: CT.headline(16, color: CT.primary),
          ),
        ],
      ),
    ),
  );
}
