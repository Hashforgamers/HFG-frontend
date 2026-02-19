import 'dart:ui';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/game_pass/cubit/game_pass_cubit.dart';
import 'package:hash/core/repositories/model/get_pass_model.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/config/flavor_config.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/payment/razorpay_controller.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

import '../../../../utils/widgets/bounce_tap_widget.dart';
import '../../../../utils/widgets/loader.dart';

class CafeSpecificPassView extends StatefulWidget {
  final TabController tabController;
  final String type; // 'vendor'
  const CafeSpecificPassView({
    super.key,
    required this.tabController,
    required this.type,
  });

  @override
  State<CafeSpecificPassView> createState() => _CafeSpecificPassViewState();
}

class _CafeSpecificPassViewState extends State<CafeSpecificPassView> {
  final RazorpayController _razorpayController = Get.put(RazorpayController());
  final UserController _userController = Get.find<UserController>();
  final _segmentService = locator<SegmentSdkService>();
  final _fbEventsService = locator<FbEventsService>();

  final RxMap<String, bool> _processingPasses = <String, bool>{}.obs;
  final RxString _paymentStatus = ''.obs;

  @override
  void initState() {
    super.initState();
    _setupPaymentListeners();
  }

  void _setupPaymentListeners() {
    // Listen to Razorpay controller payment status
    ever(_razorpayController.paymentStatus, (String status) {
      if (status.isNotEmpty) {
        _paymentStatus.value = status;
        if (status.toLowerCase().contains('successful')) {
          _clearAllProcessingStates();
          // Success message is already handled by RazorpayController
        } else if (status.toLowerCase().contains('failed') ||
            status.toLowerCase().contains('error')) {
          _clearAllProcessingStates();
          // Error message is already handled by RazorpayController
        }
      }
    });

    // Listen to Razorpay controller payment progress
    ever(_razorpayController.isPaymentInProgress, (bool inProgress) {
      if (!inProgress) {
        _clearAllProcessingStates();
      }
    });
  }

  void _clearAllProcessingStates() {
    _processingPasses.clear();
  }

  Future<void> _purchaseCafePass(GetPassModel pass) async {
    final passId = pass.id;
    if (_processingPasses[passId] == true) return;

    try {
      _processingPasses[passId] = true;
      _paymentStatus.value = 'Creating payment order...';
      // Create Razorpay order
      final orderId = await _createRazorpayOrder(pass.price);

      // Track hash pass initiated event
      _segmentService.onHashPassInitiated(
        email:
            _userController.user.value.contact?.electronicAddress?.emailId ??
            '',
        amount: pass.price,
      );

      // Track purchase initiated event
      _segmentService.onPaymentInitiated(
        bookingId: 'cafe_pass_${pass.id}',
        amount: pass.price,
        paymentMethodSelected: 'razorpay',
      );
      _fbEventsService.onPaymentInitiated(
        bookingId: 'cafe_pass_${pass.id}',
        amount: pass.price,
        paymentMethodSelected: 'razorpay',
      );

      // Open Razorpay checkout
      _razorpayController.openCheckout(
        orderId: orderId,
        name: _userController.user.value.name ?? 'User',
        description: 'Cafe Pass: ${pass.name} - ${pass.vendorName}',
        amount: pass.price,
        contact:
            _userController.user.value.contact?.electronicAddress?.mobileNo ??
            '',
        email:
            _userController.user.value.contact?.electronicAddress?.emailId ??
            '',
        paymentType: PaymentType.passPurchase,
      );

      // Store pass info for payment success handling
      _razorpayController.bookingIdList.value = [int.parse(pass.id)];
      // Clear slot IDs for pass purchases since passes don't have slots
      _razorpayController.slotIdsList.clear();
    } catch (e) {
      _processingPasses[passId] = false;
      Get.snackbar(
        'Error',
        'Failed to initiate payment: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<String> _createRazorpayOrder(double amount) async {
    final amountInPaisa = (amount * 100).toInt();
    final receiptId = "pass_rcpt_${DateTime.now().millisecondsSinceEpoch}";

    final url = '${FlavorConfig.getBaseUrl('booking')}/api/create_order';
    final payload = {
      "amount": amountInPaisa,
      "currency": "INR",
      "receipt": receiptId,
    };

    final dio = locator<NetworkProvider>().noAuth();
    final response = await dio.post(url, data: payload);

    if (response.statusCode == 200) {
      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      return data['id'];
    }

    throw Exception('Failed to create payment order: ${response.data}');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GamePassCubit, GamePassState>(
      builder: (context, state) {
        // Handle initial state - show loading to prevent flash of old data
        if (state is GamePassInitial) {
          return const Center(child: AppLinearLoader());
        }
        if (state is GamePassLoading) {
          return const Center(child: AppLinearLoader());
        }
        if (state is GamePassError) {
          return _buildError(context, state.message);
        }
        if (state is GamePassLoaded) {
          final passes = state.gamePass;
          if (passes.isEmpty) return _buildEmpty(context);

          return ListView.separated(
            scrollDirection: Axis.vertical,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: passes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final GetPassModel pass = passes[index];
              return _buildCafePassCard(context, pass);
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCafePassCard(BuildContext context, GetPassModel pass) {
    final Color accentColor = pass.name.toLowerCase().contains('24')
        ? const Color(0xff00DC00)
        : pass.name.toLowerCase().contains('7')
        ? Colors.purpleAccent
        : Colors.blueAccent;

    final String bgImage =
    (pass.vendorImages?.isNotEmpty == true)
        ? pass.vendorImages!.first.url
        : 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075171/cafepass3_on04c0.png';

    return Obx(
          () => BounceTap(
        onTap: (pass.isBought == true || _processingPasses[pass.id] == true)
            ? null
            : () => _purchaseCafePass(pass),
        child: Container(
          height: 190,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                /// 🔹 BACKGROUND IMAGE
                CachedNetworkImage(
                  imageUrl: bgImage,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                  const Center(child: RainbowGlowingLoader(size: 30)),
                  errorWidget: (_, __, ___) =>
                      Container(color: Colors.black),
                ),

                /// 🔹 BLUR LAYER
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    color: Colors.black.withOpacity(0.65),
                  ),
                ),

                /// 🔹 FOREGROUND CONTENT
                Row(
                  children: [
                    /// LEFT PROTOCOL STRIP
                    Container(
                      width: 44,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(20),
                        ),
                      ),
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: Center(
                          child: Text(
                            'PROTOCOL',
                            style: GoogleFonts.inter(
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// MAIN CONTENT
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// TOP ROW
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'LIFECYCLE',
                                  style: GoogleFonts.inter(
                                    color: accentColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  '₹${pass.price.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            /// TITLE
                            Text(
                              pass.name.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 10),

                            /// META
                            Text(
                              pass.vendorName,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),

                            const Spacer(),

                            /// ACTION BUTTON
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: pass.isBought == true
                                      ? Colors.grey.withOpacity(0.3)
                                      : accentColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _processingPasses[pass.id] == true
                                    ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: AppLinearLoader(),
                                )
                                    : Text(
                                  pass.isBought == true
                                      ? 'ACTIVE'
                                      : 'INITIALIZE',
                                  style: GoogleFonts.inter(
                                    color: pass.isBought == true
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    fontSize: 12,
                                  ),
                                ),
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
          ),
        ),
      ),
    );
  }



  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: GoogleFonts.inter(color: Colors.white)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              context.read<GamePassCubit>().getGamePass(type: widget.type);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Text(
        'No passes found',
        style: GoogleFonts.inter(color: Colors.white70),
      ),
    );
  }
}
