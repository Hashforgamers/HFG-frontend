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
  final List<dynamic> availableGames;
  final List<dynamic> amenities;
  final String contactInfo;
  final String images;
  final int vendorId;
  final List<dynamic> reviews;

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
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
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
                const SizedBox(height: 12),
                infoCard([
                  rowInfo(Icons.location_on, widget.address),
                  rowInfo(Icons.access_time, "Opening Hours: ${widget.openingHours}"),
                ]),

                const SizedBox(height: 20),
                Text("Book a slot:", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 166,
                  child: Obx(() {
                    if (_gamesController.isLoading.value) {
                      return const Center(child: RainbowGlowingLoader(size: 50));
                    }
                    if (_gamesController.games.isEmpty) {
                      return const Center(child: Text('No games available.', style: TextStyle(color: Colors.white70)));
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _gamesController.games.length,
                      itemBuilder: (context, index) {
                        final game = _gamesController.games[index];
                        return Container(
                          width: 180,
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xff181818),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xff2D2D2D)),
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
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      game['game_name'] ?? 'Unknown Game',
                                      style: const TextStyle(fontSize: 16, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Slot Price: ₹${game['single_slot_price']} | Total Slots: ${game['total_slots']}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Get.to(BookingScreen(title: widget.title, gameId: game['id'],vendorId:widget.vendorId));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xffDE3A3A),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                  ),
                                  child: const Text('Book Slot', style: TextStyle(color: Colors.black)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 20),
                sectionChip("Available Games:", widget.availableGames),
                const SizedBox(height: 20),
                sectionChip("Amenities:", widget.amenities, includeIcon: true),
                const SizedBox(height: 20),
                Text("Contact Information:", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                const SizedBox(height: 8),
                infoCard([rowInfo(Icons.phone, widget.contactInfo)]),
                const SizedBox(height: 20),
                Text("Reviews:", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                const SizedBox(height: 8),
                ...widget.reviews.map((review) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xff181818),
                    border: Border.all(color: const Color(0xff2D2D2D)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.white),
                    title: Text(review.toString(), style: const TextStyle(color: Colors.white)),
                  ),
                )),
                const SizedBox(height: 16),
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
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(color: Colors.white70))),
    ],
  );

  Widget infoCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xff181818),
      border: Border.all(color: const Color(0xff2D2D2D)),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget sectionChip(String title, List<dynamic> items, {bool includeIcon = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .where((item) {
              // For amenities, check if available is true
              if (includeIcon && item is Map) {
                return item['available'] == true;
              }
              return true; // For other items, show all
            })
            .map((item) => Chip(
          label: includeIcon
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                item is Map ? item['name']?.toString() ?? 'Unknown' : item.toString(), 
                style: const TextStyle(color: Colors.white)
              )
            ],
          )
              : Text(
                item is Map ? item['name']?.toString() ?? 'Unknown' : item.toString(), 
                style: const TextStyle(color: Colors.white)
              ),
          backgroundColor: const Color(0xff0E0E0E),
          side: const BorderSide(color: Color(0xff2D2D2D)),
        ))
            .toList(),
      )
    ],
  );
}