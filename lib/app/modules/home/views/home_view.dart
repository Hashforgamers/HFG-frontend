import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:hash/app/modules/hash_store/widgets/neon_switch.dart';
import 'dart:async';
import 'package:hash/core/utils/app_snackbar.dart';
import 'dart:math';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hash/config/feature_flags.dart';
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
import 'package:hash/app/modules/hash_store/widgets/shop_nav_bar.dart';
import 'package:hash/app/modules/shop_new/controllers/shop_controller.dart';
import 'package:hash/app/modules/shop_new/view/shop_view.dart';
import 'package:hash/app/modules/cafe_play/data/cafe_live_session_sync.dart';
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
  Worker? _shopOpenWorker;
  final _cafeSessionSync = CafeLiveSessionSync.instance;

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
    // Deep links and pushes open the shop through the controller.
    _shopOpenWorker = ever<bool>(controller.isShopOpen, (open) {
      if (open && !_isShopBarExpanded && mounted) {
        setState(() => _isShopBarExpanded = true);
      }
    });
    _bookingsWorker = ever<List<Map<String, dynamic>>>(
      bookingController.userBookings,
      _scheduleSessionProgressSync,
    );
    _cafeSessionSync.sessions.addListener(_onCafeSessionsChanged);
    _cafeSessionSync.start();
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

  void _onCafeSessionsChanged() {
    _sessionProgressController.syncCafeSessions(
      _cafeSessionSync.sessions.value,
    );
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
      AppSnackbar.show(
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
      shopController.refreshCart();
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
    _shopOpenWorker?.dispose();
    _cafeSessionSync.sessions.removeListener(_onCafeSessionsChanged);
    _cafeSessionSync.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Content runs under the frosted nav bar instead of stopping above it.
      extendBody: true,
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

        return _ChatFab(
          unread: chatService.unreadRoomCount.value,
          showLabel: !_isHomeScrolling,
          onTap: _openChatInbox,
        );
      }),

      // --- Bottom bar with Hash Shop slide animation ---
      bottomNavigationBar: Obx(() {
        final bool isShopMenuOpen = _isShopBarExpanded;
        final int activeShopIndex = shopController.shopMenuIndex.value;

        return Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // --- Bottom Navigation Bar: frosted glass over the content ---
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  // Brand green-to-pink glass; the dark base keeps the icons
                  // legible over busy artwork.
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.alphaBlend(
                          HomeTokens.green.withValues(alpha: 0.16),
                          Colors.black.withValues(alpha: 0.55),
                        ),
                        Color.alphaBlend(
                          HomeTokens.pink.withValues(alpha: 0.16),
                          Colors.black.withValues(alpha: 0.55),
                        ),
                      ],
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  // Tabs stop short of the HASH SHOP pill; the last tab
                  // ("Me") used to sit hidden and untappable under it.
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: HomeController.isHashShopReleased
                          ? HashShopDock.pillWidth
                          : 0,
                    ),
                    child: NeonSwitchFx(
                      index: _navTabs
                          .indexWhere(
                            (t) => t.screen == controller.selectedIndex.value,
                          )
                          .clamp(0, _navTabs.length - 1),
                      count: _navTabs.length,
                      // Slower than the shop dock so the main tabs read clearly.
                      response: 1.3,
                      child: BottomNavigationBar(
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
                        currentIndex: _navTabs
                            .indexWhere(
                              (t) => t.screen == controller.selectedIndex.value,
                            )
                            .clamp(0, _navTabs.length - 1),
                        onTap: (position) =>
                            _onMainNavigationTap(_navTabs[position].screen),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        selectedItemColor: const Color(0xff00DC00),
                        unselectedItemColor: Colors.grey[600],
                        items: <BottomNavigationBarItem>[
                          for (final (i, tab) in _navTabs.indexed)
                            _buildNavigationItem(
                              tab.icon,
                              slot: i,
                              label: tab.label,
                              isSelected:
                                  controller.selectedIndex.value == tab.screen,
                              isSpecial: tab.isSpecial,
                              iconHeight: tab.iconHeight,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // --- Hash Shop dock: pill that unfolds into the shop nav bar ---
            if (HomeController.isHashShopReleased)
              Positioned.fill(
                child: HashShopDock(
                  open: isShopMenuOpen,
                  activeIndex: activeShopIndex,
                  cart: shopController.cart,
                  onOpen: () => _openShopSection(0),
                  onSelect: _openShopSection,
                  onExit: _closeShop,
                ),
              ),
          ],
        );
      }),
    );
  }

  /// Bottom bar tabs in display order. [_NavTab.screen] is the screen index
  /// [HomeController] uses (0 home, 1 squad up, 2 tournaments, 3 sessions,
  /// 4 profile); positions shift when a tab is hidden, screen ids don't.
  static final List<_NavTab> _navTabs = [
    const _NavTab(0, 'assets/navbar_icons/Vector (1).png', 'Home'),
    const _NavTab(1, 'assets/navbar_icons/maki_gaming.png', 'Squad Up'),
    if (FeatureFlags.tournamentsEnabled)
      const _NavTab(
        2,
        'assets/navbar_icons/trophy.png',
        'Compete',
        isSpecial: true,
      ),
    const _NavTab(
      3,
      'assets/navbar_icons/Group.png',
      'Sessions',
      iconHeight: 17,
    ),
    const _NavTab(4, 'assets/navbar_icons/Vector (3).png', 'Me'),
  ];

  // --- BottomNavigationBar Item Builder ---
  BottomNavigationBarItem _buildNavigationItem(
    String iconPath, {
    required int slot,
    required String label,
    required bool isSelected,
    bool isSpecial = false,
    double iconHeight = 22,
  }) {
    final selected = controller.selectedIndex.value == 2
        ? Color(0xffFBA544)
        : Color(0xff00DC00);
    // Brighter than grey[800] so idle tabs read on the tinted glass.
    final unselected = Colors.grey[600];

    if (isSpecial) {
      return BottomNavigationBarItem(
        backgroundColor: Colors.black,
        icon: NeonFlip(
          slot: slot,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isSelected ? 27 : 25,
            width: isSelected ? 27 : 25,
            child: _tintedIcon(
              iconPath,
              12,
              isSelected ? selected : unselected!,
            ),
          ),
        ),
        label: label,
      );
    }

    return BottomNavigationBarItem(
      backgroundColor: Colors.black,
      icon: NeonFlip(
        slot: slot,
        child: AnimatedScale(
          scale: isSelected ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: _tintedIcon(
            iconPath,
            iconHeight,
            isSelected ? selected : unselected!,
          ),
        ),
      ),
      label: label,
    );
  }

  /// Paints a monochrome icon in [color], keeping its alpha. A colour matrix
  /// rather than BlendMode.srcIn: under Impeller the blend outlined each
  /// icon's bounds with a hairline box.
  Widget _tintedIcon(String path, double height, Color color) => ColorFiltered(
    colorFilter: ColorFilter.matrix([
      0, 0, 0, 0, color.r * 255, //
      0, 0, 0, 0, color.g * 255,
      0, 0, 0, 0, color.b * 255,
      0, 0, 0, color.a, 0,
    ]),
    child: Image.asset(path, height: height),
  );
}

class _NavTab {
  const _NavTab(
    this.screen,
    this.icon,
    this.label, {
    this.isSpecial = false,
    this.iconHeight = 22,
  });

  final int screen;
  final String icon;
  final String label;
  final bool isSpecial;
  final double iconHeight;
}

/// Frosted chat pill with a soft pink-to-orange rim and coral icon, a
/// brand-pink unread badge that pops when the count changes, and a small
/// squish on press.
class _ChatFab extends StatefulWidget {
  const _ChatFab({
    required this.unread,
    required this.showLabel,
    required this.onTap,
  });

  final int unread;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  State<_ChatFab> createState() => _ChatFabState();
}

class _ChatFabState extends State<_ChatFab> {
  bool _down = false;

  static const _shape = BorderRadius.only(
    topLeft: Radius.circular(28),
    topRight: Radius.circular(28),
    bottomLeft: Radius.circular(28),
  );
  static const _rim = 1.0;
  static const _innerShape = BorderRadius.only(
    topLeft: Radius.circular(28 - _rim),
    topRight: Radius.circular(28 - _rim),
    bottomLeft: Radius.circular(28 - _rim),
  );

  void _setDown(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final unread = widget.unread;
    final brand = HomeTokens.brandGradient;
    return Semantics(
      button: true,
      label: unread > 0 ? 'Chat, $unread unread' : 'Chat',
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _setDown(true),
        onTapUp: (_) => _setDown(false),
        onTapCancel: () => _setDown(false),
        onTap: () {
          Haptics.selection();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.94 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Gradient rim around a frosted pane, so the feed shows
              // through and the brand colour frames it.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      for (final c in brand.colors) c.withValues(alpha: 0.55),
                    ],
                  ),
                  borderRadius: _shape,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_rim),
                  child: ClipRRect(
                    borderRadius: _innerShape,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        height: 56 - _rim * 2,
                        padding: const EdgeInsets.symmetric(horizontal: 17),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/chat.png',
                              width: 20,
                              height: 20,
                              color: HomeTokens.coral,
                              fit: BoxFit.contain,
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              child: widget.showLabel
                                  ? Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Text(
                                        'Chat',
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
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
              if (unread > 0)
                Positioned(
                  right: -3,
                  top: -4,
                  child: StorePop(
                    trigger: unread,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      decoration: BoxDecoration(
                        color: HomeTokens.pink,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
