import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/tournament_detail_controller.dart';
import '../../../routes/app_routes.dart';
import '../models/tournament.dart';
import '../../tournaments_section/models/tournament_model.dart';
import '../../tournaments_section/pages/tournaments_register_view.dart';
import 'community_theme.dart';
import 'tournament_share_poster_view.dart';
import 'tournaments_view.dart' show ctCurrency, ctAmount, ctStatus;

/// Tournament detail — GET /tournaments/<id> (+ register / cancel).
class TournamentDetailView extends GetView<TournamentDetailController> {
  const TournamentDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CT.bg,
      appBar: AppBar(
        backgroundColor: CT.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: CT.onSurface),
        title: Text('Tournament', style: CT.headline(18)),
        actions: [
          Obx(() {
            final tournament = controller.tournament.value;
            return IconButton(
              tooltip: 'Share publicity poster',
              onPressed: tournament == null
                  ? null
                  : () => Get.to(
                      () => TournamentSharePosterView(tournament: tournament),
                    ),
              icon: const Icon(Icons.ios_share_rounded, size: 20),
            );
          }),
        ],
      ),
      body: Obx(() {
        final t = controller.tournament.value;
        if (controller.loading.value && t == null) {
          return const AppLinearLoader.screen();
        }
        if (t == null) {
          return Center(
            child: Text(
              controller.error.value ?? 'Not found',
              style: CT.body(15),
            ),
          );
        }
        return _body(t);
      }),
      bottomNavigationBar: Obx(() {
        final t = controller.tournament.value;
        if (t == null) return const SizedBox.shrink();
        return _cta(t);
      }),
    );
  }

  Widget _body(Tournament t) {
    final sym = ctCurrency(t.currency);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(height: 180, width: double.infinity, child: _banner(t)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.title, style: CT.display(24)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _chip(t.game, CT.secondary),
                  const SizedBox(width: 8),
                  if (t.tournamentType != null)
                    _chip(t.tournamentType!.replaceAll('_', ' '), CT.muted),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: CT.card(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat(
                      'ENTRY',
                      t.isFree ? 'FREE' : '$sym${ctAmount(t.entryFee)}',
                    ),
                    _stat('PRIZE POOL', '$sym${ctAmount(t.prizePool)}'),
                    _stat(
                      'PLAYERS',
                      '${t.registeredPlayersCount}/${t.maxPlayers}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (t.description != null && t.description!.isNotEmpty) ...[
                _section('About'),
                Text(t.description!, style: CT.body(14)),
                const SizedBox(height: 16),
              ],
              _section('Schedule'),
              _row('Registration ends', _fmt(t.registrationEndAt)),
              _row('Starts', _fmt(t.tournamentStartAt)),
              const SizedBox(height: 16),
              if (t.rules != null && t.rules!.isNotEmpty) ...[
                _section('Rules'),
                Text(t.rules!, style: CT.body(14)),
                const SizedBox(height: 16),
              ],
              if (t.prizeDistribution.isNotEmpty) ...[
                _section('Prize split'),
                for (final p in t.prizeDistribution)
                  _row('Rank ${p.rank}', '${p.percent}%'),
                const SizedBox(height: 16),
              ],
              if ((t.roomDetails?.isNotEmpty ?? false) ||
                  t.roomDetailsData != null) ...[
                _section('Room details'),
                _roomDetailsCard(t),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  if (t.discordLink != null && t.discordLink!.isNotEmpty)
                    _linkBtn('Discord', Icons.discord, t.discordLink!),
                  if (t.whatsappLink != null && t.whatsappLink!.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    _linkBtn('WhatsApp', Icons.chat_rounded, t.whatsappLink!),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cta(Tournament t) {
    final st = ctStatus(t.status);
    final canRegister = t.canRegister;
    return Container(
      color: CT.surfaceLow,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + Get.mediaQuery.padding.bottom,
      ),
      child: Obx(
        () => SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: controller.canManage.value
                ? () => Get.toNamed(
                    AppRoutes.MANAGE_TOURNAMENT,
                    arguments: {'id': t.id},
                  )
                : controller.acting.value || !canRegister
                ? null
                : () => _openRegistration(t),
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.canManage.value || canRegister
                  ? CT.primary
                  : CT.surfaceHigh,
              disabledBackgroundColor: CT.surfaceHigh,
              foregroundColor: Colors.white,
              disabledForegroundColor: CT.muted,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: controller.acting.value
                ? const AppLinearLoader.button()
                : Text(
                    controller.canManage.value
                        ? 'Manage tournament'
                        : canRegister
                        ? (t.isFree
                              ? 'Register — Free'
                              : 'Register — ${ctCurrency(t.currency)}${ctAmount(t.entryFee)}')
                        : st.label,
                    style: CT.headline(
                      15,
                      color: controller.canManage.value || canRegister
                          ? Colors.white
                          : CT.muted,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _openRegistration(Tournament tournament) async {
    final appTournament = TournamentModel.fromJson({
      'id': tournament.id,
      'source': 'community',
      'title': tournament.title,
      'game': tournament.game,
      'team_mode': tournament.teamMode ?? 'solo',
      'entry_fee': tournament.entryFee,
      'currency': tournament.currency,
      'banner_url': tournament.bannerUrl ?? '',
      'image_url': tournament.bannerUrl ?? '',
      'start_date': tournament.tournamentStartAt?.toIso8601String(),
      'end_date': tournament.tournamentEndAt?.toIso8601String(),
      'status': tournament.status,
      'max_players': tournament.maxPlayers,
      'players_count': tournament.registeredPlayersCount,
      'prize_pool': tournament.prizePool,
      'description': tournament.description ?? '',
      'rules': tournament.rules ?? '',
      'host_user_id': tournament.hostUserId,
      'can_manage': tournament.canManage,
    });
    await Get.to(() => TournamentsRegisterView(tournament: appTournament));
    await controller.refreshDetail();
  }

  Widget _banner(Tournament t) {
    if (t.bannerUrl != null && t.bannerUrl!.isNotEmpty) {
      return Image.network(
        t.bannerUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B2410), Color(0xFF090909)],
      ),
    ),
    child: Center(
      child: Icon(
        Icons.sports_esports_rounded,
        color: CT.primary.withOpacity(0.5),
        size: 48,
      ),
    ),
  );

  Widget _section(String s) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(s.toUpperCase(), style: CT.mono(11, color: CT.secondary)),
  );

  Widget _roomDetailsCard(Tournament tournament) {
    final rows = tournament.roomDetailsData == null
        ? const <MapEntry<String, String>>[]
        : _roomRows(tournament.roomDetailsData!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CT.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CT.primary.withValues(alpha: .4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tournament.roomDetails?.isNotEmpty ?? false) ...[
            SelectableText(
              tournament.roomDetails!,
              style: CT.body(14, color: CT.onSurface),
            ),
            if (rows.isNotEmpty) const Divider(color: CT.outline, height: 24),
          ],
          for (var index = 0; index < rows.length; index++) ...[
            Text(
              rows[index].key,
              style: CT.mono(9, color: CT.onSurfaceVariant),
            ),
            const SizedBox(height: 3),
            SelectableText(
              rows[index].value,
              style: CT.body(13, color: CT.onSurface, w: FontWeight.w600),
            ),
            if (index != rows.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  List<MapEntry<String, String>> _roomRows(RoomDetailsData details) {
    final rows = <MapEntry<String, String>>[];
    for (final entry in details.join.entries) {
      _appendRoomValue(rows, 'Join · ${_roomLabel(entry.key)}', entry.value);
    }
    for (final entry in details.schedule.entries) {
      _appendRoomValue(
        rows,
        'Schedule · ${_roomLabel(entry.key)}',
        entry.value,
      );
    }
    for (final contact in details.contacts) {
      final channel = contact['channel']?.toString().trim();
      final value = contact['value'];
      _appendRoomValue(
        rows,
        'Contact · ${channel?.isNotEmpty == true ? channel! : 'Contact'}',
        value,
      );
      for (final entry in contact.entries) {
        if (entry.key == 'channel' || entry.key == 'value') continue;
        _appendRoomValue(
          rows,
          'Contact · ${_roomLabel(entry.key)}',
          entry.value,
        );
      }
    }
    for (final field in details.customFields) {
      final label = field['label']?.toString().trim();
      _appendRoomValue(
        rows,
        label?.isNotEmpty == true ? label! : 'Custom field',
        field['value'],
      );
      for (final entry in field.entries) {
        if (entry.key == 'label' || entry.key == 'value') continue;
        _appendRoomValue(
          rows,
          '${label?.isNotEmpty == true ? label! : 'Custom'} · ${_roomLabel(entry.key)}',
          entry.value,
        );
      }
    }
    for (final entry in details.additionalFields.entries) {
      _appendRoomValue(rows, _roomLabel(entry.key), entry.value);
    }
    return rows;
  }

  void _appendRoomValue(
    List<MapEntry<String, String>> rows,
    String label,
    dynamic value,
  ) {
    if (value == null) return;
    if (value is Map) {
      for (final entry in value.entries) {
        _appendRoomValue(
          rows,
          '$label · ${_roomLabel(entry.key.toString())}',
          entry.value,
        );
      }
      return;
    }
    if (value is List) {
      for (var index = 0; index < value.length; index++) {
        _appendRoomValue(rows, '$label ${index + 1}', value[index]);
      }
      return;
    }
    final text = value.toString().trim();
    if (text.isEmpty) return;
    final parsedDate = DateTime.tryParse(text);
    rows.add(MapEntry(label, parsedDate == null ? text : _fmt(parsedDate)));
  }

  String _roomLabel(String key) {
    final words = key.replaceAll('_', ' ').trim();
    if (words.isEmpty) return 'Detail';
    return '${words[0].toUpperCase()}${words.substring(1)}';
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: CT.body(13, color: CT.onSurfaceVariant)),
        Text(
          v,
          style: CT.body(13, color: CT.onSurface, w: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _stat(String label, String value) => Column(
    children: [
      Text(label, style: CT.mono(9)),
      const SizedBox(height: 3),
      Text(value, style: CT.headline(15)),
    ],
  );

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(
      text,
      style: CT.body(12, color: color, w: FontWeight.w600),
    ),
  );

  Widget _linkBtn(String label, IconData icon, String url) => Expanded(
    child: OutlinedButton.icon(
      onPressed: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: CT.secondary,
        side: BorderSide(color: CT.secondary.withOpacity(0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    final l = d.toLocal();
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final ap = l.hour < 12 ? 'AM' : 'PM';
    final min = l.minute.toString().padLeft(2, '0');
    return '${m[l.month - 1]} ${l.day}, $h:$min $ap';
  }
}
