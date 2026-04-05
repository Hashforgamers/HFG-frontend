import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/home_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  static const String _hashCoinIconUrl =
      'https://res.cloudinary.com/dxjjigepf/image/upload/v1754940678/hash_loog_kze6kr.png';
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
  bool _sessionProgressSyncScheduled = false;
  List<Map<String, dynamic>> _pendingSessionProgressBookings =
      <Map<String, dynamic>>[];
  Timer? _fabExpandTimer;
  Worker? _bookingsWorker;

  @override
  void initState() {
    super.initState();
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

      await _showDailyLoginRewardPopup(amount: reward);
    } catch (_) {
      // keep home flow silent if reward call fails
    }
  }

  Future<void> _showDailyLoginRewardPopup({required int amount}) async {
    await Get.dialog<void>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1016).withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF37EBF3).withValues(alpha: 0.22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.32),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF37EBF3).withValues(alpha: 0.2),
                          const Color(0xFFF4C342).withValues(alpha: 0.14),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: const Color(0xFFF4C342).withValues(alpha: 0.22),
                      ),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: _hashCoinIconUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, _) =>
                          const Center(child: RainbowGlowingLoader(size: 16)),
                      errorWidget: (_, _, _) => const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFF4C342),
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      'Daily Login Reward',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF9EF9FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF37EBF3).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF37EBF3).withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CachedNetworkImage(
                          imageUrl: _hashCoinIconUrl,
                          width: 20,
                          height: 20,
                          placeholder: (_, _) => const Center(
                            child: RainbowGlowingLoader(size: 8),
                          ),
                          errorWidget: (_, _, _) => const Icon(
                            Icons.workspace_premium_rounded,
                            color: Color(0xFFF4C342),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'You received $amount HashCoins',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFFE08A),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Daily logins reward you with a random 5 to 20 HashCoins.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final overlayContext = Get.overlayContext;
                        if (overlayContext != null) {
                          final navigator = Navigator.of(
                            overlayContext,
                            rootNavigator: true,
                          );
                          if (navigator.canPop()) {
                            navigator.pop();
                            return;
                          }
                        }

                        if (!mounted) return;
                        final navigator = Navigator.of(
                          context,
                          rootNavigator: true,
                        );
                        if (navigator.canPop()) {
                          navigator.pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4C342),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Claim',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
    if (!HomeController.isHashShopReleased) {
      controller.onItemTapped(2);
      return;
    }
    final wasClosed = !controller.isShopOpen.value;
    if (controller.selectedIndex.value != 2) {
      controller.onItemTapped(2);
    }
    controller.isShopOpen.value = true;
    shopController.setShopMenuIndex(sectionIndex);
    if (wasClosed) {
      Haptics.medium();
    }
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
    _bookingsWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Obx(() {
              final screen = RepaintBoundary(
                key: ValueKey(controller.selectedIndex.value),
                child: controller.currentScreen.value,
              );

              if (controller.selectedIndex.value != 0) {
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
            if (controller.selectedIndex.value != 0) {
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
        if (controller.selectedIndex.value != 0) {
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

        return Stack(
          clipBehavior: Clip.none,
          children: [
            FloatingActionButton.extended(
              heroTag: 'home_chat_fab',
              isExtended: !_isHomeScrolling,
              extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
              backgroundColor: Colors.black,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: neonGreen, width: 1.6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(0),
                ),
              ),
              onPressed: _openChatInbox,
              icon: Image.asset(
                'assets/chat.png',
                width: 20,
                height: 20,
                color: neonGreen,
                fit: BoxFit.contain,
              ),
              label: Text(
                'Chat',
                style: GoogleFonts.inter(
                  color: neonGreen,
                  fontWeight: FontWeight.w700,
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
        final bool isShopMenuOpen = controller.isShopOpen.value;
        final int activeShopIndex = shopController.shopMenuIndex.value;

        return Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // --- Bottom Navigation Bar ---
            BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              enableFeedback: true,
              currentIndex: controller.selectedIndex.value,
              onTap: (index) {
                if (index == 2 && HomeController.isHashShopReleased) {
                  if (!isShopMenuOpen) {
                    Haptics.medium();
                  }
                  shopController.setShopMenuIndex(0);
                }
                controller.onItemTapped(index);
              },
              selectedFontSize: 0,
              unselectedFontSize: 0,
              backgroundColor: Colors.black,
              selectedItemColor: const Color(0xff00DC00),
              unselectedItemColor: Colors.grey[800],
              items: <BottomNavigationBarItem>[
                _buildNavigationItem(
                  'assets/navbar_icons/Vector (1).png',
                  isSelected: controller.selectedIndex.value == 0,
                ),
                _buildNavigationItem(
                  'assets/navbar_icons/maki_gaming.png',
                  isSelected: controller.selectedIndex.value == 1,
                ),
                _buildNavigationItem(
                  'assets/navbar_icons/Group.png',
                  isSelected: controller.selectedIndex.value == 2,
                  isSpecial: true,
                ),
                _buildNavigationItem(
                  'assets/navbar_icons/trophy.png',
                  isSelected: controller.selectedIndex.value == 3,
                ),
                _buildNavigationItem(
                  'assets/navbar_icons/Vector (3).png',
                  isSelected: controller.selectedIndex.value == 4,
                ),
              ],
            ),

            // --- Slide-in Hash Shop Bar ---
            if (HomeController.isHashShopReleased)
              Positioned(
                right: 0,
                bottom: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(isShopMenuOpen ? 0 : 24),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
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
                                  Colors.white.withValues(alpha: 0.03),
                                  Colors.black.withValues(alpha: 0.25),
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
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isShopMenuOpen ? 10 : 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (controller.selectedIndex.value == 2 &&
                                    isShopMenuOpen) {
                                  controller.onItemTapped(0);
                                } else {
                                  _openShopSection(0);
                                }
                              },
                              child: Row(
                                children: [
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 220),
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
                                  Text(
                                    isShopMenuOpen ? "HOME" : "HASH\nSHOP",
                                    style: GoogleFonts.orbitron(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              width: isShopMenuOpen
                                  ? (screenWidth - 140).clamp(
                                      0.0,
                                      double.infinity,
                                    )
                                  : 0,
                              margin: EdgeInsets.only(
                                left: isShopMenuOpen ? 8 : 0,
                              ),
                              child: IgnorePointer(
                                ignoring: !isShopMenuOpen,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 180),
                                  opacity: isShopMenuOpen ? 1 : 0,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _shopIcon(
                                        Icons.storefront_rounded,
                                        isActive: activeShopIndex == 0,
                                        onTap: () => _openShopSection(0),
                                      ),
                                      _shopIcon(
                                        Icons.dashboard_customize_rounded,
                                        isActive: activeShopIndex == 1,
                                        onTap: () => _openShopSection(1),
                                      ),
                                      _shopIcon(
                                        Icons.shopping_bag_rounded,
                                        isActive: activeShopIndex == 2,
                                        onTap: () => _openShopSection(2),
                                      ),
                                      _shopIcon(
                                        Icons.receipt_long_rounded,
                                        isActive: activeShopIndex == 3,
                                        onTap: () => _openShopSection(3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
    required bool isSelected,
    bool isSpecial = false,
  }) {
    final selected = controller.selectedIndex.value == 3
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
        label: '',
      );
    }

    return BottomNavigationBarItem(
      backgroundColor: Colors.black,
      icon: AnimatedScale(
        scale: isSelected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Image.asset(
          iconPath,
          height: 22,
          color: isSelected ? selected : unselected,
          colorBlendMode: BlendMode.srcIn,
        ),
      ),
      label: '',
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
        const Color(0xff00DC00).withValues(alpha: 0.22),
        const Color(0xFF7A44C0).withValues(alpha: 0.20),
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
                ? const Color(0xFFA78BFF).withValues(alpha: 0.46)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFFECE3FF) : Colors.white,
          size: isActive ? 21 : 20,
        ),
      ),
    );
  }
}
