import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
            color: const Color(0xCC10151D),
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
    const ring = Color(0xFFFF3B30);
    const ringSoft = Color(0xFFFF6B61);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F28), Color(0xFF0B0D11)],
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

class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HashLiveController>();
    final service = Get.find<HashLiveService>();

    return StreamBuilder<List<LiveStreamModel>>(
      stream: controller.liveStreams,
      builder: (context, liveSnapshot) {
        final streams = liveSnapshot.data ?? const <LiveStreamModel>[];
        return StreamBuilder<List<UpcomingStreamModel>>(
          stream: service.watchUpcomingStreams(),
          builder: (context, upcomingSnapshot) {
            final upcoming =
                upcomingSnapshot.data ?? const <UpcomingStreamModel>[];

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              physics: const BouncingScrollPhysics(),
              children: [
                _heroSection(),
                const SizedBox(height: 18),
                _sectionHeader('LIVE NOW'),
                const SizedBox(height: 10),
                if (liveSnapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(22),
                      child: CircularProgressIndicator(
                        color: LiveUi.accentSoft,
                      ),
                    ),
                  )
                else if (streams.isEmpty)
                  _emptyState('No streams live right now.'),
                if (streams.isNotEmpty)
                  SizedBox(
                    height: 276,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: streams.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) =>
                          _StanLiveCard(stream: streams[i], width: 286),
                    ),
                  ),
                const SizedBox(height: 14),
                _sectionHeader('UPCOMING STREAMS'),
                const SizedBox(height: 10),
                if (upcomingSnapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: LiveUi.accentSoft,
                      ),
                    ),
                  )
                else if (upcoming.isEmpty)
                  _emptyState('No upcoming streams scheduled.'),
                if (upcoming.isNotEmpty)
                  SizedBox(
                    height: 148,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: upcoming.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) =>
                          _UpcomingCard(item: upcoming[i], width: 280),
                    ),
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => controller.setTab(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LiveUi.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.videocam_rounded),
                  label: const Text('Go Live'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _heroSection() {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF000000), Color(0xFF2C3E50), Color(0xFF000000)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HASH LIVE',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Premium gaming streams, creators, and tournaments.',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Trending now',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: LiveUi.softText,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 12,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _GoLiveTab extends StatelessWidget {
  const _GoLiveTab();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HashLiveController>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Go Live Studio',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: LiveUi.cardDecoration(radius: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: LiveUi.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.broadcast_on_home_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Create, schedule, and manage your streams from one place.',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: LiveUi.cardDecoration(radius: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Host tools',
                style: GoogleFonts.inter(
                  color: LiveUi.softText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
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
            ],
          ),
        ),
        const SizedBox(height: 14),
        _label('Title'),
        const SizedBox(height: 6),
        TextField(
          controller: controller.titleController,
          style: const TextStyle(color: Colors.white),
          decoration: LiveUi.input(hint: 'Enter stream title'),
        ),
        const SizedBox(height: 12),
        _label('Game'),
        const SizedBox(height: 6),
        Obx(
          () => DropdownButtonFormField<String>(
            initialValue: controller.selectedGame.value.isEmpty
                ? null
                : controller.selectedGame.value,
            dropdownColor: LiveUi.surfaceSoft,
            style: const TextStyle(color: Colors.white),
            decoration: LiveUi.input(),
            items: controller.games
                .map((game) => DropdownMenuItem(value: game, child: Text(game)))
                .toList(),
            onChanged: (value) => controller.setGame(value ?? ''),
          ),
        ),
        const SizedBox(height: 12),
        _label('YouTube live link'),
        const SizedBox(height: 6),
        TextField(
          controller: controller.youtubeController,
          style: const TextStyle(color: Colors.white),
          decoration: LiveUi.input(hint: 'Paste YouTube URL'),
        ),
        const SizedBox(height: 12),
        Obx(
          () => SwitchListTile(
            value: controller.isStreamingFromCafe.value,
            activeThumbColor: LiveUi.accentSoft,
            title: Text(
              'Streaming from Café',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            onChanged: controller.setStreamingFromCafe,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => ListTile(
            tileColor: const Color(0x332C3E50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              controller.scheduledAt.value == null
                  ? 'Select schedule time'
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
        const SizedBox(height: 18),
        Obx(
          () => ElevatedButton(
            onPressed: controller.isSubmitting.value
                ? null
                : () async {
                    final streamId = await controller.startLive();
                    if (streamId == null || streamId.isEmpty) return;
                    Get.to(() => LiveStreamScreen(streamId: streamId));
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: LiveUi.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: controller.isSubmitting.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Start Live Now'),
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () => ElevatedButton(
            onPressed: controller.isSubmitting.value
                ? null
                : () async {
                    final id = await controller.scheduleStream();
                    if (id == null || id.isEmpty) return;
                    controller.scheduledAt.value = null;
                    controller.setTab(0);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Schedule Stream'),
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
          color: const Color(0x332C3E50),
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

class _HostTab extends StatelessWidget {
  const _HostTab();

  @override
  Widget build(BuildContext context) {
    final service = Get.find<HashLiveService>();
    final uid = service.currentUid ?? '';
    if (uid.isEmpty) return _emptyState('Please login to view host profile.');

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
                              stream: service.watchHostFollowersCount(uid),
                              onTap: () =>
                                  _showFollowersSheet(context, service, uid),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _hostStatTile(
                              title: 'Streams',
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
                      return _emptyState('No stream posts yet.');
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
                      return _emptyState('No upcoming streams yet.');
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
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: StreamBuilder<int>(
          stream: stream,
          builder: (_, snap) {
            final value = snap.data ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$value',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (onTap != null) ...[
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white54,
                        size: 18,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
              ],
            );
          },
        ),
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
                  Text(
                    'Followers',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
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
                    tileColor: const Color(0x332C3E50),
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

class _StanLiveCard extends StatelessWidget {
  final LiveStreamModel stream;
  final double? width;

  const _StanLiveCard({required this.stream, this.width});

  @override
  Widget build(BuildContext context) {
    final thumb = LiveYoutubeUtils.thumbnailUrl(stream.youtubeUrl);
    return GestureDetector(
      onTap: () => Get.to(() => LiveStreamScreen(streamId: stream.id)),
      child: Container(
        width: width,
        decoration: LiveUi.cardDecoration(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Container(
                height: 165,
                decoration: const BoxDecoration(color: Color(0xFF111111)),
                child: Stack(
                  children: [
                    if (thumb != null)
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: thumb,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF2C3E50), Color(0xFF111111)],
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF2C3E50), Color(0xFF111111)],
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2C3E50), Color(0xFF111111)],
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.28),
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white70,
                        size: 54,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'LIVE',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: stream.hostPhotoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(stream.hostPhotoUrl)
                        : null,
                    backgroundColor: LiveUi.surface,
                    child: stream.hostPhotoUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stream.title,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '@${stream.hostName}  •  ${stream.viewerCount} watching',
                          style: LiveUi.body,
                        ),
                      ],
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
}

class _UpcomingCard extends StatelessWidget {
  final UpcomingStreamModel item;
  final double? width;

  const _UpcomingCard({required this.item, this.width});

  @override
  Widget build(BuildContext context) {
    final service = Get.find<HashLiveService>();
    final joined = service.isJoinedUpcoming(item);

    return Container(
      width: width,
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
                Text('Host: ${item.hostName}', style: LiveUi.body),
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
          ElevatedButton(
            onPressed: () async {
              try {
                await service.toggleUpcomingJoin(
                  upcomingId: item.id,
                  join: !joined,
                );
                Fluttertoast.showToast(
                  msg: joined
                      ? 'Reminder removed'
                      : 'Reminder set successfully',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
              } catch (_) {
                Fluttertoast.showToast(
                  msg: 'Unable to update reminder. Please try again.',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: joined ? const Color(0xFF2C3E50) : LiveUi.accent,
              foregroundColor: Colors.white,
            ),
            child: Text(joined ? 'Joined' : 'Notify'),
          ),
        ],
      ),
    );
  }
}

Widget _emptyState(String text) => Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
  decoration: LiveUi.cardDecoration(radius: 12),
  child: Text(text, style: LiveUi.body, textAlign: TextAlign.center),
);
