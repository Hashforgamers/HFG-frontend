import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../views/tournament_detail_view.dart';
import '../views/tournament_view.dart';

class TournamentCard extends StatelessWidget {
  final Tournament tournament;

  const TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: ShapeDecoration(
        color: const Color(0xff1E1E1E),
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: CachedNetworkImage(
              imageUrl: tournament.imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament.title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  tournament.description,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Row(
                  children: const [
                    _TournamentDetail(icon: Icons.group_work, text: 'Squad'),
                    SizedBox(width: 15),
                    _TournamentDetail(icon: CupertinoIcons.money_dollar_circle, text: '20K'),
                    SizedBox(width: 15),
                    _TournamentDetail(icon: CupertinoIcons.group_solid, text: '10/100'),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: Get.width,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.to(TournamentDetailView());
                      // Handle tournament button tap
                    },
                    style: ElevatedButton.styleFrom(
                      primary: const Color(0xff00D701),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Register Now', style: TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
          ),
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
        Icon(icon, color: Colors.grey),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
