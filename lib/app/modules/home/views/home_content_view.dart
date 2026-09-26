import 'package:flutter/material.dart';
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
import 'package:hash/app/modules/home/controllers/home_controller.dart';
import 'package:hash/app/modules/tournaments_section/cubit/tournament_home_cubit.dart';
import 'package:hash/app/modules/tournaments_section/models/tournament_model.dart';
import 'package:hash/app/modules/tournaments_section/pages/tournaments_details_view.dart';
import 'package:hash/app/modules/login/controllers/login_controller.dart';
import 'package:hash/app/modules/news/news_section_view.dart';
import 'package:hash/app/modules/refferal/views/referral_view_with_controller.dart';
import 'package:hash/app/modules/rewards/widgets/squad_missions_card.dart';
import 'package:hash/app/routes/app_routes.dart';
import 'package:hash/app/modules/shorts/views/viral_shots_view.dart';
import 'package:hash/app/modules/social/friends_view.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hash/features/mini_games/mini_game_section.dart';
import 'package:hash/app/modules/wallet/controllers/wallet_controller.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/app/modules/home/widgets/refer_friend_modal.dart';
import 'package:hash/app/data/models/user_model.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/utils/encrypt_util.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';
import 'package:hash/utils/widgets/hash_wordmark.dart';
import 'package:hash/utils/widgets/home_section_title.dart';

import 'package:hash/core/utils/app_logger.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';

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
  late final TournamentHomeCubit tournamentHomeCubit;

  // Animation controllers
  late final AnimationController _fadeController;
  late final AnimationController _slideController;

  // Scroll controller for optimization
  late final ScrollController _scrollController;
  static const double _sectionGap = 24.0;
  static const double _maxContentWidth = 720.0;

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
      _buildLazyLoadedSection('playerLobby', _buildPlayerLobby()),
      _buildLazyLoadedSection('cafe', _cachedCafeSection),
      _buildLazyLoadedSection('squadMissions', const SquadMissionsCard()),
      _buildLazyLoadedSection('shorts', _cachedShortsSection),
      _buildLazyLoadedSection('miniGames', _cachedMiniGamesSection),
      _buildLazyLoadedSection('gamePass', _buildGamePassContainer()),
      _buildLazyLoadedSection('games', _cachedGamesSection),
      _buildLazyLoadedSection('news', _cachedNewsSection),
      _buildLazyLoadedSection('referral', _buildReferFriendModal()),
      _buildLazyLoadedSection('gameOnIndia', _buildGameOnIndiaBanner()),
    ];

    return sections.where((section) => section is! SizedBox).toList();
  }

  // State variables
  bool isInitialized = false;
  bool _isRefreshing = false;
  String? _refreshErrorMessage;
  bool showReferModal = false;
  bool _fcmRegistered = false;
  bool _welcomeClaimGateHandled = false;

  // Cached widgets for better performance
  Widget? _cachedGamePassContainer;
  Widget? _cachedGameOnIndiaBanner;
  late final Widget _cachedCafeSection;
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
    tournamentHomeCubit.close();
    super.dispose();
  }

  void _initializeControllers() {
    bookingController = Get.find<BookingController>();
    loginController = Get.find<LoginController>();
    userController = Get.find<UserController>();
    walletController = Get.find<WalletController>();
    segmentService = locator<SegmentSdkService>();
    tournamentHomeCubit = TournamentHomeCubit();
  }

  void _initializeSections() {
    // Reuse long-lived section widgets to avoid rebuilding heavy trees.
    _cachedCafeSection = CafeSection();
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
      'playerLobby': true,
      'cafe': true,
      'gamePass': true,
      'hostBanner': true,
      'miniGames': true,
      'squadMissions': true,
      'referral': false,
      'shorts': true,
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
          amountRupees: WalletController.welcomeBonusAmount,
          onClaim: () async {
            await Haptics.success();
            final claimed = await Get.find<WalletController>().claimDropCrate();
            // Keep the pending flag set so the bonus is never lost on failure;
            // the dialog stays open for a retry.
            if (!claimed) return false;

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
            return true;
          },
        );
      },
    ).then((_) {
      // If the popup was dismissed without a successful claim (e.g. "Maybe
      // later"), re-arm the gate so it can appear again on the next refresh.
      final stillPending = prefs.getBool('new_user_bonus_pending') ?? false;
      if (stillPending) {
        _welcomeClaimGateHandled = false;
      }
    });
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
    setState(() {
      _isRefreshing = true;
      _refreshErrorMessage = null;
    });
    final fcmCubit = BlocProvider.of<FcmCubit>(context);
    final hashCoinCubit = BlocProvider.of<HashCoinCubit>(context);

    try {
      final hasUser = await _fetchUserDataIfNeeded(forceRefresh: forceRefresh);
      if (hasUser) {
        await _maybeShowWelcomePopupForNewUser();
        final tasks = <Future<void>>[
          _refreshWalletIfReady(forceRefresh: forceRefresh),
          bookingController.fetchUserBookings(forceRefresh: forceRefresh),
          tournamentHomeCubit.fetchTournaments(forceRefresh: forceRefresh),
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
      if (mounted) {
        setState(() {
          _refreshErrorMessage =
              'We couldn\'t refresh your home feed. Check your connection and try again.';
        });
      }
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
        const HomeSectionTitle(title: 'Refer to a ', accent: 'Friend'),
        const SizedBox(height: 12),
        Obx(() {
          final user = userController.user.value;
          return ReferFriendModal(
            isDialog: false,
            referralCode: user.referralCode,
            referralCount: user.referralCount,
            referralRewards: user.referralRewards,
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
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: () => _refreshData(forceRefresh: true),
        backgroundColor: Colors.black,
        color: const Color(0xFF00DC00),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            const OptimizedAppBar(),
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth >= 600
                      ? 24.0
                      : 16.0;
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _maxContentWidth,
                      ),
                      child: FadeTransition(
                        opacity: _fadeController,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.035),
                            end: Offset.zero,
                          ).animate(_slideController),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 18),
                                if (_refreshErrorMessage != null) ...[
                                  _buildRefreshErrorState(),
                                  const SizedBox(height: 18),
                                ] else if (!isInitialized && _isRefreshing) ...[
                                  _buildInitialLoadingState(),
                                  const SizedBox(height: 18),
                                ],
                                ..._intersperse(
                                  _buildVisibleSections(),
                                  const SizedBox(height: _sectionGap),
                                ),
                                const SizedBox(height: 104),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshErrorState() {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1717),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x66FF6B6B)),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Color(0xFFFF8C8C)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _refreshErrorMessage!,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _isRefreshing
                  ? null
                  : () => _refreshData(forceRefresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialLoadingState() {
    return Semantics(
      label: 'Loading your home feed',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00DC00),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Getting your next game ready…',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
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

  Widget _buildPlayerLobby() {
    return BlocBuilder<TournamentHomeCubit, TournamentHomeState>(
      bloc: tournamentHomeCubit,
      builder: (context, state) {
        if (state is TournamentHomeLoaded) {
          final upcoming = state.joinableTournaments
              .where(
                (tournament) => tournament.status == TournamentStatus.upcoming,
              )
              .toList(growable: false);
          if (upcoming.isNotEmpty) {
            return _buildUpcomingTournaments(upcoming);
          }
        }
        return _buildLobbyFallback();
      },
    );
  }

  Widget _buildUpcomingTournaments(List<TournamentModel> tournaments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const HomeSectionTitle(title: 'Upcoming ', accent: 'Tournaments'),
              const Spacer(),
              TextButton(
                onPressed: () => Get.find<HomeController>().onItemTapped(2),
                child: const Text('View all'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: tournaments.length,
            separatorBuilder: (_, _) => const SizedBox(width: 9),
            itemBuilder: (_, index) =>
                _buildUpcomingTournamentCard(tournaments[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTournamentCard(TournamentModel tournament) {
    final imagePath = tournament.imageUrl.trim();
    final image = imagePath.startsWith('http')
        ? NetworkImage(imagePath)
        : AssetImage(
                imagePath.isEmpty
                    ? 'assets/hash_store_images/tournament_img1.png'
                    : imagePath,
              )
              as ImageProvider;
    final date = tournament.startDate;
    final dateLabel = date == null
        ? 'DATE TBA'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return GestureDetector(
      onTap: () {
        if (tournament.source == 'community') {
          Get.toNamed(
            AppRoutes.TOURNAMENT_DETAIL,
            arguments: {
              'id': tournament.id,
              'can_manage': tournament.canManage,
            },
          );
        } else {
          Get.to(() => TournamentsDetailsView(tournament: tournament));
        }
      },
      child: SizedBox(
        width: 124,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 124,
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(image: image, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x99000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Row(
                        children: [
                          Text(
                            tournament.statusLabel.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: const Color(0xFF00DC00),
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .7,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            tournament.entryFee,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              tournament.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateLabel,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLobbyFallback() {
    return Obx(() {
      final bookings = bookingController.userBookings.where((booking) {
        final status = (booking['status'] ?? '').toString().toLowerCase();
        return status.contains('confirm') ||
            status.contains('pending') ||
            status.contains('success');
      }).toList();
      final nextBooking = bookings.isEmpty ? null : bookings.first;
      final slot = nextBooking?['slot'];
      final slotMap = slot is Map
          ? Map<String, dynamic>.from(slot)
          : const <String, dynamic>{};
      final gamingType = slotMap['gaming_type_id'];
      final gamingMap = gamingType is Map
          ? Map<String, dynamic>.from(gamingType)
          : const <String, dynamic>{};
      final cafeValue = gamingMap['cafe_name'];
      final cafeMap = cafeValue is Map
          ? Map<String, dynamic>.from(cafeValue)
          : const <String, dynamic>{};
      final cafeName =
          (cafeMap['cafe_name'] ??
                  cafeMap['name'] ??
                  gamingMap['cafe_name'] ??
                  'Gaming café')
              .toString();
      final gameName = (gamingMap['game_name'] ?? 'Your setup').toString();

      final locked = nextBooking != null;

      // Bespoke, border-less lobby card: a soft green-tinted gradient with a
      // radial bloom and layered shadows gives it depth without an outline.
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HomeTokens.radius),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF15251B), Color(0xFF0E1116)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: HomeTokens.green.withValues(alpha: 0.12),
              blurRadius: 34,
              spreadRadius: -8,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HomeTokens.radius),
          child: Stack(
            children: [
              // Green bloom in the top-right for a subtle energy glow.
              Positioned(
                top: -90,
                right: -70,
                child: IgnorePointer(
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          HomeTokens.green.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const HomeEyebrow('Your lobby'),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (locked
                                        ? HomeTokens.green
                                        : HomeTokens.textTertiary)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: locked
                                      ? HomeTokens.green
                                      : HomeTokens.textTertiary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                locked ? 'SESSION LOCKED' : 'QUEUE: OPEN',
                                style: HomeTokens.eyebrow(
                                  locked
                                      ? HomeTokens.green
                                      : HomeTokens.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                HomeTokens.green.withValues(alpha: 0.30),
                                HomeTokens.green.withValues(alpha: 0.10),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.sports_esports_rounded,
                            color: HomeTokens.greenBright,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locked ? cafeName : 'Ready to lock in?',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: HomeTokens.title(19),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                locked
                                    ? '$gameName is queued. Pull up with the squad.'
                                    : 'Find your setup, squad up, or jump into ranked.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: HomeTokens.body(
                                  HomeTokens.textSecondary,
                                  size: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // CTA and the three shortcuts share one row: stacking them
                    // cost roughly twice the height for the same set of actions.
                    Row(
                      children: [
                        Expanded(
                          child: HomeCta(
                            height: 48,
                            label: locked ? 'Open session' : 'Find a setup',
                            icon: locked
                                ? Icons.sports_esports_rounded
                                : Icons.radar_rounded,
                            onTap: () => Get.find<HomeController>()
                                .onItemTapped(locked ? 2 : 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        HomeIconAction(
                          icon: Icons.group_add_rounded,
                          label: 'Squad up',
                          onTap: () =>
                              Get.to(() => const FriendsView(initialTab: 2)),
                        ),
                        const SizedBox(width: 8),
                        HomeIconAction(
                          icon: Icons.emoji_events_rounded,
                          label: 'Ranked',
                          onTap: () =>
                              Get.find<HomeController>().onItemTapped(2),
                        ),
                        const SizedBox(width: 8),
                        HomeIconAction(
                          icon: Icons.history_rounded,
                          label: 'Sessions',
                          onTap: () =>
                              Get.find<HomeController>().onItemTapped(3),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
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
        HomeSectionTitle(
          title: 'Earn with ',
          accent: 'HASH',
          actionLabel: 'Host program',
          accentColor: const Color(0xFFA99AFF),
          onAction: () => Get.toNamed(AppRoutes.HOST_ONBOARDING),
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
                  errorBuilder: (_, _, _) => _hostBannerFallback(),
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
}
