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
import 'package:hash/app/modules/game_pass/cubit/game_pass_cubit.dart';
import 'package:hash/core/repositories/model/get_pass_model.dart';
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
            /// Here add the UI of Game Pass
            BlocBuilder<GamePassCubit, GamePassState>(
              builder: (context, state) {
                if (state is GamePassLoading) {
                  return _buildGamePassShimmer();
                } else if (state is GamePassLoaded && state.gamePass.isNotEmpty) {
                  return _buildGamePassCarousel(state.gamePass);
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
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
                style: GoogleFonts.inter(color: Colors.white),
              )),
          Obx(() => PopupMenuButton<String>(
                offset: const Offset(0, 40),
                color: Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                onSelected: (value) => _handleMenuSelection(value),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'Profile',
                    child: Text(
                      'Profile',
                      style: GoogleFonts.inter(color: const Color(0xffDE3A3A)),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Settings',
                    child: Text('Settings',
                        style:
                            GoogleFonts.inter(color: const Color(0xffDE3A3A))),
                  ),
                  PopupMenuItem(
                    value: 'Logout',
                    onTap: _logout,
                    child: Text('Logout',
                        style:
                            GoogleFonts.inter(color: const Color(0xffDE3A3A))),
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

  Widget _buildGamePassShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade800,
            highlightColor: Colors.grey.shade600,
            child: Container(
              height: 20,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade800,
                highlightColor: Colors.grey.shade600,
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGamePassCarousel(List<GetPassModel> gamePasses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Game Passes',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: gamePasses.length,
            itemBuilder: (context, index) {
              final gamePass = gamePasses[index];
              return _buildGamePassCard(gamePass);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGamePassCard(GetPassModel gamePass) {
    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E1E),
            const Color(0xFF2D2D2D),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDE3A3A).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDE3A3A).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    gamePass.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDE3A3A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    gamePass.passType,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              gamePass.description,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[400],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${gamePass.price.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDE3A3A),
                      ),
                    ),
                    Text(
                      '${gamePass.daysValid} days',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFDE3A3A),
                        const Color(0xFFB91C1C),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Buy Now',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
