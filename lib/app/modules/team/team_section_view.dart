import 'package:flutter/material.dart';
import 'dart:math';

class TeamSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FIND A TEAM',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildTeamItem('ARE YOU AWESOME?', 'We are hiring', 'Join Us'),
            _buildTeamItem('JOIN OUR TEAM!', 'We are looking for developers & UI designers', 'Join Us'),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamItem(String title, String subtitle, String buttonText) {
    final random = Random();
    final colors = [
      Colors.red[900],
      Colors.blue[900],
      Colors.green[900],
      Colors.purple[900],
      Colors.orange[900],
      Colors.cyan[900],
      Colors.amber[900],
    ];
    final buttonColor = colors[random.nextInt(colors.length)];

    return Container(
      margin: EdgeInsets.all(5),
      width: 150,
      height: 200,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          SizedBox(
            width:120,child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.symmetric(vertical: 1, horizontal: 8),
                primary: Color(0xff00D701),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(buttonText,style: TextStyle(color: Colors.black),),
            ),
          ),
        ],
      ),
    );
  }
}
