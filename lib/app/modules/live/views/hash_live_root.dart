import 'package:url_launcher/url_launcher.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/app/modules/live/utils/live_time.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/optimized_app_bar.dart';
import 'package:hash/app/modules/live/controllers/hash_live_controller.dart';
import 'package:hash/app/modules/live/models/live_stream_model.dart';
import 'package:hash/app/modules/live/models/upcoming_stream_model.dart';
import 'package:hash/app/modules/live/services/hash_live_service.dart';
import 'package:hash/app/modules/live/utils/live_youtube_utils.dart';
import 'package:hash/app/modules/live/views/live_stream_screen.dart';
import 'package:hash/app/modules/live/widgets/hash_live_bottom_nav.dart';
import 'package:hash/app/modules/live/widgets/live_ui.dart';
import 'package:intl/intl.dart';

class HashLiveRoot extends StatefulWidget {
  const HashLiveRoot({super.key});

  @override
  State<HashLiveRoot> createState() => _HashLiveRootState();
}

class _HashLiveRootState extends State<HashLiveRoot> {
  late final HashLiveController _controller;
  late final HashLiveService _service;
  bool _showLiveHostActions = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<HashLiveController>()
        ? Get.find<HashLiveController>()
        : Get.put(HashLiveController(), permanent: true);
    _service = Get.isRegistered<HashLiveService>()
        ? Get.find<HashLiveService>()
        : Get.put(HashLiveService(), permanent: true);
    _service.startUpcomingStartAlerts();
    _service.startLiveAlertInboxListener();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: LiveUi.bg,
        body: Container(
          decoration: LiveUi.pageDecoration(),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => const [
              OptimizedAppBar(
                gradientBottomColor: LiveUi.accent,
                avatarBorderColor: LiveUi.accentSoft,
              ),
            ],
            body: IndexedStack(
              index: _controller.selectedTab.value,
              children: const [_DiscoverTab(), _GoLiveTab(), _HostTab()],
            ),
          ),
        ),
        bottomNavigationBar: HashLiveBottomNav(
          currentIndex: _controller.selectedTab.value,
          onTap: _controller.setTab,
        ),
        floatingActionButton: StreamBuilder<Map<String, dynamic>?>(
          stream: _service.watchHostProfile(_service.currentUid ?? ''),
          builder: (context, snapshot) {
            final activeStreamId = (snapshot.data?['active_stream_id'] ?? '')
                .toString();
            final isLive = snapshot.data?['is_live'] == true;
            final shouldShow = _controller.selectedTab.value == 0;
            if (activeStreamId.isEmpty || !isLive || !shouldShow) {
              return const SizedBox.shrink();
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_showLiveHostActions) ...[
                  _fabAction(
                    label: 'Resume Live',
                    color: LiveUi.accentSoft,
                    icon: Icons.play_arrow_rounded,
                    onTap: () {
                      setState(() => _showLiveHostActions = false);
                      Get.to(() => LiveStreamScreen(streamId: activeStreamId));
                    },
                  ),
                  const SizedBox(height: 8),
                  _fabAction(
                    label: 'End Stream',
                    color: LiveUi.accent,
                    icon: Icons.stop_circle_rounded,
                    onTap: () async {
                      await _controller.endLive(streamId: activeStreamId);
                      if (mounted) setState(() => _showLiveHostActions = false);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                FloatingActionButton(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  onPressed: () => setState(
                    () => _showLiveHostActions = !_showLiveHostActions,
                  ),
                  child: _showLiveHostActions
                      ? const Icon(Icons.close, color: Colors.white)
                      : _liveBadgeFab(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _fabAction({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: LiveUi.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.40), blurRadius: 14),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _liveBadgeFab() {
    const ring = LiveUi.accent;
    const ringSoft = LiveUi.accentSoft;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LiveUi.surfaceSoft, LiveUi.bg],
        ),
        border: Border.all(color: ringSoft, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: ring.withValues(alpha: 0.34),
            blurRadius: 14,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10, width: 1),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ring.withValues(alpha: 0.18),
              border: Border.all(color: ring, width: 1.2),
              boxShadow: [
                BoxShadow(color: ring.withValues(alpha: 0.45), blurRadius: 10),
              ],
            ),
            child: Center(
              child: Text(
                'LIVE',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverTab extends StatefulWidget {
  const _DiscoverTab();

  @override
  State<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<_DiscoverTab> {
  final _controller = Get.find<HashLiveController>();
  final _service = Get.find<HashLiveService>();

  // Created once: rebuilds must not resubscribe to Firestore.
  late final _live = _controller.liveStreams;
  late final _upcoming = _service.watchUpcomingStreams();
  late final _recent = _service.watchRecentStreams();

  /// Empty means all games.
  String _game = '';

  List<T> _byGame<T>(List<T> items, String Function(T) gameOf) =>
      _game.isEmpty ? items : items.where((e) => gameOf(e) == _game).toList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LiveStreamModel>>(
      stream: _live,
      builder: (context, liveSnap) {
        final streams = _byGame(
          liveSnap.data ?? const <LiveStreamModel>[],
          (s) => s.game,
        );
        final loadingLive = liveSnap.connectionState == ConnectionState.waiting;
        return StreamBuilder<List<UpcomingStreamModel>>(
          stream: _upcoming,
          builder: (context, upSnap) {
            final upcoming = _byGame(
              upSnap.data ?? const <UpcomingStreamModel>[],
              (s) => s.game,
            );
            final loadingUp = upSnap.connectionState == ConnectionState.waiting;
            return StreamBuilder<List<LiveStreamModel>>(
              stream: _recent,
              builder: (context, recentSnap) {
                final recent = _byGame(
                  recentSnap.data ?? const <LiveStreamModel>[],
                  (s) => s.game,
                );
                final quiet = !loadingLive && streams.isEmpty;
                // When nobody is live, the soonest scheduled stream becomes
                // the hero so the page still has something to look forward to.
                final hero = quiet && upcoming.isNotEmpty
                    ? upcoming.first
                    : null;
                final rail = hero == null
                    ? upcoming
                    : upcoming.skip(1).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        children: [
                          for (final game in ['', ..._controller.games]) ...[
                            _GameChip(
                              label: game.isEmpty ? 'All' : game,
                              selected: _game == game,
                              onTap: () => setState(() => _game = game),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (loadingLive)
                      const _LiveLoading(height: 270)
                    else if (streams.isNotEmpty) ...[
                      LiveSectionTitle(
                        'Live now',
                        trailing: '${streams.length} streaming',
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 270,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: streams.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (_, i) =>
                              _StanLiveCard(stream: streams[i], width: 304),
                        ),
                      ),
                    ] else
                      _QuietBanner(onGoLive: () => _controller.setTab(1)),
                    if (hero != null) ...[
                      const SizedBox(height: 22),
                      const LiveSectionTitle('Next up'),
                      const SizedBox(height: 12),
                      _UpcomingCard(item: hero, hero: true),
                    ],
                    if (loadingUp || rail.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      LiveSectionTitle(
                        'Coming up',
                        trailing: rail.isEmpty
                            ? null
                            : '${rail.length} scheduled',
                      ),
                      const SizedBox(height: 12),
                      if (loadingUp)
                        const _LiveLoading(height: 128)
                      else
                        SizedBox(
                          height: 128,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: rail.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (_, i) =>
                                _UpcomingCard(item: rail[i], width: 290),
                          ),
                        ),
                    ] else if (quiet && hero == null) ...[
                      const SizedBox(height: 22),
                      LiveEmptyState(
                        icon: Icons.event_available_rounded,
                        title: 'Nothing scheduled yet',
                        message:
                            'Schedule a stream and your followers get a '
                            'reminder before it starts.',
                        actionLabel: 'Schedule a stream',
                        onAction: () => _controller.setTab(1),
                      ),
                    ],
                    if (recent.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      const LiveSectionTitle('Catch the replays'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 186,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: recent.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (_, i) => _ReplayCard(stream: recent[i]),
                        ),
                      ),
                    ],
                    if (streams.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      LiveCta(
                        label: 'Start a live stream',
                        icon: Icons.videocam_rounded,
                        height: 54,
                        onTap: () => _controller.setTab(1),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Compact "nobody's live" row with a Go live action, instead of a page-high
/// empty card, so upcoming streams and replays stay above the fold.
class _QuietBanner extends StatelessWidget {
  const _QuietBanner({required this.onGoLive});
  final VoidCallback onGoLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: LiveUi.cardDecoration(radius: LiveUi.radiusMd),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LiveUi.accent.withValues(alpha: 0.12),
              border: Border.all(color: LiveUi.accent.withValues(alpha: 0.35)),
            ),
            child: const Icon(
              Icons.wifi_tethering_rounded,
              color: LiveUi.accentSoft,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Nobody's live right now", style: LiveUi.title),
                const SizedBox(height: 2),
                Text(
                  'Go first. Your followers get a ping.',
                  style: LiveUi.body,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _PillButton(
            label: 'Go live',
            icon: Icons.videocam_rounded,
            filled: true,
            onTap: onGoLive,
          ),
        ],
      ),
    );
  }
}

/// Small red pill action used on the Discover cards.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? LiveUi.accent : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: filled ? LiveUi.accent : LiveUi.accent.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          Haptics.selection();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: filled ? Colors.white : LiveUi.accentSoft,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: filled ? Colors.white : LiveUi.accentSoft,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps the horizontal rails at their real height while loading, so the page
/// does not jump when streams arrive.
class _LiveLoading extends StatelessWidget {
  const _LiveLoading({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: const Center(
      child: CircularProgressIndicator(color: LiveUi.accentSoft),
    ),
  );
}

class _GoLiveTab extends StatelessWidget {
  const _GoLiveTab();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HashLiveController>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text('Go live', style: LiveUi.heading(24)),
        const SizedBox(height: 4),
        Text(
          'Stream on YouTube, then share it with the Hash crowd.',
          style: GoogleFonts.inter(
            color: LiveUi.textSecondary,
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        const _GoLiveSteps(),
        const SizedBox(height: 16),
        LiveCard(
          accent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LiveEyebrow('Stream details'),
              const SizedBox(height: 14),
              _label('Title'),
              const SizedBox(height: 6),
              TextField(
                controller: controller.titleController,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: Colors.white),
                decoration: LiveUi.input(
                  hint: 'e.g. Ranked grind to Immortal',
                ).copyWith(counterStyle: LiveUi.body),
              ),
              const SizedBox(height: 6),
              _label('Game'),
              const SizedBox(height: 8),
              Obx(
                () => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final game in controller.games)
                      _GameChip(
                        label: game,
                        selected: controller.selectedGame.value == game,
                        onTap: () => controller.setGame(game),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _label('YouTube live link'),
              const SizedBox(height: 6),
              const _YoutubeLinkField(),
              const SizedBox(height: 6),
              Obx(
                () => SwitchListTile(
                  value: controller.isStreamingFromCafe.value,
                  activeThumbColor: LiveUi.accentSoft,
                  title: Text(
                    'Streaming from a café',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Shows a café badge on your stream',
                    style: LiveUi.body,
                  ),
                  onChanged: controller.setStreamingFromCafe,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Obx(
          () => LiveCta(
            label: 'Start Live Now',
            icon: Icons.sensors_rounded,
            busy: controller.isSubmitting.value,
            onTap: () async {
              final streamId = await controller.startLive();
              if (streamId == null || streamId.isEmpty) return;
              Get.to(() => LiveStreamScreen(streamId: streamId));
            },
          ),
        ),
        const SizedBox(height: 24),
        LiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LiveEyebrow(
                'Schedule for later',
                color: LiveUi.textTertiary,
              ),
              const SizedBox(height: 4),
              Text(
                'Followers get a heads-up before you start.',
                style: LiveUi.body,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _quickScheduleChip(
                    label: '+1 hour',
                    onTap: () => controller.scheduledAt.value = DateTime.now()
                        .add(const Duration(hours: 1)),
                  ),
                  _quickScheduleChip(
                    label: 'Tonight 8 PM',
                    onTap: () {
                      final now = DateTime.now();
                      final tonight = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        20,
                        0,
                      );
                      controller.scheduledAt.value = tonight.isAfter(now)
                          ? tonight
                          : tonight.add(const Duration(days: 1));
                    },
                  ),
                  _quickScheduleChip(
                    label: 'Tomorrow 8 PM',
                    onTap: () {
                      final now = DateTime.now();
                      final tomorrow = now.add(const Duration(days: 1));
                      controller.scheduledAt.value = DateTime(
                        tomorrow.year,
                        tomorrow.month,
                        tomorrow.day,
                        20,
                        0,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(
                () => ListTile(
                  tileColor: LiveUi.surfaceSoft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    controller.scheduledAt.value == null
                        ? 'Pick a date and time'
                        : DateFormat(
                            'EEE, d MMM • hh:mm a',
                          ).format(controller.scheduledAt.value!),
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.scheduledAt.value != null)
                        IconButton(
                          onPressed: () => controller.scheduledAt.value = null,
                          tooltip: 'Clear time',
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white54,
                            size: 18,
                          ),
                          splashRadius: 16,
                        ),
                      const Icon(Icons.schedule, color: Colors.white70),
                    ],
                  ),
                  onTap: () async {
                    final now = DateTime.now();
                    final date = await showDatePicker(
                      context: context,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                      initialDate: now,
                    );
                    if (date == null) return;
                    if (!context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        now.add(const Duration(hours: 1)),
                      ),
                    );
                    if (time == null) return;
                    controller.scheduledAt.value = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => OutlinedButton.icon(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : () async {
                          final id = await controller.scheduleStream();
                          if (id == null || id.isEmpty) return;
                          controller.scheduledAt.value = null;
                          controller.setTab(0);
                        },
                  icon: const Icon(Icons.event_available_rounded, size: 18),
                  label: const Text('Schedule Stream'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: LiveUi.stroke),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(String t) => Text(
    t,
    style: GoogleFonts.inter(
      color: LiveUi.softText,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _quickScheduleChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: LiveUi.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }
}

/// Pill used for picking or filtering by game.
class _GameChip extends StatelessWidget {
  const _GameChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected ? LiveUi.liveGradient : null,
            color: selected ? null : LiveUi.surfaceSoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : LiveUi.stroke,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: selected ? Colors.white : LiveUi.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Three-step explainer so hosts know Hash Live only takes YouTube streams.
class _GoLiveSteps extends StatelessWidget {
  const _GoLiveSteps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.videocam_rounded, 'Go live on YouTube'),
      (Icons.link_rounded, 'Copy the live link'),
      (Icons.content_paste_rounded, 'Paste it here'),
    ];
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: LiveUi.surface,
                borderRadius: BorderRadius.circular(LiveUi.radiusSm),
                border: Border.all(color: LiveUi.hairline),
              ),
              child: Column(
                children: [
                  Icon(steps[i].$1, color: LiveUi.accentSoft, size: 20),
                  const SizedBox(height: 6),
                  Text(
                    '${i + 1}. ${steps[i].$2}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: LiveUi.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Link input that checks the link as you type and previews the stream, so a
/// bad link is caught before "Start Live" rather than after.
class _YoutubeLinkField extends StatelessWidget {
  const _YoutubeLinkField();

  @override
  Widget build(BuildContext context) {
    final textController = Get.find<HashLiveController>().youtubeController;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: textController,
      builder: (context, value, _) {
        final text = value.text.trim();
        final thumb = LiveYoutubeUtils.thumbnailUrl(text);
        final invalid = text.isNotEmpty && thumb == null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: textController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              style: const TextStyle(color: Colors.white),
              decoration: LiveUi.input(hint: 'youtube.com/live/… or youtu.be/…')
                  .copyWith(
                    prefixIcon: const Icon(
                      Icons.smart_display_rounded,
                      color: Color(0xFFFF0033),
                    ),
                    suffixIcon: text.isEmpty
                        ? IconButton(
                            tooltip: 'Paste link',
                            icon: const Icon(
                              Icons.content_paste_rounded,
                              color: Colors.white70,
                            ),
                            onPressed: () async {
                              final data = await Clipboard.getData(
                                Clipboard.kTextPlain,
                              );
                              final pasted = data?.text?.trim() ?? '';
                              if (pasted.isNotEmpty) {
                                textController.text = pasted;
                              }
                            },
                          )
                        : IconButton(
                            tooltip: 'Clear link',
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                            ),
                            onPressed: textController.clear,
                          ),
                    errorText: invalid
                        ? 'Only YouTube live links are allowed'
                        : null,
                    errorStyle: GoogleFonts.inter(
                      color: LiveUi.accentSoft,
                      fontSize: 12,
                    ),
                  ),
            ),
            if (thumb != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(LiveUi.radiusSm),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: thumb,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) =>
                            const ColoredBox(color: LiveUi.surfaceSoft),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF3DDC84),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'YouTube link looks good',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _HostTab extends StatelessWidget {
  const _HostTab();

  @override
  Widget build(BuildContext context) {
    final service = Get.find<HashLiveService>();
    final uid = service.currentUid ?? '';
    if (uid.isEmpty) {
      return const LiveEmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in to host',
        message:
            'Your streams, followers and schedule live here once you '
            'sign in.',
      );
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: service.watchHostProfile(uid),
      builder: (context, snapshot) {
        final host = snapshot.data ?? {};
        final name = (host['name'] ?? 'Host').toString();
        final photo = (host['photo_url'] ?? '').toString();
        final isLive = host['is_live'] == true;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: LiveUi.cardDecoration(radius: 18),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundImage: photo.isNotEmpty
                                ? CachedNetworkImageProvider(photo)
                                : null,
                            backgroundColor: LiveUi.accent,
                            child: photo.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.orbitron(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isLive
                                        ? LiveUi.accent
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isLive ? 'LIVE NOW' : 'OFFLINE',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _hostStatTile(
                              title: 'Followers',
                              icon: Icons.group_rounded,
                              stream: service.watchHostFollowersCount(uid),
                              onTap: () =>
                                  _showFollowersSheet(context, service, uid),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _hostStatTile(
                              title: 'Streams',
                              icon: Icons.videocam_rounded,
                              stream: service.watchHostTotalStreams(uid),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      'Posts',
                      style: GoogleFonts.inter(
                        color: LiveUi.softText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Studio profile',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<LiveStreamModel>>(
                  stream: service.watchHostStreams(uid),
                  builder: (context, snap) {
                    final posts = snap.data ?? const <LiveStreamModel>[];
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            color: LiveUi.accentSoft,
                          ),
                        ),
                      );
                    }
                    if (posts.isEmpty) {
                      return LiveEmptyState(
                        icon: Icons.video_library_rounded,
                        title: 'No streams yet',
                        message:
                            'Streams you finish show up here for your '
                            'followers to rewatch.',
                        actionLabel: 'Go live',
                        onAction: () =>
                            Get.find<HashLiveController>().setTab(1),
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.85,
                          ),
                      itemBuilder: (_, i) => _hostPostCard(posts[i]),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Upcoming',
                  style: GoogleFonts.inter(
                    color: LiveUi.softText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<UpcomingStreamModel>>(
                  stream: service.watchUpcomingStreams(),
                  builder: (context, snap) {
                    final all = snap.data ?? const <UpcomingStreamModel>[];
                    final mine = all.where((e) => e.hostUid == uid).toList();
                    if (mine.isEmpty) {
                      return LiveEmptyState(
                        icon: Icons.event_available_rounded,
                        title: 'Nothing scheduled',
                        message:
                            'Schedule ahead so followers get a reminder '
                            'before you start.',
                        actionLabel: 'Schedule a stream',
                        onAction: () =>
                            Get.find<HashLiveController>().setTab(1),
                      );
                    }
                    return Column(
                      children: mine
                          .map((item) => _HostUpcomingEditableCard(item: item))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _hostPostCard(LiveStreamModel item) {
    final thumb = LiveYoutubeUtils.thumbnailUrl(item.youtubeUrl);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Get.to(() => LiveStreamScreen(streamId: item.id)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumb != null)
                      CachedNetworkImage(
                        imageUrl: thumb,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) =>
                            Container(color: const Color(0xFF1E2630)),
                      )
                    else
                      Container(color: const Color(0xFF1E2630)),
                    Container(color: Colors.black.withValues(alpha: 0.25)),
                    if (item.isLive)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'LIVE',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.viewerCount} watching • ${item.game}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hostStatTile({
    required String title,
    required Stream<int> stream,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (_, snap) => LiveStatTile(
        value: '${snap.data ?? 0}',
        label: title,
        icon: icon,
        onTap: onTap,
      ),
    );
  }

  void _showFollowersSheet(
    BuildContext context,
    HashLiveService service,
    String hostUid,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1116),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.62,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Followers', style: LiveUi.heading(17)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: service.watchHostFollowers(hostUid),
                      builder: (context, snapshot) {
                        final followers =
                            snapshot.data ?? const <Map<String, dynamic>>[];
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: LiveUi.accentSoft,
                            ),
                          );
                        }
                        if (followers.isEmpty) {
                          return Center(
                            child: Text(
                              'No followers yet.',
                              style: GoogleFonts.inter(color: Colors.white70),
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: followers.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final item = followers[i];
                            final name = (item['name'] ?? 'Player').toString();
                            final username = (item['username'] ?? '')
                                .toString();
                            final photo = (item['photo_url'] ?? '').toString();
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundImage: photo.isNotEmpty
                                        ? CachedNetworkImageProvider(photo)
                                        : null,
                                    backgroundColor: LiveUi.surface,
                                    child: photo.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 18,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (username.isNotEmpty)
                                          Text(
                                            '@$username',
                                            style: GoogleFonts.inter(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HostUpcomingEditableCard extends StatelessWidget {
  final UpcomingStreamModel item;

  const _HostUpcomingEditableCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: LiveUi.cardDecoration(radius: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(item.game, style: LiveUi.body),
                Text(
                  DateFormat('EEE, d MMM • hh:mm a').format(item.startAt),
                  style: GoogleFonts.inter(
                    color: LiveUi.accentSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openEditUpcomingSheet(context, item),
            icon: const Icon(Icons.edit_calendar_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _openEditUpcomingSheet(
    BuildContext context,
    UpcomingStreamModel current,
  ) {
    final service = Get.find<HashLiveService>();
    final controller = Get.find<HashLiveController>();
    final titleCtrl = TextEditingController(text: current.title);
    var selectedGame = current.game;
    var selectedAt = current.startAt;
    var streamingFromCafe = current.streamingFromCafe;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101010),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Upcoming Stream',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: LiveUi.input(hint: 'Stream title'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedGame,
                    dropdownColor: LiveUi.surfaceSoft,
                    style: const TextStyle(color: Colors.white),
                    decoration: LiveUi.input(),
                    items: controller.games
                        .map(
                          (game) =>
                              DropdownMenuItem(value: game, child: Text(game)),
                        )
                        .toList(),
                    onChanged: (value) => setModalState(
                      () => selectedGame = value ?? selectedGame,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    tileColor: LiveUi.surfaceSoft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      DateFormat('EEE, d MMM • hh:mm a').format(selectedAt),
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.schedule, color: Colors.white70),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDate: selectedAt,
                      );
                      if (date == null || !context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedAt),
                      );
                      if (time == null) return;
                      setModalState(() {
                        selectedAt = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                  ),
                  SwitchListTile(
                    value: streamingFromCafe,
                    activeThumbColor: LiveUi.accentSoft,
                    title: Text(
                      'Streaming from Café',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    onChanged: (v) =>
                        setModalState(() => streamingFromCafe = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      if (title.length < 3) {
                        Fluttertoast.showToast(
                          msg: 'Title must be at least 3 characters',
                        );
                        return;
                      }
                      if (title.length > 80) {
                        Fluttertoast.showToast(
                          msg: 'Title must be at most 80 characters',
                        );
                        return;
                      }
                      if (selectedAt.isBefore(DateTime.now())) {
                        Fluttertoast.showToast(
                          msg: 'Schedule must be in the future',
                        );
                        return;
                      }

                      try {
                        await service.updateUpcomingStream(
                          upcomingId: current.id,
                          title: title,
                          game: selectedGame,
                          startAt: selectedAt,
                          streamingFromCafe: streamingFromCafe,
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                        Fluttertoast.showToast(msg: 'Scheduled stream updated');
                      } catch (_) {
                        Fluttertoast.showToast(
                          msg: 'Failed to update schedule',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LiveUi.accent,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Live stream card: thumbnail, pulsing red rim, centred play button, host.
/// The whole card opens the stream.
class _StanLiveCard extends StatefulWidget {
  final LiveStreamModel stream;
  final double? width;

  const _StanLiveCard({required this.stream, this.width});

  @override
  State<_StanLiveCard> createState() => _StanLiveCardState();
}

class _StanLiveCardState extends State<_StanLiveCard>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _pulse.value = 0.5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _open() {
    Haptics.selection();
    Get.to(() => LiveStreamScreen(streamId: widget.stream.id));
  }

  @override
  Widget build(BuildContext context) {
    final stream = widget.stream;
    final thumb = LiveYoutubeUtils.thumbnailUrl(stream.youtubeUrl);
    return Semantics(
      button: true,
      label: '${stream.title}, live, by ${stream.hostName}. Watch.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _open,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final p = Curves.easeInOut.transform(_pulse.value);
            return Container(
              width: widget.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: LiveUi.accent.withValues(alpha: 0.35 + 0.5 * p),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: LiveUi.accent.withValues(alpha: 0.10 + 0.22 * p),
                    blurRadius: 22,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.36),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null)
                CachedNetworkImage(
                  imageUrl: thumb,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      Container(color: const Color(0xFF1A1D23)),
                  errorWidget: (_, _, _) =>
                      Container(color: const Color(0xFF1A1D23)),
                )
              else
                Container(color: const Color(0xFF1A1D23)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x14000000),
                      Color(0x22000000),
                      Color(0xE6000000),
                    ],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
              const Positioned(top: 10, left: 10, child: LivePill()),
              Positioned(
                top: 10,
                right: 10,
                child: _ViewerChip(count: stream.viewerCount),
              ),
              // Play affordance in the middle of the frame.
              Center(
                child: Container(
                  width: 58,
                  height: 58,
                  margin: const EdgeInsets.only(bottom: 40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.45),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _HostAvatar(
                          url: stream.hostPhotoUrl,
                          size: 26,
                          live: true,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: '@${stream.hostName}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                              children: [
                                if (stream.game.isNotEmpty)
                                  TextSpan(
                                    text: '  ·  ${stream.game}',
                                    style: GoogleFonts.inter(
                                      color: Colors.white60,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewerChip extends StatelessWidget {
  const _ViewerChip({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_rounded, size: 12, color: Colors.white70),
          const SizedBox(width: 5),
          // Ticks smoothly as viewers join and leave.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(a),
                child: child,
              ),
            ),
            child: Text(
              count > 0 ? '$count watching' : 'Just started',
              key: ValueKey(count),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HostAvatar extends StatelessWidget {
  const _HostAvatar({required this.url, required this.size, this.live = false});
  final String url;
  final double size;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: live ? LiveUi.accent : LiveUi.stroke,
      ),
      child: CircleAvatar(
        backgroundColor: LiveUi.surface,
        backgroundImage: url.isNotEmpty
            ? CachedNetworkImageProvider(url)
            : null,
        child: url.isEmpty
            ? Icon(Icons.person, color: Colors.white70, size: size * 0.5)
            : null,
      ),
    );
  }
}

/// Scheduled stream: host, title, a live countdown and a reminder toggle.
/// [hero] is the larger "Next up" version shown when nobody is live.
class _UpcomingCard extends StatelessWidget {
  final UpcomingStreamModel item;
  final double? width;
  final bool hero;

  const _UpcomingCard({required this.item, this.width, this.hero = false});

  Future<void> _toggle(HashLiveService service, bool joined) async {
    try {
      await service.toggleUpcomingJoin(upcomingId: item.id, join: !joined);
    } catch (_) {
      Fluttertoast.showToast(
        msg: 'Could not update the reminder. Please try again.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Get.find<HashLiveService>();
    final joined = service.isJoinedUpcoming(item);
    final remind = _PillButton(
      label: joined ? 'Reminded' : 'Notify me',
      icon: joined
          ? Icons.notifications_active_rounded
          : Icons.notifications_none_rounded,
      filled: !joined,
      onTap: () => _toggle(service, joined),
    );

    return Container(
      width: width,
      padding: EdgeInsets.all(hero ? 16 : 12),
      decoration: LiveUi.cardDecoration(radius: hero ? LiveUi.radiusLg : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HostAvatar(url: item.hostPhotoUrl, size: hero ? 44 : 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: hero ? 17 : 14,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        '@${item.hostName}',
                        if (item.game.isNotEmpty) item.game,
                      ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LiveUi.body,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // The rail gives the card a fixed height; the hero sizes to content.
          if (hero) const SizedBox(height: 14) else const Spacer(),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 15,
                color: LiveUi.accentSoft,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _Countdown(
                  start: item.startAt,
                  style: GoogleFonts.inter(
                    color: LiveUi.accentSoft,
                    fontSize: hero ? 15 : 12.5,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              remind,
            ],
          ),
        ],
      ),
    );
  }
}

/// Re-renders the "Starts in…" label every 20 seconds.
class _Countdown extends StatefulWidget {
  const _Countdown({required this.start, required this.style});
  final DateTime start;
  final TextStyle style;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
    startsInLabel(widget.start, DateTime.now()),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: widget.style,
  );
}

/// Past stream with a video link. Opens in YouTube: the in-app player is for
/// live streams and would count the viewer as joining.
class _ReplayCard extends StatelessWidget {
  const _ReplayCard({required this.stream});
  final LiveStreamModel stream;

  @override
  Widget build(BuildContext context) {
    final thumb = LiveYoutubeUtils.thumbnailUrl(stream.youtubeUrl);
    return Semantics(
      button: true,
      label: 'Replay: ${stream.title} by ${stream.hostName}. Opens YouTube.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          Haptics.selection();
          launchUrl(
            Uri.parse(stream.youtubeUrl),
            mode: LaunchMode.externalApplication,
          );
        },
        child: SizedBox(
          width: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (thumb != null)
                        CachedNetworkImage(
                          imageUrl: thumb,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              Container(color: const Color(0xFF1A1D23)),
                          errorWidget: (_, _, _) =>
                              Container(color: const Color(0xFF1A1D23)),
                        )
                      else
                        Container(color: const Color(0xFF1A1D23)),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'REPLAY',
                            style: LiveUi.eyebrow(Colors.white),
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white70,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stream.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '@${stream.hostName}  ·  ${agoLabel(stream.updatedAt, DateTime.now())}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LiveUi.body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
