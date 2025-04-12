import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/games_controller.dart';
import 'booking_screen.dart';

class ArenaDetailView extends StatefulWidget {
  final String title;
  final String address;
  final String openingHours;
  final List<String> availableGames;
  final List<String> amenities;
  final String contactInfo;
  final String images;
  final int vendorId;
  final List<String> reviews;

  ArenaDetailView({
    required this.title,
    required this.address,
    required this.openingHours,
    required this.availableGames,
    required this.amenities,
    required this.contactInfo,
    required this.reviews, required this.images, required this.vendorId,
  });

  @override
  State<ArenaDetailView> createState() => _ArenaDetailViewState();
}

class _ArenaDetailViewState extends State<ArenaDetailView> {
  final CafeGamesController _gamesController = Get.put(CafeGamesController());

  @override
  void initState() {
    super.initState();
    _gamesController.fetchGames(widget.vendorId);

  }

  @override
  Widget build(BuildContext context) {
    _gamesController.fetchGames(widget.vendorId);
    print(widget.vendorId);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        children: [
          Container(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Image.network(widget.images, width: 300, fit: BoxFit.contain),
                SizedBox(width: 8),
                Image.network(widget.images, width: 300, fit: BoxFit.contain),
                SizedBox(width: 8),
                Image.network(widget.images, width: 300, fit: BoxFit.contain),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [


                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Color(0xff0E0E0E),
                      border: Border.all(color: Color(0xff2D2D2D)),
                      borderRadius: BorderRadius.circular(15)
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on,size: 18,),
                          SizedBox(width: 8),
                          Expanded(child: Text(widget.address, style: Theme.of(context).textTheme.bodySmall)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time,size: 18,),
                          SizedBox(width: 8),
                          Expanded(child: Text("Opening Hours: ${widget.openingHours}", style: Theme.of(context).textTheme.bodySmall)),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),
                Text("Book a slot:", style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                SizedBox(
                  height: 166,
                  child:

    Obx(() {
    if (_gamesController.isLoading.value) {
    return Center(child: CircularProgressIndicator());
    }

    if (_gamesController.games.isEmpty) {
    return Center(child: Text('No games available.'));
    }
                    return ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: _gamesController.games.length,
                      itemBuilder: (context, index) {
                        final game = _gamesController.games[index];
                        print('vendorid ${widget.vendorId}');
                        print('gameid ${game['id']}');
                        return Container(width: 180,height: 100,
                          margin: EdgeInsets.symmetric(vertical: 8,horizontal: 5),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xff181818),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Color(0xff2D2D2D)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(55),
                                      child: Image.network(
                                        game['game_name']=='ps5'?
                                        'https://static0.gamerantimages.com/wordpress/wp-content/uploads/2020/01/00bcfa0319c7e24446f9ddaaeb57f15e.jpg':
                                        game['game_name']=='xbox'?
                                        'https://sm.ign.com/ign_in/screenshot/default/48de604b-99ee-4400-a600-6958a71f0959_caj1.jpg':
                                        'https://storage.googleapis.com/webdesignledger.pub.network/WDL/6f050e39-windows_10_logoblue.svg-copy_windows.jpg',fit: BoxFit.cover,height: 25,width: 25,)),
                                 SizedBox(width: 8,),
                                  Text(
                                    game['game_name'] ?? 'Unknown Game',
                                    style: TextStyle(fontSize: 16, color: Colors.white),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Slot Price: ₹${game['single_slot_price']} | Total Slots: ${game['total_slots']}",
                                style: TextStyle(color: Colors.grey),
                              ),
                              SizedBox(height: 8),

                              // SizedBox(height: 8),
                              // Wrap(
                              //   spacing: 8,
                              //   children: (game['opening_days'] as List<dynamic>)
                              //       .map((day) => Chip(
                              //     label: Text(day.toUpperCase()),
                              //     backgroundColor: Color(0xff0E0E0E),
                              //     side: BorderSide(color: Color(0xff2D2D2D)),
                              //   ))
                              //       .toList(),
                              // ),
                              // SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Get.to(
                                        BookingScreen(title: widget.title, gameId:game['id']


                                    ));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    primary: const Color(0xff00D701),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: const Text(
                                    'Book Slot',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );}
                  ),
                ),
                SizedBox(height: 20),
                Text("Available Games:", style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.availableGames.map((game) => Chip(label: Text(game),backgroundColor: MaterialStateColor.resolveWith((states) => Color(0xff0E0E0E)),
                    side: BorderSide(color: Color(0xff2D2D2D)),
                  )).toList(),
                ),
                SizedBox(height: 20),
                Text("Amenities:", style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.amenities.map((amenity) {
                    return Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check, // Replace this with the appropriate icon for each amenity
                            size: 16,
                            color: Colors.white, // Set icon color
                          ),
                          SizedBox(width: 4), // Spacing between icon and text
                          Text(
                            amenity,
                            style: TextStyle(color: Colors.white), // Set text color
                          ),
                        ],
                      ),
                      backgroundColor: MaterialStateColor.resolveWith((states) => Color(0xff0E0E0E)),
                      side: BorderSide(color: Color(0xff2D2D2D)),
                    );
                  }).toList(),
                ),

                SizedBox(height: 20),
                Text("Contact Information:", style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                Container(padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Color(0xff0E0E0E),
                      border: Border.all(color: Color(0xff2D2D2D)),
                      borderRadius: BorderRadius.circular(15)
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.phone,size: 16,),
                      SizedBox(width: 8),
                      Expanded(child: Text(widget.contactInfo, style: Theme.of(context).textTheme.bodySmall)),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text("Reviews:", style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                ...widget.reviews.map((review) => Card(color: Colors.transparent,
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Color(0xff0E0E0E),
                        border: Border.all(color: Color(0xff2D2D2D)),
                        borderRadius: BorderRadius.circular(15)
                    ),
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Review content goes here'),
                    ),
                  )

                )).toList(),
                SizedBox(height: 16),


              ],
            ),
          ),
        ],
      ),
    );
  }
}
