import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../utils/widgets/loader.dart';
import '../controller/refferal_controller.dart';
import 'package:hash/core/repositories/model/get_voucher_model.dart';
import 'package:flutter/services.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';

class ReferralViewWithController extends StatefulWidget {
  final String email;
  const ReferralViewWithController({super.key, required this.email});

  @override
  State<ReferralViewWithController> createState() =>
      _ReferralViewWithControllerState();
}

class _ReferralViewWithControllerState
    extends State<ReferralViewWithController> {
  final controller = Get.put(ReferralController());
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();
  final Color _green = const Color(0xff00DC00);
  final Color _darkCard = const Color(0xFF0F1510);
  final Color _darkCardAlt = const Color(0xFF141E16);
  final Color _cardBorder = const Color(0xFF2D4A32);
  final Color _mutedText = const Color(0xff00DC00);
  final TextStyle _heading = GoogleFonts.inter(
    color: Colors.white,
    fontWeight: FontWeight.w700,
    fontSize: 18,
  );

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    });
  }

  Widget _surfaceCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      vertical: 18,
      horizontal: 18,
    ),
    EdgeInsetsGeometry margin = const EdgeInsets.only(top: 18),
  }) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_darkCardAlt, _darkCard],
        ),
        border: Border.all(color: _cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _metricTile({
    required IconData icon,
    required String title,
    required Widget value,
    required Color glow,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: glow, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          value,
        ],
      ),
    );
  }

  Widget _stepItem({
    required String step,
    required String text,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _green.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: _green, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step,
                  style: GoogleFonts.inter(
                    color: _green,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCopiedToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Referral code copied!'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _refreshReferralData() async {
    await controller.getVoucher();
    if (!mounted) return;
    BlocProvider.of<HashCoinCubit>(context).getHashCoin();
  }

  void _shareReferralCode(String code) {
    segmentService.onReferralInitiated(email: widget.email);

    final referralCode = controller.getReferralCode();
    segmentService.onReferralSent(referralCode: referralCode, channel: 'share');
    fbEventsService.onReferralSent(
      referralCode: referralCode,
      channel: 'share',
    );

    SharePlus.instance.share(
      ShareParams(
        text:
            '🎮 Join me on *HashforGamers*! Get access to top gaming cafes, exclusive tournaments, and earn rewards.\n\n'
            'Use my referral code 👉 $code to sign up and unlock **unlimited rewards**!\n\n'
            '📲 Download now: https://play.google.com/store/apps/details?id=com.hfg.hash',
      ),
    );
  }

  Widget _milestoneChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: _green.withValues(alpha: 0.1),
        border: Border.all(color: _green.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: _green,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _earningsCard() {
    return _surfaceCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Referral Dashboard',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track coins, signups and referral rewards in one place.',
            style: GoogleFonts.inter(color: _mutedText, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  icon: CupertinoIcons.hexagon_fill,
                  title: 'Total Hash Coins',
                  glow: _green,
                  value: BlocProvider.value(
                    value: BlocProvider.of<HashCoinCubit>(context),
                    child: BlocBuilder<HashCoinCubit, HashCoinState>(
                      builder: (context, state) {
                        if (state is HashCoinLoading) {
                          return SizedBox(
                            height: 18,
                            width: 18,
                            child: RainbowLoadingBar(),
                          );
                        }
                        final value = state is HashCoinLoaded
                            ? state.hashCoin
                            : 0;
                        return Text(
                          value.toString(),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricTile(
                  icon: Icons.group_add_rounded,
                  title: 'Successful Referrals',
                  glow: _green,
                  value: Obx(
                    () => Text(
                      controller.getReferralCount().toString(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _green.withValues(alpha: 0.35)),
              color: _green.withValues(alpha: 0.08),
            ),
            child: Obx(
              () => Text(
                'Referral rewards: ${controller.getReferralRewards()}',
                style: GoogleFonts.inter(
                  color: _green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            const goal = 10;
            final referralCount = controller.getReferralCount();
            final progress = (referralCount / goal).clamp(0.0, 1.0);
            final remaining = referralCount >= goal ? 0 : goal - referralCount;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Milestone progress',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$referralCount/$goal',
                      style: GoogleFonts.inter(
                        color: _green,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(_green),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  remaining == 0
                      ? 'Milestone unlocked. Keep inviting for bonus rewards.'
                      : '$remaining more referrals to unlock next milestone reward.',
                  style: GoogleFonts.inter(
                    color: _mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _milestoneChip('5 refs • +50 coins'),
              _milestoneChip('10 refs • +100 coins'),
              _milestoneChip('20 refs • +voucher'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _referralCodeCard() {
    final code = controller.getReferralCode();
    return _surfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Referral Code', style: _heading.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'Share this code and earn coins for every successful signup.',
            style: GoogleFonts.inter(color: _mutedText, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _green.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code,
                    style: GoogleFonts.play(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      _showCopiedToast();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: _green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded, color: _green, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Copy',
                            style: GoogleFonts.inter(
                              color: _green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    _showCopiedToast();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _green,
                    side: BorderSide(color: _green.withValues(alpha: 0.42)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.copy_rounded, color: _green, size: 18),
                  label: Text(
                    'Copy',
                    style: GoogleFonts.inter(
                      color: _green,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_green, const Color(0xff00DC00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.ios_share_rounded,
                      color: Colors.black,
                    ),
                    label: Text(
                      'Share Referral Code',
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () => _shareReferralCode(code),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _howItWorksCard() {
    return _surfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How It Works', style: _heading.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'Simple 3-step flow to grow your network and rewards.',
            style: GoogleFonts.inter(color: _mutedText, fontSize: 12),
          ),
          const SizedBox(height: 14),
          _stepItem(
            step: 'Step 1',
            text: 'Share your referral code with friends.',
            icon: Icons.share_rounded,
          ),
          _stepItem(
            step: 'Step 2',
            text: 'Friends register on HashforGamers using your code.',
            icon: Icons.person_add_alt_1_rounded,
          ),
          _stepItem(
            step: 'Step 3',
            text: 'You earn rewards after successful signup.',
            icon: Icons.card_giftcard_rounded,
          ),
        ],
      ),
    );
  }

  Widget _vouchersCard() {
    return _surfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Vouchers', style: _heading.copyWith(fontSize: 16)),
              Obx(
                () => controller.isLoadingVouchers.value
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: RainbowLoadingBar(),
                      )
                    : GestureDetector(
                        onTap: () => controller.getVoucher(),
                        child: Icon(Icons.refresh, color: _green, size: 20),
                      ),
              ),
            ],
          ),
          Obx(() {
            if (controller.vouchers.isEmpty) {
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(vertical: 30),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(
                      Icons.card_giftcard_outlined,
                      color: Colors.white54,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No vouchers yet',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first voucher and start sharing discounts.',
                      style: GoogleFonts.inter(color: _mutedText, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: controller.vouchers
                  .map((voucher) => _voucherItem(voucher))
                  .toList(),
            );
          }),
          const SizedBox(height: 14),
          Obx(
            () => controller.isLoading.value
                ? SizedBox(
                    width: double.infinity,
                    child: Center(child: RainbowLoadingBar()),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _green,
                        side: BorderSide(color: _green, width: 1.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: _green.withValues(alpha: 0.07),
                      ),
                      icon: Icon(Icons.card_giftcard_rounded, color: _green),
                      label: Text(
                        'Create Voucher',
                        style: GoogleFonts.inter(
                          color: _green,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () async {
                        try {
                          await controller.createVoucher();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? _green.withValues(alpha: 0.5) : Colors.white24,
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
                      style: GoogleFonts.inter(color: _mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? _green.withValues(alpha: 0.2)
                      : Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  discountText,
                  style: GoogleFonts.inter(
                    color: isActive ? _green : Colors.white70,
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
                      ? const Color(0xff00DC00).withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? Icons.check_circle : Icons.cancel,
                      color: isActive ? const Color(0xff00DC00) : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? 'Active' : 'Inactive',
                      style: GoogleFonts.inter(
                        color: isActive ? const Color(0xff00DC00) : Colors.red,
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
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          'Use my HashforGamers voucher code: ${voucher.code} for ${voucher.discountPercentage}% discount! 🎮',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Voucher code ${voucher.code} shared!'),
                      backgroundColor: _green,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _green, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.share, color: _green, size: 14),
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
    final referralCode = controller.getReferralCode();
    return Scaffold(
      backgroundColor: const Color(0xFF030403),
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: const Color(0xFF030403),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Refer & Earn',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Share with friends. Earn rewards.',
              style: GoogleFonts.inter(color: _mutedText, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshReferralData,
            icon: Icon(Icons.refresh_rounded, color: _green),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF050705), Color(0xFF020202)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: IgnorePointer(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _green.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 180,
              left: -90,
              child: IgnorePointer(
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _green.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _green.withValues(alpha: 0.32)),
                      gradient: LinearGradient(
                        colors: [
                          _green.withValues(alpha: 0.14),
                          _green.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.gift_fill,
                              color: _green,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Referral Boost Live',
                              style: GoogleFonts.inter(
                                color: _green,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Invite friends to HashForGamers and convert referrals into coins + vouchers.',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: referralCode),
                                  );
                                  _showCopiedToast();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _green,
                                  side: BorderSide(
                                    color: _green.withValues(alpha: 0.4),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                  ),
                                ),
                                child: Text(
                                  'Copy Code',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _shareReferralCode(referralCode),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _green,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                  ),
                                ),
                                child: Text(
                                  'Invite Now',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Code: $referralCode',
                          style: GoogleFonts.inter(
                            color: _mutedText,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  _earningsCard(),
                  _referralCodeCard(),
                  _howItWorksCard(),
                  _vouchersCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
