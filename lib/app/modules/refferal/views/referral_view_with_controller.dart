import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../controller/refferal_controller.dart';
import 'package:hash/core/repositories/model/get_voucher_model.dart';

class ReferralViewWithController extends StatefulWidget {
  ReferralViewWithController({Key? key}) : super(key: key);

  @override
  State<ReferralViewWithController> createState() =>
      _ReferralViewWithControllerState();
}

class _ReferralViewWithControllerState
    extends State<ReferralViewWithController> {
  final controller = Get.put(ReferralController());

  @override
  void initState() {
    controller.getVoucher();
    super.initState();
  }

  /* -------------------------------------------------------------------------- */
  final Color _accent = const Color(0xffDE3A3A);
  // brand red
  final Color _bannerGold = const Color(0xffF4C342);
  // yellow ribbon
  final Color _darkCard = const Color(0xff0F0F0F);
  // card bg
  final TextStyle _heading = GoogleFonts.inter(
      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18);

  /* -------------------------------------------------------------------------- */
  Widget _tierProgressCard(ReferralController controller) {
    /// Get real data from controller
    final currentReferrals = controller.getReferralRewards();
    const tier1 = 1;
    const tier2 = 5;
    const tier3 = 10;
    const amountEarnable = '₹25,000';

    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: _darkCard, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amount you will Earn', style: _heading.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          Text(amountEarnable,
              style: GoogleFonts.inter(
                  fontSize: 32, fontWeight: FontWeight.w800, color: _accent)),
          const SizedBox(height: 16),
          Text('When you refer', style: _heading.copyWith(fontSize: 14)),
          const SizedBox(height: 6),
          _tierSlider(currentReferrals, [tier1, tier2, tier3]),
          const SizedBox(height: 12),
          // Create Voucher Button
          Obx(() => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff008BFF), Color(0xff0FEBFF)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : GestureDetector(
                        onTap: () => controller.createVoucher(),
                        child: Text('Create Voucher',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
              )),
          const SizedBox(height: 24),
          Text('How it Works', style: _heading),
          const SizedBox(height: 14),
          _howItWorksStep(
              'Share your referral link/code with your friends', Icons.share),
          _howItWorksStep(
              'Friend registers on HashforGamers using your link/code',
              Icons.person_add_alt_1),
          _howItWorksStep(
              'You both earn rewards when your friend makes a booking',
              Icons.card_giftcard),
        ],
      ),
    );
  }

  Widget _tierSlider(int current, List<int> tiers) {
    // Clamp the current value to the valid range to prevent slider assertion errors
    final maxValue = tiers.last.toDouble();
    final clampedValue = current.toDouble().clamp(0.0, maxValue);
    
    return Column(children: [
      SliderTheme(
        data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: _accent,
            inactiveTrackColor: Colors.white12,
            thumbColor: _accent,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7)),
        child: Slider(
          value: clampedValue,
          min: 0,
          max: maxValue,
          onChanged: (_) {},
        ),
      ),
      Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: tiers
              .map((t) => Text('TIER $t',
                  style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)))
              .toList()),
    ]);
  }

  Widget _howItWorksStep(String text, IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 18, color: _accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
          )
        ]),
      );

  // 2️⃣ REFERRAL CARD (center phone) ------------------------------------------
  Widget _centralReferralCard(BuildContext ctx, ReferralController controller) {
    final code = controller.getReferralCode();

    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff1C1C1E), Color(0xff000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        // yellow banner
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 30),
          decoration: BoxDecoration(
              color: _bannerGold,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: _bannerGold.withOpacity(.4),
                    spreadRadius: 1,
                    blurRadius: 8)
              ]),
          child: Text('Refer & Earn  ₹₹ Unlimited',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800, color: Colors.black)),
        ),
        const SizedBox(height: 28),
        Text('Your Referral Code',
            style:
                GoogleFonts.inter(color: Colors.white60, letterSpacing: 0.2)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
              border: Border.all(color: _accent, width: 2),
              borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(code,
                style: GoogleFonts.play(
                    fontSize: 26,
                    color: _accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Share.share(
                    'Join HashforGamers with my code 👉 $code (unlimited rewards!)');
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Referral code ready to share!')));
              },
              child: const Icon(Icons.copy, color: Colors.white70, size: 20),
            ),
          ]),
        ),
        const SizedBox(height: 22),
        Text('REFER VIA',
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 18),
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _shareBtns()),
        const SizedBox(height: 20),
        // Create Voucher Button - More prominent placement
        Obx(() => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accent, const Color(0xffFF6B6B)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : GestureDetector(
                      onTap: () => controller.createVoucher(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Create Voucher',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
            )),
        const SizedBox(height: 20),
        // mini progress inside the central card
        _miniProgressBar(controller),
      ]),
    );
  }

  List<Widget> _shareBtns() {
    List<(IconData, Color)> items = [
      (Icons.facebook_rounded, const Color(0xff1877F2)),
      (Icons.mail_outline, Colors.white),
      (Icons.share, _accent)
    ];
    return items
        .map((e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: e.$2.withOpacity(.15),
                child: Icon(e.$1, color: e.$2, size: 20),
              ),
            ))
        .toList();
  }

  Widget _miniProgressBar(ReferralController controller) => Column(children: [
        Text('Earn More with our Tiered Rewards',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
              color: Colors.black, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text('₹25,000',
                style: GoogleFonts.inter(
                    color: _accent, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _tierSlider(controller.getReferralRewards(), [1, 5, 10]),
          ]),
        )
      ]);

  // 3️⃣ HOW-IT-WORKS + FAQ (right phone) --------------------------------------
  Widget _howItWorksFaqCard() {
    final faqs = [
      ('Who can register as a subscriber?', 'Anyone above 13 years old.'),
      ('Which games are available?', 'All major PC titles and in-café titles.'),
      ('What are Hash Coins?', 'Reward points redeemable in our store.'),
    ];

    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: _darkCard, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How it Works', style: _heading),
        const SizedBox(height: 18),
        _howItWorksStep('Share referral link/code with friends', Icons.share),
        _howItWorksStep('Friend registers with your code', Icons.person_add),
        _howItWorksStep('Both earn cash rewards', Icons.currency_rupee),
        const SizedBox(height: 24),
        Text('Frequently Asked Questions', style: _heading),
        const SizedBox(height: 12),
        ...faqs.map((f) => _faqItem(f.$1, f.$2))
      ]),
    );
  }

  Widget _faqItem(String q, String a) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        collapsedIconColor: Colors.white60,
        iconColor: _accent,
        title: Text(q,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(a,
                style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
          )
        ],
      ),
    );
  }

  // 4️⃣ VOUCHERS LIST CARD --------------------------------------
  Widget _vouchersListCard(ReferralController controller) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: _darkCard, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Vouchers', style: _heading),
                  Obx(() => Text(
                    '${controller.vouchers.length} voucher${controller.vouchers.length == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  )),
                ],
              ),
            ),
            Obx(() => controller.isLoadingVouchers.value
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      color: _accent,
                      strokeWidth: 2,
                    ),
                  )
                : GestureDetector(
                    onTap: () => controller.getVoucher(),
                    child: Icon(
                      Icons.refresh,
                      color: _accent,
                      size: 20,
                    ),
                  )),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.vouchers.isEmpty) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.card_giftcard_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No vouchers yet',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first voucher to start earning!',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Add search bar for many vouchers
          if (controller.vouchers.length > 5) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.white54, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search vouchers...',
                            hintStyle: GoogleFonts.inter(color: Colors.white54),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            // TODO: Implement search functionality
                            // This would filter the vouchers list based on the search term
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 350, // Slightly smaller height to accommodate search bar
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: controller.vouchers.length,
                    itemBuilder: (context, index) {
                      return _voucherItem(controller.vouchers[index]);
                    },
                  ),
                ),
              ],
            );
          }

          // For many vouchers, use a scrollable container
          if (controller.vouchers.length > 3) {
            return Container(
              height: 400, // Fixed height for scrollable area
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: controller.vouchers.length,
                itemBuilder: (context, index) {
                  return _voucherItem(controller.vouchers[index]);
                },
              ),
            );
          }

          // For few vouchers, use regular column
          return Column(
            children: controller.vouchers.map((voucher) => _voucherItem(voucher)).toList(),
          );
        }),
      ]),
    );
  }

  Widget _voucherItem(Voucher voucher) {
    final isActive = voucher.isActive;
    final discountText = '${voucher.discountPercentage}% OFF';
    final createdAt = _formatDate(voucher.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? _accent : Colors.white24,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voucher.code,
                      style: GoogleFonts.play(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created: $createdAt',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? _accent : Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  discountText,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? Icons.check_circle : Icons.cancel,
                      color: isActive ? Colors.green : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? 'Active' : 'Inactive',
                      style: GoogleFonts.inter(
                        color: isActive ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Share.share(
                    'Use my HashforGamers voucher code: ${voucher.code} for ${voucher.discountPercentage}% discount! 🎮',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Voucher code ${voucher.code} copied to share!'),
                      backgroundColor: _accent,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _accent, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.share,
                        color: _accent,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Share',
                        style: GoogleFonts.inter(
                          color: _accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /* -------------------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    // Initialize the ReferralController
    final ReferralController referralController = Get.put(ReferralController());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.black,
        title: Text('Refer & Earn',
            style: GoogleFonts.inter(
                color: _accent, fontWeight: FontWeight.w700, fontSize: 22)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Color(0xff073A10),
              ]),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(children: [
            _tierProgressCard(referralController),
            const SizedBox(height: 26),
            _centralReferralCard(context, referralController),
            const SizedBox(height: 26),
            _howItWorksFaqCard(),
            const SizedBox(height: 26),
            _vouchersListCard(referralController),
          ]),
        ),
      ),
    );
  }
}
