import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/app/modules/profile/user_profile_view.dart';
import 'package:hash/app/modules/wallet/controllers/wallet_controller.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class TournamentsAppBar extends StatefulWidget {
  const TournamentsAppBar({super.key});

  @override
  State<TournamentsAppBar> createState() => _TournamentsAppBarState();
}

class _TournamentsAppBarState extends State<TournamentsAppBar> {
  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    return SliverAppBar(
      backgroundColor: const Color(0xFF0D0D0D),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
      elevation: 0,
      pinned: true,
      expandedHeight: 112,
      collapsedHeight: 112,
      toolbarHeight: 112,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      title: null,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF292826),
                Color(0xFF1B1916),
                Color(0xFF2A1B0E),
              ],
              stops: [0, .58, 1],
            ),
          ),
          child: SafeArea(
            child: Obx(() {
              final user = userController.user.value;
              final fullName = (user.name ?? '').trim();
              final name = fullName.isEmpty
                  ? 'Gamer'
                  : fullName.split(' ').first;
              final address = user.contact?.physicalAddress;
              final location = [
                address?.addressLine2,
                address?.state,
              ].where((value) => value?.trim().isNotEmpty == true).join(', ');
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 18, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.to(UserProfileView()),
                      child: userController.isLoading.value
                          ? _buildShimmerAvatar()
                          : _buildOptimizedUserAvatar(user.photoUrl, user.name),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hey, $name!',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            location.isEmpty
                                ? 'Ready for your next match?'
                                : location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    BlocBuilder<HashCoinCubit, HashCoinState>(
                      builder: (_, state) => _balanceChip(
                        Icons.hexagon_outlined,
                        state is HashCoinLoaded ? '${state.hashCoin}' : '0',
                        const Color(0xFFFFA43A),
                      ),
                    ),
                    const SizedBox(width: 7),
                    _walletChip(),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _walletChip() {
    if (!Get.isRegistered<WalletController>()) {
      return _balanceChip(Icons.toll_outlined, '₹0', const Color(0xFFFFFF38));
    }
    return Obx(() {
      final balance = Get.find<WalletController>().balance;
      final text = balance == balance.roundToDouble()
          ? '₹${balance.toInt()}'
          : '₹${balance.toStringAsFixed(0)}';
      return _balanceChip(Icons.toll_outlined, text, const Color(0xFFFFFF38));
    });
  }

  Widget _balanceChip(IconData icon, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF45413D),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFF68625C)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 5),
        Text(
          value,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _buildOptimizedUserAvatar(String? photoUrl, String? userName) {
    const double size = 62;
    final effectivePhoto = (photoUrl ?? '').trim().isNotEmpty
        ? photoUrl!.trim()
        : (firebase_auth.FirebaseAuth.instance.currentUser?.photoURL ?? '')
              .trim();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFA43A), width: 3),
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
                backgroundColor: Colors.black,
                child: effectivePhoto.isEmpty
                    ? Text(
                        (userName ?? '').trim().isEmpty
                            ? 'G'
                            : userName!.trim()[0].toUpperCase(),
                        style: GoogleFonts.orbitron(
                          color: const Color(0xFFFFD600),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
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
