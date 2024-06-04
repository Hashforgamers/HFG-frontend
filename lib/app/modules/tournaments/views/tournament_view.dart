import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TournamentView extends StatelessWidget {
  const TournamentView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text('Tournaments',style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.black,
          bottom: TabBar(
            indicatorColor:  Color(0xFF3AFF6B),
            labelColor:  Color(0xFF3AFF6B),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Live'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
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
    // Here you would fetch the actual tournaments data based on the type.
    // For simplicity, we'll use dummy data.
    final List<Map<String, String>> tournaments = List.generate(
      10,
          (index) => {
        'title': '$type Tournament ${index + 1}',
        'image': 'https://via.placeholder.com/150', // Replace with actual image URLs
        'description': 'Description for $type Tournament ${index + 1}',
      },
    );

    return ListView.builder(
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        return _buildTournamentCard(tournaments[index]);
      },
    );
  }

  Widget _buildTournamentCard(Map<String, String> tournament) {
    return Container(
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            child: CachedNetworkImage(
              imageUrl: tournament['image']!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament['title']!,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  tournament['description']!,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 10),
                SizedBox(width: Get.width,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle tournament button tap
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Color.fromRGBO(58, 255, 107, 1.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Register Now',style:TextStyle(color: Colors.black)),
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