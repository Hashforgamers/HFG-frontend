import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/views/arena_detail/arena_detail_consoles_section.dart';
import 'package:hash/app/modules/arena/views/arena_detail/arena_detail_header.dart';
import 'package:hash/app/modules/arena/views/arena_detail/arena_detail_info_section.dart';
import 'package:hash/app/modules/arena/views/arena_detail/arena_detail_reviews_section.dart';
import 'package:hash/app/modules/arena/views/booking_screen.dart';
import 'package:hash/app/modules/arena/views/menu_view.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:hash/utils/widgets/loader.dart';
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
  final List<dynamic> images;
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
    required this.vendorId,
    required this.images,
  });

  @override
  State<ArenaDetailView> createState() => _ArenaDetailViewState();
}

class _ArenaDetailViewState extends State<ArenaDetailView> {
  late final CafeGamesController _gamesController;
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  @override
  void initState() {
    super.initState();
    _gamesController = Get.put(
      CafeGamesController(),
      tag: 'vendor_${widget.vendorId}',
    );
    _gamesController.fetchGames(widget.vendorId);
    _gamesController.fetchPasses(widget.vendorId);

    // Track cafe images viewed event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      segmentService.onCafeImagesViewed(cafeId: widget.vendorId.toString());
      fbEventsService.onCafeImagesViewed(cafeId: widget.vendorId.toString());
    });
  }

  @override
  void dispose() {
    Get.delete<CafeGamesController>(tag: 'vendor_${widget.vendorId}');
    super.dispose();
  }

  bool _hasFoodAmenity(List<dynamic> amenities) {
    return amenities.any((a) {
      if (a is! Map) return false;
      final available = _truthy(a['available'] ?? a['is_available']);
      final name = (a['name'] ?? '')
          .toString()
          .toLowerCase()
          .replaceAll('_', ' ')
          .trim();
      // robust match
      final isFood =
          name == 'food' ||
          name.contains('food') ||
          name.contains('beverage') ||
          name.contains('snack') ||
          name.contains('cafe') ||
          name.contains('kitchen');
      return available && isFood;
    });
  }

  bool _truthy(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return true;
  }

  Widget _buildPassesSection() {
    return Obx(() {
      final passes = _gamesController.passes;
      if (_gamesController.isPassesLoading.value || passes.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passes',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...passes.map(
            (p) => _PassCard(
              name: p.name ?? 'Pass',
              price: (p.price ?? 0).toDouble(),
              totalHours: p.totalHour ?? 0,
              daysValid: p.daysValid ?? 0,
              description: p.description ?? '',
            ),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasFood = _hasFoodAmenity(widget.amenities);

    final List<String> imageUrls = widget.images
        .map((image) => image['url']?.toString() ?? '')
        .toList()
        .cast<String>();

    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              ArenaDetailHeader(
                imageUrls: imageUrls,
                onBack: () => Navigator.of(context).pop(),
                onShare: () {},
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ArenaDetailInfoSection(
                      title: widget.title,
                      address: widget.address,
                      openingHours: widget.openingHours,
                    ),
                    const SizedBox(height: 24),
                    ArenaDetailConsolesSection(
                      isLoading: _gamesController.isLoading,
                      games: _gamesController.games,
                    ),
                    const SizedBox(height: 24),
                    _buildPassesSection(),
                    const SizedBox(height: 24),
                    gameTitlesGrid(_gamesController),
                    const SizedBox(height: 24),
                    amenitiesGrid(widget.amenities, excludeFood: hasFood),
                    if (hasFood) ...[
                      const SizedBox(height: 24),
                      foodAndBeverageGrid([
                        {
                          'name': 'Crispy Fries',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075186/menu1_ar0hbe.png',
                        },
                        {
                          'name': 'Veggie Burger',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075187/menu2_go9rv3.png',
                        },
                        {
                          'name': 'Red Sauce Pasta',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075188/menu3_o2c0zy.png',
                        },
                        {
                          'name': 'Protein Sandwich',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075189/menu4_wgmjrq.png',
                        },
                        {
                          'name': 'Hot Coffee',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075190/menu5_f3t2l0.png',
                        },
                        {
                          'name': 'Coca Cola with Ice',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075190/menu6_qhoalw.png',
                        },
                        {
                          'name': 'Blue Lagoon',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075191/menu7_tj4lp1.png',
                        },
                        {
                          'name': 'Choco Pastry',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075192/menu8_na7k6n.png',
                        },
                        {
                          'name': 'Classic Donut',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075193/menu9_xlmk0e.png',
                        },
                      ]),
                    ],

                    const SizedBox(height: 24),

                    ArenaDetailReviewsSection(reviews: widget.reviews),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: GetX<CafeGamesController>(
                init: _gamesController,
                builder: (controller) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!controller.shopOpen.value) {
                          Get.snackbar(
                            'Shop Closed',
                            'Shop is closed today, no games available.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        final hasFood = _hasFoodAmenity(widget.amenities);

                        if (hasFood) {
                          final response = await showFoodOrderPrompt(
                            context,
                            () {
                              Get.to(
                                MenuViewPage(
                                  vendorId: widget.vendorId.toString(),
                                  email: widget.email,
                                  onContinue: (cartItems) {
                                    showBookSlotBottomSheet(
                                      context: context,
                                      email: widget.email,
                                      cartItems: cartItems,
                                    );
                                  },
                                ),
                              );
                            },
                          );

                          if (context.mounted && response != true) {
                            // response == false or null → go straight to booking
                            showBookSlotBottomSheet(
                              context: context,
                              email: widget.email,
                              cartItems: null,
                            );
                          }
                        } else {
                          // No food amenity → skip prompt
                          showBookSlotBottomSheet(
                            context: context,
                            email: widget.email,
                            cartItems: null,
                          );
                        }
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.shopOpen.value
                            ? const Color(0xff00DC00)
                            : Colors.grey.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        controller.shopOpen.value
                            ? 'Continue Booking'
                            : 'Shop Closed',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> showFoodOrderPrompt(
    BuildContext context,
    VoidCallback onYes,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFF181818),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 60,
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl:
                                'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075193/menu9_xlmk0e.png',
                            width: 70,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      SizedBox(
                        width: 70,
                        height: 60,
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl:
                                'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075189/menu4_wgmjrq.png',
                            width: 70,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      SizedBox(
                        width: 70,
                        height: 60,
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl:
                                'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075187/menu2_go9rv3.png',
                            width: 70,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "Want to order ahead \nfrom the café?",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context, true); // Return true for "Yes"
                          onYes(); // Callback for "Yes"
                        },
                        child: Container(
                          height: 40,
                          width: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Color(0xff00DC00),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              "Yes, please",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => Navigator.pop(
                          context,
                          false,
                        ), // Return false for "No"
                        child: Container(
                          height: 40,
                          width: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white24,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              "No, thanks",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<dynamic> showBookSlotBottomSheet({
    required BuildContext context,
    required email,
    List<Map<String, dynamic>>? cartItems,
  }) async {
    final safeEmail = (email ?? widget.email).toString();
    // Check if shop is open before showing booking options.
    if (!_gamesController.shopOpen.value) {
      Get.snackbar(
        'Shop Closed',
        'Shop is closed today, no games available.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
      return Future.value(null);
    }

    // If user taps quickly before initial fetch completes, refresh once.
    if (_gamesController.games.isEmpty || _gamesController.isLoading.value) {
      await _gamesController.fetchGames(widget.vendorId);
      if (!context.mounted) {
        return Future.value(null);
      }
    }

    int? asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v == null) return null;
      return int.tryParse(v.toString());
    }

    double asDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    dynamic readAny(Map<String, dynamic> map, List<String> keys) {
      for (final key in keys) {
        if (map.containsKey(key) && map[key] != null) {
          return map[key];
        }
      }
      return null;
    }

    int availabilityCount(dynamic v, {int fallback = 1}) {
      if (v is bool) return v ? 1 : 0;
      if (v is num) return v.toInt();
      if (v is String) {
        final raw = v.trim().toLowerCase();
        if (raw == 'true' || raw == 'yes') return 1;
        if (raw == 'false' || raw == 'no') return 0;
        return int.tryParse(raw) ?? fallback;
      }
      return fallback;
    }

    final Map<String, List<Map<String, dynamic>>> gamesByConsole = {};

    void upsertGame({
      required String gameName,
      required String genre,
      required String imageUrl,
      required String rawConsoleType,
      required int bookingId,
      required double price,
      required int availableCount,
    }) {
      final consoleType = _normalizeConsoleType(rawConsoleType);
      if (consoleType.isEmpty) return;
      final list = gamesByConsole.putIfAbsent(consoleType, () => []);
      final existingIndex = list.indexWhere(
        (item) => item['game_id'] == bookingId && item['title'] == gameName,
      );
      if (existingIndex >= 0) {
        list[existingIndex]['available'] =
            (list[existingIndex]['available'] as int? ?? 0) + availableCount;
        if ((list[existingIndex]['price'] as double? ?? 0) <= 0 && price > 0) {
          list[existingIndex]['price'] = price;
        }
        return;
      }

      list.add({
        'title': gameName.isEmpty ? 'Game' : gameName,
        'genre': genre,
        'image_url': imageUrl,
        'console_type': consoleType,
        'game_id': bookingId,
        'price': price,
        'available': availableCount,
      });
    }

    for (final g in _gamesController.games) {
      if (g is! Map) continue;
      final gameMap = Map<String, dynamic>.from(g);
      final gameName = (readAny(gameMap, ['game_name', 'name', 'title']) ?? '')
          .toString()
          .trim();
      final genre = (gameMap['genre'] ?? '').toString().trim();
      final imageUrl =
          (readAny(gameMap, [
                    'image_url',
                    'game_image',
                    'game_image_url',
                    'image',
                  ]) ??
                  '')
              .toString()
              .trim();
      final fallbackPrice = asDouble(
        readAny(gameMap, ['single_slot_price', 'avg_price', 'price_per_hour']),
      );
      final fallbackBookingId = asInt(
        readAny(gameMap, [
          'booking_game_id',
          'bookingGameId',
          'vendor_game_id',
          'vendorGameId',
          'game_id',
          'id',
        ]),
      );

      final gameConsoles = gameMap['consoles'];
      if (gameConsoles is List && gameConsoles.isNotEmpty) {
        for (final c in gameConsoles) {
          if (c is! Map) continue;
          final consoleMap = Map<String, dynamic>.from(c);
          final rawConsoleType =
              (readAny(consoleMap, ['console_type', 'consoleType', 'type']) ??
                      readAny(gameMap, ['game_platform', 'platform']) ??
                      'pc')
                  .toString();
          final bookingId =
              asInt(
                readAny(consoleMap, [
                  'booking_game_id',
                  'bookingGameId',
                  'vendor_game_id',
                  'vendorGameId',
                  'game_id',
                  'id',
                ]),
              ) ??
              fallbackBookingId;
          if (bookingId == null) continue;
          final price = asDouble(
            readAny(consoleMap, ['price_per_hour']) ?? fallbackPrice,
          );
          final available = availabilityCount(
            readAny(consoleMap, ['is_available', 'available']) ?? true,
          );
          upsertGame(
            gameName: gameName,
            genre: genre,
            imageUrl: imageUrl,
            rawConsoleType: rawConsoleType,
            bookingId: bookingId,
            price: price,
            availableCount: available,
          );
        }
        continue;
      }

      final fallbackConsoleType =
          (readAny(gameMap, [
                    'console_type',
                    'consoleType',
                    'type',
                    'game_platform',
                    'platform',
                  ]) ??
                  '')
              .toString();
      if (fallbackConsoleType.isEmpty || fallbackBookingId == null) {
        continue;
      }
      final fallbackAvailable = availabilityCount(
        readAny(gameMap, ['is_available', 'available']) ??
            gameMap['total_slots'],
        fallback: asInt(gameMap['total_slots']) ?? 1,
      );
      upsertGame(
        gameName: gameName,
        genre: genre,
        imageUrl: imageUrl,
        rawConsoleType: fallbackConsoleType,
        bookingId: fallbackBookingId,
        price: fallbackPrice,
        availableCount: fallbackAvailable,
      );
    }

    final List<Map<String, dynamic>> consoleOptions = [];
    for (final entry in gamesByConsole.entries) {
      final games = entry.value;
      if (games.isEmpty) continue;
      var availableGames = 0;
      var totalAvailable = 0;
      double minPrice = 0;
      for (final game in games) {
        final available = game['available'] as int? ?? 0;
        final price = game['price'] as double? ?? 0;
        if (available > 0) availableGames++;
        totalAvailable += available;
        if (price > 0 && (minPrice == 0 || price < minPrice)) {
          minPrice = price;
        }
      }

      consoleOptions.add({
        'type': entry.key,
        'label': _consoleDisplayLabel(entry.key),
        'icon': _getConsoleIcon(entry.key),
        'total_games': games.length,
        'available_games': availableGames,
        'total_available': totalAvailable,
        'starting_price': minPrice,
      });
    }

    consoleOptions.sort((a, b) {
      final aAvailable = a['available_games'] as int? ?? 0;
      final bAvailable = b['available_games'] as int? ?? 0;
      if (aAvailable != bAvailable) return bAvailable.compareTo(aAvailable);
      return (a['label'] as String).compareTo(b['label'] as String);
    });

    int selectedIndex = 0;
    for (int i = 0; i < consoleOptions.length; i++) {
      if ((consoleOptions[i]['available_games'] as int? ?? 0) > 0) {
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
            final bool canContinue = consoleOptions.isNotEmpty;
            return SafeArea(
              top: false,
              child: Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: SizedBox(
                  height: maxHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Choose console type',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 26,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (consoleOptions.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF232323),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'No console types available right now.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (consoleOptions.isNotEmpty)
                          Expanded(
                            child: GridView.builder(
                              itemCount: consoleOptions.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 1.65,
                                  ),
                              itemBuilder: (context, index) {
                                final option = consoleOptions[index];
                                final isSelected = selectedIndex == index;
                                final availableGames =
                                    option['available_games'] as int? ?? 0;
                                final totalGames =
                                    option['total_games'] as int? ?? 0;
                                final startPrice =
                                    option['starting_price'] as double? ?? 0;
                                final hasAvailable = availableGames > 0;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedIndex = index;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(
                                              0xFF00DC00,
                                            ).withValues(alpha: 0.16)
                                          : const Color(0xFF232323),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xff00DC00)
                                            : Colors.white12,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CachedNetworkImage(
                                              imageUrl: (option['icon'] ?? '')
                                                  .toString(),
                                              height: 24,
                                              width: 24,
                                              placeholder: (_, _) =>
                                                  const SizedBox(
                                                    height: 16,
                                                    width: 16,
                                                    child: RainbowGlowingLoader(
                                                      size: 10,
                                                    ),
                                                  ),
                                              errorWidget: (_, _, _) =>
                                                  const Icon(
                                                    Icons.videogame_asset,
                                                    color: Colors.white70,
                                                    size: 20,
                                                  ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                (option['label'] ?? '')
                                                    .toString(),
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Text(
                                          '$availableGames/$totalGames games available',
                                          style: GoogleFonts.inter(
                                            color: hasAvailable
                                                ? Colors.white70
                                                : Colors.redAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (startPrice > 0) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Starts at ₹${startPrice.toStringAsFixed(startPrice % 1 == 0 ? 0 : 1)}/hr',
                                            style: GoogleFonts.inter(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: canContinue
                                ? () async {
                                    final selectedConsole =
                                        consoleOptions[selectedIndex];
                                    final selectedType =
                                        (selectedConsole['type'] ?? '')
                                            .toString();
                                    final selectedGames =
                                        List<Map<String, dynamic>>.from(
                                          gamesByConsole[selectedType] ??
                                              const <Map<String, dynamic>>[],
                                        );
                                    Navigator.of(context).pop();
                                    if (!mounted) return;
                                    await Future.delayed(
                                      const Duration(milliseconds: 140),
                                    );
                                    if (!mounted) return;
                                    _showAvailableGamesBottomSheet(
                                      context: this.context,
                                      email: safeEmail,
                                      consoleType: selectedType,
                                      games: selectedGames,
                                      cartItems: cartItems,
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff00DC00),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBackgroundColor: Colors.grey.shade800,
                            ),
                            child: Text(
                              'Choose Game',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<dynamic> _showAvailableGamesBottomSheet({
    required BuildContext context,
    required String email,
    required String consoleType,
    required List<Map<String, dynamic>> games,
    List<Map<String, dynamic>>? cartItems,
  }) {
    int? asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value == null) return null;
      return int.tryParse(value.toString());
    }

    String formatPrice(double value) {
      if (value <= 0) return 'Price not available';
      return value % 1 == 0
          ? '₹${value.toInt()}/hr'
          : '₹${value.toStringAsFixed(1)}/hr';
    }

    int selectedIndex = 0;
    for (int i = 0; i < games.length; i++) {
      if ((games[i]['available'] as int? ?? 0) > 0) {
        selectedIndex = i;
        break;
      }
    }

    final consoleLabel = _consoleDisplayLabel(consoleType);
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
            final maxHeight = MediaQuery.of(context).size.height * 0.62;
            final canContinue =
                games.isNotEmpty &&
                (games[selectedIndex]['available'] as int? ?? 0) > 0;
            return SafeArea(
              top: false,
              child: SizedBox(
                height: maxHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Material(
                            color: const Color(0xFF232323),
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                Navigator.of(context).pop();
                                if (!mounted) return;
                                Future.delayed(
                                  const Duration(milliseconds: 120),
                                  () {
                                    if (!mounted) return;
                                    showBookSlotBottomSheet(
                                      context: this.context,
                                      email: email,
                                      cartItems: cartItems,
                                    );
                                  },
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Choose game • $consoleLabel',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 26,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (games.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF232323),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'No games available for $consoleLabel right now.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (games.isNotEmpty)
                        Expanded(
                          child: ListView.separated(
                            itemCount: games.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final game = games[index];
                              final isSelected = selectedIndex == index;
                              final available = game['available'] as int? ?? 0;
                              final isAvailable = available > 0;
                              final price = game['price'] as double? ?? 0;
                              final title = (game['title'] ?? 'Game')
                                  .toString()
                                  .trim();
                              final genre = (game['genre'] ?? '')
                                  .toString()
                                  .trim();
                              final imageUrl = (game['image_url'] ?? '')
                                  .toString()
                                  .trim();

                              return GestureDetector(
                                onTap: isAvailable
                                    ? () => setState(() {
                                        selectedIndex = index;
                                      })
                                    : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected && isAvailable
                                        ? const Color(
                                            0xFF00DC00,
                                          ).withValues(alpha: 0.16)
                                        : const Color(0xFF232323),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected && isAvailable
                                          ? const Color(0xff00DC00)
                                          : Colors.white12,
                                      width: 1.4,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: imageUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                height: 56,
                                                width: 56,
                                                fit: BoxFit.cover,
                                                placeholder: (_, _) => Container(
                                                  height: 56,
                                                  width: 56,
                                                  color: const Color(
                                                    0xFF1A1A1A,
                                                  ),
                                                  child: const Center(
                                                    child: RainbowGlowingLoader(
                                                      size: 12,
                                                    ),
                                                  ),
                                                ),
                                                errorWidget: (_, _, _) =>
                                                    Container(
                                                      height: 56,
                                                      width: 56,
                                                      color: const Color(
                                                        0xFF1A1A1A,
                                                      ),
                                                      child: const Icon(
                                                        Icons.sports_esports,
                                                        color: Colors.white54,
                                                        size: 24,
                                                      ),
                                                    ),
                                              )
                                            : Container(
                                                height: 56,
                                                width: 56,
                                                color: const Color(0xFF1A1A1A),
                                                child: const Icon(
                                                  Icons.sports_esports,
                                                  color: Colors.white54,
                                                  size: 24,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                color: isAvailable
                                                    ? Colors.white
                                                    : Colors.white54,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (genre.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                genre,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  color: Colors.white60,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isAvailable
                                                    ? const Color(0xFF181818)
                                                    : const Color(0xFF3A2323),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '$available available',
                                                style: GoogleFonts.inter(
                                                  color: isAvailable
                                                      ? Colors.white70
                                                      : Colors.redAccent,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        formatPrice(price),
                                        style: GoogleFonts.inter(
                                          color: isAvailable
                                              ? Colors.white
                                              : Colors.white54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: canContinue
                              ? () {
                                  final selectedGame = games[selectedIndex];
                                  final selectedGameId = asInt(
                                    selectedGame['game_id'],
                                  );
                                  if (selectedGameId == null) {
                                    _showSafeErrorSnackBar(
                                      context,
                                      'Game ID not found for booking',
                                    );
                                    return;
                                  }

                                  try {
                                    Navigator.of(context).pop();
                                    if (!mounted) return;
                                    Navigator.of(this.context).push(
                                      MaterialPageRoute(
                                        builder: (_) => BookingScreen(
                                          email: email,
                                          consoleType: _getConsoleType(
                                            consoleType,
                                          ),
                                          title: widget.title,
                                          gameId: selectedGameId,
                                          vendorId: widget.vendorId,
                                          cartItems: cartItems ?? [],
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    debugPrint(
                                      'Failed to open booking screen: $e',
                                    );
                                    _showSafeErrorSnackBar(
                                      context,
                                      'Failed to open booking screen',
                                    );
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff00DC00),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBackgroundColor: Colors.grey.shade800,
                          ),
                          child: Text(
                            'Continue to Booking',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
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

  String _normalizeConsoleType(String consoleName) {
    final name = consoleName.toLowerCase().trim();
    if (name.isEmpty) return '';
    if (name.contains('playstation') || name.contains('ps')) return 'ps5';
    if (name.contains('xbox')) return 'xbox';
    if (name.contains('vr') || name.contains('virtual')) return 'vr';
    if (name.contains('nintendo') || name.contains('switch')) return 'nintendo';
    if (name.contains('pc') || name.contains('computer')) return 'pc';
    return name;
  }

  String _consoleDisplayLabel(String consoleName) {
    switch (_normalizeConsoleType(consoleName)) {
      case 'ps5':
        return 'PS5';
      case 'xbox':
        return 'XBOX';
      case 'vr':
        return 'VR';
      case 'nintendo':
        return 'NINTENDO';
      case 'pc':
        return 'PC';
      default:
        return consoleName.toUpperCase();
    }
  }

  void _showSafeErrorSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final fallbackContext = Get.context;
    if (fallbackContext != null && Overlay.maybeOf(fallbackContext) != null) {
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    debugPrint('Unable to show snackbar: $message');
  }

  Widget rowInfo(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 18, color: Colors.white70),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, style: GoogleFonts.inter(color: Colors.white70)),
      ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget sectionChip(
    String title,
    List<dynamic> items, {
    bool includeIcon = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
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
            .map(
              (item) => Chip(
                label: includeIcon
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getAmenityIcon(
                              item is Map
                                  ? item['name']?.toString() ?? ''
                                  : item.toString(),
                            ),
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item is Map
                                ? item['name']?.toString() ?? 'Unknown'
                                : item.toString(),
                            style: GoogleFonts.inter(color: Colors.white),
                          ),
                        ],
                      )
                    : Text(
                        item is Map
                            ? item['name']?.toString() ?? 'Unknown'
                            : item.toString(),
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                backgroundColor: const Color(0xff0E0E0E),
                side: const BorderSide(color: Color(0xff2D2D2D)),
              ),
            )
            .toList(),
      ),
    ],
  );

  Widget gameTitlesGrid(CafeGamesController controller) {
    const placeholderImage =
        'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075080/pc_ah5ulv.png';

    bool _looksLikeConsoleLabel(String value) {
      final v = value.trim().toLowerCase();
      if (v.isEmpty) return true;
      const invalidLabels = <String>{
        'n/a',
        'na',
        'none',
        'null',
        'unknown',
        '-',
      };
      if (invalidLabels.contains(v)) return true;
      const blocked = <String>{
        'pc',
        'xbox',
        'xbox one',
        'xbox series',
        'xbox series s',
        'xbox series x',
        'playstation',
        'play station',
        'ps',
        'ps4',
        'ps5',
        'vr',
      };
      if (blocked.contains(v)) return true;
      if (v.startsWith('ps') && v.length <= 4) return true;
      return false;
    }

    String _gameName(Map<String, dynamic> game) {
      final candidates = [
        game['game_name'],
        game['name'],
        game['title'],
        game['gameTitle'],
      ];
      for (final c in candidates) {
        final name = (c ?? '').toString().trim();
        if (name.isEmpty) continue;
        if (_looksLikeConsoleLabel(name)) continue;
        return name;
      }
      return '';
    }

    String _gameImage(Map<String, dynamic> game) {
      final orderedKeys = [
        'image_url',
        'image',
        'game_image',
        'game_image_url',
        'thumbnail',
        'cover',
        'logo',
      ];
      for (final key in orderedKeys) {
        final v = game[key];
        if (v is String && v.trim().isNotEmpty) return v;
      }
      return placeholderImage;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Available Games",
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: AppLinearLoader());
            }

            final List<Map<String, String>> displayGames = [];

            for (final item in controller.games) {
              if (item is! Map) continue;
              final game = Map<String, dynamic>.from(item);
              final name = _gameName(game);
              if (name.isEmpty) continue;
              displayGames.add({'name': name, 'image': _gameImage(game)});
            }

            // Fallback to cafe-level games list when vendor-games payload has
            // platform labels (PC/PS5/XBOX) instead of actual game titles.
            if (displayGames.isEmpty) {
              for (final item in widget.availableGames) {
                final name = item is Map
                    ? (item['name'] ??
                          item['game_name'] ??
                          item['title'] ??
                          item['game'])
                          .toString()
                          .trim()
                    : item.toString().trim();
                if (name.isEmpty || _looksLikeConsoleLabel(name)) continue;
                displayGames.add({'name': name, 'image': placeholderImage});
              }
            }

            if (displayGames.isEmpty) {
              return Center(
                child: Text(
                  'No games available for now.',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displayGames.length,
              separatorBuilder: (_, __) => const SizedBox(width: 2),
              itemBuilder: (context, index) {
                final item = displayGames[index];
                final name = item['name'] ?? 'Game';
                final image = item['image'] ?? placeholderImage;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5.0,
                    vertical: 4.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: image,
                            width: 90,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 90,
                              height: 100,
                              color: const Color(0xff1A1A1A),
                              child: const Center(child: AppLinearLoader()),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 90,
                              height: 100,
                              color: const Color(0xff1A1A1A),
                              child: Image.network(
                                placeholderImage,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 90,
                        height: 16,
                        child: _MarqueeText(
                          text: name,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget foodAndBeverageGrid(List<Map<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Food & Beverages Offered",
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
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: CachedNetworkImage(
                  imageUrl: item['image']!,
                  height: 60,
                  width: 70,
                  fit: BoxFit.contain,
                  placeholder: (_, _) =>
                      const Center(child: RainbowGlowingLoader(size: 10)),
                  errorWidget: (_, _, _) =>
                      const Icon(Icons.error, color: Colors.red),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget amenitiesGrid(List<dynamic> amenities, {bool excludeFood = false}) {
    // Normalize amenities: accept maps or strings from API
    final normalized = amenities
        .map((item) {
          if (item is Map) {
            return {
              'name':
                  item['name'] ?? item['amenity'] ?? item['amenity_name'] ?? '',
              'available':
                  item['available'] ??
                  item['is_available'] ??
                  item['isAvailable'] ??
                  true,
            };
          }
          if (item is String) {
            return {'name': item, 'available': true};
          }
          return null;
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    final filtered = normalized.where((item) {
      if (!_truthy(item['available'])) return false;
      final name = (item['name'] ?? '').toString().toLowerCase();
      if (excludeFood &&
          (name == 'food' ||
              name.contains('food') ||
              name.contains('beverage') ||
              name.contains('snack') ||
              name.contains('cafe'))) {
        return false;
      }
      return name.isNotEmpty;
    }).toList();
    final display = filtered.isNotEmpty
        ? filtered
        : normalized
              .where(
                (item) => (item['name'] ?? '').toString().trim().isNotEmpty,
              )
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
            itemCount: display.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = display[index];
              final name = item['name']?.toString() ?? '';
              final displayName = name
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map(
                    (w) => w.isNotEmpty
                        ? '${w[0].toUpperCase()}${w.substring(1)}'
                        : '',
                  )
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
                  Container(
                    width: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Text(
                      displayName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
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
        name.contains('snack')) {
      return Icons.restaurant;
    }
    if (name.contains('coffee') ||
        name.contains('tea') ||
        name.contains('drink')) {
      return Icons.local_cafe;
    }
    if (name.contains('water') || name.contains('beverage')) {
      return Icons.local_drink;
    }

    // Comfort & Facilities
    if (name.contains('ac') || name.contains('air_condition')) {
      return FontAwesomeIcons.snowflake;
    }
    if (name.contains('wifi') || name.contains('internet')) {
      return FontAwesomeIcons.wifi;
    }
    if (name.contains('parking')) return FontAwesomeIcons.parking;
    if (name.contains('toilet') ||
        name.contains('washroom') ||
        name.contains('bathroom')) {
      return Icons.wc;
    }
    if (name.contains('charging') || name.contains('power')) return Icons.power;
    if (name.contains('headphone') || name.contains('audio')) {
      return FontAwesomeIcons.headphones;
    }
    if (name.contains('chair') || name.contains('seat')) {
      return FontAwesomeIcons.chair;
    }
    if (name.contains('table')) return FontAwesomeIcons.table;

    // Entertainment
    if (name.contains('tv') || name.contains('television')) {
      return FontAwesomeIcons.tv;
    }
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
      return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075080/pc_ah5ulv.png';
    }
    if (name.contains('xbox') || name.contains('x-box')) {
      return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075086/xbox_fmz0bn.png';
    }
    if (name.contains('ps5') ||
        name.contains('ps') ||
        name.contains('playstation')) {
      return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075082/ps_krf4kw.png';
    }
    if (name.contains('vr') || name.contains('virtual reality')) {
      return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075086/vr_rzqkbq.png';
    }
    if (name.contains('nintendo') || name.contains('switch')) {
      return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/gaming-pad-01_byibeu.png';
    }

    // Default icon
    return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075080/pc_ah5ulv.png';
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

class _PassCard extends StatelessWidget {
  final String name;
  final double price;
  final int totalHours;
  final int daysValid;
  final String description;

  const _PassCard({
    required this.name,
    required this.price,
    required this.totalHours,
    required this.daysValid,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalHours hrs • $daysValid days',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${price.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff00DC00),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Buy',
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  const _MarqueeText({
    required this.text,
    required this.style,
    this.blankSpace = 20,
    this.velocity = 30,
  });

  final String text;
  final TextStyle style;
  final double blankSpace;
  final double velocity; // pixels per second

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  void _startAnimation(Duration duration) {
    if (_controller.duration != duration || !_controller.isAnimating) {
      _controller.duration = duration;
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final textWidth = _measureTextWidth(widget.text, widget.style);
        if (textWidth <= maxWidth) {
          _controller.stop();
          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          );
        }

        final distance = textWidth + widget.blankSpace;
        final seconds = distance / widget.velocity;
        _startAnimation(Duration(milliseconds: (seconds * 1000).round()));

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: maxWidth,
            maxWidth: double.infinity,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                final offset = -distance * _controller.value;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.text, style: widget.style),
                      SizedBox(width: widget.blankSpace),
                      Text(widget.text, style: widget.style),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
