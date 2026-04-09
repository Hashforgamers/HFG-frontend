import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/utils/arena_games_extractor.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/arena/views/arena_detail/arena_detail_consoles_section.dart';
import 'package:hash/app/modules/arena/views/arena_detail/arena_detail_header.dart';
import 'package:hash/app/modules/arena/views/arena_detail/arena_detail_info_section.dart';
import 'package:hash/app/modules/arena/views/arena_detail/arena_detail_reviews_section.dart';
import 'package:hash/app/modules/arena/views/booking_screen.dart';
import 'package:hash/app/modules/arena/views/menu_view.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/funnel_notification_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/games_controller.dart';

class ArenaDetailView extends StatefulWidget {
  final String title;
  final String address;
  final String openingHours;
  final List<dynamic> availableGames;
  final List<dynamic> amenities;
  final String phone;
  final String email;
  final String ownerName;
  final List<dynamic> images;
  final int vendorId;
  final List<dynamic> reviews;

  const ArenaDetailView({
    super.key,
    required this.title,
    required this.address,
    required this.openingHours,
    required this.availableGames,
    required this.amenities,
    required this.phone,
    required this.email,
    required this.ownerName,
    required this.reviews,
    required this.vendorId,
    required this.images,
  });

  @override
  State<ArenaDetailView> createState() => _ArenaDetailViewState();
}

class _ArenaDetailViewState extends State<ArenaDetailView> {
  static const Duration _foodAvailabilityCacheTtl = Duration(minutes: 15);
  static final Map<int, bool> _foodAvailabilityCache = <int, bool>{};
  static final Map<int, DateTime> _foodAvailabilityCacheTime =
      <int, DateTime>{};

  late final CafeGamesController _gamesController;
  final RemoteRepoInterface _remoteRepo = locator<RemoteRepoInterface>();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();
  final funnelNotificationService = locator<FunnelNotificationService>();
  late final ConfettiController _squadConfettiController;
  bool? _hasFoodOrderingAvailableCache;
  bool _isBookingFlowLaunching = false;
  final Set<String> _activeModalGuards = <String>{};

  @override
  void initState() {
    super.initState();
    _squadConfettiController = ConfettiController(
      duration: const Duration(milliseconds: 850),
    );
    _gamesController = Get.put(
      CafeGamesController(),
      tag: 'vendor_${widget.vendorId}',
    );
    _gamesController.fetchGames(widget.vendorId, forceRefresh: false);
    _gamesController.fetchPasses(widget.vendorId, forceRefresh: false);

    // Track cafe images viewed event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      funnelNotificationService.trackEvent(
        'cafe_viewed',
        payload: {
          'cafe_id': widget.vendorId.toString(),
          'cafe_name': widget.title,
        },
      );
      segmentService.onCafeImagesViewed(cafeId: widget.vendorId.toString());
      fbEventsService.onCafeImagesViewed(cafeId: widget.vendorId.toString());
      segmentService.onCustomEvent('Cafe Amenities Viewed', {
        'cafe_id': widget.vendorId.toString(),
      });
      fbEventsService.onCafeAmenitiesViewed(cafeId: widget.vendorId.toString());
      segmentService.onCustomEvent('Cafe Timings Viewed', {
        'cafe_id': widget.vendorId.toString(),
      });
      fbEventsService.onCafeTimingsViewed(cafeId: widget.vendorId.toString());
      segmentService.onCustomEvent('Cafe Location Viewed', {
        'cafe_id': widget.vendorId.toString(),
      });
      fbEventsService.onCafeLocationViewed(cafeId: widget.vendorId.toString());
      segmentService.onCustomEvent('Cafe Reviews Viewed', {
        'cafe_id': widget.vendorId.toString(),
      });
      fbEventsService.onCafeReviewsViewed(cafeId: widget.vendorId.toString());
    });
  }

  @override
  void dispose() {
    _squadConfettiController.dispose();
    Get.delete<CafeGamesController>(tag: 'vendor_${widget.vendorId}');
    super.dispose();
  }

  bool _hasFoodAmenity(List<dynamic> amenities) {
    return amenities.any((a) {
      dynamic rawName;
      dynamic rawAvailable = true;

      if (a is Map) {
        rawName =
            a['name'] ??
            a['title'] ??
            a['label'] ??
            a['amenity'] ??
            a['facility'];
        rawAvailable = a['available'] ?? a['is_available'] ?? a['isAvailable'];
      } else {
        rawName = a;
      }

      final available = _truthy(rawAvailable);
      final name = (rawName ?? '')
          .toString()
          .toLowerCase()
          .replaceAll('_', ' ')
          .trim();
      if (name.isEmpty) return false;

      // robust match
      final isFood =
          name == 'food' ||
          name.contains('food') ||
          name.contains('beverage') ||
          name.contains('snack') ||
          name.contains('cafe') ||
          name.contains('kitchen');
      return available && isFood;
    });
  }

  bool _truthy(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return true;
  }

  Future<bool> _hasFoodOrderingAvailable() async {
    final cached = _hasFoodOrderingAvailableCache;
    if (cached != null) return cached;

    final sharedCached = _foodAvailabilityCache[widget.vendorId];
    final sharedCachedAt = _foodAvailabilityCacheTime[widget.vendorId];
    final hasFreshSharedCache =
        sharedCached != null &&
        sharedCachedAt != null &&
        DateTime.now().difference(sharedCachedAt) < _foodAvailabilityCacheTtl;
    if (hasFreshSharedCache) {
      _hasFoodOrderingAvailableCache = sharedCached;
      return sharedCached;
    }

    try {
      final foodMenu = await _remoteRepo.getFoodMenu(
        vendorId: widget.vendorId.toString(),
      );
      final hasItems = foodMenu.categories.any(
        (category) => category.menus?.isNotEmpty ?? false,
      );
      _hasFoodOrderingAvailableCache = hasItems;
      _foodAvailabilityCache[widget.vendorId] = hasItems;
      _foodAvailabilityCacheTime[widget.vendorId] = DateTime.now();
      return hasItems;
    } catch (_) {
      _hasFoodOrderingAvailableCache = false;
      _foodAvailabilityCache[widget.vendorId] = false;
      _foodAvailabilityCacheTime[widget.vendorId] = DateTime.now();
      return false;
    }
  }

  Future<T?> _openModalOnce<T>(
    String key,
    Future<T?> Function() openModal,
  ) async {
    if (_activeModalGuards.contains(key)) {
      debugPrint('Skipping duplicate modal open -> $key');
      return null;
    }

    _activeModalGuards.add(key);
    try {
      return await openModal();
    } finally {
      _activeModalGuards.remove(key);
    }
  }

  Future<void> _startBookingFlow(BuildContext context) async {
    if (_isBookingFlowLaunching) {
      debugPrint('Skipping duplicate booking flow launch');
      return;
    }

    _isBookingFlowLaunching = true;
    try {
      if (!_gamesController.shopOpen.value) {
        segmentService.onCustomEvent('Slot Unavailable', {
          'cafe_id': widget.vendorId.toString(),
          'slot_time': 'shop_closed',
        });
        fbEventsService.onSlotUnavailable(
          cafeId: widget.vendorId.toString(),
          slotTime: 'shop_closed',
        );
        Get.snackbar(
          'Shop Closed',
          'Shop is closed today, no games available.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final hasFood = await _hasFoodOrderingAvailable();
      if (!mounted || !context.mounted) {
        return;
      }

      if (hasFood) {
        final response = await showFoodOrderPrompt(context, () {
          Get.to(
            MenuViewPage(
              vendorId: widget.vendorId.toString(),
              email: widget.email,
              onContinue: (cartItems) {
                if (!mounted || !context.mounted) {
                  return;
                }
                showBookSlotBottomSheet(
                  context: context,
                  email: widget.email,
                  cartItems: cartItems,
                );
              },
            ),
          );
        });

        if (!mounted || !context.mounted) {
          return;
        }

        if (response != true) {
          await showBookSlotBottomSheet(
            context: context,
            email: widget.email,
            cartItems: null,
          );
        }
      } else {
        if (!mounted || !context.mounted) {
          return;
        }
        await showBookSlotBottomSheet(
          context: context,
          email: widget.email,
          cartItems: null,
        );
      }
    } finally {
      _isBookingFlowLaunching = false;
    }
  }

  Future<BookingPartySelection?> _showBookingPartyBottomSheet(
    BuildContext context,
    String consoleType,
  ) {
    final chatService = Get.find<ChatService>();
    final maxSquadSize = _estimateMaxSquadSize(consoleType);
    bool isSquad = false;
    final int minSquadSize = maxSquadSize >= 2 ? 2 : 1;
    int squadCount = minSquadSize;
    List<ChatUserModel> results = const [];
    List<ChatUserModel> selectedMembers = <ChatUserModel>[];
    bool isSearching = false;
    String inlineError = '';
    String queryText = '';

    return _openModalOnce<BookingPartySelection>('booking_party_sheet', () {
      return showModalBottomSheet<BookingPartySelection>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF181818),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              final requiredMembers = isSquad
                  ? (squadCount - 1).clamp(0, 98)
                  : 0;
              final canContinue =
                  !isSquad ||
                  (squadCount >= minSquadSize &&
                      selectedMembers.length == requiredMembers &&
                      selectedMembers.every(_hasUsablePhoneNumber));

              Future<void> runSearch(String value) async {
                final q = value.trim();
                setModalState(() {
                  queryText = value;
                  inlineError = '';
                });

                if (q.length < 2) {
                  setModalState(() {
                    results = const [];
                    isSearching = false;
                  });
                  return;
                }

                setModalState(() {
                  isSearching = true;
                });

                try {
                  final users = await chatService.searchUsers(q, limit: 20);
                  if (!context.mounted) return;
                  setModalState(() {
                    results = users;
                  });
                } catch (_) {
                  if (!context.mounted) return;
                  setModalState(() {
                    inlineError = 'Unable to search players right now.';
                  });
                } finally {
                  if (context.mounted) {
                    setModalState(() {
                      isSearching = false;
                    });
                  }
                }
              }

              return SafeArea(
                top: false,
                child: FractionallySizedBox(
                  heightFactor: isSquad ? 0.92 : 0.56,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Booking type',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Choose solo for the regular flow, or squad to lock the exact number of consoles/PCs you want to book.',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildBookingTypeOption(
                                        label: 'Solo',
                                        subtitle: '1 setup',
                                        isSelected: !isSquad,
                                        onTap: () {
                                          setModalState(() {
                                            isSquad = false;
                                            squadCount = minSquadSize;
                                            selectedMembers = <ChatUserModel>[];
                                            results = const [];
                                            queryText = '';
                                            inlineError = '';
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildBookingTypeOption(
                                        label: 'Squad',
                                        subtitle: '$maxSquadSize max',
                                        isSelected: isSquad,
                                        onTap: () {
                                          setModalState(() {
                                            isSquad = true;
                                            if (squadCount < minSquadSize) {
                                              squadCount = minSquadSize;
                                            }
                                          });
                                          _squadConfettiController
                                            ..stop()
                                            ..play();
                                        },
                                        showEliteFx: true,
                                        confettiController:
                                            _squadConfettiController,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isSquad) ...[
                                  const SizedBox(height: 18),
                                  Text(
                                    'Number of setups needed',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Select from $minSquadSize to $maxSquadSize based on the maximum consoles available at one time.',
                                    style: GoogleFonts.inter(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF232323),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildCounterButton(
                                          icon: Icons.remove,
                                          enabled: squadCount > minSquadSize,
                                          onTap: () {
                                            if (squadCount <= minSquadSize) {
                                              return;
                                            }
                                            setModalState(() {
                                              squadCount -= 1;
                                              final nextRequired =
                                                  (squadCount - 1).clamp(0, 98);
                                              if (selectedMembers.length >
                                                  nextRequired) {
                                                selectedMembers =
                                                    selectedMembers
                                                        .take(nextRequired)
                                                        .toList();
                                              }
                                            });
                                          },
                                        ),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Text(
                                                '$squadCount',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                'Required setups',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white60,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _buildCounterButton(
                                          icon: Icons.add,
                                          enabled: squadCount < maxSquadSize,
                                          onTap: () {
                                            if (squadCount >= maxSquadSize)
                                              return;
                                            setModalState(() {
                                              squadCount += 1;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF171717),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xff00DC00,
                                                ).withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.person_search_rounded,
                                                color: Color(0xff00DC00),
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Squad Members',
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    requiredMembers == 0
                                                        ? 'Only you are included in this squad right now.'
                                                        : 'Add $requiredMembers player${requiredMembers == 1 ? '' : 's'} for this booking. You are included automatically.',
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white60,
                                                      fontSize: 11,
                                                      height: 1.35,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.06,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                '${selectedMembers.length}/$requiredMembers',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(1),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xff2E2E2E),
                                                Color(0xff3D3D3D),
                                              ],
                                            ),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF111111),
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                            ),
                                            child: TextField(
                                              onChanged: runSearch,
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                              decoration: const InputDecoration(
                                                hintText:
                                                    'Search username/email',
                                                hintStyle: TextStyle(
                                                  color: Colors.white54,
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.search,
                                                  color: Colors.white70,
                                                ),
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (selectedMembers.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: selectedMembers.map((
                                              user,
                                            ) {
                                              final safePhotoUrl =
                                                  _safePhotoUrl(user);
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.06),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                  border: Border.all(
                                                    color: Colors.white10,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 12,
                                                      backgroundImage:
                                                          safePhotoUrl != null
                                                          ? NetworkImage(
                                                              safePhotoUrl,
                                                            )
                                                          : null,
                                                      backgroundColor:
                                                          Colors.white12,
                                                      child:
                                                          safePhotoUrl == null
                                                          ? Text(
                                                              _initialsForUser(
                                                                user,
                                                              ),
                                                              style: GoogleFonts.inter(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            )
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      user.displayName,
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    GestureDetector(
                                                      onTap: () {
                                                        setModalState(() {
                                                          selectedMembers =
                                                              selectedMembers
                                                                  .where(
                                                                    (member) =>
                                                                        member
                                                                            .uid !=
                                                                        user.uid,
                                                                  )
                                                                  .toList();
                                                        });
                                                      },
                                                      child: const Icon(
                                                        Icons.close_rounded,
                                                        size: 16,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                        if (inlineError.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.red.withValues(
                                                  alpha: 0.25,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              inlineError,
                                              style: GoogleFonts.inter(
                                                color: Colors.red.shade200,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          height: 220,
                                          child: requiredMembers == 0
                                              ? Center(
                                                  child: Text(
                                                    'Increase squad size to add squad members.',
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white54,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                )
                                              : isSearching
                                              ? const Center(
                                                  child: SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.4,
                                                          color: Color(
                                                            0xff00DC00,
                                                          ),
                                                        ),
                                                  ),
                                                )
                                              : results.isEmpty
                                              ? Center(
                                                  child: Text(
                                                    queryText.trim().length < 2
                                                        ? 'Type at least 2 letters to search'
                                                        : 'No players found',
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white60,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                )
                                              : ListView.separated(
                                                  itemCount: results.length,
                                                  separatorBuilder: (_, _) =>
                                                      const SizedBox(height: 8),
                                                  itemBuilder: (_, index) {
                                                    final user = results[index];
                                                    final safePhotoUrl =
                                                        _safePhotoUrl(user);
                                                    final isSelectedMember =
                                                        selectedMembers.any(
                                                          (member) =>
                                                              member.uid ==
                                                              user.uid,
                                                        );
                                                    final canSelectMore =
                                                        selectedMembers.length <
                                                        requiredMembers;

                                                    return Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFF111111,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        border: Border.all(
                                                          color:
                                                              isSelectedMember
                                                              ? const Color(
                                                                  0xff00DC00,
                                                                )
                                                              : Colors.white10,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 20,
                                                            backgroundImage:
                                                                safePhotoUrl !=
                                                                    null
                                                                ? NetworkImage(
                                                                    safePhotoUrl,
                                                                  )
                                                                : null,
                                                            backgroundColor:
                                                                Colors.white12,
                                                            child:
                                                                safePhotoUrl ==
                                                                    null
                                                                ? Text(
                                                                    _initialsForUser(
                                                                      user,
                                                                    ),
                                                                    style: GoogleFonts.inter(
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                  )
                                                                : null,
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  user.displayName,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: GoogleFonts.inter(
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 2,
                                                                ),
                                                                Text(
                                                                  user
                                                                          .username
                                                                          .isNotEmpty
                                                                      ? '@${user.username}'
                                                                      : user.email,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: GoogleFonts.inter(
                                                                    color: Colors
                                                                        .white70,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          ElevatedButton(
                                                            onPressed:
                                                                isSelectedMember ||
                                                                    !canSelectMore
                                                                ? null
                                                                : () async {
                                                                    var memberToAdd =
                                                                        user;
                                                                    if (!_hasUsablePhoneNumber(
                                                                      user,
                                                                    )) {
                                                                      final phoneNumber =
                                                                          await _showMemberPhoneBottomSheet(
                                                                            context,
                                                                            user,
                                                                          );
                                                                      if (phoneNumber ==
                                                                              null ||
                                                                          phoneNumber
                                                                              .trim()
                                                                              .isEmpty) {
                                                                        return;
                                                                      }
                                                                      memberToAdd = _copyUserWithPhone(
                                                                        user,
                                                                        phoneNumber
                                                                            .trim(),
                                                                      );
                                                                    }
                                                                    setModalState(() {
                                                                      selectedMembers = [
                                                                        ...selectedMembers,
                                                                        memberToAdd,
                                                                      ];
                                                                      inlineError =
                                                                          '';
                                                                    });
                                                                  },
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  const Color(
                                                                    0xff00DC00,
                                                                  ),
                                                              foregroundColor:
                                                                  Colors.black,
                                                              disabledBackgroundColor:
                                                                  Colors
                                                                      .white10,
                                                              disabledForegroundColor:
                                                                  Colors
                                                                      .white38,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      10,
                                                                    ),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              isSelectedMember
                                                                  ? 'Added'
                                                                  : 'Add',
                                                              style: GoogleFonts.inter(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: canContinue
                                ? () {
                                    Navigator.of(context).pop(
                                      BookingPartySelection(
                                        isSquad: isSquad,
                                        requiredConsoleCount: isSquad
                                            ? squadCount
                                            : 1,
                                        selectedMembers: selectedMembers,
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff00DC00),
                              disabledBackgroundColor: Colors.grey.shade800,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Continue',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    });
  }

  Widget _buildBookingTypeOption({
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    bool showEliteFx = false,
    ConfettiController? confettiController,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected && showEliteFx
              ? const LinearGradient(
                  colors: [
                    Color(0xFF120F2A),
                    Color(0xFF2A1D68),
                    Color(0xFF0E7CFF),
                    Color(0xFF7CF3FF),
                  ],
                  stops: [0.0, 0.34, 0.72, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? (showEliteFx
                    ? null
                    : const Color(0xFF00DC00).withValues(alpha: 0.14))
              : const Color(0xFF232323),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (showEliteFx
                      ? const Color(0xFF9FE7FF)
                      : const Color(0xff00DC00))
                : Colors.white12,
            width: 1.4,
          ),
          boxShadow: isSelected && showEliteFx
              ? [
                  BoxShadow(
                    color: const Color(0xFF0E7CFF).withValues(alpha: 0.22),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: const Color(0xFF7CF3FF).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (showEliteFx && isSelected && confettiController != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ConfettiWidget(
                      confettiController: confettiController,
                      blastDirectionality: BlastDirectionality.directional,
                      blastDirection: math.pi / 2,
                      shouldLoop: false,
                      emissionFrequency: 0.065,
                      numberOfParticles: 14,
                      maxBlastForce: 7,
                      minBlastForce: 3,
                      gravity: 0.18,
                      particleDrag: 0.05,
                      minimumSize: const Size(3, 5),
                      maximumSize: const Size(5, 8),
                      colors: const [
                        Color(0xFFEFFCFF),
                        Color(0xFF9FE7FF),
                        Color(0xFF4CB8FF),
                        Color(0xFF7D7BFF),
                        Color(0xFFFFFFFF),
                      ],
                    ),
                  ),
                ),
              ),
            if (showEliteFx && isSelected)
              Positioned(
                top: -1,
                left: 18,
                right: 18,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (showEliteFx && isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0B1022,
                          ).withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          'Elite',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: isSelected && showEliteFx
                        ? Colors.white.withValues(alpha: 0.96)
                        : Colors.white60,
                    fontSize: 12,
                    fontWeight: isSelected && showEliteFx
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initialsForUser(ChatUserModel user) {
    final source = user.displayName.trim().isNotEmpty
        ? user.displayName.trim()
        : (user.username.trim().isNotEmpty ? user.username.trim() : 'P');
    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String? _safePhotoUrl(ChatUserModel user) {
    final raw = user.photoUrl.trim();
    if (raw.isEmpty) return null;

    final normalized = raw.toLowerCase();
    if (normalized == 'not defined' ||
        normalized == 'undefined' ||
        normalized == 'null' ||
        normalized == 'n/a') {
      return null;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return null;
    }

    return raw;
  }

  bool _hasUsablePhoneNumber(ChatUserModel user) {
    final normalized = user.phoneNumber.trim().replaceAll(RegExp(r'\s+'), '');
    return normalized.isNotEmpty &&
        normalized.toLowerCase() != 'not defined' &&
        normalized.toLowerCase() != 'undefined' &&
        normalized.toLowerCase() != 'null';
  }

  ChatUserModel _copyUserWithPhone(ChatUserModel user, String phoneNumber) {
    return ChatUserModel(
      uid: user.uid,
      displayName: user.displayName,
      username: user.username,
      email: user.email,
      phoneNumber: phoneNumber,
      photoUrl: user.photoUrl,
      backendUserId: user.backendUserId,
      isOnline: user.isOnline,
      updatedAt: user.updatedAt,
      lastSeenAt: user.lastSeenAt,
    );
  }

  Future<String?> _showMemberPhoneBottomSheet(
    BuildContext context,
    ChatUserModel user,
  ) {
    final controller = TextEditingController();
    String? errorText;

    return _openModalOnce<String>('member_phone_sheet', () {
      return showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF181818),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
              return SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 20 + bottomInset),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Add ${user.displayName}\'s phone number',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                      Text(
                        'This is required to add them to the squad booking.',
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: controller,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter phone number',
                          hintStyle: const TextStyle(color: Colors.white38),
                          errorText: errorText,
                          filled: true,
                          fillColor: const Color(0xFF111111),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            final raw = controller.text.trim();
                            final normalized = raw.replaceAll(
                              RegExp(r'[^0-9+]'),
                              '',
                            );
                            if (normalized.length < 10) {
                              setSheetState(() {
                                errorText =
                                    'Enter a valid phone number to continue.';
                              });
                              return;
                            }
                            Navigator.of(sheetContext).pop(normalized);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff00DC00),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Save & Add Member',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    });
  }

  Widget _buildCounterButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled ? const Color(0xFF121212) : const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 42,
          width: 42,
          child: Icon(icon, color: enabled ? Colors.white : Colors.white24),
        ),
      ),
    );
  }

  int _estimateMaxSquadSize([String? forConsoleType]) {
    int maxAvailable = 1;
    final normalizedTargetConsole = forConsoleType == null
        ? ''
        : _normalizeConsoleType(forConsoleType);

    int? asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value == null) return null;
      return int.tryParse(value.toString());
    }

    int availabilityCount(dynamic value, {int fallback = 1}) {
      if (value is bool) return value ? 1 : 0;
      if (value is num) return value.toInt();
      if (value is String) {
        final raw = value.trim().toLowerCase();
        if (raw == 'true' || raw == 'yes') return 1;
        if (raw == 'false' || raw == 'no') return 0;
        return int.tryParse(raw) ?? fallback;
      }
      return fallback;
    }

    dynamic readAny(Map<String, dynamic> map, List<String> keys) {
      for (final key in keys) {
        if (map.containsKey(key) && map[key] != null) {
          return map[key];
        }
      }
      return null;
    }

    for (final rawGame in _gamesController.games) {
      if (rawGame is! Map) continue;
      final game = Map<String, dynamic>.from(rawGame);
      final normalizedConsoleType = _normalizeConsoleType(
        (readAny(game, [
                  'console_type',
                  'consoleType',
                  'type',
                  'game_name',
                  'name',
                  'title',
                ]) ??
                '')
            .toString(),
      );
      if (normalizedTargetConsole.isNotEmpty &&
          normalizedConsoleType != normalizedTargetConsole) {
        continue;
      }
      final fallbackCount =
          asInt(
            readAny(game, ['available_slot', 'available_slots', 'count']),
          ) ??
          asInt(game['total_slots']) ??
          1;
      final consoles = game['consoles'];

      if (consoles is List && consoles.isNotEmpty) {
        for (final rawConsole in consoles) {
          if (rawConsole is! Map) continue;
          final console = Map<String, dynamic>.from(rawConsole);
          final count = availabilityCount(
            readAny(console, [
                  'available_slot',
                  'available_slots',
                  'available_count',
                  'available',
                  'count',
                  'quantity',
                ]) ??
                fallbackCount,
            fallback: fallbackCount,
          );
          if (count > maxAvailable) {
            maxAvailable = count;
          }
        }
        continue;
      }

      if (fallbackCount > maxAvailable) {
        maxAvailable = fallbackCount;
      }
    }

    return maxAvailable.clamp(1, 99);
  }

  Widget _buildPassesSection() {
    return Obx(() {
      final passes = _gamesController.passes;
      if (_gamesController.isPassesLoading.value || passes.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passes',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...passes.map(
            (p) => _PassCard(
              name: p.name ?? 'Pass',
              price: (p.price ?? 0).toDouble(),
              totalHours: p.totalHour ?? 0,
              daysValid: p.daysValid ?? 0,
              description: p.description ?? '',
            ),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasFood = _hasFoodAmenity(widget.amenities);

    final List<String> imageUrls = widget.images
        .map((image) => image['url']?.toString() ?? '')
        .toList()
        .cast<String>();

    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              ArenaDetailHeader(
                imageUrls: imageUrls,
                onBack: () => Navigator.of(context).pop(),
                onShare: () {
                  final shareText =
                      '${widget.title}\n${widget.address}\nCheck it out on Hash Hub.';
                  Share.share(shareText);
                  segmentService.onCustomEvent('Cafe Shared', {
                    'cafe_id': widget.vendorId.toString(),
                    'channel': 'system_share',
                  });
                  fbEventsService.onCafeShared(
                    cafeId: widget.vendorId.toString(),
                    channel: 'system_share',
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ArenaDetailInfoSection(
                      title: widget.title,
                      address: widget.address,
                      openingHours: widget.openingHours,
                    ),
                    const SizedBox(height: 24),
                    ArenaDetailConsolesSection(
                      isLoading: _gamesController.isLoading,
                      games: _gamesController.games,
                    ),
                    const SizedBox(height: 24),
                    _buildPassesSection(),
                    const SizedBox(height: 24),
                    gameTitlesGrid(_gamesController),
                    const SizedBox(height: 24),
                    amenitiesGrid(widget.amenities, excludeFood: hasFood),
                    if (hasFood) ...[
                      const SizedBox(height: 24),
                      foodAndBeverageGrid([
                        {
                          'name': 'Crispy Fries',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075186/menu1_ar0hbe.png',
                        },
                        {
                          'name': 'Veggie Burger',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075187/menu2_go9rv3.png',
                        },
                        {
                          'name': 'Red Sauce Pasta',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075188/menu3_o2c0zy.png',
                        },
                        {
                          'name': 'Protein Sandwich',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075189/menu4_wgmjrq.png',
                        },
                        {
                          'name': 'Hot Coffee',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075190/menu5_f3t2l0.png',
                        },
                        {
                          'name': 'Coca Cola with Ice',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075190/menu6_qhoalw.png',
                        },
                        {
                          'name': 'Blue Lagoon',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075191/menu7_tj4lp1.png',
                        },
                        {
                          'name': 'Choco Pastry',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075192/menu8_na7k6n.png',
                        },
                        {
                          'name': 'Classic Donut',
                          'image':
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075193/menu9_xlmk0e.png',
                        },
                      ]),
                    ],

                    const SizedBox(height: 24),

                    ArenaDetailReviewsSection(
                      vendorId: widget.vendorId,
                      initialReviews: widget.reviews,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
          // Book Slot Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: GetX<CafeGamesController>(
                init: _gamesController,
                builder: (controller) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _startBookingFlow(context);
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.shopOpen.value
                            ? const Color(0xff00DC00)
                            : Colors.grey.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        controller.shopOpen.value
                            ? 'Continue Booking'
                            : 'Shop Closed',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> showFoodOrderPrompt(
    BuildContext context,
    VoidCallback onYes,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFF181818),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 60,
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl:
                                'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075193/menu9_xlmk0e.png',
                            width: 70,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      SizedBox(
                        width: 70,
                        height: 60,
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl:
                                'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075189/menu4_wgmjrq.png',
                            width: 70,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      SizedBox(
                        width: 70,
                        height: 60,
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl:
                                'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075187/menu2_go9rv3.png',
                            width: 70,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "Want to order ahead \nfrom the café?",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context, true); // Return true for "Yes"
                          onYes(); // Callback for "Yes"
                        },
                        child: Container(
                          height: 40,
                          width: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Color(0xff00DC00),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              "Yes, please",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => Navigator.pop(
                          context,
                          false,
                        ), // Return false for "No"
                        child: Container(
                          height: 40,
                          width: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white24,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              "No, thanks",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<dynamic> showBookSlotBottomSheet({
    required BuildContext context,
    required email,
    List<Map<String, dynamic>>? cartItems,
  }) async {
    return _openModalOnce<dynamic>('book_slot_sheet', () async {
      final safeEmail = (email ?? widget.email).toString();
      segmentService.onCustomEvent('Cafe Slot Viewed', {
        'cafe_id': widget.vendorId.toString(),
        'slot_time': 'all',
      });
      fbEventsService.onCafeSlotViewed(
        cafeId: widget.vendorId.toString(),
        slotTime: 'all',
      );
      // Check if shop is open before showing booking options.
      if (!_gamesController.shopOpen.value) {
        Get.snackbar(
          'Shop Closed',
          'Shop is closed today, no games available.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
        return Future.value(null);
      }

      // If user taps quickly before initial fetch completes, refresh once.
      if (_gamesController.games.isEmpty || _gamesController.isLoading.value) {
        await _gamesController.fetchGames(widget.vendorId, forceRefresh: false);
        if (!context.mounted) {
          return Future.value(null);
        }
      }

      int? asInt(dynamic v) {
        if (v is int) return v;
        if (v is num) return v.toInt();
        if (v == null) return null;
        return int.tryParse(v.toString());
      }

      double asDouble(dynamic v) {
        if (v is double) return v;
        if (v is int) return v.toDouble();
        return double.tryParse(v?.toString() ?? '') ?? 0;
      }

      dynamic readAny(Map<String, dynamic> map, List<String> keys) {
        for (final key in keys) {
          if (map.containsKey(key) && map[key] != null) {
            return map[key];
          }
        }
        return null;
      }

      int availabilityCount(dynamic v, {int fallback = 1}) {
        if (v is bool) return v ? 1 : 0;
        if (v is num) return v.toInt();
        if (v is String) {
          final raw = v.trim().toLowerCase();
          if (raw == 'true' || raw == 'yes') return 1;
          if (raw == 'false' || raw == 'no') return 0;
          return int.tryParse(raw) ?? fallback;
        }
        return fallback;
      }

      final Map<String, List<Map<String, dynamic>>> gamesByConsole = {};

      void upsertGame({
        required String gameName,
        required String genre,
        required String imageUrl,
        required String rawConsoleType,
        required int bookingId,
        required double price,
        required int availableCount,
      }) {
        final consoleType = _normalizeConsoleType(rawConsoleType);
        if (consoleType.isEmpty) return;
        final list = gamesByConsole.putIfAbsent(consoleType, () => []);
        final existingIndex = list.indexWhere(
          (item) => item['game_id'] == bookingId && item['title'] == gameName,
        );
        if (existingIndex >= 0) {
          list[existingIndex]['available'] =
              (list[existingIndex]['available'] as int? ?? 0) + availableCount;
          if ((list[existingIndex]['price'] as double? ?? 0) <= 0 &&
              price > 0) {
            list[existingIndex]['price'] = price;
          }
          return;
        }

        list.add({
          'title': gameName.isEmpty
              ? _consoleDisplayLabel(consoleType)
              : gameName,
          'genre': genre,
          'image_url': imageUrl,
          'console_type': consoleType,
          'game_id': bookingId,
          'price': price,
          'available': availableCount,
        });
      }

      for (final g in _gamesController.games) {
        if (g is! Map) continue;
        final gameMap = Map<String, dynamic>.from(g);
        final gameName =
            (readAny(gameMap, ['game_name', 'name', 'title']) ?? '')
                .toString()
                .trim();
        final genre = (gameMap['genre'] ?? '').toString().trim();
        final imageUrl =
            (readAny(gameMap, [
                      'image_url',
                      'game_image',
                      'game_image_url',
                      'image',
                    ]) ??
                    '')
                .toString()
                .trim();
        final fallbackPrice = asDouble(
          readAny(gameMap, [
            'single_slot_price',
            'avg_price',
            'price_per_hour',
          ]),
        );
        final fallbackBookingId = asInt(
          readAny(gameMap, [
            'booking_game_id',
            'bookingGameId',
            'vendor_game_id',
            'vendorGameId',
            'game_id',
            'id',
          ]),
        );

        final gameConsoles = gameMap['consoles'];
        if (gameConsoles is List && gameConsoles.isNotEmpty) {
          for (final c in gameConsoles) {
            if (c is! Map) continue;
            final consoleMap = Map<String, dynamic>.from(c);
            final rawConsoleType =
                (readAny(consoleMap, ['console_type', 'consoleType', 'type']) ??
                        readAny(gameMap, ['game_platform', 'platform']) ??
                        'pc')
                    .toString();
            final bookingId =
                asInt(
                  readAny(consoleMap, [
                    'booking_game_id',
                    'bookingGameId',
                    'vendor_game_id',
                    'vendorGameId',
                    'game_id',
                    'id',
                  ]),
                ) ??
                fallbackBookingId;
            if (bookingId == null) continue;
            final price = asDouble(
              readAny(consoleMap, ['price_per_hour']) ?? fallbackPrice,
            );
            final available = availabilityCount(
              readAny(consoleMap, ['is_available', 'available']) ?? true,
            );
            upsertGame(
              gameName: gameName,
              genre: genre,
              imageUrl: imageUrl,
              rawConsoleType: rawConsoleType,
              bookingId: bookingId,
              price: price,
              availableCount: available,
            );
          }
          continue;
        }

        final fallbackConsoleType =
            (readAny(gameMap, [
                      'console_type',
                      'consoleType',
                      'type',
                      'game_platform',
                      'platform',
                    ]) ??
                    '')
                .toString();
        if (fallbackConsoleType.isEmpty || fallbackBookingId == null) {
          continue;
        }
        final fallbackAvailable = availabilityCount(
          readAny(gameMap, ['is_available', 'available']) ??
              gameMap['total_slots'],
          fallback: asInt(gameMap['total_slots']) ?? 1,
        );
        upsertGame(
          gameName: gameName,
          genre: genre,
          imageUrl: imageUrl,
          rawConsoleType: fallbackConsoleType,
          bookingId: fallbackBookingId,
          price: fallbackPrice,
          availableCount: fallbackAvailable,
        );
      }

      final List<Map<String, dynamic>> consoleOptions = [];
      for (final entry in gamesByConsole.entries) {
        final games = entry.value;
        if (games.isEmpty) continue;
        var totalAvailable = 0;
        double minPrice = 0;
        for (final game in games) {
          final available = game['available'] as int? ?? 0;
          final price = game['price'] as double? ?? 0;
          totalAvailable += available;
          if (price > 0 && (minPrice == 0 || price < minPrice)) {
            minPrice = price;
          }
        }

        final primaryBookingGame = games
            .cast<Map<String, dynamic>?>()
            .firstWhere(
              (game) => (game?['available'] as int? ?? 0) > 0,
              orElse: () => games.first,
            );

        consoleOptions.add({
          'type': entry.key,
          'label': _consoleDisplayLabel(entry.key),
          'icon': _getConsoleIcon(entry.key),
          'total_available': totalAvailable,
          'starting_price': minPrice,
          'booking_game_id': primaryBookingGame?['game_id'],
        });
      }

      consoleOptions.sort((a, b) {
        final aAvailable = a['total_available'] as int? ?? 0;
        final bAvailable = b['total_available'] as int? ?? 0;
        if (aAvailable != bAvailable) return bAvailable.compareTo(aAvailable);
        return (a['label'] as String).compareTo(b['label'] as String);
      });

      int selectedIndex = 0;
      for (int i = 0; i < consoleOptions.length; i++) {
        if ((consoleOptions[i]['total_available'] as int? ?? 0) > 0) {
          selectedIndex = i;
          break;
        }
      }

      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF181818),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              final double maxHeight = MediaQuery.of(context).size.height * 0.5;
              final bool canContinue = consoleOptions.isNotEmpty;
              return SafeArea(
                top: false,
                child: Padding(
                  padding: MediaQuery.of(context).viewInsets,
                  child: SizedBox(
                    height: maxHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Choose console type',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (consoleOptions.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF232323),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'No console types available right now.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (consoleOptions.isNotEmpty)
                            Expanded(
                              child: GridView.builder(
                                itemCount: consoleOptions.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 1.65,
                                    ),
                                itemBuilder: (context, index) {
                                  final option = consoleOptions[index];
                                  final isSelected = selectedIndex == index;
                                  final totalAvailable =
                                      option['total_available'] as int? ?? 0;
                                  final startPrice =
                                      option['starting_price'] as double? ?? 0;
                                  final hasAvailable = totalAvailable > 0;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedIndex = index;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(
                                                0xFF00DC00,
                                              ).withValues(alpha: 0.16)
                                            : const Color(0xFF232323),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xff00DC00)
                                              : Colors.white12,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Builder(
                                                builder: (context) {
                                                  final iconUrl =
                                                      (option['icon'] ?? '')
                                                          .toString();
                                                  final fallbackIcon =
                                                      _getConsoleFallbackIcon(
                                                        (option['type'] ?? '')
                                                            .toString(),
                                                      );
                                                  if (iconUrl.isEmpty) {
                                                    return Icon(
                                                      fallbackIcon,
                                                      color: Colors.white70,
                                                      size: 20,
                                                    );
                                                  }
                                                  return CachedNetworkImage(
                                                    imageUrl: iconUrl,
                                                    height: 24,
                                                    width: 24,
                                                    placeholder: (_, _) =>
                                                        const SizedBox(
                                                          height: 16,
                                                          width: 16,
                                                          child:
                                                              RainbowGlowingLoader(
                                                                size: 10,
                                                              ),
                                                        ),
                                                    errorWidget: (_, _, _) =>
                                                        Icon(
                                                          fallbackIcon,
                                                          color: Colors.white70,
                                                          size: 20,
                                                        ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  (option['label'] ?? '')
                                                      .toString(),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Text(
                                            totalAvailable == 1
                                                ? '1 setup available'
                                                : '$totalAvailable setups available',
                                            style: GoogleFonts.inter(
                                              color: hasAvailable
                                                  ? Colors.white70
                                                  : Colors.redAccent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (startPrice > 0) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Starts at ₹${startPrice.toStringAsFixed(startPrice % 1 == 0 ? 0 : 1)}/hr',
                                              style: GoogleFonts.inter(
                                                color: Colors.white70,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: canContinue
                                  ? () async {
                                      final selectedConsole =
                                          consoleOptions[selectedIndex];
                                      final selectedType =
                                          (selectedConsole['type'] ?? '')
                                              .toString();
                                      final selectedGameId = asInt(
                                        selectedConsole['booking_game_id'],
                                      );
                                      Navigator.of(context).pop();
                                      if (!mounted) return;
                                      await Future.delayed(
                                        const Duration(milliseconds: 140),
                                      );
                                      if (!mounted) return;
                                      if (selectedGameId == null) {
                                        _showSafeErrorSnackBar(
                                          this.context,
                                          'No booking option found for this console.',
                                        );
                                        return;
                                      }
                                      int requiredConsoleCount = 1;
                                      String bookingModeLabel = 'solo';
                                      List<ChatUserModel> selectedSquadMembers =
                                          const <ChatUserModel>[];

                                      if (_normalizeConsoleType(selectedType) ==
                                          'pc') {
                                        final bookingSelection =
                                            await _showBookingPartyBottomSheet(
                                              this.context,
                                              selectedType,
                                            );
                                        if (!mounted ||
                                            bookingSelection == null) {
                                          return;
                                        }
                                        requiredConsoleCount = bookingSelection
                                            .requiredConsoleCount;
                                        bookingModeLabel =
                                            bookingSelection.isSquad
                                            ? 'squad'
                                            : 'solo';
                                        selectedSquadMembers =
                                            bookingSelection.selectedMembers;
                                      }

                                      if (!mounted) return;
                                      Navigator.of(this.context).push(
                                        MaterialPageRoute(
                                          builder: (_) => BookingScreen(
                                            email: safeEmail,
                                            consoleType: _getConsoleType(
                                              selectedType,
                                            ),
                                            title: widget.title,
                                            gameId: selectedGameId,
                                            vendorId: widget.vendorId,
                                            cartItems: cartItems ?? [],
                                            isSquadBooking:
                                                bookingModeLabel == 'squad',
                                            requiredConsoleCount:
                                                requiredConsoleCount,
                                            selectedSquadMembers:
                                                selectedSquadMembers,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff00DC00),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                disabledBackgroundColor: Colors.grey.shade800,
                              ),
                              child: Text(
                                'Continue to Booking',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    });
  }

  String _normalizeConsoleType(String consoleName) {
    final name = consoleName
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
    if (name.isEmpty) return '';
    if (name.contains('playstation') || name.contains('ps')) return 'ps5';
    if (name.contains('xbox')) return 'xbox';
    if (name.contains('vr') || name.contains('virtual')) return 'vr_headset';
    if (name.contains('nintendo') || name.contains('switch')) {
      return 'nintendo_switch';
    }
    if (name.contains('steam') || name.contains('deck')) return 'steam_deck';
    if (name.contains('arcade')) return 'arcade_cabinet';
    if (name.contains('racing') || name.contains('rig')) return 'racing_rig';
    if (name.contains('simulator')) return 'simulator';
    if (name.contains('private') && name.contains('room')) {
      return 'private_room';
    }
    if (name.contains('vip') && name.contains('room')) return 'vip_room';
    if (name.contains('bootcamp') && name.contains('room')) {
      return 'bootcamp_room';
    }
    if (name.contains('pc') || name.contains('computer')) return 'pc';
    return name.replaceAll(' ', '_');
  }

  String _consoleDisplayLabel(String consoleName) {
    switch (_normalizeConsoleType(consoleName)) {
      case 'ps5':
        return 'PS5';
      case 'xbox':
        return 'XBOX';
      case 'vr_headset':
        return 'VR';
      case 'nintendo_switch':
        return 'NINTENDO SWITCH';
      case 'steam_deck':
        return 'STEAM DECK';
      case 'arcade_cabinet':
        return 'ARCADE CABINET';
      case 'racing_rig':
        return 'RACING RIG';
      case 'simulator':
        return 'SIMULATOR';
      case 'private_room':
        return 'PRIVATE ROOM';
      case 'vip_room':
        return 'VIP ROOM';
      case 'bootcamp_room':
        return 'BOOTCAMP ROOM';
      case 'pc':
        return 'PC';
      default:
        return consoleName.replaceAll('_', ' ').toUpperCase();
    }
  }

  void _showSafeErrorSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final fallbackContext = Get.context;
    if (fallbackContext != null && Overlay.maybeOf(fallbackContext) != null) {
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    debugPrint('Unable to show snackbar: $message');
  }

  Widget rowInfo(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 18, color: Colors.white70),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, style: GoogleFonts.inter(color: Colors.white70)),
      ),
    ],
  );

  Widget infoCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xff181818),
      border: Border.all(color: const Color(0xff2D2D2D)),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget sectionChip(
    String title,
    List<dynamic> items, {
    bool includeIcon = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .where((item) {
              // For amenities, check if available is true
              if (includeIcon && item is Map) {
                return item['available'] == true;
              }
              return true; // For other items, show all
            })
            .map(
              (item) => Chip(
                label: includeIcon
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getAmenityIcon(
                              item is Map
                                  ? item['name']?.toString() ?? ''
                                  : item.toString(),
                            ),
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item is Map
                                ? item['name']?.toString() ?? 'Unknown'
                                : item.toString(),
                            style: GoogleFonts.inter(color: Colors.white),
                          ),
                        ],
                      )
                    : Text(
                        item is Map
                            ? item['name']?.toString() ?? 'Unknown'
                            : item.toString(),
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                backgroundColor: const Color(0xff0E0E0E),
                side: const BorderSide(color: Color(0xff2D2D2D)),
              ),
            )
            .toList(),
      ),
    ],
  );

  Widget gameTitlesGrid(CafeGamesController controller) {
    const placeholderImage =
        'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075080/pc_ah5ulv.png';

    bool _looksLikeConsoleLabel(String value) {
      final v = value
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[_-]+'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ');
      if (v.isEmpty) return true;
      const invalidLabels = <String>{
        'n/a',
        'na',
        'none',
        'null',
        'unknown',
        '-',
      };
      if (invalidLabels.contains(v)) return true;
      const blocked = <String>{
        'pc',
        'pcs',
        'gaming pc',
        'gaming pcs',
        'pc setup',
        'pc setups',
        'xbox',
        'xbox one',
        'xbox series',
        'xbox series s',
        'xbox series x',
        'playstation',
        'play station',
        'playstation 4',
        'playstation 5',
        'ps',
        'ps4',
        'ps5',
        'vr',
        'vr headset',
        'virtual reality',
      };
      if (blocked.contains(v)) return true;
      const blockedKeywords = <String>[
        'playstation',
        'play station',
        'xbox',
        'gaming pc',
        'pc setup',
        'pc station',
        'console setup',
        'nintendo switch',
        'switch console',
        'steam deck',
        'arcade',
        'racing rig',
        'simulator',
        'vip room',
        'private room',
        'bootcamp room',
      ];
      if (blockedKeywords.any(v.contains)) return true;
      if (v.startsWith('ps') && v.length <= 4) return true;
      if (v.endsWith(' console')) return true;
      if (v.endsWith(' setup')) return true;
      return false;
    }

    String _gameName(Map<String, dynamic> game) {
      final candidates = [
        game['game_name'],
        game['name'],
        game['title'],
        game['gameTitle'],
      ];
      for (final c in candidates) {
        final name = (c ?? '').toString().trim();
        if (name.isEmpty) continue;
        if (_looksLikeConsoleLabel(name)) continue;
        return name;
      }
      return '';
    }

    String _gameImage(Map<String, dynamic> game) {
      final orderedKeys = [
        'image_url',
        'image',
        'game_image',
        'game_image_url',
        'thumbnail',
        'cover',
        'logo',
      ];
      for (final key in orderedKeys) {
        final v = game[key];
        if (v is String && v.trim().isNotEmpty) return v;
      }
      return placeholderImage;
    }

    return Obx(() {
      if (controller.isLoading.value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Available Games",
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            const SizedBox(
              height: 160,
              child: Center(child: AppLinearLoader()),
            ),
          ],
        );
      }

      final List<Map<String, String>> displayGames = [];

      for (final item in controller.games) {
        if (item is! Map) continue;
        final game = Map<String, dynamic>.from(item);
        final name = _gameName(game);
        if (name.isEmpty) continue;
        if (_looksLikeConsoleLabel(name)) continue;
        displayGames.add({'name': name, 'image': _gameImage(game)});
      }

      // Fallback to cafe-level games list when vendor-games payload has
      // platform labels (PC/PS5/XBOX) instead of actual game titles.
      if (displayGames.isEmpty) {
        for (final name in sanitizeArenaGameList(widget.availableGames)) {
          displayGames.add({'name': name, 'image': placeholderImage});
        }
      }

      if (displayGames.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Available Games",
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displayGames.length,
              separatorBuilder: (_, __) => const SizedBox(width: 2),
              itemBuilder: (context, index) {
                final item = displayGames[index];
                final name = item['name'] ?? 'Game';
                final image = item['image'] ?? placeholderImage;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5.0,
                    vertical: 4.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: image,
                            width: 90,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 90,
                              height: 100,
                              color: const Color(0xff1A1A1A),
                              child: const Center(child: AppLinearLoader()),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 90,
                              height: 100,
                              color: const Color(0xff1A1A1A),
                              child: Image.network(
                                placeholderImage,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 90,
                        height: 16,
                        child: _MarqueeText(
                          text: name,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget foodAndBeverageGrid(List<Map<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Food & Beverages Offered",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: CachedNetworkImage(
                  imageUrl: item['image']!,
                  height: 60,
                  width: 70,
                  fit: BoxFit.contain,
                  placeholder: (_, _) =>
                      const Center(child: RainbowGlowingLoader(size: 10)),
                  errorWidget: (_, _, _) =>
                      const Icon(Icons.error, color: Colors.red),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget amenitiesGrid(List<dynamic> amenities, {bool excludeFood = false}) {
    // Normalize amenities: accept maps or strings from API
    final normalized = amenities
        .map((item) {
          if (item is Map) {
            return {
              'name':
                  item['name'] ?? item['amenity'] ?? item['amenity_name'] ?? '',
              'available':
                  item['available'] ??
                  item['is_available'] ??
                  item['isAvailable'] ??
                  true,
            };
          }
          if (item is String) {
            return {'name': item, 'available': true};
          }
          return null;
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    final filtered = normalized.where((item) {
      if (!_truthy(item['available'])) return false;
      final name = (item['name'] ?? '').toString().toLowerCase();
      if (excludeFood &&
          (name == 'food' ||
              name.contains('food') ||
              name.contains('beverage') ||
              name.contains('snack') ||
              name.contains('cafe'))) {
        return false;
      }
      return name.isNotEmpty;
    }).toList();
    final display = filtered.isNotEmpty
        ? filtered
        : normalized
              .where(
                (item) => (item['name'] ?? '').toString().trim().isNotEmpty,
              )
              .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Facilities",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: display.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = display[index];
              final name = item['name']?.toString() ?? '';
              final displayName = name
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map(
                    (w) => w.isNotEmpty
                        ? '${w[0].toUpperCase()}${w.substring(1)}'
                        : '',
                  )
                  .join(' ');
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xff232323),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      _getAmenityIcon(name),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Text(
                      displayName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getAmenityIcon(String amenityName) {
    final name = amenityName.toLowerCase();

    // Gaming related amenities
    if (name.contains('ps5') || name.contains('playstation')) {
      return Icons.games;
    }
    if (name.contains('xbox')) return Icons.games;
    if (name.contains('pc') || name.contains('computer')) return Icons.computer;
    if (name.contains('gaming') || name.contains('game')) {
      return Icons.sports_esports;
    }

    // Food & Beverage
    if (name.contains('food') ||
        name.contains('meal') ||
        name.contains('snack')) {
      return Icons.restaurant;
    }
    if (name.contains('coffee') ||
        name.contains('tea') ||
        name.contains('drink')) {
      return Icons.local_cafe;
    }
    if (name.contains('water') || name.contains('beverage')) {
      return Icons.local_drink;
    }

    // Comfort & Facilities
    if (name.contains('ac') || name.contains('air_condition')) {
      return FontAwesomeIcons.snowflake;
    }
    if (name.contains('wifi') || name.contains('internet')) {
      return FontAwesomeIcons.wifi;
    }
    if (name.contains('parking')) return FontAwesomeIcons.parking;
    if (name.contains('toilet') ||
        name.contains('washroom') ||
        name.contains('bathroom')) {
      return Icons.wc;
    }
    if (name.contains('charging') || name.contains('power')) return Icons.power;
    if (name.contains('headphone') || name.contains('audio')) {
      return FontAwesomeIcons.headphones;
    }
    if (name.contains('chair') || name.contains('seat')) {
      return FontAwesomeIcons.chair;
    }
    if (name.contains('table')) return FontAwesomeIcons.table;

    // Entertainment
    if (name.contains('tv') || name.contains('television')) {
      return FontAwesomeIcons.tv;
    }
    if (name.contains('music') || name.contains('sound')) {
      return FontAwesomeIcons.music;
    }
    if (name.contains('lighting') || name.contains('light')) {
      return FontAwesomeIcons.lightbulb;
    }

    // Security & Safety
    if (name.contains('security') || name.contains('cctv')) {
      return FontAwesomeIcons.shield;
    }
    if (name.contains('first aid') || name.contains('medical')) {
      return FontAwesomeIcons.medkit;
    }

    // General amenities
    if (name.contains('locker') || name.contains('storage')) return Icons.lock;
    if (name.contains('fan') || name.contains('ventilation')) {
      return FontAwesomeIcons.fan;
    }
    if (name.contains('clean') || name.contains('hygiene')) {
      return FontAwesomeIcons.broom;
    }

    // Default icon for unknown amenities
    return Icons.check;
  }

  String _getConsoleIcon(String consoleName) {
    switch (_normalizeConsoleType(consoleName)) {
      case 'pc':
        return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075080/pc_ah5ulv.png';
      case 'xbox':
        return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075086/xbox_fmz0bn.png';
      case 'ps5':
        return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075082/ps_krf4kw.png';
      case 'vr_headset':
        return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075086/vr_rzqkbq.png';
      case 'nintendo_switch':
        return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/gaming-pad-01_byibeu.png';
      case 'vip_room':
        return 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/crown_mzzqhy.png';
      default:
        return '';
    }
  }

  IconData _getConsoleFallbackIcon(String consoleName) {
    switch (_normalizeConsoleType(consoleName)) {
      case 'steam_deck':
        return Icons.sports_esports_outlined;
      case 'arcade_cabinet':
        return Icons.videogame_asset_outlined;
      case 'racing_rig':
        return Icons.sports_motorsports_outlined;
      case 'simulator':
        return Icons.rocket_launch_outlined;
      case 'private_room':
        return Icons.meeting_room_outlined;
      case 'vip_room':
        return Icons.workspace_premium_outlined;
      case 'bootcamp_room':
        return Icons.groups_2_outlined;
      default:
        return Icons.sports_esports_outlined;
    }
  }

  String _getConsoleType(String consoleName) {
    switch (_normalizeConsoleType(consoleName)) {
      case 'ps5':
        return 'PS';
      case 'xbox':
        return 'XB';
      case 'vr_headset':
        return 'VR';
      case 'nintendo_switch':
        return 'NS';
      case 'steam_deck':
        return 'SD';
      case 'arcade_cabinet':
        return 'ARCADE';
      case 'racing_rig':
        return 'RACING';
      case 'simulator':
        return 'SIM';
      case 'private_room':
        return 'PRIVATE';
      case 'vip_room':
        return 'VIP';
      case 'bootcamp_room':
        return 'BOOTCAMP';
      default:
        return 'PC';
    }
  }
}

class _PassCard extends StatelessWidget {
  final String name;
  final double price;
  final int totalHours;
  final int daysValid;
  final String description;

  const _PassCard({
    required this.name,
    required this.price,
    required this.totalHours,
    required this.daysValid,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalHours hrs • $daysValid days',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${price.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff00DC00),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Buy',
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  const _MarqueeText({
    required this.text,
    required this.style,
    this.blankSpace = 20,
    this.velocity = 30,
  });

  final String text;
  final TextStyle style;
  final double blankSpace;
  final double velocity; // pixels per second

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  void _startAnimation(Duration duration) {
    if (_controller.duration != duration || !_controller.isAnimating) {
      _controller.duration = duration;
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final textWidth = _measureTextWidth(widget.text, widget.style);
        if (textWidth <= maxWidth) {
          _controller.stop();
          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          );
        }

        final distance = textWidth + widget.blankSpace;
        final seconds = distance / widget.velocity;
        _startAnimation(Duration(milliseconds: (seconds * 1000).round()));

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: maxWidth,
            maxWidth: double.infinity,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                final offset = -distance * _controller.value;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.text, style: widget.style),
                      SizedBox(width: widget.blankSpace),
                      Text(widget.text, style: widget.style),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class BookingPartySelection {
  const BookingPartySelection({
    required this.isSquad,
    required this.requiredConsoleCount,
    this.selectedMembers = const <ChatUserModel>[],
  });

  final bool isSquad;
  final int requiredConsoleCount;
  final List<ChatUserModel> selectedMembers;
}
