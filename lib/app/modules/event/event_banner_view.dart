import 'package:flutter/material.dart';

class EventBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: Colors.purple,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(35),

          )         ),
      child: Column(
        children: [
          Text(
            'RETRO GAME NIGHT',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'Prize Pool',
            style: TextStyle(color: Colors.white),
          ),
          Text(
            '₹50,000',
            style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          ),
          Text(
            'Starting on 06 Oct 2023, 12:00pm',
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              primary: Color(0xff00D701),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Join Now'),
          ),
        ],
      ),
    );
  }
}
