import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:share_plus/share_plus.dart';
import '../controller/refferal_controller.dart';
import 'package:hash/core/repositories/model/get_voucher_model.dart';
import 'package:flutter/services.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';

class ReferralViewWithController extends StatefulWidget {
  const ReferralViewWithController({Key? key}) : super(key: key);

  @override
  State<ReferralViewWithController> createState() =>
      _ReferralViewWithControllerState();
}

class _ReferralViewWithControllerState
    extends State<ReferralViewWithController> {
  final controller = Get.put(ReferralController());
  final segmentService = locator<SegmentSdkService>();
  final Color _accent =
      const Color(0xffDE3A3A); // Keep for error, but use green for highlights
  final Color _green = const Color(0xFF21C362); // Main green from screenshot
  final Color _darkCard = const Color(0xff181F1A); // Slightly lighter for cards
  final Color _cardBorder = const Color(0xFF263126);
  final TextStyle _heading = GoogleFonts.inter(
      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18);

  @override
  void initState() {
    controller.getVoucher();
    BlocProvider.of<HashCoinCubit>(context).getHashCoin();
    super.initState();

    // Listen to error messages from controller
    ever(controller.errorMessage, (String error) {
      if (error.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    });
  }

  Widget _earningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      decoration: BoxDecoration(
        color: _darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              children: [
                Icon(CupertinoIcons.hexagon, color: _green, size: 28),
                const SizedBox(height: 8),
                Text('Total Earnings',
                    style:
                        GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 4),
                BlocProvider.value(
                  value: BlocProvider.of<HashCoinCubit>(context),
                  child: BlocBuilder<HashCoinCubit, HashCoinState>(
                    builder: (context, state) {
                      if (state is HashCoinLoading) {
                        return const CircularProgressIndicator(
                          color: Colors.green,
                        );
                      }
                      if (state is HashCoinLoaded) {
                        return Text(
                          state.hashCoin.toString(),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 48, color: Colors.white12),
          Expanded(
            child: Column(
              children: [
                Icon(Icons.person_add_alt_1, color: _green, size: 28),
                const SizedBox(height: 8),
                Text('My Referrals',
                    style:
                        GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 4),
                Obx(() => Text(
                      controller.getReferralRewards().toString(),
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _referralCodeCard(BuildContext ctx) {
    final code = controller.getReferralCode();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        color: _darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Referral Code',
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(code,
                      style: GoogleFonts.play(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2)),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Referral code copied!')));
                  },
                  child: Row(
                    children: [
                      Text('Copy',
                          style: GoogleFonts.inter(
                              color: _green, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(Icons.copy, color: _green, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.share, color: Colors.white),
              label: Text('Share Referral Code',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              onPressed: () {
                // Track referral sent event
                final referralCode = controller.getReferralCode();
                segmentService.onReferralSent(
                  referralCode: referralCode,
                  channel: 'share',
                );

                Share.share(
                    'Join HashforGamers with my code 👉 $code (unlimited rewards!)');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _howItWorksCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How It Works', style: _heading),
          const SizedBox(height: 18),
          _howItWorksStep('Step 1',
              'Share your referral link/code with your friends', Icons.share),
          _howItWorksStep(
              'Step 2',
              'Friends registers on HashforGamers using your link/code',
              Icons.person_add_alt_1),
          _howItWorksStep(
              'Step 3',
              'You both earn rewards when your friend makes a booking',
              Icons.card_giftcard),
        ],
      ),
    );
  }

  Widget _howItWorksStep(String step, String text, IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _green.withOpacity(0.15),
              child: Icon(icon, color: _green, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step,
                      style: GoogleFonts.inter(
                          color: _green,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(text,
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _vouchersCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Vouchers', style: _heading.copyWith(fontSize: 16)),
              Obx(() => controller.isLoadingVouchers.value
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          color: _green, strokeWidth: 2))
                  : GestureDetector(
                      onTap: () => controller.getVoucher(),
                      child: Icon(Icons.refresh, color: _green, size: 20),
                    )),
            ],
          ),
          Obx(() {
            if (controller.vouchers.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 36),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.card_giftcard_outlined,
                        color: Colors.white54, size: 48),
                    const SizedBox(height: 16),
                    Text('No vouchers yet',
                        style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('Create your first voucher to start earning!',
                        style: GoogleFonts.inter(
                            color: Colors.white54, fontSize: 14),
                        textAlign: TextAlign.center),
                  ],
                ),
              );
            }
            // If vouchers exist, show them (not shown in screenshot, so keep as is)
            return Column(
              children: controller.vouchers
                  .map((voucher) => _voucherItem(voucher))
                  .toList(),
            );
          }),
          const SizedBox(height: 18),
          Obx(
            () => controller.isLoading.value
                ? SizedBox(
                    width: double.infinity,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: _green, strokeWidth: 2)),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _green,
                        side: BorderSide(color: _green, width: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(Icons.card_giftcard, color: _green),
                      label: Text('Create Voucher',
                          style: GoogleFonts.inter(
                              color: _green,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      onPressed: () async {
                        try {
                          await controller.createVoucher();
                        } catch (e) {
                          // Fallback error handling in case controller doesn't show snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        }
                      },
                    ),
                  ),
          ),
        ],
      ),
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
          color: isActive ? _green : Colors.white24,
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
                        color: _green,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? _green : Colors.white24,
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
                  color: isActive
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
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
                      content:
                          Text('Voucher code ${voucher.code} copied to share!'),
                      backgroundColor: _green,
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _green, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.share,
                        color: _green,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Share',
                        style: GoogleFonts.inter(
                          color: _green,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Refer your friends &\n',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20),
              ),
              TextSpan(
                text: 'Hash Coins',
                style: GoogleFonts.inter(
                    color: _green, fontWeight: FontWeight.w700, fontSize: 20),
              ),
            ],
          ),
        ),
        toolbarHeight: 80,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _earningsCard(),
            _referralCodeCard(context),
            _howItWorksCard(),
            _vouchersCard(),
          ],
        ),
      ),
    );
  }
}
