import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:hash/app/modules/hash_coin/cubit/create_offer_cubit.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

import '../../utils/widgets/loader.dart';

class GlobalBottomSheetService {
  static final GlobalBottomSheetService _instance = GlobalBottomSheetService._internal();
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
        'desc': 'Redeem for just 10,000 HashCoins.'
      },
      {
        'discount': 20,
        'requiredCoins': 20000,
        'code': 'Hash20',
        'desc': 'Redeem for just 20,000 HashCoins.'
      },
      {
        'discount': 30,
        'requiredCoins': 30000,
        'code': 'Hash30',
        'desc': 'Redeem for just 30,000 HashCoins.'
      },
    ];

    int? selectedVoucher;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
                onSuccess('Successfully redeemed! Your voucher has been created.');
              } else if (state is CreateOfferFailure) {
                Navigator.pop(context);
                onError(state.message);
              }
            },
            child: StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Close button
                            Align(
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // HashCoins Balance
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Stack(alignment: Alignment.center,
                                    children: [
                                      const Icon(Icons.hexagon, color: Colors.green, size: 28),
                                      Text('H',style: TextStyle( color: Colors.black),),

                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'HashCoins Balance',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _formatHashCoins(hashCoin),
                                      style: GoogleFonts.inter(
                                        fontSize: 32,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use your HashCoins to unlock exclusive discounts on your bookings',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Vouchers',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.separated(
                                itemCount: vouchers.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                  final voucher = vouchers[i];
                                  final int requiredCoins = voucher['requiredCoins'] as int;
                                  final int discount = voucher['discount'] as int;
                                  final String code = voucher['code'] as String;
                                  final String desc = voucher['desc'] as String;
                                  final bool hasEnough = hashCoin >= requiredCoins;
                                  final bool isSelected = selectedVoucher == i;
                                  final int coinsNeeded = requiredCoins - hashCoin;
                                  return GestureDetector(
                                    onTap: hasEnough
                                        ? () {
                                            setState(() {
                                              selectedVoucher = i;
                                            });
                                          }
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.01),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.green
                                              : hasEnough
                                                  ? Colors.white.withOpacity(0.2)
                                                  : Colors.grey.withOpacity(0.3),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.card_giftcard,
                                            color: hasEnough ? Colors.white : Colors.grey,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Flat $discount% OFF',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w700,
                                                        color: hasEnough ? Colors.white : Colors.grey,
                                                      ),
                                                    ),
                                                    if (isSelected)
                                                      Padding(
                                                        padding: const EdgeInsets.only(left: 8.0),
                                                        child: Icon(Icons.check_circle, color: Colors.green, size: 18),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  desc,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    color: hasEnough ? Colors.white70 : Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: hasEnough ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    code,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13,
                                                      color: hasEnough ? Colors.green : Colors.grey,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                if (!hasEnough)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 6.0),
                                                    child: Text(
                                                      'You need \'${_formatHashCoins(coinsNeeded)}\' more HashCoins to redeem this voucher.',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Radio<int>(
                                            value: i,
                                            groupValue: selectedVoucher,
                                            onChanged: hasEnough
                                                ? (val) {
                                                    setState(() {
                                                      selectedVoucher = val;
                                                    });
                                                  }
                                                : null,
                                            activeColor: Colors.green,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            BlocBuilder<CreateOfferCubit, CreateOfferState>(
                              builder: (context, state) {
                                final isLoading = state is CreateOfferLoading;
                                return GestureDetector(
                                  onTap: (selectedVoucher != null && !isLoading)
                                      ? () {
                                          final voucher = vouchers[selectedVoucher!];
                                          final int discount = voucher['discount'] as int;
                                          _processRedemption(discount, hashCoin);
                                        }
                                      : null,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    decoration: BoxDecoration(
                                      color: (selectedVoucher != null && !isLoading)
                                          ? Colors.green
                                          : Colors.grey.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: isLoading
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: RainbowLoadingBar(
                                               ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Processing...',
                                                style: GoogleFonts.inter(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            'Redeem',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ],
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
            _createOfferCubit.emit(const CreateOfferFailure(message: 'User ID not found'));
          }
        } else {
          _createOfferCubit.emit(const CreateOfferFailure(message: 'User data not found'));
        }
      } catch (e) {
        _createOfferCubit.emit(CreateOfferFailure(message: 'Error processing redemption: $e'));
      }
    } else {
      _createOfferCubit.emit(CreateOfferFailure(
        message: 'Insufficient coins. You need ${_formatHashCoins(requiredCoins)} coins for $percentage% redemption.'
      ));
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
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
             SizedBox(
              width: 20,
              height: 20,
              child: RainbowLoadingBar(

              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Processing redemption...',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xffDE3A3A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 