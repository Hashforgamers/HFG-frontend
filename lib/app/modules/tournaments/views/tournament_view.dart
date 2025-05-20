import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widget/tournament_card.dart';

class TournamentView extends StatelessWidget {
  const TournamentView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const Text('Tournaments', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          bottom: const TabBar(
            indicatorColor: Color(0xffDE3A3A),
            labelColor: Color(0xffDE3A3A),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Live'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TournamentsListView(type: 'Upcoming'),
            TournamentsListView(type: 'Live'),
            TournamentsListView(type: 'Completed'),
          ],
        ),
      ),
    );
  }
}

class TournamentsListView extends StatelessWidget {
  final String type;

  const TournamentsListView({required this.type});

  @override
  Widget build(BuildContext context) {
    // Dummy data for demonstration
    final List<Tournament> tournaments = [
      Tournament(
        title: '19 Nov 2024 - Battle of Champions',
        imageUrl: 'https://www.animationxpress.com/wp-content/uploads/2022/04/NODWIN_LOCO_Invitational_Banner.jpg',
        description: 'Top 12 Battle Pass. Compete with the best and prove your skills!',
      ),
      Tournament(
        title: '25 Dec 2024 - Winter Clash',
        imageUrl: 'https://mir-s3-cdn-cf.behance.net/project_modules/max_1200/de3520114882855.6043aab478154.jpg',
        description: 'Christmas special tournament with exclusive rewards for winners.',
      ),
      Tournament(
        title: '01 Jan 2025 - New Year Showdown',
        imageUrl: 'https://images.hindustantimes.com/tech/img/2020/08/24/960x540/image002_(2)_1598262864796_1598262880895.png',
        description: 'Start the new year with a bang! Join the ultimate showdown.',
      ),
    ];
    return ListView.builder(
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        return TournamentCard(tournament: tournaments[index]);
      },
    );
  }
}

class Tournament {
  final String title;
  final String imageUrl;
  final String description;

  Tournament({
    required this.title,
    required this.imageUrl,
    required this.description,
  });
}


