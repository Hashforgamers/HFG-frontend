import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class ArenaSection extends StatelessWidget {
  final List<Map<String, String>> arenaItems = [
    {
      'text': 'Tournament is going on\nFree Entry',
      'image': 'https://fortnite.gg/img/lore/bg-chapter-2.jpg?2'
    },
    {
      'text': 'Fan Meet in\nBangalore',
      'image':
          'https://static.wixstatic.com/media/7ef39e_5e704881922a40f293a56f4602a9384c~mv2.jpeg/v1/fill/w_640,h_360,al_c,q_80,usm_0.66_1.00_0.01,enc_auto/7ef39e_5e704881922a40f293a56f4602a9384c~mv2.jpeg'
    },
    {
      'text': 'Launching new\nGames',
      'image':
          'https://images.hindustantimes.com/tech/img/2021/07/07/960x540/youtube-screenshot-thelaunchpartybattlegroundsmobileindia_1625651911539_1625651921244.jpeg'
    },
    // Add more items as needed
  ];

   ArenaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IN THE ARENA',
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: arenaItems.length,
            itemBuilder: (context, index) {
              final item = arenaItems[index];
              return _buildArenaItem(item['text']!, item['image']!);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArenaItem(String text, String imageUrl) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(
              imageUrl), // CachedNetworkImage for performance
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
