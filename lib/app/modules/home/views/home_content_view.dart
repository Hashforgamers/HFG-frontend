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
import 'package:hash/app/modules/rewards/reward_section_view.dart';
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
              child: EventBanner(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CafeSection(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ShopSection(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: GamerNewsSection(),
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
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x1AFFFFFF), Color(0x1A64BD55)],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        leadingWidth: 65,
        leading: Obx(
          () => Padding(
            padding: const EdgeInsets.only(left: 10),
            child: _userAvatar(userController.user.value.photoUrl),
          ),
        ),
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
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: BlocBuilder<HashCoinCubit, HashCoinState>(
              builder: (_, state) => RewardsSection(
                hashCoin: (state is HashCoinLoaded) ? state.hashCoin : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userAvatar(String? photoUrl) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF6DFB60), width: 2),
        borderRadius: BorderRadius.circular(28),
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
            ? CachedNetworkImageProvider(photoUrl)
            : const NetworkImage(
                    'https://wallpapers.com/images/hd/placeholder-profile-icon-20tehfawxt5eihco.jpg',
                  )
                  as ImageProvider,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildGameOnIndiaBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: const Color(0xFF00DC00), width: 2),
        borderRadius: BorderRadius.circular(50),
      ),
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
}
