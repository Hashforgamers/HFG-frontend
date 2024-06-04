import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TournamentsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOURNAMENTS',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTournamentItem('Game Time', 'https://marketplace.canva.com/EAFptWmm4ww/1/0/1131w/canva-purple-modern-gradient-animated-esports-gaming-tournament-poster-DD4QH8VFKE0.jpg'),
              _buildTournamentItem('8 Ball Pool Tournament', 'https://marketplace.canva.com/EAFptWmm4ww/1/0/1131w/canva-purple-modern-gradient-animated-esports-gaming-tournament-poster-DD4QH8VFKE0.jpg'),
              _buildTournamentItem('Galactic Battle', 'https://marketplace.canva.com/EAFptWmm4ww/1/0/1131w/canva-purple-modern-gradient-animated-esports-gaming-tournament-poster-DD4QH8VFKE0.jpg'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentItem(String title, String imageUrl) {
    return Container(
      margin: EdgeInsets.all(5),
      width: 150,height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(10),topRight:  Radius.circular(10),),

            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 130,
              width: 150,

              fit: BoxFit.cover,

              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
          ),
          SizedBox(height: 5),
          Container(
            padding: EdgeInsets.all(10),

            child: Text(
              title,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact,
                primary: Color.fromRGBO(58, 255, 107, 1.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Get it now'),
            ),
          ),
        ],
      ),
    );
  }
}
