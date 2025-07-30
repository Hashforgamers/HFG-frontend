import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/app/modules/cafe/views/cafe_section_view.dart';
import 'package:hash/app/modules/event/event_banner_view.dart';
import 'package:hash/app/modules/fcm/cubit/fcm_cubit.dart';
import 'package:hash/app/modules/game/views/game_section_view.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/app/modules/login/controllers/login_controller.dart';
import 'package:hash/app/modules/news/news_section_view.dart';
import 'package:hash/app/modules/shop/views/shop_section_view.dart';
import 'package:hash/app/modules/shorts/views/viral_shots_view.dart';
import 'package:hash/app/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hash/app/modules/wallet/controllers/wallet_controller.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';

class HomeContentView extends StatefulWidget {
  const HomeContentView({super.key});

  @override
  State<HomeContentView> createState() => _HomeContentViewState();
}

class _HomeContentViewState extends State<HomeContentView> {
  final BookingController bookingController = Get.find();
  final LoginController loginController = Get.find();
  final UserController userController = Get.find();
  final segmentService = locator<SegmentSdkService>();

  final List<Map<String, String>> gameNewsCards = [
    {
      'image': "assets/images/gameNews_1.png",
      'title':
          'The Season 4 outro cutscene for Black Ops 6 and Warzone has players once again speculati...'
    },
    {
      'image': "assets/images/gameNews_2.png",
      'title':
          'The Season 4 outro cutscene for Black Ops 6 and Warzone has players once again speculati...'
    },
    {
      'image': "assets/images/gameNews_3.png",
      'title':
          'The Season 4 outro cutscene for Black Ops 6 and Warzone has players once again speculati...'
    },
    {
      'image': "assets/images/gameNews_4.png",
      'title':
          'The Season 4 outro cutscene for Black Ops 6 and Warzone has players once again speculati...'
    },
  ];

  @override
  void initState() {
    super.initState();
    BlocProvider.of<FcmCubit>(context).registerFCMToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
      _ensureWalletFetched();
      _trackHomeScreenViewed();
    });
  }

  void _trackHomeScreenViewed() {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      segmentService.onHomeScreenViewed(userId: currentUser.uid);
    }
  }

  void _ensureWalletFetched() {
    // Ensure wallet is fetched after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      final walletController = Get.find<WalletController>();
      if (walletController.isWalletReady &&
          walletController.balance.value == 0) {
        print('🔄 Ensuring wallet is fetched from home screen');
        walletController.refreshWallet();
      }
    });
  }

  Future<void> _refreshData() async {
    try {
      // Call all APIs in parallel for better performance
      await Future.wait([
        bookingController.fetchUserBookings(),
        loginController.checkUserExistsInAPI(),
        BlocProvider.of<HashCoinCubit>(context).getHashCoin(),
        _fetchUserDataIfNeeded(),
        _refreshWalletIfReady(),
      ]);
    } catch (e) {
      // Handle any errors during refresh
      print('Error refreshing data: $e');
    }
  }

  Future<void> _fetchUserDataIfNeeded() async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await userController.fetchUserData(currentUser.uid);

      // Add a small delay to ensure user data is properly set
      await Future.delayed(const Duration(milliseconds: 100));

      // Manually trigger wallet refresh after user data is loaded
      final walletController = Get.find<WalletController>();
      if (walletController.isWalletReady) {
        await walletController.refreshWallet();
      } else {
        // If wallet is not ready, try again after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (walletController.isWalletReady) {
          await walletController.refreshWallet();
        }
      }
    }
  }

  Future<void> _refreshWalletIfReady() async {
    final walletController = Get.find<WalletController>();
    if (walletController.isWalletReady) {
      await walletController.refreshWallet();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        backgroundColor: Colors.black,
        child: ListView(
          children: [
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _buildEventBanner(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CafeSection(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _buildShopSection(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _buildGamerNewsSection(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: GamesSection(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ViralShotsSection(),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _buildGameOnIndiaBanner(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(85),
      child: AppBar(
        backgroundColor: Colors.transparent,
        systemOverlayStyle:
            const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x1AFFFFFF),
                  Color(0x1A64BD55),
                ]),
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        leadingWidth: 65,
        leading: Obx(() => Padding(
              padding: const EdgeInsets.only(left: 10),
              child: _userAvatar(userController.user.value.photoUrl),
            )),
        title: Obx(
          () => Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hey, ${userController.user.value.gameUserName}!',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  'Viman Nagar, Pune',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB6B6B6),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
        actions: [
          Center(
              child: _buildPillContainer(
                  icon: "assets/icons/union.png", label: '4800')),
          const SizedBox(width: 8),
          Center(
            child: Stack(
              children: [
                _buildPillContainer(
                    icon: "assets/icons/coin.png", label: '₹200'),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Image.asset(
                    "assets/icons/vector.png",
                    height: 10,
                    width: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _userAvatar(String? photoUrl) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF6DFB60),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
            ? CachedNetworkImageProvider(photoUrl)
            : const NetworkImage(
                    'https://wallpapers.com/images/hd/placeholder-profile-icon-20tehfawxt5eihco.jpg')
                as ImageProvider,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildPillContainer({required String icon, required String label}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                icon,
                height: 18,
                width: 18,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventBanner() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              'assets/images/bannerBg.png',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Special Gaming Event',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Win prize upto 70,000*',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB6B6B6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 70),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border:
                        Border.all(color: const Color(0xFF75F94C), width: 2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    'Join Now',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            right: 62,
            child: SizedBox(
              height: 180,
              child: Image.asset(
                "assets/images/bannerHero.png",
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HASH QUEST',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.asset(
                  'assets/images/hashQuestBg.png',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hash Headphones',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'premium quality leather with foam \ncushion for maximum comfort.',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 50),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                            color: const Color(0xFF75F94C), width: 2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        'Pre-Register',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 20,
                right: 30,
                child: SizedBox(
                  height: 160,
                  child: Image.asset(
                    "assets/images/headphone.png",
                    height: 140,
                    width: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 30,
                right: 10,
                child: Transform.rotate(
                  angle: 170,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00DC00),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '₹2499',
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGamerNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GAMER FIREWIRE',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            height: 200,
            width: 400,
            child: Stack(
              children: List.generate(
                gameNewsCards.length,
                (index) {
                  final cards = gameNewsCards[index];
                  return Positioned(
                    top: ((cards.length - 1) - index) * 14 + 14,
                    left: ((cards.length - 1) - index) * 12 + 12,
                    right: ((cards.length - 1) - index) * 12 + 12,
                    child: _buildGameNewsCard(
                        image: cards['image']!, title: cards['title']!),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameNewsCard({required String image, required String title}) {
    return Container(
      height: 150,
      width: 400,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x1AFFFFFF),
              Color(0x1A64BD55),
            ]),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 150,
                width: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Positioned(
            top: 15,
            bottom: 15,
            left: 15,
            right: 15,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    image,
                    height: 120,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerAvatar() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade600,
      child: const CircleAvatar(radius: 15, backgroundColor: Colors.grey),
    );
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user_data');

      // Track unexpected logout event
      segmentService.onUnexpectedLogout(reason: 'user_initiated');

      Get.offAllNamed(AppRoutes.LOGIN);
    } catch (e) {
      // Track unexpected logout event with error
      segmentService.onUnexpectedLogout(reason: 'logout_error: $e');

      Get.offAllNamed(AppRoutes.LOGIN);
    }
  }

  void _handleMenuSelection(String value) {
    if (value == 'Profile') {
      // Handle profile tap
    } else if (value == 'Settings') {
      // Handle settings tap
    }
  }

  Widget _buildGameOnIndiaBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: const Color(0xFF00DC00), width: 2),
          borderRadius: BorderRadius.circular(50)),
      child: Text(
        'Game On, India!',
        textAlign: TextAlign.center,
        style: GoogleFonts.tulpenOne(
          fontSize: 35,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF75F94C),
        ),
      ),
    );
  }
}
