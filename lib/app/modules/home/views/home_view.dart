import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/app/modules/arena/services/booking_food_order_service.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/app/modules/home/controllers/app_mode_controller.dart';
import 'package:hash/app/modules/home/controllers/session_progress_controller.dart';
import 'package:hash/app/modules/game_pass/view/game_pass_view.dart';
import 'package:hash/app/modules/shop_new/controllers/shop_controller.dart';
import 'package:hash/app/modules/shop_new/view/shop_view.dart';
import 'package:hash/app/modules/home/widgets/live_session_glass_card.dart';
import 'package:hash/app/routes/app_routes.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/firebase_in_app_messaging_service.dart';
import 'package:hash/core/service/funnel_notification_service.dart';
import 'package:hash/core/service/location_analytics_service.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/squad_missions_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/app/modules/hash_coin/widgets/daily_login_reward_dialog.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/home_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeController controller = Get.find();
  final BookingController bookingController = Get.find<BookingController>();
  final ShopController shopController = Get.find<ShopController>();
  final ChatService chatService = Get.find<ChatService>();
  late final SessionProgressController _sessionProgressController;
  final LocationAnalyticsService _locationAnalyticsService =
      locator<LocationAnalyticsService>();
  final FirebaseInAppMessagingService _fiamService =
      locator<FirebaseInAppMessagingService>();
  final SquadMissionsService _squadMissionsService =
      locator<SquadMissionsService>();
  final BookingFoodOrderService _bookingFoodOrderService =
      BookingFoodOrderService();
  bool _didApplyTabArgument = false;
  bool _didApplyPassesArgument = false;
  bool _didSyncChatProfile = false;
  bool _dailyLoginRewardHandled = false;
  bool _isHomeScrolling = false;
  bool _isShopBarExpanded = false;
  bool _sessionProgressSyncScheduled = false;
  List<Map<String, dynamic>> _pendingSessionProgressBookings =
      <Map<String, dynamic>>[];
  Timer? _fabExpandTimer;
  Timer? _shopBarCollapseTimer;
  Worker? _bookingsWorker;

  @override
  void initState() {
    super.initState();
    _isShopBarExpanded = controller.isShopOpen.value;
    final appModeController = Get.isRegistered<AppModeController>()
        ? Get.find<AppModeController>()
        : Get.put(AppModeController(), permanent: true);
    appModeController.setMode(AppMode.hub);
    _sessionProgressController = Get.isRegistered<SessionProgressController>()
        ? Get.find<SessionProgressController>()
        : Get.put(SessionProgressController(), permanent: true);
    _scheduleSessionProgressSync(bookingController.userBookings);
    _bookingsWorker = ever<List<Map<String, dynamic>>>(
      bookingController.userBookings,
      _scheduleSessionProgressSync,
    );
    _syncChatProfile();
    unawaited(
      _squadMissionsService.trackAction(action: SquadMissionAction.dailyLogin),
    );
    unawaited(_handleDailyLoginHashCoinReward());
    unawaited(
      _locationAnalyticsService.trackCurrentLocation(source: 'home_init'),
    );
    unawaited(_fiamService.triggerHomeOpen());
  }

  void _scheduleSessionProgressSync(List<Map<String, dynamic>> bookings) {
    _pendingSessionProgressBookings = List<Map<String, dynamic>>.from(bookings);
    if (_sessionProgressSyncScheduled) return;
    _sessionProgressSyncScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sessionProgressSyncScheduled = false;
      if (!mounted) return;
      _sessionProgressController.syncFromPastBookings(
        _pendingSessionProgressBookings,
      );
    });
  }

  Future<void> _handleDailyLoginHashCoinReward() async {
    if (_dailyLoginRewardHandled) return;
    _dailyLoginRewardHandled = true;

    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final prefs = locator<SharedPreferences>();
    final userData = await locator<RemoteRepoInterface>()
        .getUserFromPreferences();
    final backendUserId = (userData?['id'] ?? userData?['user_id'] ?? '')
        .toString()
        .trim();
    final rewardUserKey = backendUserId.isNotEmpty
        ? backendUserId
        : currentUser.uid;
    if (rewardUserKey.isEmpty) return;

    final now = DateTime.now();
    final dayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final claimedKey = 'daily_login_hash_reward_${rewardUserKey}_$dayKey';
    if (prefs.getBool(claimedKey) ?? false) return;

    final reward = 5 + Random().nextInt(16);

    try {
      await locator<RemoteRepoInterface>().addHashCoins(
        amount: reward,
        source: 'daily_login_reward',
        referenceId: 'daily_login_${rewardUserKey}_$dayKey',
      );
      await prefs.setBool(claimedKey, true);
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          context.read<HashCoinCubit>().getHashCoin();
        } catch (_) {
          // ignore if cubit context is unavailable
        }
      });

      await locator<FunnelNotificationService>().trackEvent(
        'coin_earned',
        payload: {'amount': reward, 'source': 'daily_login_reward'},
      );
      await locator<FunnelNotificationService>().trackEvent(
        'reward_unlocked',
        payload: {'amount': reward, 'source': 'daily_login_reward'},
      );

      await _showDailyLoginRewardPopup(
        amount: reward,
        streak: _dailyLoginStreak(prefs, rewardUserKey, now),
      );
    } catch (_) {
      // keep home flow silent if reward call fails
    }
  }

  /// Counts back from today over the per-day claim flags this flow already
  /// writes, so the streak needs no extra storage and no backend call.
  int _dailyLoginStreak(
    SharedPreferences prefs,
    String rewardUserKey,
    DateTime today,
  ) {
    var streak = 0;
    for (var back = 0; back < 365; back++) {
      final day = today.subtract(Duration(days: back));
      final key =
          'daily_login_hash_reward_${rewardUserKey}_'
          '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';
      if (!(prefs.getBool(key) ?? false)) break;
      streak++;
    }
    return streak;
  }

  Future<void> _showDailyLoginRewardPopup({
    required int amount,
    required int streak,
  }) async {
    await Get.dialog<void>(
      DailyLoginRewardDialog(amount: amount, streak: streak),
    );
  }

  Future<void> _syncChatProfile() async {
    if (_didSyncChatProfile || !chatService.isLoggedIn) return;
    _didSyncChatProfile = true;
    await chatService.ensureCurrentUserProfile();
    await chatService.startChatNotifications();
  }

  Future<void> _openChatInbox() async {
    if (!chatService.isLoggedIn) {
      Get.snackbar(
        'Chat',
        'Please sign in to use chat.',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
      );
      return;
    }

    final segmentService = locator<SegmentSdkService>();
    final fbEventsService = locator<FbEventsService>();
    unawaited(
      segmentService.onCustomEvent('Chat FAB Clicked', {
        'source': 'home',
        'unread_room_count': chatService.unreadRoomCount.value,
      }),
    );
    unawaited(
      fbEventsService.logEvent('Chat FAB Clicked', {
        'source': 'home',
        'unread_room_count': chatService.unreadRoomCount.value,
      }),
    );

    unawaited(Haptics.medium());
    unawaited(chatService.ensureCurrentUserProfile());
    if (!mounted) return;
    Get.toNamed(AppRoutes.CHAT);
  }

  Future<void> _openLiveSessionFoodOrder() async {
    final booking = _sessionProgressController.currentBooking.value;
    if (booking == null) return;
    await _bookingFoodOrderService.orderForActiveSession(
      context: context,
      booking: booking.rawBooking,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didApplyTabArgument) return;
    _didApplyTabArgument = true;

    final args = Get.arguments;
    if (args is Map && args['tabIndex'] is int) {
      final targetIndex = args['tabIndex'] as int;
      if (controller.selectedIndex.value != targetIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          controller.onItemTapped(targetIndex);
        });
      }
    }

    if (args is Map && args['openPasses'] == true && !_didApplyPassesArgument) {
      _didApplyPassesArgument = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await Future<void>.delayed(const Duration(milliseconds: 220));
        if (!mounted) return;
        await Get.to(() => const GamePassViewPage());
      });
    }
  }

  void _openShopSection(int sectionIndex) {
    final wasClosed = !controller.isShopOpen.value;
    _shopBarCollapseTimer?.cancel();
    shopController.setShopMenuIndex(sectionIndex);
    if (!_isShopBarExpanded) {
      setState(() => _isShopBarExpanded = true);
    }
    controller.isShopOpen.value = true;
    if (wasClosed) {
      Haptics.medium();
    }
  }

  void _closeShop() {
    if (!controller.isShopOpen.value && !_isShopBarExpanded) return;
    Haptics.navigation();
    controller.isShopOpen.value = false;
    _shopBarCollapseTimer?.cancel();
    _shopBarCollapseTimer = Timer(const Duration(milliseconds: 170), () {
      if (!mounted || !_isShopBarExpanded) return;
      setState(() => _isShopBarExpanded = false);
    });
  }

  void _onMainNavigationTap(int index) {
    _shopBarCollapseTimer?.cancel();
    if (_isShopBarExpanded) {
      setState(() => _isShopBarExpanded = false);
    }
    controller.onItemTapped(index);
  }

  bool _handleHomeScrollNotification(ScrollNotification notification) {
    if (controller.selectedIndex.value != 0) return false;
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification) {
      _fabExpandTimer?.cancel();
      if (!_isHomeScrolling && mounted) {
        setState(() => _isHomeScrolling = true);
      }
      return false;
    }

    if (notification is ScrollEndNotification ||
        (notification is UserScrollNotification &&
            notification.direction == ScrollDirection.idle)) {
      _fabExpandTimer?.cancel();
      _fabExpandTimer = Timer(const Duration(milliseconds: 180), () {
        if (!mounted || !_isHomeScrolling) return;
        setState(() => _isHomeScrolling = false);
      });
    }

    return false;
  }

  @override
  void dispose() {
    _fabExpandTimer?.cancel();
    _shopBarCollapseTimer?.cancel();
    _bookingsWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            reverseDuration: const Duration(milliseconds: 240),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return FadeTransition(
                opacity: curvedAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.035, 0),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                ),
              );
            },
            child: Obx(() {
              final isShowingShop =
                  HomeController.isHashShopReleased &&
                  controller.isShopOpen.value;
              final screen = RepaintBoundary(
                key: ValueKey(
                  isShowingShop ? 'hash_shop' : controller.selectedIndex.value,
                ),
                child: isShowingShop
                    ? const ShopMenuView()
                    : controller.currentScreen.value,
              );

              if (isShowingShop || controller.selectedIndex.value != 0) {
                if (_isHomeScrolling) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || !_isHomeScrolling) return;
                    setState(() => _isHomeScrolling = false);
                  });
                }
                return screen;
              }

              return NotificationListener<ScrollNotification>(
                onNotification: _handleHomeScrollNotification,
                child: screen,
              );
            }),
          ),
          Obx(() {
            if (controller.isShopOpen.value ||
                controller.selectedIndex.value != 0) {
              return const SizedBox.shrink();
            }
            return Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: IgnorePointer(
                ignoring: false,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.elasticOut,
                  offset: _isHomeScrolling
                      ? const Offset(0, 0.52)
                      : Offset.zero,
                  child: LiveSessionGlassCard(
                    controller: _sessionProgressController,
                    forceVisible: false,
                    unreadCount: chatService.unreadRoomCount.value,
                    onChatTap: _openChatInbox,
                    onOrderFoodTap:
                        (_sessionProgressController
                                .currentBooking
                                .value
                                ?.vendorId
                                .isNotEmpty ??
                            false)
                        ? _openLiveSessionFoodOrder
                        : null,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Obx(() {
        if (controller.isShopOpen.value ||
            controller.selectedIndex.value != 0) {
          return const SizedBox.shrink();
        }

        final hasActiveSession =
            _sessionProgressController.currentBooking.value != null;
        if (hasActiveSession) {
          // Chat action is embedded inside the live session card.
          return const SizedBox.shrink();
        }

        final unreadCount = chatService.unreadRoomCount.value;
        const neonGreen = Color(0xff00DC00);
        final bool showLabel = !_isHomeScrolling;
        const fabShape = BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(0),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Frosted blurred-glass pill: a translucent surface over a
            // BackdropFilter so the feed behind shows through, framed by the
            // neon-green brand border.
            ClipRRect(
              borderRadius: fabShape,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openChatInbox,
                    borderRadius: fabShape,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        // Subtle green-tinted frost so the blur reads even over
                        // dark content.
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.10),
                            neonGreen.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: fabShape,
                        border: Border.all(color: neonGreen, width: 1.6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/chat.png',
                            width: 20,
                            height: 20,
                            color: neonGreen,
                            fit: BoxFit.contain,
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            child: showLabel
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Text(
                                      'Chat',
                                      style: GoogleFonts.inter(
                                        color: neonGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      }),

      // --- Bottom bar with Hash Shop slide animation ---
      bottomNavigationBar: Obx(() {
        final bool isShopMenuOpen = _isShopBarExpanded;
        final int activeShopIndex = shopController.shopMenuIndex.value;
        final double shopActionsWidth = (screenWidth - 140).clamp(
          0.0,
          double.infinity,
        );

        return Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // --- Bottom Navigation Bar ---
            BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              enableFeedback: true,
              showSelectedLabels: true,
              showUnselectedLabels: false,
              selectedFontSize: 10.5,
              unselectedFontSize: 10,
              selectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
              currentIndex: controller.selectedIndex.value,
              onTap: _onMainNavigationTap,
              backgroundColor: Colors.black,
              selectedItemColor: const Color(0xff00DC00),
              unselectedItemColor: Colors.grey[800],
              items: <BottomNavigationBarItem>[
                _buildNavigationItem(
                  'assets/navbar_icons/Vector (1).png',
                  label: 'Home',
                  isSelected: controller.selectedIndex.value == 0,
                ),
                _buildNavigationItem(
                  'assets/navbar_icons/maki_gaming.png',
                  label: 'Squad Up',
                  isSelected: controller.selectedIndex.value == 1,
                ),
                _buildNavigationItem(
                  'assets/navbar_icons/trophy.png',
                  label: 'Compete',
                  isSelected: controller.selectedIndex.value == 2,
                  isSpecial: true,
                ),
                _buildNavigationItem(
                  'assets/navbar_icons/Group.png',
                  label: 'Sessions',
                  isSelected: controller.selectedIndex.value == 3,
                  iconHeight: 17,
                ),
                _buildNavigationItem(
                  'assets/navbar_icons/Vector (3).png',
                  label: 'Me',
                  isSelected: controller.selectedIndex.value == 4,
                ),
              ],
            ),

            // --- Slide-in Hash Shop Bar ---
            if (HomeController.isHashShopReleased)
              Positioned(
                right: 0,
                bottom: bottomSafeArea + 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(isShopMenuOpen ? 0 : 24),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      width: isShopMenuOpen ? screenWidth : 84,
                      height: isShopMenuOpen ? 52 : 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(isShopMenuOpen ? 0 : 24),
                        ),
                        gradient: isShopMenuOpen
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF0B1B08),
                                  Color(0xFF12351E),
                                  Color(0xFF4A2D7A),
                                  Color(0xFF7A44C0),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.08),
                                  const Color(
                                    0xFF7A44C0,
                                  ).withValues(alpha: 0.28),
                                  Colors.black.withValues(alpha: 0.48),
                                ],
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 2,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: const Color(
                              0xFF7A44C0,
                            ).withValues(alpha: 0.24),
                            blurRadius: 10,
                            offset: const Offset(0, 0),
                          ),
                          BoxShadow(
                            color: const Color(
                              0xFF56C785,
                            ).withValues(alpha: 0.14),
                            blurRadius: 8,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.42),
                                    Colors.black,
                                    Colors.black,
                                  ],
                                  stops: const [0.0, 0.34, 0.82, 1.0],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isShopMenuOpen ? 10 : 8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (isShopMenuOpen) {
                                      _closeShop();
                                    } else {
                                      _openShopSection(0);
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      AnimatedOpacity(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        opacity: isShopMenuOpen ? 1 : 0,
                                        child: const Padding(
                                          padding: EdgeInsets.only(right: 8.0),
                                          child: Icon(
                                            Icons.arrow_back_ios_new_sharp,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        transitionBuilder: (child, animation) =>
                                            FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            ),
                                        child: Text(
                                          isShopMenuOpen
                                              ? "HASH\nAPP"
                                              : "HASH\nSHOP",
                                          key: ValueKey(isShopMenuOpen),
                                          style: GoogleFonts.orbitron(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeInOutCubic,
                                  width: isShopMenuOpen ? shopActionsWidth : 0,
                                  margin: EdgeInsets.only(
                                    left: isShopMenuOpen ? 8 : 0,
                                  ),
                                  child: ClipRect(
                                    child: OverflowBox(
                                      alignment: Alignment.centerRight,
                                      minWidth: shopActionsWidth,
                                      maxWidth: shopActionsWidth,
                                      child: IgnorePointer(
                                        ignoring: !isShopMenuOpen,
                                        child: AnimatedOpacity(
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          opacity: isShopMenuOpen ? 1 : 0,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              _shopIcon(
                                                Icons.storefront_rounded,
                                                isActive: activeShopIndex == 0,
                                                onTap: () =>
                                                    _openShopSection(0),
                                              ),
                                              _shopIcon(
                                                Icons.shopping_bag_rounded,
                                                isActive: activeShopIndex == 2,
                                                onTap: () =>
                                                    _openShopSection(2),
                                              ),
                                              _shopIcon(
                                                Icons.receipt_long_rounded,
                                                isActive: activeShopIndex == 3,
                                                onTap: () =>
                                                    _openShopSection(3),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  // --- BottomNavigationBar Item Builder ---
  BottomNavigationBarItem _buildNavigationItem(
    String iconPath, {
    required String label,
    required bool isSelected,
    bool isSpecial = false,
    double iconHeight = 22,
  }) {
    final selected = controller.selectedIndex.value == 2
        ? Color(0xffFBA544)
        : Color(0xff00DC00);
    final unselected = Colors.grey[800];

    if (isSpecial) {
      return BottomNavigationBarItem(
        backgroundColor: Colors.black,
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isSelected ? 27 : 25,
          width: isSelected ? 27 : 25,
          child: Image.asset(
            iconPath,
            height: 12,
            color: isSelected ? selected : unselected,
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
        label: label,
      );
    }

    return BottomNavigationBarItem(
      backgroundColor: Colors.black,
      icon: AnimatedScale(
        scale: isSelected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Image.asset(
          iconPath,
          height: iconHeight,
          color: isSelected ? selected : unselected,
          colorBlendMode: BlendMode.srcIn,
        ),
      ),
      label: label,
    );
  }

  // --- Shop Icons ---
  Widget _shopIcon(
    IconData icon, {
    required VoidCallback onTap,
    required bool isActive,
  }) {
    final activeBg = LinearGradient(
      colors: [
        const Color(0xff00DC00).withValues(alpha: 0.28),
        const Color(0xFF7A44C0).withValues(alpha: 0.32),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: isActive ? activeBg : null,
          color: isActive ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? const Color(0xff00DC00).withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xff67FF67) : Colors.white70,
          size: isActive ? 21 : 20,
        ),
      ),
    );
  }
}
