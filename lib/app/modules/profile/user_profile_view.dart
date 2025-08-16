import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/game_pass/page/game_pass_page.dart';
import 'package:hash/app/modules/hash_coin/pages/hash_coin_page.dart';
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
    final userController = Get.find<UserController>();

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
        title: Text('Profile',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
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
        return const Center(
          child: RainbowGlowingLoader(size: 50),
        );
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
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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

  Widget _buildProfileOption(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
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

          Get.offAllNamed(AppRoutes
              .LOGIN); // Navigates to the login screen and removes all previous routes
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text(
          'Logout',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(UserController userController) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: OutlinedButton(
        onPressed: () async {
          bool? confirm = await showCupertinoDialog<bool>(
            context: Get.context!,
            builder: (context) => CupertinoAlertDialog(
              title: const Text("Delete Account"),
              content: const Text(
                "Are you sure you want to delete your account? This action cannot be undone.",
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Delete"),
                ),
              ],
            ),
          );

          if (confirm == true) {
            final success = await userController.deleteUser();
            if (success) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              Get.offAllNamed(AppRoutes.LOGIN);
            } else {
              Get.snackbar("Error", "Failed to delete account",
                  backgroundColor: Colors.red, colorText: Colors.white);
            }
          }
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text(
          'Delete Account',
          style: GoogleFonts.inter(color: Colors.red, fontSize: 18),
        ),
      ),
    );
  }




}
