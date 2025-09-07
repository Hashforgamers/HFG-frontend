import 'dart:ui';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/game_pass/cubit/game_pass_cubit.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';
import 'package:http/http.dart' as http;
import 'package:hash/core/repositories/model/get_pass_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/config/flavor_config.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/payment/razorpay_controller.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

import '../../../../utils/widgets/loader.dart';

enum GlobalPassCardBtnType { btnCenter, btnRight }

enum GlobalPassCardTitleType { titleCenter, titleLeft }

enum GlobalPassCardSubTitleType { up, down }

class GlobalPassView extends StatefulWidget {
  final TabController tabController;
  final String type; // 'hash'
  const GlobalPassView({
    super.key,
    required this.tabController,
    required this.type,
  });

  @override
  State<GlobalPassView> createState() => _GlobalPassViewState();
}

class _GlobalPassViewState extends State<GlobalPassView> {
  final RazorpayController _razorpayController = Get.put(RazorpayController());
  final UserController _userController = Get.find<UserController>();
  final _remoteRepo = locator<RemoteRepoInterface>();
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

  Future<void> _purchaseGamePass(GetPassModel pass) async {
    final passId = pass.id;
    if (_processingPasses[passId] == true) return;

    try {
      _processingPasses[passId] = true;
      _paymentStatus.value = 'Creating payment order...';

      // Get user data
      final userData = await _remoteRepo.getUserFromPreferences();
      if (userData == null) {
        throw Exception('User not found. Please login again.');
      }

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
        bookingId: 'pass_${pass.id}',
        amount: pass.price,
        paymentMethodSelected: 'razorpay',
      );
      _fbEventsService.onPaymentInitiated(
        bookingId: 'pass_${pass.id}',
        amount: pass.price,
        paymentMethodSelected: 'razorpay',
      );

      // Open Razorpay checkout
      _razorpayController.openCheckout(
        orderId: orderId,
        name: _userController.user.value.name ?? 'User',
        description: 'Game Pass: ${pass.name}',
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

  final List<String> passImagesHQ = [
    'https://res.cloudinary.com/dxjjigepf/image/upload/v1756904249/dailyPass_kphyzf.png',
    'https://res.cloudinary.com/dxjjigepf/image/upload/v1756904250/weeklyPass_p7fhtm.png',
    'https://res.cloudinary.com/dxjjigepf/image/upload/v1756904250/monthlyPass_xcqhyf.png',
    'https://res.cloudinary.com/dxjjigepf/image/upload/q_auto:best,f_auto,w_1080,h_720,c_fill/v1755075171/cafepass3_on04c0.png',
  ];

  Future<String> _createRazorpayOrder(double amount) async {
    final amountInPaisa = (amount * 100).toInt();
    final receiptId = "pass_rcpt_${DateTime.now().millisecondsSinceEpoch}";

    final url = '${FlavorConfig.getBaseUrl('booking')}/api/create_order';
    final payload = {
      "amount": amountInPaisa,
      "currency": "INR",
      "receipt": receiptId,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'];
    } else {
      throw Exception('Failed to create payment order: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GamePassCubit, GamePassState>(
      builder: (context, state) {
        if (state is GamePassLoading) {
          return const Center(child: RainbowLoadingBar());
        }

        if (state is GamePassError) {
          return _buildError(context, state.message);
        }

        if (state is GamePassLoaded) {
          final passes = state.gamePass;
          if (passes.isEmpty) {
            return _buildEmpty(context);
          }

          return ListView.separated(
            itemCount: passes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final GetPassModel pass = passes[index];
              final title = pass.name;
              final info = _formatInfo(pass);

              return _buildGlobalPassCard(
                index: index,
                pass: pass,
                image:
                    passImagesHQ[index %
                        passImagesHQ.length], // cycles through list
                title: title,
                info: info,
                onTap: () {},
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  String _formatInfo(GetPassModel pass) {
    // Example: "30 Days @ Rs.1500"
    final durationPart = pass.passType.toLowerCase() == 'daily'
        ? '24 Hours'
        : pass.passType.toLowerCase() == 'monthly'
        ? '${pass.daysValid} Days'
        : '${pass.daysValid} Days';
    final pricePart = 'Rs.${pass.price.toStringAsFixed(0)}';
    return '$durationPart @ $pricePart';
  }

  Widget _buildGlobalPassCard({
    required int index,
    required GetPassModel pass,
    required String image,
    required String title,
    required String info,
    required VoidCallback onTap,
  }) {
    const gradients = [
      LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF302C2A), Color(0xFF968983)],
      ),
      LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF331F45), Color(0xFF745195)],
      ),
      LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF144542), Color(0xFF6EAAA9)],
      ),
    ];

    // 🔹 Apply exact params for the first 3 passes
    final Gradient btnColor = index < gradients.length
        ? gradients[index]
        : const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF444444), Color(0xFF888888)], // fallback
          );

    const tops = [30.0, 70.0, 40.0];
    final double top = index < tops.length ? tops[index] : 30.0;

    const titleTypes = [
      GlobalPassCardTitleType.titleCenter,
      GlobalPassCardTitleType.titleCenter,
      GlobalPassCardTitleType.titleLeft,
    ];

    final titleType = index < titleTypes.length
        ? titleTypes[index]
        : GlobalPassCardTitleType.titleCenter;

    const subTitleTypes = [
      GlobalPassCardSubTitleType.down,
      GlobalPassCardSubTitleType.up,
      GlobalPassCardSubTitleType.down,
    ];

    final subTitleType = index < subTitleTypes.length
        ? subTitleTypes[index]
        : GlobalPassCardSubTitleType.down;

    const btnTypes = [
      GlobalPassCardBtnType.btnRight,
      GlobalPassCardBtnType.btnCenter,
      GlobalPassCardBtnType.btnRight,
    ];

    final btnType = index < btnTypes.length
        ? btnTypes[index]
        : GlobalPassCardBtnType.btnRight;

    print("pass image $image");
    return BounceTap(
      onTap: pass.isBought == true ? null : onTap,
      child: Container(
        height: 200,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(26)),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: CachedNetworkImage(
                imageUrl: image,
                height: 200,
                filterQuality:
                    FilterQuality.high, // 👈 improves scaling quality

                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    const Center(child: RainbowGlowingLoader(size: 40)),
                errorWidget: (_, _, _) => Container(
                  color: Colors.grey,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              ),
            ),
            Positioned(
              top: top,
              left: titleType == GlobalPassCardTitleType.titleCenter ? 60 : 30,
              right: titleType == GlobalPassCardTitleType.titleCenter
                  ? 60
                  : 110,
              child: Column(
                crossAxisAlignment:
                    titleType == GlobalPassCardTitleType.titleCenter
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  subTitleType == GlobalPassCardSubTitleType.up
                      ? Text(
                          'PREMIUM',
                          style: GoogleFonts.merriweather(
                            color: Color(0xFFA09F9F),
                            fontSize: 16,
                            letterSpacing: 6,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const SizedBox(),
                  Text(
                    title,
                    textAlign: titleType == GlobalPassCardTitleType.titleCenter
                        ? TextAlign.center
                        : TextAlign.start,
                    style: GoogleFonts.merriweather(
                      color: Color(0xFFDADADA),
                      fontSize: 20,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subTitleType == GlobalPassCardSubTitleType.down
                      ? Text(
                          'PREMIUM',
                          style: GoogleFonts.merriweather(
                            color: Color(0xFFA09F9F),
                            fontSize: 16,
                            letterSpacing: 6,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const SizedBox(),
                ],
              ),
            ),
            Positioned(
              bottom: 24,
              right: btnType == GlobalPassCardBtnType.btnRight ? 30 : 120,
              child: Column(
                crossAxisAlignment: btnType == GlobalPassCardBtnType.btnRight
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.center,
                children: [
                  Text(
                    info,
                    style: GoogleFonts.merriweather(
                      color: Color(0xFFB3B3B3),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => GestureDetector(
                      onTap:
                          (pass.isBought == true ||
                              _processingPasses[pass.id] == true)
                          ? null
                          : () => _purchaseGamePass(pass),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 24,
                        ),
                        decoration: BoxDecoration(
                          // color: (pass.isBought == true || _processingPasses[pass.id] == true)
                          //     ? Colors.grey
                          //     : color,
                          gradient: btnColor,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: _processingPasses[pass.id] == true
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: RainbowLoadingBar(),
                              )
                            : Text(
                                pass.isBought == true
                                    ? 'Already Bought'
                                    : 'Get Now',
                                style: GoogleFonts.merriweather(
                                  // color: pass.isBought == true
                                  //     ? Colors.white
                                  //     : Colors.black,
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 100,
              bottom: 4,
              child: Text(
                'can be used to book at any cafe',
                style: GoogleFonts.merriweather(
                  color: Color(0xFF717171),
                  fontSize: 10,
                ),
              ),
            ),
          ],
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
