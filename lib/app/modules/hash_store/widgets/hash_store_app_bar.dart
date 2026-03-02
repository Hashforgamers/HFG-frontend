import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/app/modules/profile/user_profile_view.dart';
import 'package:hash/app/modules/rewards/reward_section_view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class HashStoreAppBar extends StatelessWidget {
  const HashStoreAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    return SliverAppBar(
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
                  const Color(0xFF7A44C0).withOpacity(0.2),
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
            onTap: (){
              Get.to(UserProfileView());
            },
            child: _buildOptimizedUserAvatar(userController.user.value.photoUrl),
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
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 13,
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
  }

  Widget _buildOptimizedUserAvatar(String? photoUrl) {
    const double size = 40;
    final effectivePhoto =
        (photoUrl ?? '').trim().isNotEmpty
        ? photoUrl!.trim()
        : (firebase_auth.FirebaseAuth.instance.currentUser?.photoURL ?? '')
              .trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF7A44C0), width: 2),
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundImage: effectivePhoto.isNotEmpty
            ? CachedNetworkImageProvider(
          effectivePhoto,
          errorListener: (error) => AppLogger.d('Avatar image error: $error'),
        )
            : null,
        backgroundColor: Colors.white,
        child: effectivePhoto.isEmpty
            ? const Icon(Icons.person_rounded, color: Colors.black54)
            : null,
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
