import 'package:flutter/material.dart';

class ArenaDetailView extends StatelessWidget {
  final String title;
  final String address;
  final String openingHours;
  final List<String> availableGames;
  final List<String> amenities;
  final String contactInfo;
  final List<String> reviews;

  ArenaDetailView({
    required this.title,
    required this.address,
    required this.openingHours,
    required this.availableGames,
    required this.amenities,
    required this.contactInfo,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headline4),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on),
                SizedBox(width: 8),
                Expanded(child: Text(address, style: Theme.of(context).textTheme.subtitle1)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time),
                SizedBox(width: 8),
                Expanded(child: Text("Opening Hours: $openingHours", style: Theme.of(context).textTheme.subtitle1)),
              ],
            ),
            SizedBox(height: 16),
            Text("Available Games:", style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableGames.map((game) => Chip(label: Text(game))).toList(),
            ),
            SizedBox(height: 16),
            Text("Amenities:", style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenities.map((amenity) => Chip(label: Text(amenity))).toList(),
            ),
            SizedBox(height: 16),
            Text("Contact Information:", style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone),
                SizedBox(width: 8),
                Expanded(child: Text(contactInfo)),
              ],
            ),
            SizedBox(height: 16),
            Text("Reviews:", style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 8),
            ...reviews.map((review) => Card(
              margin: EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text(review),
              ),
            )).toList(),
            SizedBox(height: 16),
            Text("Gallery:", style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 8),
            Container(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Image.network('https://example.com/image1.jpg', width: 200, fit: BoxFit.cover),
                  SizedBox(width: 8),
                  Image.network('https://example.com/image2.jpg', width: 200, fit: BoxFit.cover),
                  SizedBox(width: 8),
                  Image.network('https://example.com/image3.jpg', width: 200, fit: BoxFit.cover),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
