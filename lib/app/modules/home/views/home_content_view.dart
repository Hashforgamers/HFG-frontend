import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';

import '../../../../utils/widgets/loader.dart';
import '../../../data/services/user_controller.dart';
import '../../../routes/app_routes.dart';
import '../../arena/controllers/booking_controller.dart';
import '../../arena/views/arena_section_view.dart';
import '../../event/event_banner_view.dart';
import '../../game/views/game_section_view.dart';
import '../../login/controllers/login_controller.dart';
import '../../news/news_section_view.dart';
import '../../rewards/reward_section_view.dart';
import '../../shop/views/shop_section_view.dart';
import '../../shorts/views/viral_shots_view.dart';
import '../../team/team_section_view.dart';
import '../../tournaments/views/tournament_section_view.dart';
import '../widgets/booking_card_widget.dart';

class HomeContentView extends StatelessWidget {
  final BookingController bookingController = Get.put(BookingController());
  final LoginController loginController = Get.put(LoginController());
  final segmentService = locator<SegmentSdkService>();

  HomeContentView({super.key}) {
    // Fetch user bookings when HomeContentView is initialized
    bookingController.fetchUserBookings();
    loginController.checkUserExistsInAPI();
  }

  String _formatTimeTo24Hour(String rawTime) {
    if (rawTime == 'N/A') return rawTime;
    try {
      final DateTime parsedTime = DateFormat('HH:mm:ss').parse(rawTime);
      return DateFormat('HH:mm').format(parsedTime);
    } catch (e) {
      print('Error formatting time: $e');
      return 'Invalid Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserController user = Get.find<UserController>();
    segmentService.onHomeScreenViewed(userId: '');
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(() => Text(
                  'Hey, ${user.user.value.gameUserName}!',
                  style: const TextStyle(color: Colors.white),
                )),
            Obx(() {
              if (user.isLoading.value) {
                return const CircularProgressIndicator(color: Colors.white);
              } else {
                return PopupMenuButton<String>(
                  offset: const Offset(0, 40),
                  color: Colors.black87,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  onSelected: (String result) => print(result),
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'Profile',
                      child: Text('Profile',
                          style: TextStyle(color: Color(0xffDE3A3A))),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Settings',
                      child: Text('Settings',
                          style: TextStyle(color: Color(0xffDE3A3A))),
                    ),
                    PopupMenuItem<String>(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('token');
                        await prefs.remove('user_data');
                        Get.offAllNamed(AppRoutes.LOGIN);
                      },
                      value: 'Logout',
                      child: const Text('Logout',
                          style: TextStyle(color: Color(0xffDE3A3A))),
                    ),
                  ],
                  child: Obx(() => CircleAvatar(
                        radius: 15,
                        backgroundImage: user.user.value.photoUrl != null &&
                                user.user.value.photoUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(
                                user.user.value.photoUrl!) as ImageProvider
                            : const NetworkImage(
                                'https://wallpapers.com/images/hd/placeholder-profile-icon-20tehfawxt5eihco.jpg'),
                        backgroundColor: Colors.white,
                      )),
                );
              }
            }),
          ],
        ),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(10),
        children: [
          RewardsSection(), // Static widget; marked as const
          const SizedBox(height: 18),
          RainbowLoadingBar(height: 0.5, width: Get.width),
          const SizedBox(height: 18),
          EventBanner(), // Static widget; marked as const
          const SizedBox(height: 18),
          // Obx(() {
          //   if (bookingController.isLoading.value) {
          //     return const Center(child: RainbowGlowingLoader(size: 50),);
          //   }
          //   if (bookingController.userBookings.isEmpty) {
          //     return const SizedBox();
          //   }
          //   return _buildBookingsSection();
          // }),
          const SizedBox(height: 18),
          GamerNewsSection(),
          const SizedBox(height: 18),

          ViralShotsSection(), // Static widget
          const SizedBox(height: 18),
          ShopSection(), // Static widget
          const SizedBox(height: 18),
          TournamentsSection(), // Static widget
          const SizedBox(height: 18),
          ArenaSection(), // Static widget
          const SizedBox(height: 18),
          TeamSection(), // Static widget
          const SizedBox(height: 18),
          GamesSection(), // Static widget
          _buildGameOnIndiaBanner(),
        ],
      ),
    );
  }

  Widget _buildBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BOOKINGS',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 122,
          width: Get.width * 0.99,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: bookingController.userBookings.length,
            itemBuilder: (context, index) {
              final booking = bookingController.userBookings[index];
              return BookingCard(
                gameName: booking['slot']?['gaming_type_id']?['game_name'] ??
                    'Unknown Game',
                cafeName: booking['slot']?['gaming_type_id']?['cafe_name']
                        ['cafe_name'] ??
                    'Unknown Cafe',
                startTime: _formatTimeTo24Hour(
                    booking['slot']?['time']?['start_time'] ?? 'N/A'),
                endTime: _formatTimeTo24Hour(
                    booking['slot']?['time']?['end_time'] ?? 'N/A'),
                status: booking['status'] ?? 'Pending',
                price: (booking['slot']?['gaming_type_id']
                            ?['single_slot_price'] ??
                        0.0)
                    .toDouble(),
                location: booking['slot']?['location'] ?? 'Mumbai',
                bookingId: booking['booking_id'] ?? 0,
                additionalServices: booking['additional_services'] ?? '',
                booking: booking,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGameOnIndiaBanner() {
    return Padding(
      padding: const EdgeInsets.only(top: 45.0),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFF9933), // Saffron
              Colors.white, // White
              Color(0xFF138808), // Green
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Game On, India!',
            style: GoogleFonts.tulpenOne(
              fontSize: 100,
              fontWeight: FontWeight.normal,
              color: Colors.white, // Text color required for ShaderMask
            ),
          ),
        ),
      ),
    );
  }
}
