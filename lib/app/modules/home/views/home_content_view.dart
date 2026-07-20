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
import 'package:hash/app/modules/rewards/widgets/squad_missions_card.dart';
import 'package:hash/app/routes/app_routes.dart';
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
import 'package:hash/app/routes/app_routes.dart';
import 'package:hash/app/data/models/user_model.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/utils/encrypt_util.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';
import 'package:hash/utils/widgets/hash_wordmark.dart';

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
  static const double _horizontalSectionPadding = 8.0;

  final remoteRepo = locator<RemoteRepoInterface>();

  List<Widget> _intersperse(List<Widget> items, Widget separator) {
    if (items.isEmpty) return const [];
    return List.generate(
      items.length * 2 - 1,
      (i) => i.isEven ? items[i ~/ 2] : separator,
    );
  }

  List<Widget> _buildVisibleSections() {
    final sections = <Widget>[
      _buildLazyLoadedSection('hostBanner', _buildHostBanner()),
      _buildLazyLoadedSection('cafe', _cachedCafeSection),
      _buildLazyLoadedSection('gamePass', _buildGamePassContainer()),
      _buildLazyLoadedSection('squadMissions', const SquadMissionsCard()),
      _buildLazyLoadedSection('referral', _buildReferFriendModal()),
      _buildLazyLoadedSection('miniGames', _cachedMiniGamesSection),
      _buildLazyLoadedSection('shorts', _cachedShortsSection),
      _buildLazyLoadedSection('games', _cachedGamesSection),
      _buildLazyLoadedSection('news', _cachedNewsSection),
      _buildLazyLoadedSection('support', _cachedSupportSection),
      _buildLazyLoadedSection('gameOnIndia', _buildGameOnIndiaBanner()),
    ];

    return sections.where((section) => section is! SizedBox).toList();
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
    _sectionVisibility.addAll({
      'cafe': true,
      'hostBanner': true,
      'gamePass': true,
      'support': true,
      'miniGames': false,
      'squadMissions': false,
      'referral': false,
      'shorts': false,
      'news': false,
      'games': false,
      'gameOnIndia': false,
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshData(forceRefresh: false);
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
    bool changed = false;

    void reveal(String key) {
      if (_sectionVisibility[key] == true) return;
      _sectionVisibility[key] = true;
      changed = true;
    }

    if (currentScroll > maxScroll * 0.15) reveal('miniGames');
    if (currentScroll > maxScroll * 0.30) reveal('squadMissions');
    if (currentScroll > maxScroll * 0.45) reveal('referral');
    if (currentScroll > maxScroll * 0.60) reveal('shorts');
    if (currentScroll > maxScroll * 0.72) reveal('news');
    if (currentScroll > maxScroll * 0.82) reveal('games');
    if (currentScroll > maxScroll * 0.90) reveal('gameOnIndia');

    if (changed && mounted) {
      setState(() {});
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
            final userKey = backendUserId.isNotEmpty
                ? backendUserId
                : firebaseUid;
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
    final firebaseUid =
        firebase_auth.FirebaseAuth.instance.currentUser?.uid ?? '';
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

  Future<void> _refreshData({bool forceRefresh = true}) async {
    if (_isRefreshing) return;

    if (!mounted) return;
    setState(() => _isRefreshing = true);
    final fcmCubit = BlocProvider.of<FcmCubit>(context);
    final hashCoinCubit = BlocProvider.of<HashCoinCubit>(context);

    try {
      final hasUser = await _fetchUserDataIfNeeded(forceRefresh: forceRefresh);
      if (hasUser) {
        await _maybeShowWelcomePopupForNewUser();
        final tasks = <Future<void>>[
          _refreshWalletIfReady(forceRefresh: forceRefresh),
          bookingController.fetchUserBookings(forceRefresh: forceRefresh),
          hashCoinCubit.getHashCoin(forceRefresh: forceRefresh),
        ];
        if (!_fcmRegistered) {
          tasks.add(
            fcmCubit.registerFCMToken(forceRefresh: forceRefresh).then((
              registered,
            ) {
              _fcmRegistered = registered;
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

  Future<bool> _fetchUserDataIfNeeded({required bool forceRefresh}) async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _redirectToLogin();
      return false;
    }

    if (!forceRefresh) {
      final cachedUser = await remoteRepo.getUserFromPreferences();
      final jwt = await remoteRepo.getJwtFromPreferences();
      final backendId = (cachedUser?['id'] ?? cachedUser?['user_id'] ?? '')
          .toString()
          .trim();
      final hasUsableCachedSession =
          cachedUser != null &&
          backendId.isNotEmpty &&
          jwt != null &&
          !isJwtExpired(jwt);

      if (hasUsableCachedSession) {
        userController.setUserData(User.fromJson(cachedUser));
        userController.id.value = backendId;
        return true;
      }
    }

    // Refresh backend session + JWT before any authed calls.
    final apiUser = await remoteRepo.checkUserExistsInAPI(currentUser.uid);

    if (apiUser != null && mounted) {
      // push into controller without a second network call
      userController.setUserData(User.fromJson(apiUser));
      final backendId = (apiUser['id'] ?? apiUser['user_id'] ?? '').toString();
      if (backendId.trim().isEmpty) {
        _redirectToLogin();
        return false;
      }
      userController.id.value = backendId;
    } else {
      // fall back to existing fetch (no-auth) for safety
      final fetchedUser = await userController.fetchUserData(currentUser.uid);
      final backendId =
          (fetchedUser?['id'] ??
                  fetchedUser?['user_id'] ??
                  userController.userId)
              .toString()
              .trim();
      if (backendId.isEmpty) {
        _redirectToLogin();
        return false;
      }
      userController.id.value = backendId;
    }
    return true;
  }

  void _redirectToLogin() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Get.offAllNamed(AppRoutes.LOGIN);
    });
  }

  Future<void> _refreshWalletIfReady({required bool forceRefresh}) async {
    if (walletController.isWalletReady) {
      await walletController.fetchWallet(forceRefresh: forceRefresh);
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
        onRefresh: () => _refreshData(forceRefresh: true),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: _horizontalSectionPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: _sectionGap), // top padding
                        ..._intersperse(
                          _buildVisibleSections(),
                          const SizedBox(height: _sectionGap),
                        ),
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
    _sectionVisibility[sectionKey] ??= false;

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
    final effectivePhoto = (photoUrl ?? '').trim().isNotEmpty
        ? photoUrl!.trim()
        : (firebase_auth.FirebaseAuth.instance.currentUser?.photoURL ?? '')
              .trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xff00DC00), width: 2),
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundImage: effectivePhoto.isNotEmpty
            ? CachedNetworkImageProvider(
                effectivePhoto,
                errorListener: (error) =>
                    AppLogger.d('Avatar image error: $error'),
              )
            : null,
        backgroundColor: Colors.white,
        child: effectivePhoto.isEmpty
            ? const Icon(Icons.person_rounded, color: Colors.black54)
            : null,
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

  Widget _buildHostBanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Earn with ',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const HashWordmark(fontSize: 15, letterSpacing: 2.5),
                  ],
                ),
              ),
              Text(
                'HOST PROGRAM',
                style: GoogleFonts.inter(
                  color: const Color(0xFFA99AFF),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        BounceTap(
          onTap: () => Get.toNamed(AppRoutes.HOST_ONBOARDING),
          child: Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF745CFF), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D6D28FF),
                  blurRadius: 14,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.5),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 1672 / 941,
                child: Image.asset(
                  'assets/community_host_banner.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _hostBannerFallback(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _hostBannerFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7A1FA2), Color(0xFFDE3A3A)],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HashWordmark(fontSize: 9, letterSpacing: 1.5),
              const SizedBox(width: 7),
              Text(
                'HOST PROGRAM',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Earn lakhs by hosting\ntournaments on HASH',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              'Become a Host  ›',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
