import 'package:flutter/material.dart';

class ArenaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IN THE ARENA',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildArenaItem('Tournament is going on\nFree Entry'),
              _buildArenaItem('Fan Meet in\nBangalore'),
              _buildArenaItem('Launching new\nGames'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArenaItem(String text) {
    return Container(alignment: Alignment.center,

      margin: EdgeInsets.all(5),
      width: 140,
      height: 140,
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(image: DecorationImage(image: NetworkImage('https://fortnite.gg/img/lore/bg-chapter-2.jpg?2'),fit: BoxFit.cover),
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(alignment: Alignment.center,
        width: 140,
        height: 60,

        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5)
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
