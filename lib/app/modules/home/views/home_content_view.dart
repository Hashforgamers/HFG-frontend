import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
import 'package:hash/utils/widgets/loader.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
      _ensureWalletFetched();
      _trackHomeScreenViewed();
      BlocProvider.of<FcmCubit>(context).registerFCMToken();
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF338125),
        child: const Icon(Icons.support_agent_outlined, color: Colors.white),
      ),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF338125),
        backgroundColor: Colors.black,
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            BlocBuilder<HashCoinCubit, HashCoinState>(
              builder: (_, state) => RewardsSection(
                hashCoin: (state is HashCoinLoaded) ? state.hashCoin : 0,
              ),
            ),
            const SizedBox(height: 18),
            RainbowLoadingBar(height: 0.5, width: Get.width),
            const SizedBox(height: 18),
            EventBanner(),
            const SizedBox(height: 18),
            CafeSection(),
            const SizedBox(height: 18),
            const GamerNewsSection(),
            const SizedBox(height: 18),
            ViralShotsSection(),
            const SizedBox(height: 18),
            ShopSection(),
            const SizedBox(height: 18),
            GamesSection(),
            _buildGameOnIndiaBanner(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() => Text(
                'Hey, ${userController.user.value.gameUserName}!',
                style: const TextStyle(color: Colors.white),
              )),
          Obx(() => PopupMenuButton<String>(
                offset: const Offset(0, 40),
                color: Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                onSelected: (value) => _handleMenuSelection(value),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'Profile',
                    child: Text('Profile',
                        style: TextStyle(color: Color(0xffDE3A3A))),
                  ),
                  const PopupMenuItem(
                    value: 'Settings',
                    child: Text('Settings',
                        style: TextStyle(color: Color(0xffDE3A3A))),
                  ),
                  PopupMenuItem(
                    value: 'Logout',
                    onTap: _logout,
                    child: const Text('Logout',
                        style: TextStyle(color: Color(0xffDE3A3A))),
                  ),
                ],
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: userController.isLoading.value
                      ? _shimmerAvatar()
                      : _userAvatar(userController.user.value.photoUrl),
                ),
              )),
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

  Widget _userAvatar(String? photoUrl) {
    return CircleAvatar(
      radius: 15,
      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
          ? CachedNetworkImageProvider(photoUrl)
          : const NetworkImage(
                  'https://wallpapers.com/images/hd/placeholder-profile-icon-20tehfawxt5eihco.jpg')
              as ImageProvider,
      backgroundColor: Colors.white,
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
    return Padding(
      padding: const EdgeInsets.only(top: 45.0),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF9933), Colors.white, Color(0xFF138808)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Game On, India!',
            style: GoogleFonts.tulpenOne(
              fontSize: 100,
              fontWeight: FontWeight.normal,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
