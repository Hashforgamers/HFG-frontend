import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/optimized_app_bar.dart';
import 'package:hash/app/modules/live/views/go_live_screen.dart';

class HashLiveHome extends StatelessWidget {
  const HashLiveHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const OptimizedAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Live Now'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _liveNow.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, index) {
                        final item = _liveNow[index];
                        return _LiveNowCard(item: item);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Upcoming Streams'),
                  const SizedBox(height: 10),
                  ..._upcoming.map((item) => _UpcomingTile(item: item)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Get.to(() => const GoLiveScreen()),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF00DC00)),
                        minimumSize: const Size.fromHeight(46),
                      ),
                      icon: const Icon(Icons.video_call_rounded, color: Color(0xFF00DC00)),
                      label: Text(
                        'Go Live',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF00DC00),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LiveNowCard extends StatelessWidget {
  final Map<String, String> item;

  const _LiveNowCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    color: const Color(0xFF1C1C1C),
                    alignment: Alignment.center,
                    child: const Icon(Icons.play_circle_fill_rounded, size: 42, color: Colors.white70),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('LIVE', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(item['viewers']!, style: GoogleFonts.inter(color: Colors.white70, fontSize: 10)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage:
                        (item['photo_url'] ?? '').trim().isNotEmpty
                        ? NetworkImage((item['photo_url'] ?? '').trim())
                        : null,
                    backgroundColor: const Color(0xFF00DC00),
                    child: (item['photo_url'] ?? '').trim().isEmpty
                        ? const Icon(Icons.person, size: 14, color: Colors.black)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['creator']!, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(item['game']!, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(item['cafe']!, style: GoogleFonts.inter(color: const Color(0xFF00DC00), fontSize: 11)),
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

class _UpcomingTile extends StatelessWidget {
  final Map<String, String> item;

  const _UpcomingTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title']!, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Host: ${item['host']}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                Text(item['time']!, style: GoogleFonts.inter(color: const Color(0xFF00DC00), fontSize: 12)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00DC00)),
            ),
            child: Text('Notify Me', style: GoogleFonts.inter(color: const Color(0xFF00DC00), fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

const List<Map<String, String>> _liveNow = [
  {'creator': 'RogueRana', 'game': 'Valorant Ranked', 'viewers': '3.2k watching', 'cafe': 'Hash Arena Delhi'},
  {'creator': 'NoScopeNeil', 'game': 'BGMI Scrims', 'viewers': '1.1k watching', 'cafe': 'Hash Hub Pune'},
  {'creator': 'AstraAvi', 'game': 'FIFA Showdown', 'viewers': '850 watching', 'cafe': 'Hash Cafe Mumbai'},
];

const List<Map<String, String>> _upcoming = [
  {'title': 'Road to Immortal', 'host': 'RogueRana', 'time': 'Today, 8:30 PM'},
  {'title': 'BGMI Night Grind', 'host': 'NoScopeNeil', 'time': 'Today, 10:00 PM'},
  {'title': 'Weekend FIFA Cup Warmup', 'host': 'AstraAvi', 'time': 'Tomorrow, 6:00 PM'},
];
