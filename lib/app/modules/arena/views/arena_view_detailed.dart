// Enhanced ArenaDetailView with full dark theme and polished UI
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/widgets/glow_neon_loader.dart';
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
    required this.reviews,
    required this.images,
    required this.vendorId,
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
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xff0F0F0F),
        title: Text(widget.title, style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          Container(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(widget.images, width: 300, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12),
                infoCard([
                  rowInfo(Icons.location_on, widget.address),
                  rowInfo(Icons.access_time, "Opening Hours: ${widget.openingHours}"),
                ]),

                SizedBox(height: 20),
                Text("Book a slot:", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                SizedBox(height: 8),
                SizedBox(
                  height: 166,
                  child: Obx(() {
                    if (_gamesController.isLoading.value) {
                      return Center(child: RainbowGlowingLoader(size: 50));
                    }
                    if (_gamesController.games.isEmpty) {
                      return Center(child: Text('No games available.', style: TextStyle(color: Colors.white70)));
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _gamesController.games.length,
                      itemBuilder: (context, index) {
                        final game = _gamesController.games[index];
                        return Container(
                          width: 180,
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xff181818),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Color(0xff2D2D2D)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      game['game_name'] == 'ps5'
                                          ? 'https://static0.gamerantimages.com/wordpress/wp-content/uploads/2020/01/00bcfa0319c7e24446f9ddaaeb57f15e.jpg'
                                          : game['game_name'] == 'xbox'
                                          ? 'https://sm.ign.com/ign_in/screenshot/default/48de604b-99ee-4400-a600-6958a71f0959_caj1.jpg'
                                          : 'https://storage.googleapis.com/webdesignledger.pub.network/WDL/6f050e39-windows_10_logoblue.svg-copy_windows.jpg',
                                    ),
                                    radius: 12,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      game['game_name'] ?? 'Unknown Game',
                                      style: TextStyle(fontSize: 16, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Slot Price: ₹${game['single_slot_price']} | Total Slots: ${game['total_slots']}",
                                style: TextStyle(color: Colors.grey),
                              ),
                              Spacer(),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Get.to(BookingScreen(title: widget.title, gameId: game['id']));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xffDE3A3A),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                  ),
                                  child: Text('Book Slot', style: TextStyle(color: Colors.black)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
                SizedBox(height: 20),
                sectionChip("Available Games:", widget.availableGames),
                SizedBox(height: 20),
                sectionChip("Amenities:", widget.amenities, includeIcon: true),
                SizedBox(height: 20),
                Text("Contact Information:", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                SizedBox(height: 8),
                infoCard([rowInfo(Icons.phone, widget.contactInfo)]),
                SizedBox(height: 20),
                Text("Reviews:", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                SizedBox(height: 8),
                ...widget.reviews.map((review) => Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xff181818),
                    border: Border.all(color: Color(0xff2D2D2D)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.person, color: Colors.white),
                    title: Text(review, style: TextStyle(color: Colors.white)),
                  ),
                )),
                SizedBox(height: 16),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget rowInfo(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 18, color: Colors.white70),
      SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(color: Colors.white70))),
    ],
  );

  Widget infoCard(List<Widget> children) => Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Color(0xff181818),
      border: Border.all(color: Color(0xff2D2D2D)),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget sectionChip(String title, List<String> items, {bool includeIcon = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map((item) => Chip(
          label: includeIcon
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 16, color: Colors.white),
              SizedBox(width: 4),
              Text(item, style: TextStyle(color: Colors.white))
            ],
          )
              : Text(item, style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xff0E0E0E),
          side: BorderSide(color: Color(0xff2D2D2D)),
        ))
            .toList(),
      )
    ],
  );
}