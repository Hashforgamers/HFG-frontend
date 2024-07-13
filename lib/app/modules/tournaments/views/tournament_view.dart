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
            indicatorColor: Color(0xff00D701),
            labelColor: Color(0xff00D701),
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
    final List<Tournament> tournaments = List.generate(
      3,
          (index) => Tournament(
        title: '19 Nov 2024',
        imageUrl: 'https://t4.ftcdn.net/jpg/05/57/61/79/360_F_557617905_iSt6BAH73qgXHULb0ZpHOwADFj7tX6q8.jpg',
        description: 'Top 12 Battle Pass',
      ),
    );

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


