// Enhanced ArenaDetailView with full dark theme and polished UI
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/views/booking_screen.dart';
import 'dart:ui';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';

import '../controllers/games_controller.dart';

class ArenaDetailView extends StatefulWidget {
  final String title;
  final String address;
  final String openingHours;
  final List<dynamic> availableGames;
  final List<dynamic> amenities;
  final String phone;
  final String email;
  final String ownerName;
  final String images;
  final int vendorId;
  final List<dynamic> reviews;

  const ArenaDetailView({
    super.key,
    required this.title,
    required this.address,
    required this.openingHours,
    required this.availableGames,
    required this.amenities,
    required this.phone,
    required this.email,
    required this.ownerName,
    required this.reviews,
    required this.images,
    required this.vendorId,
  });

  @override
  State<ArenaDetailView> createState() => _ArenaDetailViewState();
}

class _ArenaDetailViewState extends State<ArenaDetailView> {
  final CafeGamesController _gamesController = Get.put(CafeGamesController());
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  @override
  void initState() {
    super.initState();
    _gamesController.fetchGames(widget.vendorId);
    
    // Track cafe images viewed event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      segmentService.onCafeImagesViewed(
        cafeId: widget.vendorId.toString(),
      );
      fbEventsService.onCafeImagesViewed(
        cafeId: widget.vendorId.toString(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> imageUrls =
        widget.images.split(','); // Assuming images is a comma-separated string
    int _currentPage = 0;
    final PageController _pageController = PageController();

    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 260,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: imageUrls.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) => Image.network(
                        imageUrls[index],
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 40,
                      left: 16,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white, size: 32),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 16,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.share,
                                  color: Colors.white, size: 28),
                              onPressed: () {},
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          imageUrls.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 28,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? const Color(0xff338125)
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xff181818),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.address,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xff181818),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.openingHours,
                                    style: GoogleFonts.inter(
                                        color: Colors.white, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Available Consoles",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 70,
                      child: GetX<CafeGamesController>(
                        builder: (controller) {
                          if (controller.isLoading.value) {
                            return const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            );
                          }

                          final List<dynamic> consoles =
                              controller.games.toList();

                          if (consoles.isEmpty) {
                            // Fallback to hardcoded consoles
                            return ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _consoleIcon('assets/icons/pc.png', "PC"),
                                _consoleIcon('assets/icons/xbox.png', "XBOX"),
                                _consoleIcon('assets/icons/ps.png', "PS5"),
                                _consoleIcon('assets/icons/vr.png', "VR"),
                              ],
                            );
                          }

                          return ListView(
                            scrollDirection: Axis.horizontal,
                            children: consoles.map((console) {
                              final Map<String, dynamic> consoleMap =
                                  console as Map<String, dynamic>;
                              final consoleName = consoleMap['game_name']
                                      ?.toString()
                                      .toUpperCase() ??
                                  'Unknown';
                              final iconPath = _getConsoleIcon(
                                  consoleMap['game_name'] ?? '');
                              return _consoleIcon(iconPath, consoleName);
                            }).toList(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    gameTitlesGrid(),
                    const SizedBox(height: 24),
                    amenitiesGrid(widget.amenities),
                    const SizedBox(height: 24),
                    Text("Reviews",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),),
                    const SizedBox(height: 8),
                    ...widget.reviews.map((review) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xff181818),
                            border: Border.all(color: const Color(0xff2D2D2D)),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            leading:
                                const Icon(Icons.person, color: Colors.white),
                            title: Text(review.toString(),
                                style: const TextStyle(color: Colors.white)),
                          ),
                        )),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
          // Book Slot Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    showBookSlotBottomSheet(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff338125),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Book your slot',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<dynamic> showBookSlotBottomSheet(BuildContext context) {
    // Get console data from the controller (API response games = consoles)
    final List<dynamic> consoles = _gamesController.games.toList();

    // Transform API console data to slot format
    final List<Map<String, dynamic>> slots = consoles.map((console) {
      final Map<String, dynamic> consoleMap = console as Map<String, dynamic>;

      final consoleName = consoleMap['game_name']?.toString() ?? '';
      final consoleId = consoleMap['id'];

      return {
        'label': consoleName.toUpperCase(),
        'icon': _getConsoleIcon(consoleName),
        'price': consoleMap['single_slot_price'] ?? 0,
        'available': consoleMap['total_slots'] ?? 0,
        'console_id': consoleId, // This should be the correct field from API
        'console_name': consoleName,
        'game_label':
            _getConsoleType(consoleName), // Add console type for booking screen
        'opening_days': consoleMap['opening_days'] ?? [],
      };
    }).toList();

    int selectedIndex = 0;
    for (int i = 0; i < slots.length; i++) {
      if (slots[i]['available'] > 0) {
        selectedIndex = i;
        break;
      }
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final double maxHeight = MediaQuery.of(context).size.height * 0.5;
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Container(
                height: maxHeight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Book your slot',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 28),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.6,
                        ),
                        itemCount: slots.length,
                        itemBuilder: (context, index) {
                          final slot = slots[index];
                          final isSelected = selectedIndex == index;
                          final isAvailable = slot['available'] > 0;
                          return GestureDetector(
                            onTap: isAvailable
                                ? () {
                                    setState(() {
                                      selectedIndex = index;
                                    });
                                  }
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected && isAvailable
                                    ? const Color(0xFF338125).withOpacity(0.15)
                                    : (isAvailable
                                        ? const Color(0xFF232323)
                                        : const Color(0xFF232323)
                                            .withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(14),
                                border: isSelected && isAvailable
                                    ? Border.all(
                                        color: const Color(0xFF338125),
                                        width: 2)
                                    : Border.all(
                                        color: Colors.transparent, width: 2),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Image.asset(slot['icon'],
                                          width: 22, height: 22),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          slot['label'],
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: isAvailable
                                                ? Colors.white
                                                : Colors.white54,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF181818),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '₹ ${slot['price']}',
                                          style: GoogleFonts.inter(
                                            color: isAvailable
                                                ? Colors.white
                                                : Colors.white54,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isAvailable
                                              ? const Color(0xFF181818)
                                              : const Color(0xFF3A2323),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isAvailable
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              color: isAvailable
                                                  ? Colors.white
                                                  : Colors.redAccent,
                                              size: 11,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${slot['available']} Available',
                                              style: GoogleFonts.inter(
                                                color: isAvailable
                                                    ? Colors.white
                                                    : Colors.redAccent,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: slots[selectedIndex]['available'] > 0
                              ? () {
                                  // Handle proceed action
                                  debugPrint('Selected index: $selectedIndex');
                                  debugPrint('Total slots: ${slots.length}');
                                  debugPrint(
                                      'Selected slot data: ${slots[selectedIndex]}');

                                  final consoleId =
                                      slots[selectedIndex]['console_id'];
                                  debugPrint(
                                      'Console ID for booking: $consoleId');
                                  debugPrint(
                                      'Console ID type: ${consoleId.runtimeType}');

                                  if (consoleId != null && consoleId is int) {
                                    try {
                                      Get.to(
                                        BookingScreen(
                                            consoleType: slots[selectedIndex]
                                                    ['game_label'] ??
                                                '',
                                            title: widget.title,
                                            gameId: consoleId,
                                            vendorId: widget.vendorId),
                                      );
                                    } catch (e) {
                                      debugPrint(
                                          'Error navigating to booking: $e');
                                      Get.snackbar(
                                        'Error',
                                        'Failed to open booking screen',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    }
                                  } else {
                                    debugPrint(
                                        'Console ID is null or not int: $consoleId, type: ${consoleId.runtimeType}');
                                    Get.snackbar(
                                      'Error',
                                      'Console ID not found or invalid',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                  }
                                  debugPrint(
                                      'Console ID: ${slots[selectedIndex]['console_id']}');
                                  debugPrint(
                                      'Console ID type: ${slots[selectedIndex]['console_id'].runtimeType}');
                                  debugPrint('Vendor ID: ${widget.vendorId}');
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF338125),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey.shade800,
                          ),
                          child: Text(
                            'Proceed',
                            style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _consoleIcon(String path, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 24.0),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xff181818),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Image.asset(path),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget rowInfo(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: const TextStyle(color: Colors.white70))),
        ],
      );

  Widget infoCard(List<Widget> children) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xff181818),
          border: Border.all(color: const Color(0xff2D2D2D)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget sectionChip(String title, List<dynamic> items,
          {bool includeIcon = false}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
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
                                Icon(
                                    _getAmenityIcon(item is Map
                                        ? item['name']?.toString() ?? ''
                                        : item.toString()),
                                    size: 16,
                                    color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                    item is Map
                                        ? item['name']?.toString() ?? 'Unknown'
                                        : item.toString(),
                                    style: const TextStyle(color: Colors.white))
                              ],
                            )
                          : Text(
                              item is Map
                                  ? item['name']?.toString() ?? 'Unknown'
                                  : item.toString(),
                              style: const TextStyle(color: Colors.white)),
                      backgroundColor: const Color(0xff0E0E0E),
                      side: const BorderSide(color: Color(0xff2D2D2D)),
                    ))
                .toList(),
          )
        ],
      );

  Widget gameTitlesGrid() {
    // Hardcoded popular games with their images
    final List<Map<String, String>> hardcodedGames = [
      {
        'name': 'Valorant',
        'image':
            'https://freelogopng.com/images/all_img/1664302216valorant-logo-png.png'
      },
      {
        'name': 'CS2',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/730/header.jpg'
      },
      {
        'name': 'Dota 2',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/570/header.jpg'
      },
      {
        'name': 'FIFA 24',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/1506830/header.jpg'
      },
      {
        'name': 'PUBG',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/578080/header.jpg'
      },
      {
        'name': 'Fortnite',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/945360/header.jpg'
      },
      {
        'name': 'Apex Legends',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/1172470/header.jpg'
      },
      {
        'name': 'Rocket League',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/252950/header.jpg'
      },
      {
        'name': 'Overwatch 2',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/2357570/header.jpg'
      },
      {
        'name': 'League of Legends',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/12170/header.jpg'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Available Games",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: hardcodedGames.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final game = hardcodedGames[index];

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      game['image']!,
                      width: 110,
                      height: 144,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget amenitiesGrid(List<dynamic> amenities) {
    final filtered = amenities
        .where((item) => item is Map && item['available'] == true)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Facilities",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = filtered[index];
              final name = item['name']?.toString() ?? '';
              final displayName = name
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map((w) => w.isNotEmpty
                      ? '${w[0].toUpperCase()}${w.substring(1)}'
                      : '')
                  .join(' ');
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xff232323),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      _getAmenityIcon(name),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getAmenityIcon(String amenityName) {
    final name = amenityName.toLowerCase();

    // Gaming related amenities
    if (name.contains('ps5') || name.contains('playstation')) {
      return Icons.games;
    }
    if (name.contains('xbox')) return Icons.games;
    if (name.contains('pc') || name.contains('computer')) return Icons.computer;
    if (name.contains('gaming') || name.contains('game')) {
      return Icons.sports_esports;
    }

    // Food & Beverage
    if (name.contains('food') ||
        name.contains('meal') ||
        name.contains('snack')) return Icons.restaurant;
    if (name.contains('coffee') ||
        name.contains('tea') ||
        name.contains('drink')) return Icons.local_cafe;
    if (name.contains('water') || name.contains('beverage')) {
      return Icons.local_drink;
    }

    // Comfort & Facilities
    if (name.contains('ac') || name.contains('air_condition')) {
      return FontAwesomeIcons.snowflake;
    }
    if (name.contains('wifi') || name.contains('internet'))
      return FontAwesomeIcons.wifi;
    if (name.contains('parking')) return FontAwesomeIcons.parking;
    if (name.contains('toilet') ||
        name.contains('washroom') ||
        name.contains('bathroom')) return Icons.wc;
    if (name.contains('charging') || name.contains('power')) return Icons.power;
    if (name.contains('headphone') || name.contains('audio')) {
      return FontAwesomeIcons.headphones;
    }
    if (name.contains('chair') || name.contains('seat'))
      return FontAwesomeIcons.chair;
    if (name.contains('table')) return FontAwesomeIcons.table;

    // Entertainment
    if (name.contains('tv') || name.contains('television'))
      return FontAwesomeIcons.tv;
    if (name.contains('music') || name.contains('sound')) {
      return FontAwesomeIcons.music;
    }
    if (name.contains('lighting') || name.contains('light')) {
      return FontAwesomeIcons.lightbulb;
    }

    // Security & Safety
    if (name.contains('security') || name.contains('cctv')) {
      return FontAwesomeIcons.shield;
    }
    if (name.contains('first aid') || name.contains('medical')) {
      return FontAwesomeIcons.medkit;
    }

    // General amenities
    if (name.contains('locker') || name.contains('storage')) return Icons.lock;
    if (name.contains('fan') || name.contains('ventilation')) {
      return FontAwesomeIcons.fan;
    }
    if (name.contains('clean') || name.contains('hygiene')) {
      return FontAwesomeIcons.broom;
    }

    // Default icon for unknown amenities
    return Icons.check;
  }

  String _getConsoleIcon(String consoleName) {
    final name = consoleName.toLowerCase();

    // Map console names to icon assets based on API response
    if (name.contains('pc') || name.contains('computer')) {
      return 'assets/icons/pc.png';
    }
    if (name.contains('xbox') || name.contains('x-box')) {
      return 'assets/icons/xbox.png';
    }
    if (name.contains('ps5') ||
        name.contains('ps') ||
        name.contains('playstation')) {
      return 'assets/icons/ps.png';
    }
    if (name.contains('vr') || name.contains('virtual reality')) {
      return 'assets/icons/vr.png';
    }
    if (name.contains('nintendo') || name.contains('switch')) {
      return 'assets/icons/gaming-pad-01.png';
    }

    // Default icon
    return 'assets/icons/pc.png';
  }

  String _getConsoleType(String consoleName) {
    final name = consoleName.toLowerCase();

    // Map console names to console types for booking screen
    if (name.contains('ps') || name.contains('playstation')) {
      return 'PS';
    }
    if (name.contains('xbox') || name.contains('x-box')) {
      return 'XB';
    }
    if (name.contains('vr') || name.contains('virtual reality')) {
      return 'VR';
    }
    if (name.contains('nintendo') || name.contains('switch')) {
      return 'NS';
    }

    // Default to PC
    return 'PC';
  }
}
