import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hash/app/modules/game_pass/cubit/game_pass_cubit.dart';
import 'package:hash/core/repositories/model/get_pass_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/config/flavor_config.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/payment/razorpay_controller.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';

class CafeSpecificPassView extends StatefulWidget {
  final TabController tabController;
  final String type; // 'vendor'
  const CafeSpecificPassView({super.key, required this.tabController, required this.type});

  @override
  State<CafeSpecificPassView> createState() => _CafeSpecificPassViewState();
}

class _CafeSpecificPassViewState extends State<CafeSpecificPassView> {
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
          _showSuccessMessage();
        } else if (status.toLowerCase().contains('failed') || 
                   status.toLowerCase().contains('error')) {
          _clearAllProcessingStates();
          _showErrorMessage(status);
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

  void _showSuccessMessage() {
    Get.snackbar(
      'Success!',
      'Cafe pass purchased successfully!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _showErrorMessage(String message) {
    Get.snackbar(
      'Payment Failed',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  Future<void> _purchaseCafePass(GetPassModel pass) async {
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
        contact: _userController.user.value.contact?.electronicAddress?.mobileNo ?? '',
        email: _userController.user.value.contact?.electronicAddress?.emailId ?? '',
      );

      // Store pass info for payment success handling
      _razorpayController.bookingIdList.value = [int.parse(pass.id)];

    } catch (e) {
      _processingPasses[passId] = false;
      _showErrorMessage('Failed to initiate payment: $e');
    }
  }

  Future<String> _createRazorpayOrder(double amount) async {
    final amountInPaisa = (amount * 100).toInt();
    final receiptId = "cafe_pass_order_${DateTime.now().millisecondsSinceEpoch}";
    
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
          return const Center(child: CircularProgressIndicator());
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
            itemCount: passes.length + 2,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              if (index == 0) return _buildLabel();
              if (index == 1) return const SizedBox(height: 30);
              final GetPassModel pass = passes[index - 2];
              return _buildCafePassCard(context, pass);
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  GestureDetector _buildCafePassCard(
    BuildContext context,
    GetPassModel pass,
  ) {
    return GestureDetector(
      onTap: () {
        _purchaseCafePass(pass);
      },
      child: Container(
        height: 200,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.asset(
                'assets/images/cafepass1.png',
                height: 200,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: Row(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: Colors.greenAccent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  pass.vendorName,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const SizedBox(width: 12),
                                Row(
                                  children: List.generate(
                                    4,
                                    (index) => const Icon(
                                      Icons.star,
                                      color: Color(0xFFE6D009),
                                      size: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pass: ${pass.name}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 13),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Obx(() => GestureDetector(
                          onTap: _processingPasses[pass.id] == true 
                              ? null 
                              : () => _purchaseCafePass(pass),
                          child: Container(
                            height: 36,
                            width: 100,
                            decoration: BoxDecoration(
                              color: _processingPasses[pass.id] == true 
                                  ? Colors.grey.withOpacity(0.3)
                                  : Colors.transparent,
                              border: Border.all(
                                color: _processingPasses[pass.id] == true 
                                    ? Colors.grey 
                                    : const Color(0xFFDADADA),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: _processingPasses[pass.id] == true
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Buy Pass',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFDADADA),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
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
        Image.asset('assets/icons/cafePassIcon.png', height: 50, width: 50),
        const SizedBox(height: 8),
        Text(
          'All Participating Cafes',
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
              context.read<GamePassCubit>().getGamePass(type: widget.type);
            },
            child: const Text('Retry'),
          )
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
