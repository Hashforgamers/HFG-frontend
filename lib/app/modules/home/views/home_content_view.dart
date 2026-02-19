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
import 'package:hash/app/modules/home/widgets/home_game_on_india_banner.dart';
import 'package:hash/app/modules/home/widgets/home_game_pass_card.dart';
import 'package:hash/app/modules/home/widgets/optimized_app_bar.dart';
import 'package:hash/app/modules/home/widgets/welcome_aboard_dialog.dart';
import 'package:hash/app/modules/login/controllers/login_controller.dart';
import 'package:hash/app/modules/news/news_section_view.dart';
import 'package:hash/app/modules/profile/user_profile_view.dart';
import 'package:hash/app/modules/refferal/views/referral_view_with_controller.dart';
import 'package:hash/app/modules/rewards/reward_section_view.dart';
import 'package:hash/app/modules/shorts/views/viral_shots_view.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hash/features/mini_games/mini_game_section.dart';
import 'package:hash/app/modules/wallet/controllers/wallet_controller.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/app/modules/home/widgets/refer_friend_modal.dart';
import 'package:hash/app/data/models/user_model.dart';
import 'package:hash/core/utils/haptics.dart';

import '../../support/support_screen.dart';
import 'package:hash/core/utils/app_logger.dart';

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
  late final WalletController walletController;
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
  bool _fcmRegistered = false;
  bool _welcomeClaimGateHandled = false;

  // Cached widgets for better performance
  Widget? _cachedAppBar;
  Widget? _cachedGamePassContainer;
  Widget? _cachedGameOnIndiaBanner;
  late final Widget _cachedCafeSection;
  late final Widget _cachedSupportSection;
  late final Widget _cachedMiniGamesSection;
  late final Widget _cachedShortsSection;
  late final Widget _cachedNewsSection;
  late final Widget _cachedGamesSection;

  // Visibility tracking for lazy loading
  final Map<String, bool> _sectionVisibility = {};
  final prefs = locator<SharedPreferences>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeSections();
    _initializeAnimations();
    _initializeScrollController();
    _initializeData();
  }

  @override
  void dispose() {
    // remove listeners before disposing controller
    _scrollController.removeListener(_onScrollChanged);
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    bookingController = Get.find<BookingController>();
    loginController = Get.find<LoginController>();
    userController = Get.find<UserController>();
    walletController = Get.find<WalletController>();
    segmentService = locator<SegmentSdkService>();
  }

  void _initializeSections() {
    // Reuse long-lived section widgets to avoid rebuilding heavy trees.
    _cachedCafeSection = CafeSection();
    _cachedSupportSection = const ContactSupport();
    _cachedMiniGamesSection = const MiniGamesSection();
    _cachedShortsSection = ViralShotsSection();
    _cachedNewsSection = const GamerNewsSection();
    _cachedGamesSection = const GamesSection();
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
    _scrollController = ScrollController()..addListener(_onScrollChanged);
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
        return WelcomeAboardDialog(
          onClaim: () async {
            await Haptics.success();
            final claimed = await Get.find<WalletController>().claimDropCrate();
            if (!claimed) return;

            final backendUserId = userController.userId.trim();
            final firebaseUid =
                firebase_auth.FirebaseAuth.instance.currentUser?.uid ?? '';
            final userKey = backendUserId.isNotEmpty ? backendUserId : firebaseUid;
            if (userKey.isNotEmpty) {
              await prefs.setBool('drop_crate_claimed_$userKey', true);
            }
            await prefs.setBool('new_user_bonus_pending', false);
          },
        );
      },
    );
  }

  Future<void> _maybeShowWelcomePopupForNewUser() async {
    if (_welcomeClaimGateHandled || !mounted) return;
    _welcomeClaimGateHandled = true;

    final pending = prefs.getBool('new_user_bonus_pending') ?? false;
    if (!pending) return;

    final backendUserId = userController.userId.trim();
    final firebaseUid = firebase_auth.FirebaseAuth.instance.currentUser?.uid ?? '';
    final userKey = backendUserId.isNotEmpty ? backendUserId : firebaseUid;
    if (userKey.isEmpty) return;

    final claimedKey = 'drop_crate_claimed_$userKey';
    final alreadyClaimed = prefs.getBool(claimedKey) ?? false;
    if (alreadyClaimed) {
      await prefs.setBool('new_user_bonus_pending', false);
      return;
    }

    if (!mounted) return;
    _showWelcomePopup(context);
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    if (!mounted) return;
    setState(() => _isRefreshing = true);
    final fcmCubit = BlocProvider.of<FcmCubit>(context);
    final hashCoinCubit = BlocProvider.of<HashCoinCubit>(context);

    try {
      final hasUser = await _fetchUserDataIfNeeded();
      if (hasUser) {
        await _maybeShowWelcomePopupForNewUser();
        final tasks = <Future<void>>[
          _refreshWalletIfReady(),
          bookingController.fetchUserBookings(),
          hashCoinCubit.getHashCoin(),
        ];
        if (!_fcmRegistered) {
          tasks.add(
            fcmCubit.registerFCMToken().then((_) {
              _fcmRegistered = true;
            }),
          );
        }
        await Future.wait(tasks);
      }
      if (!mounted) return;

      if (!isInitialized) {
        setState(() => isInitialized = true);
      }
    } catch (e) {
      AppLogger.e('Error refreshing data: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<bool> _fetchUserDataIfNeeded() async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    // Refresh backend session + JWT before any authed calls.
    final apiUser = await remoteRepo.checkUserExistsInAPI(currentUser.uid);

    if (apiUser != null && mounted) {
      // push into controller without a second network call
      userController.setUserData(User.fromJson(apiUser));
      final backendId = apiUser['id'] ?? apiUser['user_id'] ?? currentUser.uid;
      userController.id.value = backendId.toString();
    } else {
      // fall back to existing fetch (no-auth) for safety
      await userController.fetchUserData(currentUser.uid);
    }
    return true;
  }

  Future<void> _refreshWalletIfReady() async {
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
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Get.to(HashStoreHomePage());
      //   },
      //   child: Icon(Icons.shopping_cart),
      // ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        backgroundColor: Colors.black,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            const OptimizedAppBar(),
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
                          _buildLazyLoadedSection(
                            'gamePass',
                            _buildGamePassContainer(),
                          ),

                          // 🔷 2. Café Section – Main booking action
                          _buildLazyLoadedSection('cafe', _cachedCafeSection),

                          // 🔷 3. Contact Support – High trust & user concern item
                          _cachedSupportSection,

                          // 🔷 4. Mini Games – Retention boost (engaging short content)
                          _buildLazyLoadedSection(
                            'miniGames',
                            _cachedMiniGamesSection,
                          ),

                          // 🔷 5. Refer & Earn – Growth lever
                          _buildLazyLoadedSection(
                            'referral',
                            _buildReferFriendModal(),
                          ),

                          // 🔷 6. Viral Shorts – Fun scroll content, lower intent
                          _buildLazyLoadedSection(
                            'shorts',
                            _cachedShortsSection,
                          ),

                          // 🔷 7. Gamer News – Passive consumption
                          _buildLazyLoadedSection('news', _cachedNewsSection),

                          // 🔷 8. Games List – Browse-only for now (assuming no play feature)
                          _buildLazyLoadedSection('games', _cachedGamesSection),

                          // 🔷 9. GameOn India Banner – Occasional promo
                          _buildLazyLoadedSection(
                            'gameOnIndia',
                            _buildGameOnIndiaBanner(),
                          ),
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
                  const Color(0xff00DC00).withOpacity(0.2),
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
          padding: const EdgeInsets.only(left: 10, top: 5),
          child: userController.isLoading.value
              ? _buildShimmerAvatar()
              : GestureDetector(
                  onTap: () {
                    Get.to(UserProfileView());
                  },
                  child: _buildOptimizedUserAvatar(
                    userController.user.value.photoUrl,
                  ),
                ),
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
        border: Border.all(color: const Color(0xff00DC00), width: 2),
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
            ? CachedNetworkImageProvider(
                photoUrl,
                errorListener: (error) =>
                    AppLogger.d('Avatar image error: $error'),
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

    _cachedGamePassContainer = HomeGamePassCard(
      onTap: () => Get.to(() => GamePassViewPage()),
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
  //                 const Color(0xff00DC00).withOpacity(0.2),
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
  //       border: Border.all(color: const Color(0xff00DC00), width: 2),
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
  //         border: Border.all(color: const Color(0xff00DC00), width: 1.5),
  //         borderRadius: BorderRadius.circular(50),
  //       ),
  //       child: Center(
  //         child: Text(
  //           'Game On, India!',
  //           style: GoogleFonts.inter(
  //             fontSize: 16,
  //             color: const Color(0xff00DC00),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //   return _cachedGameOnIndiaBanner!;
  // }
  Widget _buildGameOnIndiaBanner() {
    if (_cachedGameOnIndiaBanner != null) return _cachedGameOnIndiaBanner!;

    _cachedGameOnIndiaBanner = const HomeGameOnIndiaBanner();

    return _cachedGameOnIndiaBanner!;
  }

  Widget _buildShimmerAvatar() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade600,
      child: const CircleAvatar(radius: 13, backgroundColor: Colors.grey),
    );
  }
}
