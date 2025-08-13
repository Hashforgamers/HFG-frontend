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
import 'package:hash/app/modules/game_pass/view/game_pass_view.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/app/modules/login/controllers/login_controller.dart';
import 'package:hash/app/modules/news/news_section_view.dart';
import 'package:hash/app/modules/refferal/views/referral_view_with_controller.dart';
import 'package:hash/app/modules/rewards/reward_section_view.dart';
import 'package:hash/app/modules/shop/views/shop_section_view.dart';
import 'package:hash/app/modules/shorts/views/viral_shots_view.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hash/app/modules/wallet/controllers/wallet_controller.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/app/modules/home/widgets/refer_friend_modal.dart';

class HomeContentView extends StatefulWidget {
  const HomeContentView({super.key});

  @override
  State<HomeContentView> createState() => _HomeContentViewState();
}

class _HomeContentViewState extends State<HomeContentView>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  // Controllers
  late final BookingController bookingController;
  late final LoginController loginController;
  late final UserController userController;
  late final SegmentSdkService segmentService;
  
  // Animation controllers
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  
  // Scroll controller for optimization
  late final ScrollController _scrollController;
  
  // State variables
  bool _isInitialized = false;
  bool _isRefreshing = false;
  bool _showReferModal = false;
  
  // Cached widgets for better performance
  Widget? _cachedAppBar;
  Widget? _cachedGamePassContainer;
  Widget? _cachedGameOnIndiaBanner;
  
  // Visibility tracking for lazy loading
  final Map<String, bool> _sectionVisibility = {};
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _initializeScrollController();
    _initializeData();
  }

  void _initializeControllers() {
    bookingController = Get.find<BookingController>();
    loginController = Get.find<LoginController>();
    userController = Get.find<UserController>();
    segmentService = locator<SegmentSdkService>();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _initializeScrollController() {
    _scrollController = ScrollController()
      ..addListener(_onScrollChanged);
  }

  void _initializeData() {
    // Register FCM token immediately
    BlocProvider.of<FcmCubit>(context).registerFCMToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
      _trackHomeScreenViewed();
      _startAnimations();
    });
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
  }

  void _onScrollChanged() {
    // Implement intersection observer logic for lazy loading
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final maxScroll = position.maxScrollExtent;
      final currentScroll = position.pixels;
      
      // Trigger lazy loading when user scrolls to certain sections
      if (currentScroll > maxScroll * 0.7 && !_sectionVisibility['shorts']!) {
        _sectionVisibility['shorts'] = true;
        setState(() {});
      }
    }
  }

  void _trackHomeScreenViewed() {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      segmentService.onHomeScreenViewed(userId: currentUser.uid);
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    
    try {
      // Optimized parallel API calls with proper error handling
      await Future.wait([
        _fetchUserDataIfNeeded(),
        _refreshWalletIfReady(),
        bookingController.fetchUserBookings(),
        loginController.checkUserExistsInAPI(),
        BlocProvider.of<HashCoinCubit>(context).getHashCoin(),
      ], eagerError: false).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Data refresh timeout');
          return [];
        },
      );
      
      setState(() => _isInitialized = true);
    } catch (e) {
      print('Error refreshing data: $e');
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _fetchUserDataIfNeeded() async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await userController.fetchUserData(currentUser.uid);
      await _refreshWalletIfReady();
    }
  }

  Future<void> _refreshWalletIfReady() async {
    final walletController = Get.find<WalletController>();
    if (walletController.isWalletReady) {
      await walletController.refreshWallet();
    }
  }

  void _showReferFriendModal() {
    if (_showReferModal) return;
    
    setState(() => _showReferModal = true);
    
    showReferFriendModal(
      context,
      onReferNow: () {
        Get.to(() => const ReferralViewWithController());
        setState(() => _showReferModal = false);
      },
      onNoThanks: () {
        Navigator.pop(context);
        setState(() => _showReferModal = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        backgroundColor: Colors.black,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildOptimizedAppBar(),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeController,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(_slideController),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildLazyLoadedSection('event', const EventBanner()),
                        const SizedBox(height: 24),
                        _buildLazyLoadedSection('cafe', CafeSection()),
                        const SizedBox(height: 24),
                        _buildLazyLoadedSection('gamePass', _buildGamePassContainer()),
                        const SizedBox(height: 24),
                        _buildLazyLoadedSection('shop', const ShopSection()),
                        const SizedBox(height: 24),
                        _buildLazyLoadedSection('news', const GamerNewsSection()),
                        const SizedBox(height: 24),
                        _buildLazyLoadedSection('games', const GamesSection()),
                        const SizedBox(height: 24),
                        _buildLazyLoadedSection('shorts', ViralShotsSection()),
                        const SizedBox(height: 32),
                        _buildLazyLoadedSection('gameOnIndia', _buildGameOnIndiaBanner()),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLazyLoadedSection(String sectionKey, Widget child) {
    // Initialize visibility map if not exists
    _sectionVisibility[sectionKey] ??= true;
    
    if (!_sectionVisibility[sectionKey]!) {
      return const SizedBox.shrink();
    }
    
    return RepaintBoundary(
      child: child,
    );
  }

  Widget _buildOptimizedAppBar() {
    if (_cachedAppBar != null) return _cachedAppBar!;
    
    _cachedAppBar = SliverAppBar(
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
            ),
          ),
        ),
      ),
      leadingWidth: 55,
      leading: Obx(
        () => Padding(
          padding: const EdgeInsets.only(left: 10),
          child: userController.isLoading.value
              ? _buildShimmerAvatar()
              : _buildOptimizedUserAvatar(userController.user.value.photoUrl),
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
    
    return _cachedAppBar!;
  }

  Widget _buildOptimizedUserAvatar(String? photoUrl) {
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
            ? CachedNetworkImageProvider(
                photoUrl,
                errorListener: (error) => print('Avatar image error: $error'),
              )
            : const NetworkImage(
                    'https://wallpapers.com/images/hd/placeholder-profile-icon-20tehfawxt5eihco.jpg',
                  )
                  as ImageProvider,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildGamePassContainer() {
    if (_cachedGamePassContainer != null) return _cachedGamePassContainer!;
    
    _cachedGamePassContainer = GestureDetector(
      onTap: () => Get.to(() => GamePassViewPage()),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF6DFB60), width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl:
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075177/gamepassbg_jkkq7b.png',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                // cacheWidth: 400, // Optimize memory usage
                placeholder: (_, _) =>
                    const Center(child: RainbowGlowingLoader(size: 40)),
                errorWidget: (_, _, _) => Container(
                  color: Colors.grey,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
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
    
    return _cachedGamePassContainer!;
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
            ),
          ),
        ),
      ),

      leadingWidth: 55,
      leading: Obx(
        () => Padding(
          padding: const EdgeInsets.only(left: 10),
          child: userController.isLoading.value
                ? _buildShimmerAvatar()
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
    if (_cachedGameOnIndiaBanner != null) return _cachedGameOnIndiaBanner!;
    
    _cachedGameOnIndiaBanner = GestureDetector(
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
    
    return _cachedGameOnIndiaBanner!;
  }

  Widget _buildShimmerAvatar() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade600,
      child: const CircleAvatar(radius: 15, backgroundColor: Colors.grey),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
