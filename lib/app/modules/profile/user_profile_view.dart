import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/about/about_page.dart';
import 'package:hash/app/modules/game_pass/page/game_pass_page.dart';
import 'package:hash/app/modules/hash_coin/pages/hash_coin_page.dart';
import 'package:hash/app/modules/need_help/need_help_page.dart';
import 'package:hash/app/modules/profile/profile_view.dart';
import 'package:hash/app/modules/refferal/views/referral_view_with_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/widgets/glow_neon_loader.dart';
import '../../data/services/user_controller.dart';
import '../../routes/app_routes.dart';

class UserProfileView extends StatelessWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    UserController userController = Get.put(UserController());

    return Scaffold(
      bottomNavigationBar: Container(height: 120,
        child: Column(
          children: [

            _buildLogoutButton(),
            _buildDeleteButton(userController),

          ],
        ),
      ),
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Profile',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(userController),
            const SizedBox(height: 30),
            _buildProfileOption(
              icon: CupertinoIcons.person,
              title: 'Profile',
              onTap: () {
                Get.to(ProfileView());
                // Handle view orders
              },
            ),
            // _buildProfileOption(
            //   icon: CupertinoIcons.bag,
            //   title: 'My Orders',
            //   onTap: () {
            //     Get.to(const GamePassPage());
            //   },
            // ),
            // _buildProfileOption(
            //   icon: CupertinoIcons.settings,
            //   title: 'Settings',
            //   onTap: () {
            //     // Handle settings
            //   },
            // ),
            // _buildProfileOption(
            //   icon: CupertinoIcons.money_dollar_circle,
            //   title: 'Wallet',
            //   onTap: () {
            //     // Handle wallet
            //     // Get.to(WalletDetailView());
            //     Get.to(const HashCoinPage());
            //   },
            // ),
            _buildProfileOption(
              icon: CupertinoIcons.person_2,
              title: 'Refer & Earn',
              onTap: () {
                Get.to(const ReferralViewWithController());
              },
            ),
            // _buildProfileOption(
            //   icon: CupertinoIcons.heart,
            //   title: 'Wishlist',
            //   onTap: () {
            //     // Handle wishlist
            //   },
            // ),
            // _buildProfileOption(
            //   icon: Icons.change_circle_outlined,
            //   title: 'Change Address',
            //   onTap: () {
            //     // Handle change password
            //   },
            // ),
            _buildProfileOption(
              icon: Icons.question_mark,
              title: 'Need Help',
              onTap: () {
                // Handle wishlist
                Get.to(NeedHelpPage());
              },
            ),
            _buildProfileOption(
              icon: Icons.info_outline,
              title: 'About Us',
              onTap: () {
                Get.to(AboutPage());
              },
            ),
            // _buildProfileOption(
            //   icon: CupertinoIcons.info,
            //   title: 'About',
            //   onTap: () {
            //     // Handle about
            //   },
            // ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserController userController) {
    return Obx(() {
      if (userController.isLoading.value) {
        return const Center(child: RainbowGlowingLoader(size: 50));
      }

      final user = userController.user.value;

      return Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: CachedNetworkImageProvider(
              'https://upload.wikimedia.org/wikipedia/commons/8/89/Portrait_Placeholder.png', // Replace with actual profile image URL
            ),
          ),
          const SizedBox(height: 20),
          Text(
            user.name!,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            user.contact?.electronicAddress?.emailId ?? "",
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
          ),
        ],
      );
    });
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(
        title,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 18),
      ),
      trailing: const Icon(CupertinoIcons.forward, color: Colors.white70),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: ElevatedButton(
        onPressed: () async {
          // Handle logout
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          await prefs.remove('user_data');

          Get.offAllNamed(
            AppRoutes.LOGIN,
          ); // Navigates to the login screen and removes all previous routes
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text(
          'Logout',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

// inside UserProfileView
  Widget _buildDeleteButton(UserController userController) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: OutlinedButton(
        onPressed: () => showBlackCupertinoDeleteDialog(Get.context!, userController),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const Text('Delete Account', style: TextStyle(color: Colors.red, fontSize: 18)),
      ),
    );
  }

  Future<void> showDeleteAccountDialog(BuildContext context, UserController userController) async {
    bool isChecked = false;
    int secondsLeft = 10;
    ValueNotifier<int> timerNotifier = ValueNotifier(secondsLeft);
    ValueNotifier<bool> acceptNotifier = ValueNotifier(false);

    // Start countdown
    Future(() async {
      while (secondsLeft > 0) {
        await Future.delayed(const Duration(seconds: 1));
        secondsLeft--;
        timerNotifier.value = secondsLeft;
      }
    });

    await showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CupertinoTheme(
          data: const CupertinoThemeData(
            brightness: Brightness.dark,
            primaryColor: CupertinoColors.systemRed,
            scaffoldBackgroundColor: CupertinoColors.black,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return CupertinoAlertDialog(
                title: const Text(
                  "⚠️ Delete Account",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemRed,
                  ),
                ),
                content: Column(
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      "This action is permanent.\n\n"
                          "Once deleted, you cannot create another account using the same EMAIL/NUMBER for 30 days.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Countdown
                    ValueListenableBuilder<int>(
                      valueListenable: timerNotifier,
                      builder: (_, value, __) {
                        return Text(
                          value > 0
                              ? "⏳ Please wait $value sec..."
                              : "✅ You may now continue",
                          style: TextStyle(
                            color: value > 0
                                ? CupertinoColors.systemYellow
                                : CupertinoColors.activeGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // Checkbox replacement
                    ValueListenableBuilder<int>(
                      valueListenable: timerNotifier,
                      builder: (_, value, __) {
                        return GestureDetector(
                          onTap: value == 0
                              ? () {
                            setState(() {
                              isChecked = !isChecked;
                              acceptNotifier.value = isChecked;
                            });
                          }
                              : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isChecked
                                    ? CupertinoIcons.check_mark_circled_solid
                                    : CupertinoIcons.circle,
                                size: 24,
                                color: value == 0
                                    ? CupertinoColors.activeGreen
                                    : CupertinoColors.inactiveGray,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "I understand the risk",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: value == 0
                                      ? CupertinoColors.white
                                      : CupertinoColors.inactiveGray,
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: CupertinoColors.activeBlue),
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: acceptNotifier,
                    builder: (_, accepted, __) {
                      return CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: accepted
                            ? () async {
                          Navigator.of(context).pop();
                          final success = await userController.deleteUser();
                          if (success) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            Get.offAllNamed(AppRoutes.LOGIN);
                          } else {
                            Get.snackbar("Error", "Failed to delete account",
                                backgroundColor: CupertinoColors.systemRed,
                                colorText: CupertinoColors.white);
                          }
                        }
                            : null,
                        child: const Text("Delete"),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }




}

// --- drop this anywhere accessible (e.g., same file, bottom) ---
Future<void> showBlackCupertinoDeleteDialog(
    BuildContext context,
    UserController userController,
    ) async {
  int secondsLeft = 10;
  final timerVN = ValueNotifier<int>(secondsLeft);
  final acceptedVN = ValueNotifier<bool>(false);

  // Countdown (outside widget tree; cancel on close)
  final timer = Timer.periodic(const Duration(seconds: 1), (t) {
    if (secondsLeft <= 0) {
      t.cancel();
    } else {
      secondsLeft--;
      timerVN.value = secondsLeft;
    }
  });

  await showCupertinoDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => CupertinoTheme(
      data: const CupertinoThemeData(
        brightness: Brightness.dark,                 // black dialog
        primaryColor: CupertinoColors.systemRed,
      ),
      child: WillPopScope(
        onWillPop: () async => false,                // block back
        child: CupertinoAlertDialog(
          title: const Text(
            '⚠️ Delete Account',
            style: TextStyle(
              color: CupertinoColors.systemRed,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                'This action is permanent.\n\n'
                    'After deleting, you CANNOT create another account '
                    'with the same EMAIL/NUMBER for 30 days.',
                textAlign: TextAlign.center,
                style: TextStyle(color: CupertinoColors.white, fontSize: 15),
              ),
              const SizedBox(height: 16),

              // Countdown
              ValueListenableBuilder<int>(
                valueListenable: timerVN,
                builder: (_, v, __) => Text(
                  v > 0 ? 'Please wait $v sec…' : 'You may now continue.',
                  style: TextStyle(
                    color: v > 0
                        ? CupertinoColors.systemYellow
                        : CupertinoColors.activeGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // “I understand the risk” toggle (enabled after timer)
              ValueListenableBuilder<int>(
                valueListenable: timerVN,
                builder: (_, v, __) {
                  final enabled = v == 0;
                  return GestureDetector(
                    onTap: enabled ? () => acceptedVN.value = !acceptedVN.value : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: acceptedVN,
                          builder: (_, ok, __) => Icon(
                            ok
                                ? CupertinoIcons.check_mark_circled_solid
                                : CupertinoIcons.circle,
                            color: enabled
                                ? (ok
                                ? CupertinoColors.activeGreen
                                : CupertinoColors.white)
                                : CupertinoColors.inactiveGray,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'I understand the risk',
                          style: TextStyle(
                            color: enabled
                                ? CupertinoColors.white
                                : CupertinoColors.inactiveGray,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                if (timer.isActive) timer.cancel();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: CupertinoColors.activeBlue)),
            ),
            ValueListenableBuilder2<bool, int>(
              first: acceptedVN,
              second: timerVN,
              builder: (_, accepted, v, __) {
                final canDelete = accepted && v == 0;
                return CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: canDelete
                      ? () async {
                    if (timer.isActive) timer.cancel();
                    Navigator.of(context).pop();

                    final ok = await userController.deleteUser();
                    if (ok) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      Get.offAllNamed(AppRoutes.LOGIN);
                    } else {
                      Get.snackbar(
                        'Error',
                        'Failed to delete account',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  }
                      : null,
                  child: Text(
                    v > 0 ? 'Delete ($v)' : 'Delete',
                    style: TextStyle(
                      color: canDelete
                          ? CupertinoColors.systemRed
                          : CupertinoColors.systemRed.withOpacity(0.4),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );

  if (timer.isActive) timer.cancel(); // safety
}

/// Small helper to listen to two notifiers at once
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;
  final Widget? child;
  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (_, a, __) => ValueListenableBuilder<B>(
        valueListenable: second,
        builder: (ctx, b, ___) => builder(ctx, a, b, child),
      ),
    );
  }
}
