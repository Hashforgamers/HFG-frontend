import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RefferalView extends StatefulWidget {
  const RefferalView({Key? key}) : super(key: key);

  @override
  State<RefferalView> createState() => _RefferalViewState();
}

class _RefferalViewState extends State<RefferalView> {
  final prefs = SharedPreferences.getInstance();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Refer & Earn',
          style: TextStyle(
            color: Color(0xffDE3A3A),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Referral Code Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xffDE3A3A).withOpacity(0.1),
                      Colors.black,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xffDE3A3A).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your Referral Code',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xffDE3A3A),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${Get.find<UserController>().user.value.referralCode}',
                            style: GoogleFonts.play(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xffDE3A3A),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.copy,
                                color: Color(0xffDE3A3A)),
                            onPressed: () {
                              // TODO: Implement copy functionality
                              Get.snackbar(
                                'Copied!',
                                'Referral code copied to clipboard',
                                backgroundColor: Colors.black87,
                                colorText: const Color(0xffDE3A3A),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Section
              // const Text(
              //   'Your Progress',
              //   style: TextStyle(
              //     color: Colors.white,
              //     fontSize: 20,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              // const SizedBox(height: 20),
              // Container(
              //   padding: const EdgeInsets.all(20),
              //   decoration: BoxDecoration(
              //     color: Colors.grey[900],
              //     borderRadius: BorderRadius.circular(15),
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       const Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //         children: [
              //           Text(
              //             'Earned Gifts',
              //             style: TextStyle(
              //               color: Colors.white,
              //               fontSize: 16,
              //             ),
              //           ),
              //           Text(
              //             '3/5',
              //             style: TextStyle(
              //               color: Color(0xffDE3A3A),
              //               fontSize: 16,
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //         ],
              //       ),
              //       const SizedBox(height: 15),
              //       ClipRRect(
              //         borderRadius: BorderRadius.circular(10),
              //         child: LinearProgressIndicator(
              //           value: 0.6,
              //           backgroundColor: Colors.grey[800],
              //           valueColor: const AlwaysStoppedAnimation<Color>(
              //               Color(0xffDE3A3A)),
              //           minHeight: 10,
              //         ),
              //       ),
              //       const SizedBox(height: 20),
              //       const Text(
              //         '2 more referrals to unlock next reward!',
              //         style: TextStyle(
              //           color: Colors.white70,
              //           fontSize: 14,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 30),

              // // Rewards Section
              // const Text(
              //   'Rewards',
              //   style: TextStyle(
              //     color: Colors.white,
              //     fontSize: 20,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              // const SizedBox(height: 20),
              // _buildRewardCard(
              //   title: '1st Referral',
              //   reward: '100 Hash Coins',
              //   isUnlocked: true,
              // ),
              // _buildRewardCard(
              //   title: '3rd Referral',
              //   reward: '500 Hash Coins',
              //   isUnlocked: true,
              // ),
              // _buildRewardCard(
              //   title: '5th Referral',
              //   reward: '1000 Hash Coins + Premium Membership',
              //   isUnlocked: false,
              // ),
              const SizedBox(height: 30),

              // Points Summary Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Points Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildPointsRow('Total Referrals', '3'),
                    _buildPointsRow('Points Earned', '600'),
                    _buildPointsRow('Available for Redemption', '600'),
                    Divider(
                      color: Colors.grey[800],
                      height: 30,
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Points',
                          style: TextStyle(
                            color: Color(0xffDE3A3A),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '600',
                          style: TextStyle(
                            color: Color(0xffDE3A3A),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Referral Rules Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Referral Rules',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildRuleItem(
                      '1. Share your unique referral code with friends',
                      Icons.share,
                    ),
                    _buildRuleItem(
                      '2. Friend must use your code during signup',
                      Icons.person_add,
                    ),
                    _buildRuleItem(
                      '3. Both you and your friend get rewards',
                      Icons.card_giftcard,
                    ),
                    _buildRuleItem(
                      '4. Points can be redeemed for rewards',
                      Icons.stars,
                    ),
                    _buildRuleItem(
                      '5. No limit on number of referrals',
                      Icons.all_inclusive,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xffDE3A3A),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
