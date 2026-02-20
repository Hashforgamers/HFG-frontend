import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/app_mode_segmented_toggle.dart';
import 'package:hash/app/modules/live/controllers/hash_live_controller.dart';
import 'package:hash/app/modules/live/services/hash_live_service.dart';

class HostProfileScreen extends StatefulWidget {
  final String hostUid;

  const HostProfileScreen({super.key, required this.hostUid});

  @override
  State<HostProfileScreen> createState() => _HostProfileScreenState();
}

class _HostProfileScreenState extends State<HostProfileScreen> {
  late final HashLiveService _service;
  late final HashLiveController _controller;

  @override
  void initState() {
    super.initState();
    _service = Get.isRegistered<HashLiveService>()
        ? Get.find<HashLiveService>()
        : Get.put(HashLiveService(), permanent: true);
    _controller = Get.isRegistered<HashLiveController>()
        ? Get.find<HashLiveController>()
        : Get.put(HashLiveController(), permanent: true);
    _controller.syncFollowState(widget.hostUid);
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile = _service.currentUid == widget.hostUid;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text('Host Profile', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(56),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: AppModeSegmentedToggle(compact: true),
          ),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _service.watchHostProfile(widget.hostUid),
        builder: (context, snapshot) {
          final host = snapshot.data ?? {};
          final hostName = (host['name'] ?? 'Host').toString();
          final photo = (host['photo_url'] ?? '').toString();
          final isLive = host['is_live'] == true;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF00DC00),
                    backgroundImage: photo.isNotEmpty ? CachedNetworkImageProvider(photo) : null,
                    child: photo.isEmpty ? const Icon(Icons.person, size: 34, color: Colors.black) : null,
                  ),
                  const SizedBox(height: 12),
                  Text(hostName, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  StreamBuilder<int>(
                    stream: _service.watchHostFollowersCount(widget.hostUid),
                    builder: (context, followSnap) => Text(
                      'Followers: ${followSnap.data ?? 0}',
                      style: GoogleFonts.inter(color: Colors.white70),
                    ),
                  ),
                  StreamBuilder<int>(
                    stream: _service.watchHostTotalStreams(widget.hostUid),
                    builder: (context, streamSnap) => Text(
                      'Total streams: ${streamSnap.data ?? 0}',
                      style: GoogleFonts.inter(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                      child: Text('Currently Live', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  const Spacer(),
                  if (!isOwnProfile)
                    SizedBox(
                      width: double.infinity,
                      child: Obx(
                        () => OutlinedButton(
                          onPressed: _controller.isFollowSubmitting.value
                              ? null
                              : () => _controller.toggleFollow(widget.hostUid),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF00DC00))),
                          child: Text(
                            _controller.isFollowingHost.value ? 'Following' : 'Follow',
                            style: GoogleFonts.inter(color: const Color(0xFF00DC00), fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
