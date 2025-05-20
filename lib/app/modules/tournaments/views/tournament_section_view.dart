// Optimized TournamentsSection with structured layout and clean code
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../utils/widgets/glow_neon_loader.dart';

class TournamentsSection extends StatelessWidget {
  const TournamentsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Tournament> tournaments = [
      Tournament(
        title: 'Game Time',
        imageUrl: 'https://t4.ftcdn.net/jpg/05/57/61/79/360_F_557617905_iSt6BAH73qgXHULb0ZpHOwADFj7tX6q8.jpg',
        description: 'Exciting Tournament!',
        prize: '20K',
      ),
      Tournament(
        title: '8 Ball Pool Tournament',
        imageUrl: 'https://marketplace.canva.com/EAFptWmm4ww/1/0/1131w/canva-purple-modern-gradient-animated-esports-gaming-tournament-poster-DD4QH8VFKE0.jpg',
        description: 'Join Now!',
        prize: '50K',
      ),
      Tournament(
        title: 'Galactic Battle',
        imageUrl: 'https://marketplace.canva.com/EAFptWmm4ww/1/0/1131w/canva-purple-modern-gradient-animated-esports-gaming-tournament-poster-DD4QH8VFKE0.jpg',
        description: 'Battle for Glory!',
        prize: '30K',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TOURNAMENTS',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 192,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tournaments.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => TournamentCard(tournament: tournaments[index]),
          ),
        ),
      ],
    );
  }
}

class Tournament {
  final String title;
  final String imageUrl;
  final String description;
  final String prize;

  const Tournament({
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.prize,
  });
}

class TournamentCard extends StatelessWidget {
  final Tournament tournament;

  const TournamentCard({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xff1E1E1E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: CachedNetworkImage(
              imageUrl: tournament.imageUrl,
              height: 65,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: RainbowGlowingLoader(size: 40)),
              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tournament.title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tournament.description,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _TournamentDetail(icon: CupertinoIcons.money_dollar_circle, text: tournament.prize),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffDE3A3A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, color: Colors.black, size: 16),
                        SizedBox(width: 6),
                        Text('Coming Soon', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _TournamentDetail extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TournamentDetail({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.yellow, size: 16),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
