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
import 'package:hash/app/modules/game_pass/cubit/game_pass_cubit.dart';
import 'package:hash/app/modules/game_pass/view/game_pass_view.dart';
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
    BlocProvider.of<GamePassCubit>(context).getGamePass();
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        backgroundColor: Colors.black,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const EventBanner(),
                    const SizedBox(height: 24),
                    CafeSection(),
                    const SizedBox(height: 24),
                    _buildGamePassContainer(),
                    const SizedBox(height: 24),
                    const ShopSection(),
                    const SizedBox(height: 24),
                    const GamerNewsSection(),
                    const SizedBox(height: 24),
                    const GamesSection(),
                    const SizedBox(height: 24),
                    ViralShotsSection(),
                    const SizedBox(height: 32),
                    _buildGameOnIndiaBanner(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamePassContainer() {
    return GestureDetector(
      onTap: () => Get.to(GamePassView()),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFF6DFB60), width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/gamepassbg.png',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              left: 20,
              top: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pay with Hash Pass',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get the digital membership card now.\nUse at any participating gaming cafe.',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 10),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF75F94C),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      'Know More',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
      elevation: 0,
      pinned: false,
      expandedHeight: 70,
      flexibleSpace: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFFFFFF).withOpacity(0.1),
                  const Color(0xFF64BD55).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              // border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
          ),
        ),
      ),

      leadingWidth: 55,
      leading: Obx(
        () => Padding(
          padding: const EdgeInsets.only(left: 10),
          child: userController.isLoading.value
              ? _shimmerAvatar()
              : _userAvatar(userController.user.value.photoUrl),
        ),
      ),
      title: Obx(
        () => Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hey, ${userController.user.value.gameUserName}!',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                'Viman Nagar, Pune',
                style: GoogleFonts.inter(
                  color: const Color(0xFFB6B6B6),
                  fontSize: 11.5,
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
    );
  }

  Widget _userAvatar(String? photoUrl) {
    const double size = 40;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF6DFB60), width: 2),
      ),
      child: CircleAvatar(
        radius: size / 2,
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
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: const Color(0xFF00DC00), width: 1.5),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: Text(
            'Game On, India!',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF75F94C),
            ),
          ),
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
