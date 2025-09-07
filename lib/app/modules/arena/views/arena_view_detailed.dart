import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/views/booking_screen.dart';
import 'package:hash/app/modules/arena/views/menu_view.dart';
import 'dart:ui';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../utils/widgets/loader.dart';
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
  final CafeGamesController _gamesController = Get.put(CafeGamesController());
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  int currentPage = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    _gamesController.fetchGames(widget.vendorId);

    // Track cafe images viewed event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      segmentService.onCafeImagesViewed(cafeId: widget.vendorId.toString());
      fbEventsService.onCafeImagesViewed(cafeId: widget.vendorId.toString());
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  bool _hasFoodAmenity(List<dynamic> amenities) {
    return amenities.any((a) {
      if (a is! Map) return false;
      final available = a['available'] == true;
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
              SizedBox(
                height: 260,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: pageController,
                      itemCount: imageUrls.length,
                      onPageChanged: (index) {
                        setState(() {
                          currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) => CachedNetworkImage(
                        imageUrl: imageUrls[index],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: RainbowGlowingLoader(size: 40)),
                        errorWidget: (_, _, _) => Container(
                          color: Colors.grey,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Colors.white54,
                          ),
                        ),
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
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 32,
                              ),
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
                              icon: const Icon(
                                Icons.share,
                                color: Colors.white,
                                size: 28,
                              ),
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
                              color: currentPage == index
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
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
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xff181818),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 18,
                                ),
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
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xff181818),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.openingHours,
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
                            return const Center(child: RainbowLoadingBar());
                          }

                          final List<dynamic> consoles = controller.games
                              .where((game) =>
                          game['game_name'] != null &&
                              (game['total_slots'] ?? 0) > 0)
                              .toList();

                          if (consoles.isEmpty) {
                            return const Center(
                              child: Text(
                                "No consoles available",
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }
                          if (consoles.isEmpty) {
                            // Fallback to hardcoded consoles
                            return ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _consoleIcon(
                                  'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075080/pc_ah5ulv.png',
                                  "PC",
                                ),
                                _consoleIcon(
                                  'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075086/xbox_fmz0bn.png',
                                  "XBOX",
                                ),
                                _consoleIcon(
                                  'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075082/ps_krf4kw.png',
                                  "PS5",
                                ),
                                _consoleIcon(
                                  'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075086/vr_rzqkbq.png',
                                  "VR",
                                ),
                              ],
                            );
                          }

                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: consoles.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 0),
                            itemBuilder: (context, index) {
                              final Map<String, dynamic> console = consoles[index];
                              final String name =
                                  console['game_name']?.toString().toUpperCase() ?? 'UNKNOWN';
                              final String iconPath =
                              _getConsoleIcon(console['game_name']?.toString() ?? '');

                              return _consoleIcon(iconPath, name);
                            },
                          );

                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    gameTitlesGrid(),
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

                    Text(
                      "Reviews",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.reviews.map(
                      (review) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xff181818),
                          border: Border.all(color: const Color(0xff2D2D2D)),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                          title: Text(
                            review.toString(),
                            style: GoogleFonts.inter(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
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
                            ? const Color(0xff338125)
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
                              color: Color(0xFF6DFB60),
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
  }) {
    // Check if shop is open before showing booking options
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
    final List<dynamic> consoles = _gamesController.games.toList();

    final List<Map<String, dynamic>> slots = consoles.map((console) {
      final Map<String, dynamic> consoleMap = console as Map<String, dynamic>;

      final consoleName = consoleMap['game_name']?.toString() ?? '';
      final consoleId = consoleMap['id'];

      return {
        'label': consoleName.toUpperCase(),
        'icon': _getConsoleIcon(consoleName),
        'price': consoleMap['single_slot_price'] ?? 0,
        'available': consoleMap['total_slots'] ?? 0,
        'console_id': consoleId,
        'console_name': consoleName,
        'game_label': _getConsoleType(consoleName),
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
            final double maxHeight = MediaQuery.of(context).size.height * 0.45;
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Container(
                height: maxHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
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
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 28,
                            ),
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
                              childAspectRatio: 1.7,
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
                                          : const Color(
                                              0xFF232323,
                                            ).withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected && isAvailable
                                    ? Border.all(
                                        color: const Color(0xFF338125),
                                        width: 2,
                                      )
                                    : Border.all(
                                        color: Colors.transparent,
                                        width: 2,
                                      ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: slot['icon'],
                                        height: 22,
                                        width: 22,
                                        placeholder: (_, _) => const Center(
                                          child: RainbowGlowingLoader(size: 10),
                                        ),
                                        errorWidget: (_, _, _) => const Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                      ),

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
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF181818),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isAvailable
                                              ? const Color(0xFF181818)
                                              : const Color(0xFF3A2323),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                                              size: 8,
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
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: slots[selectedIndex]['available'] > 0
                              ? () {
                                  final consoleId =
                                      slots[selectedIndex]['console_id'];
                                  if (consoleId != null && consoleId is int) {
                                    try {
                                      Get.to(
                                        BookingScreen(
                                          email: email,
                                          consoleType:
                                              slots[selectedIndex]['game_label'] ??
                                              '',
                                          title: widget.title,
                                          gameId: consoleId,
                                          vendorId: widget.vendorId,
                                          cartItems: cartItems ?? [],
                                        ),
                                      );
                                    } catch (e) {
                                      Get.snackbar(
                                        'Error',
                                        'Failed to open booking screen',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    }
                                  } else {
                                    Get.snackbar(
                                      'Error',
                                      'Console ID not found or invalid',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF338125),
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

  Widget _consoleIcon(String path, String label) {
    return Padding(
      padding: EdgeInsets.only(right: 20.w),
      child: Column(
        children: [
          CachedNetworkImage(
            imageUrl: path,
            height: 48.h,
            width: 48.w,
            placeholder: (_, _) =>
                const Center(child: RainbowGlowingLoader(size: 20)),
            errorWidget: (_, _, _) =>
                const Icon(Icons.error, color: Colors.red),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 11),
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

  Widget gameTitlesGrid() {
    // Hardcoded popular games with their images
    final List<Map<String, String>> hardcodedGames = [
      {
        'name': 'Valorant',
        'image':
            'https://freelogopng.com/images/all_img/1664302216valorant-logo-png.png',
      },
      {
        'name': 'CS2',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/730/header.jpg',
      },
      {
        'name': 'Dota 2',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/570/header.jpg',
      },
      {
        'name': 'FIFA 24',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/1506830/header.jpg',
      },
      {
        'name': 'PUBG',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/578080/header.jpg',
      },
      {
        'name': 'Fortnite',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/945360/header.jpg',
      },
      {
        'name': 'Apex Legends',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/1172470/header.jpg',
      },
      {
        'name': 'Rocket League',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/252950/header.jpg',
      },
      {
        'name': 'Overwatch 2',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/2357570/header.jpg',
      },
      {
        'name': 'League of Legends',
        'image':
            'https://cdn.cloudflare.steamstatic.com/steam/apps/12170/header.jpg',
      },
    ];

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
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: hardcodedGames.length,
            separatorBuilder: (_, __) => const SizedBox(width: 2),
            itemBuilder: (context, index) {
              final game = hardcodedGames[index];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5.0,
                  vertical: 8.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      game['image']!,
                      width: 80,
                      height: 112,
                      fit: BoxFit.cover,
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
    final filtered = amenities.where((item) {
      if (item is! Map) return false;
      if (item['available'] != true) return false;
      final name = (item['name'] ?? '').toString().toLowerCase();
      if (excludeFood &&
          (name == 'food' ||
              name.contains('food') ||
              name.contains('beverage') ||
              name.contains('snack') ||
              name.contains('cafe'))) {
        return false;
      }
      return true;
    }).toList();
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
