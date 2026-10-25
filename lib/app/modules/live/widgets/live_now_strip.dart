import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/controllers/app_mode_controller.dart';
import 'package:hash/app/modules/live/models/live_stream_model.dart';
import 'package:hash/app/modules/live/services/hash_live_service.dart';
import 'package:hash/app/modules/live/utils/live_youtube_utils.dart';
import 'package:hash/app/modules/live/views/hash_live_splash_screen.dart';
import 'package:hash/app/modules/live/views/live_stream_screen.dart';
import 'package:hash/app/modules/live/widgets/live_ui.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/utils/widgets/home_section_title.dart';

/// "Live now" rail for the Hub home: who is streaming right now, tap to
/// watch. Takes no space unless someone is live, then adds [bottomGap].
class LiveNowStrip extends StatefulWidget {
  const LiveNowStrip({super.key, this.bottomGap = 0});

  final double bottomGap;

  @override
  State<LiveNowStrip> createState() => _LiveNowStripState();
}

class _LiveNowStripState extends State<LiveNowStrip> {
  // One live-only query for the widget's life; rebuilds must not resubscribe.
  late final _live =
      (Get.isRegistered<HashLiveService>()
              ? Get.find<HashLiveService>()
              : Get.put(HashLiveService(), permanent: true))
          .watchLiveNow();

  void _openLiveMode() {
    final mode = Get.isRegistered<AppModeController>()
        ? Get.find<AppModeController>()
        : Get.put(AppModeController(), permanent: true);
    mode.setMode(AppMode.live);
    Get.offAll(
      () => const HashLiveSplashScreen(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LiveStreamModel>>(
      stream: _live,
      builder: (context, snap) {
        final streams = snap.data ?? const <LiveStreamModel>[];
        if (streams.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(bottom: widget.bottomGap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeSectionTitle(
                title: 'Live ',
                accent: 'now',
                accentColor: LiveUi.accent,
                actionLabel: 'Hash Live',
                onAction: _openLiveMode,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 176,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: streams.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _LiveTile(stream: streams[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveTile extends StatelessWidget {
  const _LiveTile({required this.stream});
  final LiveStreamModel stream;

  @override
  Widget build(BuildContext context) {
    final thumb = LiveYoutubeUtils.thumbnailUrl(stream.youtubeUrl);
    return Semantics(
      button: true,
      label: '${stream.hostName} is live: ${stream.title}. Watch.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          Haptics.selection();
          Get.to(() => LiveStreamScreen(streamId: stream.id));
        },
        child: Container(
          width: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: LiveUi.accent.withValues(alpha: 0.6),
              width: 1.2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null)
                CachedNetworkImage(
                  imageUrl: thumb,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: LiveUi.surface),
                  errorWidget: (_, _, _) => Container(color: LiveUi.surface),
                )
              else
                Container(color: LiveUi.surface),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xE6000000)],
                    stops: [0.35, 1],
                  ),
                ),
              ),
              const Positioned(top: 8, left: 8, child: LivePill(compact: true)),
              if (stream.viewerCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '👁 ${stream.viewerCount}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 9,
                right: 9,
                bottom: 9,
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
                        fontSize: 12.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          padding: const EdgeInsets.all(1.2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: LiveUi.accent,
                          ),
                          child: CircleAvatar(
                            backgroundColor: LiveUi.surface,
                            backgroundImage: stream.hostPhotoUrl.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    stream.hostPhotoUrl,
                                  )
                                : null,
                            child: stream.hostPhotoUrl.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white70,
                                    size: 11,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '@${stream.hostName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
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
