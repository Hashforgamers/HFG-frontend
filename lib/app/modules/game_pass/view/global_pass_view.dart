import 'dart:ui';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/game_pass/cubit/get_game_pass_cubit.dart';
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

enum GlobalPassCardType { rightImage, leftImage }

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

      final userId = userData['id']?.toString() ?? '';
      if (userId.isEmpty) {
        throw Exception('User ID not found. Please login again.');
      }

      // Create Razorpay order
      final orderId = await _createRazorpayOrder(pass.price);

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
    return BlocBuilder<GetGamePassCubit, GetGamePassState>(
      builder: (context, state) {
        if (state is GetGamePassLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is GetGamePassError) {
          return _buildError(context, state.message);
        }

        if (state is GetGamePassLoaded) {
          final passes = state.gamePass;
          if (passes.isEmpty) {
            return _buildEmpty(context);
          }

          return ListView.separated(
            itemCount: passes.length + 2,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              if (index == 0) return _buildLabel();
              if (index == 1) return const SizedBox(height: 30);
              final GetPassModel pass = passes[index - 2];
              final title = pass.name;
              final info = _formatInfo(pass);
              return _buildGlobalPassCard(
                pass: pass,
                image: 'assets/images/globalpass1.png',
                title: title,
                info: info,
                color: const Color(0xFFE6D009),
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
    required GetPassModel pass,
    GlobalPassCardType type = GlobalPassCardType.leftImage,
    required String image,
    required String title,
    required String info,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: CachedNetworkImage(
                imageUrl: image,
                height: 200,
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
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 24,
              left: type == GlobalPassCardType.rightImage ? 0 : 20,
              right: type == GlobalPassCardType.rightImage ? 20 : 0,
              child: Column(
                crossAxisAlignment: type == GlobalPassCardType.rightImage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  CachedNetworkImage(
                    imageUrl:
                        'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/crown_mzzqhy.png',
                    height: 26,
                    width: 26,
                    placeholder: (_, _) =>
                        const Center(child: RainbowGlowingLoader(size: 20)),
                    errorWidget: (_, _, _) =>
                        const Icon(Icons.error, color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info,
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'use to book at any cafe',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 10),
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () => GestureDetector(
                      onTap: _processingPasses[pass.id] == true
                          ? null
                          : () => _purchaseGamePass(pass),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: _processingPasses[pass.id] == true
                              ? Colors.grey
                              : color,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: _processingPasses[pass.id] == true
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Buy Pass',
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel() {
    return Column(
      children: [
        CachedNetworkImage(
          imageUrl:
              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/globalPassIcon_t5cod0.png',
          height: 80,
          width: 80,
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
        const SizedBox(height: 8),
        Text(
          'Buy a Global Hash Pass',
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
        ),
      ],
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
              context.read<GetGamePassCubit>().getActiveGamePass();
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
