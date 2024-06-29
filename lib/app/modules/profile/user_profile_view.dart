import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserProfileView extends StatelessWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: GestureDetector(
            onTap: () {
              Get.back();
            },
            child: Icon(
              CupertinoIcons.back,
              color: Color.fromRGBO(58, 255, 107, 1.0),
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          children: [
            SizedBox(height: 20),
            _buildProfileHeader(),
            SizedBox(height: 30),
            _buildProfileOption(
              icon: CupertinoIcons.person,
              title: 'My Orders',
              onTap: () {
                // Handle view orders
              },
            ),
            _buildProfileOption(
              icon: CupertinoIcons.settings,
              title: 'Settings',
              onTap: () {
                // Handle settings
              },
            ),
            _buildProfileOption(
              icon: CupertinoIcons.money_dollar_circle,
              title: 'Wallet',
              onTap: () {
                // Handle wishlist
              },
            ),
            _buildProfileOption(
              icon: CupertinoIcons.heart,
              title: 'Wishlist',
              onTap: () {
                // Handle wishlist
              },
            ),
            _buildProfileOption(
              icon: CupertinoIcons.lock,
              title: 'Change Password',
              onTap: () {
                // Handle change password
              },
            ),
            _buildProfileOption(
              icon: CupertinoIcons.info,
              title: 'About',
              onTap: () {
                // Handle about
              },
            ),
            SizedBox(height: 30),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: CachedNetworkImageProvider(
            'https://via.placeholder.com/150', // Replace with actual profile image URL
          ),
        ),
        SizedBox(height: 20),
        Text(
          'John Doe',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          'john.doe@example.com',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildProfileOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Color.fromRGBO(58, 255, 107, 1.0)),
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      trailing: Icon(CupertinoIcons.forward, color: Colors.white70),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: () {
        // Handle logout
      },
      style: ElevatedButton.styleFrom(
        primary: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: Size(double.infinity, 50),
      ),
      child: Text('Logout', style: TextStyle(color: Colors.white, fontSize: 18)),
    );
  }
}
