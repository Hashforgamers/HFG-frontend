import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/routes/app_routes.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/app/modules/event/event_banner_view.dart';
import 'package:hash/app/modules/game/views/game_section_view.dart';
import 'package:hash/app/modules/login/controllers/login_controller.dart';
import 'package:hash/app/modules/news/news_section_view.dart';
import 'package:hash/app/modules/rewards/reward_section_view.dart';
import 'package:hash/app/modules/shop/views/shop_section_view.dart';
import 'package:hash/app/modules/shorts/views/viral_shots_view.dart';
import 'package:hash/app/modules/cafe/views/cafe_section_view.dart';

import '../../../../utils/widgets/custom_card.dart';

class HomeContentView extends StatefulWidget {
  const HomeContentView({super.key});

  @override
  State<HomeContentView> createState() => _HomeContentViewState();
}

class _HomeContentViewState extends State<HomeContentView> {
  final BookingController bookingController = Get.put(BookingController());

  final LoginController loginController = Get.put(LoginController());

  @override
  void initState() {
    bookingController.fetchUserBookings();
    loginController.checkUserExistsInAPI();
    BlocProvider.of<HashCoinCubit>(context).getHashCoin();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final UserController user = Get.find<UserController>();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF338125),
        child: const Icon(
          Icons.support_agent_outlined,
          color: Colors.white,
        ),
      ),
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
          BlocBuilder<HashCoinCubit, HashCoinState>(
            builder: (context, state) {
              if (state is HashCoinLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (state is HashCoinLoaded) {
                return RewardsSection(
                  hashCoin: state.hashCoin,
                );
              }
              if (state is HashCoinError) {
                return const Center(
                  child: Text('Error loading hash coin'),
                );
              }
              return const RewardsSection(hashCoin: 0);
            },
          ), // Static widget; marked as const
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
          CafeSection(), // Add the new cafe section
          const SizedBox(height: 18),
          const GamerNewsSection(),
          const SizedBox(height: 18),

          ViralShotsSection(), // Static widget
          const SizedBox(height: 18),
          ShopSection(), // Static widget
          const SizedBox(height: 18),
          // const TournamentsSection(), // Static widget
          // const SizedBox(height: 18),

          GamesSection(), // Static widget
          _buildGameOnIndiaBanner(),
        ],
      ),
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
