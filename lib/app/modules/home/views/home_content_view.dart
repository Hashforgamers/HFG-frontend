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
import 'package:hash/app/modules/fcm/cubit/fcm_cubit.dart';
import 'package:hash/app/modules/game/views/game_section_view.dart';
import 'package:hash/app/modules/game_pass/view/game_pass_view.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/app/modules/login/controllers/login_controller.dart';
import 'package:hash/app/modules/news/news_section_view.dart';
import 'package:hash/app/modules/refferal/views/referral_view_with_controller.dart';
import 'package:hash/app/modules/rewards/reward_section_view.dart';
import 'package:hash/app/modules/shorts/views/viral_shots_view.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hash/app/modules/wallet/controllers/wallet_controller.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/app/modules/home/widgets/refer_friend_modal.dart';

import '../../../../features/mini_games/fruit_ninja/fruit_ninja_screen.dart';
import '../../../../features/mini_games/mini_game_section.dart';
import '../../../../utils/widgets/bounce_tap_widget.dart';
import '../../arena/views/payment_success.dart';
import '../../support/support_screen.dart';

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
  static const double _sectionGap = 24.0;

  final remoteRepo = locator<RemoteRepoInterface>();

  List<Widget> _intersperse(List<Widget> items, Widget separator) {
    if (items.isEmpty) return const [];
    return List.generate(
      items.length * 2 - 1,
      (i) => i.isEven ? items[i ~/ 2] : separator,
    );
  }

  // State variables
  bool isInitialized = false;
  bool _isRefreshing = false;
  bool showReferModal = false;

  // Cached widgets for better performance
  Widget? _cachedAppBar;
  Widget? _cachedGamePassContainer;
  Widget? _cachedGameOnIndiaBanner;

  // Visibility tracking for lazy loading
  final Map<String, bool> _sectionVisibility = {};
final prefs = locator<SharedPreferences>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _initializeScrollController();
    _initializeData();

    // 🔹Check if Welcome Aboard popup was already shown
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool shown = prefs.getBool('welcome_shown') ?? false;

      if (!shown) {
        _showWelcomePopup(context); // your function
        await prefs.setBool('welcome_shown', true);
      }
    });
  }

  @override
  void dispose() {
    // remove listeners before disposing controller
    _scrollController.removeListener(_onScrollChanged);
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    _initAuthToken();
    super.dispose();
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

  void _initAuthToken() async {
    final uid = await remoteRepo.getUIDFromPreferences();
    if (uid.isNotEmpty) {
      await remoteRepo.checkUserExistsInAPI(uid);
    }
  }

  void _initializeScrollController() {
    _scrollController = ScrollController()..addListener(_onScrollChanged);
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
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    final wasSeen = _sectionVisibility['shorts'] ?? false;
    if (currentScroll > maxScroll * 0.7 && !wasSeen) {
      _sectionVisibility['shorts'] = true;
      if (!mounted) return;
      setState(() {}); // guarded
    }
  }

  void _trackHomeScreenViewed() {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      segmentService.onHomeScreenViewed(userId: currentUser.uid);
    }
  }

  void _showWelcomePopup(BuildContext context) {
    showDialog(
      useSafeArea: false,
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: SweepGradient(
                center: Alignment.center,
                startAngle: 0.0,
                endAngle: 6.28319, // 2 * pi
                colors: [
                  Color(0xFF1541A3), // 22%
                  Color(0xFF070C29), // 28%
                  Color(0xFF040309), // 66%
                  Color(0xFF060A22), // 73%
                  Color(0xFF8320C3), // 97%
                  Color(0xFF1541A3), // repeat start to close loop
                ],
                stops: [
                  0.22,
                  0.28,
                  0.66,
                  0.73,
                  0.97,
                  1.0,
                ],
                transform: GradientRotation(-1), // -90° in radians (π/2)
              ),
            ),
            child: Stack(
              children: [
                ///Added individual icons
                // Example:
                Positioned(
                  top: 50,
                  left: 20,
                  child: Transform.rotate(
                    angle: 0.4,
                    child: Image.asset("assets/welcome_aboard_images/dollar.png", width: 62),
                  ),
                ),
                Positioned(
                  top: 5,
                  right: -70,
                  child: Transform(
                    transform: Matrix4.identity()..scale(-1.0, 1.0),
                    child: Image.asset("assets/welcome_aboard_images/dollar.png", width: 82, fit: BoxFit.fill,),
                  ),
                ),
                Positioned(
                  top: 280,
                  right: -30,
                  child: Transform.rotate(
                    angle: 0.4,
                    child: Image.asset("assets/welcome_aboard_images/dollar.png", width: 72, fit: BoxFit.fill,),
                  ),
                ),
                Positioned(
                  bottom: 120,
                  right: -80,
                  child: Transform(
                    transform: Matrix4.identity()..scale(-1.0, 1.0),
                    child: Image.asset("assets/welcome_aboard_images/dollar.png", width: 62, fit: BoxFit.fill,),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  right: 150,
                  child: Transform.rotate(
                    angle: 0.4,
                    child: Image.asset("assets/welcome_aboard_images/dollar.png", width: 62, fit: BoxFit.fill,),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 20,
                  child: Image.asset("assets/welcome_aboard_images/dollar.png", width: 52, fit: BoxFit.fill,),
                ),
                Positioned(
                  bottom: 170,
                  left: -20,
                  child: Transform.rotate(
                    angle: 0.4,
                    child: Image.asset("assets/welcome_aboard_images/dollar.png", width: 62, fit: BoxFit.fill,),
                  ),
                ),

                Positioned(
                  top: -20,
                  left: 180,
                  child: Transform(
                    transform: Matrix4.identity()..scale(-1.0, 1.0)..rotateZ(-0.3),
                    child: Image.asset("assets/welcome_aboard_images/lightning_bolt.png", height: 82, fit: BoxFit.cover,),
                  ),
                ),
                Positioned(
                  top: 110,
                  right: -30,
                  child: Transform.rotate(
                    angle: 0.3,
                    child: Image.asset("assets/welcome_aboard_images/lightning_bolt.png", height: 85, fit: BoxFit.cover,),
                  ),
                ),
                Positioned(
                  bottom: 250,
                  right: -100,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..scale(-1.0, 1.0)
                      ..rotateZ(0.4),
                    child: Image.asset("assets/welcome_aboard_images/lightning_bolt.png", height: 82, fit: BoxFit.cover,),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  right: -75,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..scale(-1.0, 1.0)
                      ..rotateZ(0.4),
                    child: Image.asset("assets/welcome_aboard_images/lightning_bolt.png", height: 82, fit: BoxFit.cover,),
                  ),
                ),
                Positioned(
                  bottom: 115,
                  left: 55,
                  child: Image.asset("assets/welcome_aboard_images/lightning_bolt.png", height: 52, fit: BoxFit.cover,),
                ),
                Positioned(
                  top: 220,
                  left: 5,
                  child: Image.asset("assets/welcome_aboard_images/lightning_bolt.png", height: 52, fit: BoxFit.cover,),
                ),

                // Main content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Welcome Aboard!",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Gift box image
                      Image.asset(
                        "assets/welcome_aboard_images/gift_box.png",
                        height: 160,
                        fit: BoxFit.fill,
                      ),

                      const SizedBox(height: 25),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "You’ve unlocked ",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                                Text(" ₹30 bonus crate! 🎁", style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),),
                              ],
                            ),
                            Text("Use it to book your favourite café today!", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      GestureDetector(
                        onTap: ()async{
                          Navigator.of(context).pop();
                          await Get.find<WalletController>().claimDropCrate();                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Stack(
                            children: [
                              // Frosted background blur
                              BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  width: 280,
                                  height: 50,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      width: 1.5,
                                      style: BorderStyle.solid,
                                      color: Colors.white.withOpacity(0.3), // base glass stroke
                                    ),
                                  ),
                                  child: ShaderMask(
                                    shaderCallback: (Rect bounds) {
                                      return LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withOpacity(0.8), // reflection
                                          Colors.transparent,            // fades away
                                          Colors.white.withOpacity(0.4),
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ).createShader(bounds);
                                    },
                                    blendMode: BlendMode.srcATop,
                                    child: const Text(
                                      "Claim in Drop Crate",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
      },
    );
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    if (!mounted) return;
    setState(() => _isRefreshing = true);

    try {
      // Optimized parallel API calls with proper error handling
      await Future.wait([
        _fetchUserDataIfNeeded(),
        _refreshWalletIfReady(),
        bookingController.fetchUserBookings(),
        BlocProvider.of<HashCoinCubit>(context).getHashCoin(),
      ], eagerError: false).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return [];
        },
      );
      if (!mounted) return;

      setState(() => isInitialized = true);
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    } finally {
      if (!mounted) return;
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

  Widget _buildReferFriendModal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REFER TO A FRIEND',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ReferFriendModal(
          isDialog: false,
          onReferNow: () {
            segmentService.onReferralViewed(
              email:
                  userController
                      .user
                      .value
                      .contact
                      ?.electronicAddress
                      ?.emailId ??
                  '',
            );
            Get.to(
              () => ReferralViewWithController(
                email:
                    userController
                        .user
                        .value
                        .contact
                        ?.electronicAddress
                        ?.emailId ??
                    '',
              ),
            );
          },
        ),
      ],
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
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: _sectionGap), // top padding
                        ..._intersperse([

                          // 🔷 1. Game Pass – Monetization + Core use
                          _buildLazyLoadedSection('gamePass', _buildGamePassContainer()),

                          // 🔷 2. Café Section – Main booking action
                          _buildLazyLoadedSection('cafe', CafeSection()),

                          // 🔷 3. Contact Support – High trust & user concern item
                          ContactSupport(),

                          // 🔷 4. Mini Games – Retention boost (engaging short content)
                          // _buildLazyLoadedSection('miniGames', const MiniGamesSection()),

                          // 🔷 5. Refer & Earn – Growth lever
                          _buildLazyLoadedSection('referral', _buildReferFriendModal()),

                          // 🔷 6. Viral Shorts – Fun scroll content, lower intent
                          _buildLazyLoadedSection('shorts', ViralShotsSection()),

                          // 🔷 7. Gamer News – Passive consumption
                          _buildLazyLoadedSection('news', const GamerNewsSection()),

                          // 🔷 8. Games List – Browse-only for now (assuming no play feature)
                          _buildLazyLoadedSection('games', const GamesSection()),

                          // 🔷 9. GameOn India Banner – Occasional promo
                          _buildLazyLoadedSection('gameOnIndia', _buildGameOnIndiaBanner()),

                        ], const SizedBox(height: _sectionGap)),
                        const SizedBox(height: _sectionGap), // bottom padding
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

    return RepaintBoundary(child: child);
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
      expandedHeight: 60,
      flexibleSpace: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
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
      centerTitle: false,
      leading: Obx(
        () => Padding(
          padding: const EdgeInsets.only(left: 10,top: 5),
          child: userController.isLoading.value
              ? _buildShimmerAvatar()
              : _buildOptimizedUserAvatar(userController.user.value.photoUrl),
        ),
      ),
      title: Obx(
        () => Padding(
          padding: const EdgeInsets.only(top: 15.0),
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
                '${userController.user.value.contact?.physicalAddress?.addressLine1}',
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

    _cachedGamePassContainer = BounceTap(
      // onTap: () => Get.to(() => PaymentSuccessScreen(
      //   dateText: "2/8/25",
      //   timeText: "11:45 pm",
      //   totalText: "₹500",
      //   email: "test00@gmail.com",
      //   onViewInvoice: () {
      //     // Navigate to invoice screen or open a link
      //   },
      // ),),
      // onTap: () => Get.to(() => FruitCuttingScreen()),
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

  // Widget _buildAppBar() {
  //   return SliverAppBar(
  //     backgroundColor: Colors.transparent,
  //     systemOverlayStyle: const SystemUiOverlayStyle(
  //       statusBarColor: Colors.transparent,
  //     ),
  //     elevation: 0,
  //     pinned: false,
  //     expandedHeight: 70,
  //     flexibleSpace: ClipRRect(
  //       borderRadius: BorderRadius.circular(25),
  //       child: BackdropFilter(
  //         filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
  //         child: Container(
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               begin: Alignment.topCenter,
  //               end: Alignment.bottomCenter,
  //               colors: [
  //                 const Color(0xFFFFFFFF).withOpacity(0.1),
  //                 const Color(0xFF64BD55).withOpacity(0.2),
  //               ],
  //             ),
  //             borderRadius: BorderRadius.circular(25),
  //           ),
  //         ),
  //       ),
  //     ),
  //
  //     leadingWidth: 55,
  //     leading: Obx(
  //       () => Padding(
  //         padding: const EdgeInsets.only(left: 10),
  //         child: userController.isLoading.value
  //               ? _buildShimmerAvatar()
  //             : _userAvatar(userController.user.value.photoUrl),
  //       ),
  //     ),
  //     title: Obx(
  //       () => Padding(
  //         padding: const EdgeInsets.only(top: 12.0),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Text(
  //               'Hey, ${userController.user.value.gameUserName}!',
  //               style: GoogleFonts.inter(
  //                 color: Colors.white,
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //               overflow: TextOverflow.ellipsis,
  //               maxLines: 1,
  //             ),
  //             const SizedBox(height: 2),
  //             Text(
  //               'Viman Nagar, Pune',
  //               style: GoogleFonts.inter(
  //                 color: const Color(0xFFB6B6B6),
  //                 fontSize: 11.5,
  //               ),
  //               overflow: TextOverflow.ellipsis,
  //               maxLines: 1,
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //
  //     actions: [
  //       Padding(
  //         padding: const EdgeInsets.only(right: 10),
  //         child: BlocBuilder<HashCoinCubit, HashCoinState>(
  //           builder: (_, state) => RewardsSection(
  //             hashCoin: (state is HashCoinLoaded) ? state.hashCoin : 0,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Widget _userAvatar(String? photoUrl) {
  //   const double size = 40;
  //
  //   return Container(
  //     width: size,
  //     height: size,
  //     decoration: BoxDecoration(
  //       shape: BoxShape.circle,
  //       border: Border.all(color: const Color(0xFF6DFB60), width: 2),
  //     ),
  //     child: CircleAvatar(
  //       radius: size / 2,
  //       backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
  //           ? CachedNetworkImageProvider(photoUrl)
  //           : const NetworkImage(
  //                   'https://wallpapers.com/images/hd/placeholder-profile-icon-20tehfawxt5eihco.jpg',
  //                 )
  //                 as ImageProvider,
  //       backgroundColor: Colors.white,
  //     ),
  //   );
  // }

  // Widget _buildGameOnIndiaBanner() {
  //   if (_cachedGameOnIndiaBanner != null) return _cachedGameOnIndiaBanner!;
  //   _cachedGameOnIndiaBanner = GestureDetector(
  //     onTap: () {},
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(vertical: 4),
  //       height: 50,
  //       width: double.infinity,
  //       decoration: BoxDecoration(
  //         color: Colors.transparent,
  //         border: Border.all(color: const Color(0xFF00DC00), width: 1.5),
  //         borderRadius: BorderRadius.circular(50),
  //       ),
  //       child: Center(
  //         child: Text(
  //           'Game On, India!',
  //           style: GoogleFonts.inter(
  //             fontSize: 16,
  //             color: const Color(0xFF75F94C),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //   return _cachedGameOnIndiaBanner!;
  // }
  Widget _buildGameOnIndiaBanner() {
    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
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

  Widget _buildShimmerAvatar() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade600,
      child: const CircleAvatar(radius: 13, backgroundColor: Colors.grey),
    );
  }
}
