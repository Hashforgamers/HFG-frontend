import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/tournaments_section/models/gamer_profile_model.dart';
import 'package:hash/utils/widgets/hash_wordmark.dart';
import 'package:hash/utils/widgets/loader.dart';

class GamerProfileStoryView extends StatefulWidget {
  const GamerProfileStoryView({super.key, this.profile});

  final GamerProfileModel? profile;

  @override
  State<GamerProfileStoryView> createState() => _GamerProfileStoryViewState();
}

class _GamerProfileStoryViewState extends State<GamerProfileStoryView> {
  final GlobalKey _storyKey = GlobalKey();
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Your gamer story',
          style: GoogleFonts.orbitron(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(30, 8, 30, 24),
        children: [
          RepaintBoundary(
            key: _storyKey,
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: _GamerStory(profile: widget.profile),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Built for Instagram Stories · also works on WhatsApp and Discord',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: FilledButton.icon(
            key: _shareButtonKey,
            onPressed: _sharing ? null : _shareStory,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: const Color(0xFFFFD600),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _sharing
                ? const AppLinearLoader(width: 32, height: 3)
                : const Icon(Icons.ios_share_rounded),
            label: Text(
              _sharing ? 'Cooking your story…' : 'Share to your story',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareStory() async {
    setState(() => _sharing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      var boundary =
          _storyKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null || boundary.debugNeedsPaint) {
        await WidgetsBinding.instance.endOfFrame;
        boundary =
            _storyKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
      }
      if (boundary == null || boundary.debugNeedsPaint) {
        throw StateError('Story is not ready');
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not render story');

      final directory = await getTemporaryDirectory();
      final userId = (widget.profile?.id ?? 'gamer').toString();
      final file = File('${directory.path}/hash-gamer-story-$userId.png');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          subject: 'My HASH gamer profile',
          text:
              'POV: I entered my tournament era 🎮⚡\n'
              'Build your gamer profile on HASH.\n\n'
              '#HASH #GamerProfile #Esports #LockedIn',
          sharePositionOrigin: _shareOrigin(),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to share gamer story: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        Get.snackbar(
          'Story failed the vibe check',
          'Give it one more try.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Rect? _shareOrigin() {
    final box =
        _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.isEmpty) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

class _GamerStory extends StatelessWidget {
  const _GamerStory({this.profile});

  final GamerProfileModel? profile;

  @override
  Widget build(BuildContext context) {
    final user = Get.find<UserController>().user.value;
    final displayName = profile?.displayName.trim().isNotEmpty == true
        ? profile!.displayName.trim()
        : ((user.name ?? '').trim().isEmpty ? 'HASH Gamer' : user.name!.trim());
    final username = profile?.gameUsername.trim() ?? '';
    final avatar = profile?.avatarUrl.isNotEmpty == true
        ? profile!.avatarUrl
        : (user.photoUrl ?? '');
    final stats = profile?.stats;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF050505), Color(0xFF241000), Color(0xFF050505)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -70,
              child: _glow(const Color(0xFFFFD600), 190),
            ),
            Positioned(
              bottom: 80,
              left: -90,
              child: _glow(const Color(0xFFFF1493), 210),
            ),
            const Positioned(
              top: 52,
              left: 28,
              right: 28,
              child: Center(child: HashWordmark(fontSize: 19)),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              width: 42,
              height: 42,
              child: Image.asset(
                'assets/hash_for_gamers_badge.png',
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 178, 22, 72),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MAIN CHARACTER\nENERGY.',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 23,
                      height: .98,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'POV: the tournament arc just started ⚡',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFFD600),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Transform.scale(
                    scaleX: 1.17,
                    alignment: Alignment.center,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 16,
                            offset: Offset(0, 7),
                          ),
                        ],
                      ),
                      child: AspectRatio(
                        aspectRatio: 1.9,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final height = constraints.maxHeight;
                              final avatarSize = width * .175;

                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    'assets/gamer_profile_holographic_bg.png',
                                    fit: BoxFit.fill,
                                  ),
                                  Positioned(
                                    left: width * .092,
                                    top: height * .255,
                                    width: avatarSize,
                                    height: avatarSize,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black,
                                      backgroundImage: avatar.startsWith('http')
                                          ? CachedNetworkImageProvider(avatar)
                                          : null,
                                      child: avatar.startsWith('http')
                                          ? null
                                          : Text(
                                              displayName[0].toUpperCase(),
                                              style: GoogleFonts.orbitron(
                                                color: const Color(0xFFFFD600),
                                                fontSize: width * .055,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    left: width * .292,
                                    right: width * .18,
                                    top: height * .205,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                displayName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: width * .041,
                                                  fontWeight: FontWeight.w800,
                                                  height: 1.05,
                                                  shadows: const [
                                                    Shadow(
                                                      color: Colors.black,
                                                      blurRadius: 5,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (profile?.host.isVerified ==
                                                true) ...[
                                              SizedBox(width: width * .012),
                                              Icon(
                                                Icons.verified_rounded,
                                                color: const Color(0xFF1D9BF0),
                                                size: width * .038,
                                              ),
                                            ],
                                          ],
                                        ),
                                        SizedBox(height: height * .025),
                                        if (username.isNotEmpty)
                                          Text(
                                            '@$username',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: Colors.white70,
                                              fontSize: width * .023,
                                              height: 1,
                                            ),
                                          ),
                                        SizedBox(height: height * .07),
                                        Text(
                                          'LOCKED IN 🔒',
                                          maxLines: 1,
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFFFFD600),
                                            fontSize: width * .02,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: width * .0025,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    left: width * .075,
                                    right: width * .075,
                                    bottom: height * .13,
                                    height: height * .22,
                                    child: Row(
                                      children: [
                                        _StoryStat(
                                          '${stats?.joined ?? 0}',
                                          'PLAYED',
                                        ),
                                        _StoryStat(
                                          '${stats?.wins ?? 0}',
                                          'WINS',
                                        ),
                                        _StoryStat(
                                          '${stats?.podiumFinishes ?? 0}',
                                          'PODIUMS',
                                        ),
                                        _StoryStat(
                                          '${stats?.hosted ?? 0}',
                                          'HOSTED',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'NO NPC MOVES.\nJUST GG ENERGY.',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'HOST. HYPE. EARN. REPEAT.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFFD600),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
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

  Widget _glow(Color color, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: .22),
          blurRadius: 75,
          spreadRadius: 28,
        ),
      ],
    ),
  );
}

class _StoryStat extends StatelessWidget {
  const _StoryStat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 7,
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
            ),
          ),
        ),
      ],
    ),
  );
}
