import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:hash/app/modules/hash_coin/cubit/create_offer_cubit.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/app/modules/hash_coin/widgets/hash_coin_icon.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

import '../../utils/widgets/loader.dart';

class GlobalBottomSheetService {
  static final GlobalBottomSheetService _instance =
      GlobalBottomSheetService._internal();
  factory GlobalBottomSheetService() => _instance;
  GlobalBottomSheetService._internal();

  // Cubit instances
  late CreateOfferCubit _createOfferCubit;
  late HashCoinCubit _hashCoinCubit;

  // Initialize cubits
  void initializeCubits() {
    _createOfferCubit = CreateOfferCubit();
    _hashCoinCubit = HashCoinCubit();
  }

  // Get cubit instances
  CreateOfferCubit get createOfferCubit => _createOfferCubit;
  HashCoinCubit get hashCoinCubit => _hashCoinCubit;

  // Dispose cubits
  void disposeCubits() {
    _createOfferCubit.close();
    _hashCoinCubit.close();
  }

  // Show hash coin redemption bottom sheet
  Future<void> showHashCoinRedemptionBottomSheet(
    BuildContext context, {
    required int hashCoin,
    required Function(String) onSuccess,
    required Function(String) onError,
    required Function() onLoading,
  }) async {
    // Initialize cubits if not already done
    initializeCubits();

    final vouchers = [
      {
        'discount': 10,
        'requiredCoins': 10000,
        'code': 'Hash10',
        'desc': 'Save on your next cafe booking',
      },
      {
        'discount': 20,
        'requiredCoins': 20000,
        'code': 'Hash20',
        'desc': 'Save on your next cafe booking',
      },
      {
        'discount': 30,
        'requiredCoins': 30000,
        'code': 'Hash30',
        'desc': 'Save on your next cafe booking',
      },
    ];

    int? selectedVoucher;
    // Vouchers are sorted by cost, so the first locked one is the next goal.
    final nextGoal = vouchers
        .where((v) => hashCoin < (v['requiredCoins'] as int))
        .firstOrNull;
    final hasRedeemableVoucher = vouchers.any(
      (v) => hashCoin >= (v['requiredCoins'] as int),
    );
    const earnWays = [
      (
        Icons.sports_esports_rounded,
        'Play games',
        'Every gaming session',
        '+50',
      ),
      (
        Icons.group_add_rounded,
        'Refer friends',
        'Each successful referral',
        '+100',
      ),
      (
        Icons.calendar_today_rounded,
        'Daily login',
        'A random reward every day',
        '5-20',
      ),
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      isScrollControlled: true,
      builder: (context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _createOfferCubit),
            BlocProvider.value(value: _hashCoinCubit),
          ],
          child: BlocListener<CreateOfferCubit, CreateOfferState>(
            listener: (context, state) {
              if (state is CreateOfferLoading) {
                onLoading();
              } else if (state is CreateOfferSuccess) {
                Navigator.pop(context);
                onSuccess(
                  'Successfully redeemed! Your voucher has been created.',
                );
              } else if (state is CreateOfferFailure) {
                Navigator.pop(context);
                onError(state.message);
              }
            },
            child: StatefulBuilder(
              builder: (context, setState) {
                const accent = Color(0xff00DC00);
                return FractionallySizedBox(
                  heightFactor: 0.74,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xE6161818), Color(0xD6080A08)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 28,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    width: 42,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.22,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Redeem HashCoins',
                                            style: GoogleFonts.inter(
                                              fontSize: 21,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Unlock discounts on your next bookings',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        accent.withValues(alpha: 0.14),
                                        Colors.white.withValues(alpha: 0.035),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: accent.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: accent.withValues(
                                                alpha: 0.12,
                                              ),
                                            ),
                                            child: const Center(
                                              child: HashCoinIcon(size: 30),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Balance',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${_formatHashCoins(hashCoin)} HC',
                                                style: GoogleFonts.inter(
                                                  fontSize: 22,
                                                  color: accent,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (nextGoal != null) ...[
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                          child: LinearProgressIndicator(
                                            value:
                                                hashCoin /
                                                (nextGoal['requiredCoins']
                                                    as int),
                                            minHeight: 6,
                                            color: accent,
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.1),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${_formatHashCoins((nextGoal['requiredCoins'] as int) - hashCoin)} HC '
                                          'to ${nextGoal['discount']}% OFF',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  hasRedeemableVoucher
                                      ? 'Choose a reward'
                                      : 'Rewards',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: ListView.separated(
                                    // Nothing redeemable: end with ways to
                                    // earn instead of a dead button.
                                    itemCount:
                                        vouchers.length +
                                        (hasRedeemableVoucher ? 0 : 1),
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, i) {
                                      if (i == vouchers.length) {
                                        return _earnWaysCard(earnWays, accent);
                                      }
                                      final voucher = vouchers[i];
                                      final int requiredCoins =
                                          voucher['requiredCoins'] as int;
                                      final int discount =
                                          voucher['discount'] as int;
                                      final String code =
                                          voucher['code'] as String;
                                      final String desc =
                                          voucher['desc'] as String;
                                      final bool hasEnough =
                                          hashCoin >= requiredCoins;
                                      final bool isSelected =
                                          selectedVoucher == i;
                                      final int coinsNeeded =
                                          requiredCoins - hashCoin;
                                      return GestureDetector(
                                        onTap: hasEnough
                                            ? () => setState(
                                                () => selectedVoucher = i,
                                              )
                                            : null,
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? accent.withValues(alpha: 0.14)
                                                : Colors.white.withValues(
                                                    alpha: 0.045,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? accent
                                                  : hasEnough
                                                  ? Colors.white.withValues(
                                                      alpha: 0.16,
                                                    )
                                                  : Colors.white.withValues(
                                                      alpha: 0.08,
                                                    ),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: hasEnough
                                                      ? accent.withValues(
                                                          alpha: 0.16,
                                                        )
                                                      : Colors.white.withValues(
                                                          alpha: 0.06,
                                                        ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.local_offer_rounded,
                                                  color: hasEnough
                                                      ? accent
                                                      : Colors.white54,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            '$discount% OFF',
                                                            style: GoogleFonts.inter(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color: hasEnough
                                                                  ? Colors.white
                                                                  : Colors
                                                                        .white54,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '${_formatHashCoins(requiredCoins)} HC',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: hasEnough
                                                                ? accent
                                                                : Colors
                                                                      .white54,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      desc,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        color: hasEnough
                                                            ? Colors.white70
                                                            : Colors.white54,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    if (!hasEnough) ...[
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              99,
                                                            ),
                                                        child: LinearProgressIndicator(
                                                          value:
                                                              hashCoin /
                                                              requiredCoins,
                                                          minHeight: 4,
                                                          color: accent
                                                              .withValues(
                                                                alpha: 0.7,
                                                              ),
                                                          backgroundColor:
                                                              Colors.white
                                                                  .withValues(
                                                                    alpha: 0.08,
                                                                  ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        '${_formatHashCoins(coinsNeeded)} HC to go',
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .white60,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ] else
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: accent
                                                                  .withValues(
                                                                    alpha: 0.08,
                                                                  ),
                                                              border: Border.all(
                                                                color: accent
                                                                    .withValues(
                                                                      alpha:
                                                                          0.12,
                                                                    ),
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              code,
                                                              style: GoogleFonts.inter(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: hasEnough
                                                                    ? accent
                                                                    : Colors
                                                                          .white70,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(
                                                hasEnough
                                                    ? (isSelected
                                                          ? Icons.check_circle
                                                          : Icons
                                                                .radio_button_unchecked)
                                                    : Icons
                                                          .lock_outline_rounded,
                                                color: hasEnough
                                                    ? (isSelected
                                                          ? accent
                                                          : Colors.white54)
                                                    : Colors.white38,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (hasRedeemableVoucher) ...[
                                  const SizedBox(height: 12),
                                  BlocBuilder<
                                    CreateOfferCubit,
                                    CreateOfferState
                                  >(
                                    builder: (context, state) {
                                      final isLoading =
                                          state is CreateOfferLoading;
                                      final canRedeem =
                                          selectedVoucher != null && !isLoading;
                                      final ctaText = selectedVoucher != null
                                          ? 'Redeem ${vouchers[selectedVoucher!]['discount']}% OFF'
                                          : 'Select a reward to continue';
                                      return GestureDetector(
                                        onTap: canRedeem
                                            ? () {
                                                final voucher =
                                                    vouchers[selectedVoucher!];
                                                final int discount =
                                                    voucher['discount'] as int;
                                                _processRedemption(
                                                  discount,
                                                  hashCoin,
                                                );
                                              }
                                            : null,
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            gradient: canRedeem
                                                ? LinearGradient(
                                                    colors: [
                                                      accent,
                                                      accent.withValues(
                                                        alpha: 0.78,
                                                      ),
                                                    ],
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                  )
                                                : null,
                                            color: canRedeem
                                                ? null
                                                : Colors.white.withValues(
                                                    alpha: 0.14,
                                                  ),
                                          ),
                                          child: isLoading
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: AppLinearLoader(),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      'Processing...',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Text(
                                                  ctaText,
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    color: canRedeem
                                                        ? Colors.black
                                                        : Colors.white,
                                                  ),
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _earnWaysCard(
    List<(IconData, String, String, String)> ways,
    Color accent,
  ) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.045),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ways to earn',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        for (final (icon, title, subtitle, coins) in ways)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Icon(icon, color: accent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$coins HC',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  // Helper method to format hash coin numbers
  String _formatHashCoins(int coins) {
    if (coins >= 1000) {
      double kValue = coins / 1000.0;
      return '${kValue.toStringAsFixed(kValue.truncateToDouble() == kValue ? 0 : 1)}K';
    }
    return coins.toString();
  }

  // Process redemption
  void _processRedemption(int percentage, int hashCoin) async {
    // Calculate required coins based on percentage
    int requiredCoins;
    switch (percentage) {
      case 10:
        requiredCoins = 10000;
        break;
      case 20:
        requiredCoins = 20000;
        break;
      case 30:
        requiredCoins = 30000;
        break;
      default:
        requiredCoins = 10000;
    }

    // Check if user has enough coins
    if (hashCoin >= requiredCoins) {
      try {
        final remoteRepo = locator<RemoteRepoInterface>();
        final userData = await remoteRepo.getUserFromPreferences();

        if (userData != null) {
          final userId = userData['id']?.toString() ?? '';
          if (userId.isNotEmpty) {
            // Use the CreateOfferCubit to process the redemption
            _createOfferCubit.createOffer(percentage, userId);
          } else {
            // Handle error through callback
            _createOfferCubit.fail('User ID not found');
          }
        } else {
          _createOfferCubit.fail('User data not found');
        }
      } catch (e) {
        _createOfferCubit.fail('Error processing redemption: $e');
      }
    } else {
      _createOfferCubit.fail(
        'Insufficient coins. You need ${_formatHashCoins(requiredCoins)} coins for $percentage% redemption.',
      );
    }
  }

  // Show success snackbar
  void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xff00DC00),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Show error snackbar
  void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Show loading snackbar
  void showLoadingSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20, child: AppLinearLoader()),
            const SizedBox(width: 16),
            Text(
              'Processing redemption...',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xffDE3A3A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
