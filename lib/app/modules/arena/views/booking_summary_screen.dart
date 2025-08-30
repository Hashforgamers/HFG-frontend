import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/app/modules/arena/views/payment_success.dart';
import 'package:hash/app/modules/home/controllers/home_controller.dart';
import 'package:hash/app/modules/payment/razorpay_controller.dart';
import 'package:hash/app/modules/arena/views/past_booking_screen.dart';
import 'package:hash/config/flavor_config.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/repositories/model/get_pass_model.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/repositories/model/get_voucher_model.dart';
import '../../../../core/repositories/model/extra_services_model.dart';
import '../../../../utils/widgets/loader.dart';
import '../../../data/services/user_controller.dart';
import '../../../../core/repositories/model/booking_model.dart';

class BookingSummaryScreen extends StatefulWidget {
  final String selectedCafeName;
  final String consoleType;
  final String selectedDate;
  final List<Map<String, dynamic>> selectedSlots;
  final List<Map<String, dynamic>> cartItems;
  final int gameId;
  final int vendorId;

  const BookingSummaryScreen({
    super.key,
    required this.selectedCafeName,
    required this.consoleType,
    required this.selectedSlots,
    required this.cartItems,
    required this.vendorId,
    required this.gameId,
    required this.selectedDate,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

enum PaymentStage {
  idle,
  creatingBooking,
  debitingWallet,
  initiatingGateway,
  confirmingVoucher,
  confirmingGamePass,
  confirmingPayAtCafe,
  openingRazorpay,
  done,
  error,
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  final BookingController bookingController = Get.put(BookingController());
  final RazorpayController razorpayController = Get.put(RazorpayController());
  final HomeController homeController = Get.find();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();
  final _remoteRepo = locator<RemoteRepoInterface>();
  final prefs = locator<SharedPreferences>();
  final RxString _selectedPayment =
      'gateway'.obs; // 'wallet', 'gateway' or 'none'
  final UserController userController = Get.find<UserController>();

  // Voucher related variables
  final TextEditingController _voucherController = TextEditingController();
  final RxBool _isLoadingVouchers = false.obs;
  final RxList<Voucher> _availableVouchers = <Voucher>[].obs;
  final Rx<Voucher?> _appliedVoucher = Rx<Voucher?>(null);
  final RxBool _isApplyingVoucher = false.obs;
  final RxString _voucherError = ''.obs;

  // Game Pass related variables
  final RxBool _isLoadingGamePasses = false.obs;
  final RxList<GetPassModel> _userGamePasses = <GetPassModel>[].obs;
  final Rx<GetPassModel?> _selectedGamePass = Rx<GetPassModel?>(null);
  final RxString _gamePassError = ''.obs;

  // Payment processing state
  final RxBool _isProcessingPayment = false.obs;
  final RxString _paymentStatus = ''.obs;

  // Add this field to store the bookingId to slotId mapping
  Map<int, int> _bookingIdToSlotId = {};

  // Payment stage management
  final Rx<PaymentStage> _stage = PaymentStage.idle.obs;
  final RxString _errorMessage = ''.obs;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
    _loadUserGamePasses();
    // Listen to payment events
    _setupPaymentListeners();

    // Track booking summary viewed event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      segmentService.onBookingSummaryViewed(
        bookingId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        cafeId: 'cafe_${widget.gameId}',
        amount: calculateTotalPrice(),
      );
      fbEventsService.onBookingSummaryViewed(
        bookingId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        cafeId: 'cafe_${widget.gameId}',
        amount: calculateTotalPrice(),
      );
    });
  }

  @override
  void dispose() {
    _voucherController.dispose();
    _resetPaymentState();
    _selectedGamePass.value = null;
    super.dispose();
  }

  void _setupPaymentListeners() {
    // Listen to booking controller loading state
    ever(bookingController.isLoading, (bool loading) {
      if (!loading && _isProcessingPayment.value) {
        // Booking creation completed, payment will be initiated
        _paymentStatus.value = 'Initiating payment...';
        _stage.value = PaymentStage.initiatingGateway;
      }
    });

    // Listen to Razorpay controller payment status
    ever(razorpayController.paymentStatus, (String status) {
      if (status.isNotEmpty) {
        _paymentStatus.value = status;
        if (status.toLowerCase().contains('success')) {
          _stage.value = PaymentStage.done;
          _isProcessingPayment(false);
        } else if (status.toLowerCase().contains('failed') ||
            status.toLowerCase().contains('error') ||
            status.toLowerCase().contains('cancelled')) {
          _stage.value = PaymentStage.error;
          _errorMessage.value = status;
          _isProcessingPayment(false);
          razorpayController.isPaymentInProgress(false);
        }
      }
    });

    // Listen to Razorpay controller payment progress
    ever(razorpayController.isPaymentInProgress, (bool inProgress) {
      if (!inProgress && _isProcessingPayment.value) {
        // Payment completed (success or failure)
        if (_stage.value != PaymentStage.done &&
            _stage.value != PaymentStage.error) {
          _stage.value = PaymentStage.idle;
        }
        _isProcessingPayment(false);
        _paymentStatus.value = '';
      }
    });

    // Listen to Razorpay payment status changes
    ever(razorpayController.paymentStatus, (String status) {
      if (status.isNotEmpty) {
        _paymentStatus.value = status;
        if (status.toLowerCase().contains('successful')) {
          _stage.value = PaymentStage.done;
          _isProcessingPayment(false);
        } else if (status.toLowerCase().contains('failed') ||
            status.toLowerCase().contains('error') ||
            status.toLowerCase().contains('cancelled')) {
          _stage.value = PaymentStage.error;
          _errorMessage.value = status;
          _isProcessingPayment(false);
          razorpayController.isPaymentInProgress(false);
        }
      }
    });
  }

  Future<void> _loadVouchers() async {
    _isLoadingVouchers(true);
    try {
      final voucherResponse = await _remoteRepo.getVoucher(userId: '');
      if (voucherResponse.isNotEmpty) {
        _availableVouchers.value = voucherResponse.first.vouchers;
      } else {
        _availableVouchers.value = [];
      }
    } catch (e) {
      _availableVouchers.value = [];
    } finally {
      _isLoadingVouchers(false);
    }
  }

  Future<void> _loadUserGamePasses() async {
    _isLoadingGamePasses(true);
    _gamePassError.value = '';
    try {
      final userData = await _remoteRepo.getUserFromPreferences();
      if (userData != null) {
        final userId = userData['id']?.toString() ?? '0';
        final gamePasses = await _remoteRepo.getUserActiveGamePass(
          userId: userId,
        );

        // Filter passes based on vendor ID match
        final filteredPasses = _filterPassesByVendor(gamePasses);
        _userGamePasses.value = filteredPasses;
      } else {
        _userGamePasses.value = [];
        _gamePassError.value = 'User not found';
      }
    } catch (e) {
      _userGamePasses.value = [];
      _gamePassError.value = 'Failed to load game passes: $e';
    } finally {
      _isLoadingGamePasses(false);
    }
  }

  List<GetPassModel> _filterPassesByVendor(List<GetPassModel> passes) {
    // Use vendor ID from the constructor
    final currentVendorId = widget.vendorId.toString();

    // Filter passes to only show those that match the vendor ID
    // or are HASH Passes (vendor_id is null) - which can be used at any cafe
    return passes.where((pass) {
      // Show HASH Passes (vendor_id is null) - can be used at any cafe
      if (pass.vendorId == null) {
        return true;
      }

      // Show passes that match the current vendor
      return pass.vendorId == currentVendorId;
    }).toList();
  }

  Future<void> _applyVoucher() async {
    if (_voucherController.text.trim().isEmpty) {
      _voucherError.value = 'Please enter a voucher code';
      return;
    }

    _isApplyingVoucher(true);
    _voucherError.value = '';

    try {
      // Find voucher in available vouchers
      final voucher = _availableVouchers.firstWhereOrNull(
        (v) =>
            v.code.toLowerCase() ==
            _voucherController.text.trim().toLowerCase(),
      );

      if (voucher != null) {
              if (voucher.isActive) {
        // Check if this is a 100% voucher and validate slot count
        if (_isHundredPercentVoucher(voucher)) {
          if (!_canApplyVoucher(voucher)) {
            _voucherError.value = '100% vouchers can only be used for one slot. Please remove extra slots.';
            _isApplyingVoucher(false);
            return;
          }
        }

          _appliedVoucher.value = voucher;
          _voucherError.value = '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Voucher applied! ${voucher.discountPercentage}% discount',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _voucherError.value = 'This voucher is not active';
        }
      } else {
        _voucherError.value = 'Invalid voucher code';
      }
    } catch (e) {
      _voucherError.value = 'Error applying voucher';
    } finally {
      _isApplyingVoucher(false);
    }
  }

  void _selectVoucher(Voucher voucher) {
    if (voucher.isActive) {
      // Check if this is a 100% voucher and validate slot count
      if (_isHundredPercentVoucher(voucher) && !_canApplyVoucher(voucher)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('100% vouchers can only be used for one slot. Please remove extra slots.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      _voucherController.text = voucher.code;
      _applyVoucher();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This voucher is not active'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeVoucher() {
    _appliedVoucher.value = null;
    _voucherController.clear();
    _voucherError.value = '';
  }

  bool _isHundredPercentVoucher(Voucher voucher) {
    return voucher.discountPercentage == 100;
  }

  bool _canApplyVoucher(Voucher voucher) {
    // Check if voucher can be applied based on current slot selection
    if (_isHundredPercentVoucher(voucher)) {
      return widget.selectedSlots.length <= 1;
    }
    return true;
  }

  void _showGamePassSelectionDialog() {
    // Refresh game passes before showing dialog
    _loadUserGamePasses();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 500, minHeight: 200),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Hash Game Pass',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        Obx(
                          () => _isLoadingGamePasses.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CupertinoActivityIndicator(
                                    color: Colors.green,
                                  ),
                                )
                              : IconButton(
                                  onPressed: _loadUserGamePasses,
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.green,
                                  ),
                                ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Obx(() {
                  if (_isLoadingGamePasses.value) {
                    return const Center(child: RainbowLoadingBar());
                  }

                  if (_gamePassError.value.isNotEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _gamePassError.value,
                              style: GoogleFonts.inter(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_userGamePasses.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.gamepad_outlined,
                            color: Colors.grey.shade400,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Compatible Game Passes',
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade400,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You don\'t have any active game passes that can be used at this cafe.',
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'HASH Passes can be used at any cafe. Cafe-specific passes can only be used at their respective cafes.',
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return SizedBox(
                    height: 300, // Fixed height to avoid layout issues
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _userGamePasses.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final pass = _userGamePasses[index];
                        final isSelected =
                            _selectedGamePass.value?.id == pass.id;
                        final isExpired = pass.progressValue >= 1.0;

                        return GestureDetector(
                          onTap: isExpired
                              ? null
                              : () {
                                  _selectedGamePass.value = pass;
                                },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF338125).withOpacity(0.2)
                                  : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF338125)
                                    : isExpired
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pass.name,
                                            style: GoogleFonts.inter(
                                              color: isExpired
                                                  ? Colors.grey.shade500
                                                  : Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            pass.vendorName,
                                            style: GoogleFonts.inter(
                                              color: Colors.grey.shade400,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF338125),
                                        size: 24,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pass.expiryText,
                                            style: GoogleFonts.inter(
                                              color: isExpired
                                                  ? Colors.red
                                                  : Colors.grey.shade300,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (pass.description.isNotEmpty)
                                            Text(
                                              pass.description,
                                              style: GoogleFonts.inter(
                                                color: Colors.grey.shade400,
                                                fontSize: 12,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isExpired
                                                ? Colors.red.withOpacity(0.2)
                                                : const Color(
                                                    0xFF338125,
                                                  ).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            isExpired ? 'EXPIRED' : 'ACTIVE',
                                            style: GoogleFonts.inter(
                                              color: isExpired
                                                  ? Colors.red
                                                  : const Color(0xFF338125),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: pass.vendorId == null
                                                ? Colors.blue.withOpacity(0.2)
                                                : Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            pass.vendorId == null
                                                ? 'HASH'
                                                : 'CAFE',
                                            style: GoogleFonts.inter(
                                              color: pass.vendorId == null
                                                  ? Colors.blue
                                                  : Colors.orange,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (!isExpired) ...[
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: pass.progressValue,
                                    backgroundColor: Colors.grey.withOpacity(
                                      0.3,
                                    ),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF338125),
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade300,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: _selectedGamePass.value != null
                              ? () {
                                  Navigator.of(context).pop();
                                  // Proceed with the selected game pass
                                  _proceedWithGamePass();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF338125),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Proceed',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Color(0xff404040),
          title: const Text(
            "Enjoying our app?",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "We’d love your feedback! Please rate us on the Play Store.",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // dismiss
              },
              child: const Text(
                "Maybe Later",
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(
                  'hasRatedApp',
                  true,
                ); // remember that user rated
                final InAppReview inAppReview = InAppReview.instance;
                await inAppReview.openStoreListing();
              },
              child: const Text(
                "Rate Us",
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _maybeShowRatingDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRated = prefs.getBool('hasRatedApp') ?? false;

    if (!hasRated) {
      _showRatingDialog();
    }
  }

  void _proceedWithGamePass() {
    // This method will be called when user selects a game pass and clicks proceed
    // The actual booking logic will be handled in the existing handleBooking method
    if (_selectedGamePass.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a game pass to proceed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    handleBooking(
      context,
      isVoucherApplied: _appliedVoucher.value != null,
      useWallet: false,
      isGamePass: true,
      selectedPassId: _selectedGamePass.value!.id,
      isPayAtCafe: false,
    );
  }

  double calculateTotalPrice() {
    // Calculate subtotal including slots and cart items
    double subtotal = calculateSubtotal();

    if (_appliedVoucher.value != null) {
      double discount =
          subtotal * (_appliedVoucher.value!.discountPercentage / 100);
      double total = subtotal - discount;
      // Ensure total is not negative
      return total < 0 ? 0.0 : total;
    }

    return subtotal;
  }

  double calculateDiscount() {
    if (_appliedVoucher.value != null) {
      double subtotal = calculateSubtotal();
      double discount =
          subtotal * (_appliedVoucher.value!.discountPercentage / 100);
      // Ensure discount doesn't exceed subtotal
      return discount > subtotal ? subtotal : discount;
    }
    return 0.0;
  }

  double calculateSubtotal() {
    // Calculate slots subtotal with validation
    double slotsSubtotal = widget.selectedSlots.fold(0.0, (sum, slot) {
      double slotPrice = (slot['price'] ?? 50.0).toDouble();
      // Ensure price is not negative
      slotPrice = slotPrice < 0 ? 0.0 : slotPrice;
      return sum + slotPrice;
    });

    // Calculate cart items subtotal with validation
    double cartSubtotal = _getValidatedCartItems().fold(0.0, (sum, item) {
      double itemPrice = (item['price'] ?? 0.0).toDouble();
      int quantity = (item['qty'] ?? 1) as int;

      // Ensure price and quantity are not negative
      itemPrice = itemPrice < 0 ? 0.0 : itemPrice;
      quantity = quantity < 0 ? 0 : quantity;

      return sum + (itemPrice * quantity);
    });

    return slotsSubtotal + cartSubtotal;
  }

  double calculateSlotsSubtotal() {
    return widget.selectedSlots.fold(0.0, (sum, slot) {
      double slotPrice = (slot['price'] ?? 50.0).toDouble();
      // Ensure price is not negative
      slotPrice = slotPrice < 0 ? 0.0 : slotPrice;
      return sum + slotPrice;
    });
  }

  double calculateCartSubtotal() {
    return _getValidatedCartItems().fold(0.0, (sum, item) {
      double itemPrice = (item['price'] ?? 0.0).toDouble();
      int quantity = (item['qty'] ?? 1) as int;

      // Ensure price and quantity are not negative
      itemPrice = itemPrice < 0 ? 0.0 : itemPrice;
      itemPrice = itemPrice.isNaN ? 0.0 : itemPrice;
      quantity = quantity < 0 ? 0 : quantity;

      return sum + (itemPrice * quantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          '${widget.selectedCafeName} - ${widget.consoleType}',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   '${widget.selectedCafeName} - ${widget.consoleType}',
              //   style: GoogleFonts.inter(
              //     fontSize: 22,
              //     fontWeight: FontWeight.w600,
              //     color: Colors.white,
              //   ),
              // ),
              // const SizedBox(height: 4),
              Text(
                '${widget.selectedSlots.length} Slot(s) Selected',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB0B0B0),
                ),
              ),
              const SizedBox(height: 10),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.selectedSlots.length,
                separatorBuilder: (context, index) =>
                    Divider(color: Colors.grey.shade800),
                itemBuilder: (context, index) {
                  final slot = widget.selectedSlots[index];
                  final double slotPrice = (slot['price'] ?? 50.0).toDouble();
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot['console_label'] ?? 'PC ${slot['pc_index']}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${slot['start_time']} - ${slot['end_time']}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₹${slotPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(0xFF6DFB60),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 5),
              _getValidatedCartItems().isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF191919),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Food & Beverages',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF338125).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getCartItemsSummary(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Color(0xFF6DFB60),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemCount: _getValidatedCartItems().length,
                            itemBuilder: (context, index) {
                              final cartItem = _getValidatedCartItems()[index];
                              final int quantity =
                                  (cartItem['qty'] ?? 1) as int;
                              final double itemPrice =
                                  (cartItem['price'] ?? 0.0).toDouble();
                              final double totalItemPrice =
                                  itemPrice * quantity;

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F1F1F),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Food & Beverages',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF338125,
                                            ).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            _getCartItemsSummary(),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: const Color(0xFF6DFB60),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ..._getValidatedCartItems().map((item) {
                                      final quantity = item['qty'] ?? 1;
                                      final price = (item['price'] ?? 0.0)
                                          .toDouble();
                                      final total = price * quantity;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${item['name']} (x$quantity)',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '₹${total.toStringAsFixed(2)}',
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF6DFB60),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  : SizedBox(),
              // : _buildMealButton(),
              const SizedBox(height: 1),
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking User',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8B8B8B),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(
                          () => Text(
                            userController.user.value.name ?? 'User',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        // Add change logic here
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'Change',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 1),
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Payment Method',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Payment Options ─────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _paymentChip(
                              'Wallet',
                              Icons.account_balance_wallet,
                              'wallet',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _paymentChip(
                              'Hash Game Pass',
                              Icons.gamepad,
                              'none',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _paymentChip(
                              'UPI / Card',
                              Icons.credit_card,
                              'gateway',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _paymentChip(
                              'Pay in Cafe',
                              Icons.directions_walk,
                              'pay_at_cafe',
                            ),
                          ),
                        ],
                      ),

                      // ── Game Pass Selected Info ──────────────
                      if (_selectedPayment.value == 'none' &&
                          _selectedGamePass.value != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF338125).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF338125).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF338125),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Selected: ${_selectedGamePass.value!.name}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFF6DFB60),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedGamePass.value!.vendorName,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => _selectedGamePass.value = null,
                                child: Text(
                                  'Change',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF6DFB60),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 1),
              _buildVoucherSection(),
              const SizedBox(height: 1),

              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Obx(() {
                  double totalPrice = calculateTotalPrice();
                  double discount = calculateDiscount();
                  double subtotal = calculateSubtotal();
                  double slotsSubtotal = calculateSlotsSubtotal();
                  double cartSubtotal = calculateCartSubtotal();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Summary',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (widget.selectedSlots.isNotEmpty)
                        buildPaymentRow(
                          'Slots',
                          '₹${slotsSubtotal.toStringAsFixed(2)}',
                        ),

                      if (_getValidatedCartItems().isNotEmpty)
                        buildPaymentRow(
                          'Food & Beverages',
                          '₹${cartSubtotal.toStringAsFixed(2)}',
                        ),

                      buildPaymentRow(
                        'Subtotal',
                        '₹${subtotal.toStringAsFixed(2)}',
                      ),

                      if (discount > 0)
                        buildPaymentRow(
                          'Discount',
                          '-₹${discount.toStringAsFixed(2)}',
                          color: Colors.green,
                        ),

                      buildPaymentRow('GST', '₹0.00'),

                      Divider(
                        color: Colors.grey.shade800,
                        thickness: 1,
                        height: 24,
                      ),

                      buildPaymentRow(
                        'GRAND TOTAL',
                        '₹${totalPrice.toStringAsFixed(2)}',
                        bold: true,
                        fontSize: 16,
                      ),
                    ],
                  );
                }),
              ),

              // ─── Payment Method ──────────────────────────────────────────
            ],
          ),
        ),
      ),
        bottomNavigationBar: BottomAppBar(
          color: const Color(0xFF0F0F0F),
          elevation: 16,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Total Amount
                Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Payable',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '₹ ${calculateTotalPrice().toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Proceed / Select Pass Button
              Obx(() {
                final isProcessing =
                    _isProcessingPayment.value ||
                    _stage.value == PaymentStage.creatingBooking ||
                    _stage.value == PaymentStage.debitingWallet ||
                    _stage.value == PaymentStage.initiatingGateway ||
                    _stage.value == PaymentStage.confirmingVoucher ||
                    _stage.value == PaymentStage.confirmingGamePass ||
                    _stage.value == PaymentStage.openingRazorpay;

                final isGamePassSelected = _selectedPayment.value == 'none';
                final hasSelectedPass = _selectedGamePass.value != null;

                final showSelectPass = isGamePassSelected && !hasSelectedPass;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF338125),

                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFF338125)),
                  ),
                  child: ElevatedButton(
                    onPressed: isProcessing
                        ? null
                        : () {
                            if (showSelectPass) {
                              _showGamePassSelectionDialog();
                            } else if (_selectedPayment.value ==
                                'pay_at_cafe') {
                              // Handle Pay at Café booking flow
                              handleBooking(
                                context,
                                isVoucherApplied: _appliedVoucher.value != null,
                                useWallet: false, // Not wallet
                                isGamePass: false,
                                selectedPassId: null,
                                isPayAtCafe:
                                    true, // <-- add this param in handleBooking
                              );
                            } else {
                              // Default (wallet / online gateway)
                              handleBooking(
                                context,
                                isVoucherApplied: _appliedVoucher.value != null,
                                useWallet: _selectedPayment.value == 'wallet',
                                isGamePass: false,
                                selectedPassId: null,
                                isPayAtCafe: false,
                              );
                            }
                          },

                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 23,
                        vertical: 8,
                      ),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            showSelectPass ? 'Select Pass' : 'Pay',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildMealButton() {
  //   return GestureDetector(
  //     onTap: () {
  //       Navigator.pop(context);
  //     },
  //     child: Container(
  //       height: 50,
  //       width: double.infinity,
  //       decoration: BoxDecoration(
  //         color: Colors.transparent,
  //         border: Border.all(color: const Color(0xFF00DC00), width: 1.5),
  //         borderRadius: BorderRadius.circular(50),
  //       ),
  //       child: Center(
  //         child: Text(
  //           '+ Select your meal',
  //           style: GoogleFonts.inter(
  //             fontSize: 16,
  //             color: const Color(0xFF75F94C),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildVoucherSection() {
    return Container(
      margin: EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Color(0xFF191919),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Have a Voucher?',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                height: 20,
                child: Obx(
                  () => _isLoadingVouchers.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CupertinoActivityIndicator(),
                        )
                      : GestureDetector(
                          onTap: _loadVouchers,
                          child: const Icon(
                            CupertinoIcons.refresh,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Applied Voucher Info
          Obx(() {
            final applied = _appliedVoucher.value;
            if (applied != null) {
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Applied: ${applied.code}',
                            style: GoogleFonts.inter(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${applied.discountPercentage}% discount active',
                            style: GoogleFonts.inter(
                              color: Colors.green.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                          if (applied.discountPercentage == 100) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '⚠️ Limited to 1 slot only',
                                style: GoogleFonts.inter(
                                  color: Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _removeVoucher,
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.green,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Remove Voucher',
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Available Vouchers Count
          Obx(() {
            if (_availableVouchers.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Your Available Vouchers (${_availableVouchers.length})',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade300,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Voucher Input and Apply Button Row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _voucherController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter voucher code',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: Color(0xFF505050),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: Color(0xFF505050),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFF338125),
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Obx(() {
                return GestureDetector(
                  onTap: _isApplyingVoucher.value ? null : _applyVoucher,
                  child: Container(
                    height: 44,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: const Color(0xFF338125),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: _isApplyingVoucher.value
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: RainbowLoadingBar(),
                            )
                          : Text(
                              'Apply',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                );
              }),
            ],
          ),

          // Error Message
          Obx(() {
            if (_voucherError.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _voucherError.value,
                  style: GoogleFonts.inter(
                    color: Colors.red.shade300,
                    fontSize: 12,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Available Vouchers List
          Obx(() {
            if (_availableVouchers.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableVouchers.length,
                      itemBuilder: (context, index) {
                        final voucher = _availableVouchers[index];
                        final isActive = voucher.isActive;
                        final canApply = isActive && _canApplyVoucher(voucher);
                        return GestureDetector(
                          onTap: canApply ? () => _selectVoucher(voucher) : null,
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: canApply
                                  ? Colors.deepOrange.withOpacity(0.08)
                                  : isActive
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: canApply
                                    ? Colors.deepOrange.withOpacity(0.3)
                                    : isActive
                                        ? Colors.orange.withOpacity(0.3)
                                        : Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  voucher.code,
                                  style: GoogleFonts.inter(
                                    color: canApply
                                        ? Colors.deepOrange
                                        : isActive
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${voucher.discountPercentage}% OFF',
                                  style: GoogleFonts.inter(
                                    color: canApply
                                        ? Colors.white
                                        : isActive
                                            ? Colors.grey.shade400
                                            : Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  canApply ? 'Available' : isActive ? 'Limited' : 'Inactive',
                                  style: GoogleFonts.inter(
                                    color: canApply
                                        ? Colors.green
                                        :isActive ? Colors.orange : Colors.red,
                                    fontSize: 10,
                                  ),
                                ),
                                if (isActive && voucher.discountPercentage == 100) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: canApply
                                          ? Colors.orange.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      canApply ? '1 slot only' : 'Too many slots',
                                      style: GoogleFonts.inter(
                                        color: canApply ? Colors.orange : Colors.red,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  bool _validateBooking() {
    // Check if slots are selected
    if (widget.selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No slots selected!'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Check if 100% voucher is applied and validate slot count
    if (_appliedVoucher.value != null && _isHundredPercentVoucher(_appliedVoucher.value!)) {
      if (!_canApplyVoucher(_appliedVoucher.value!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('100% vouchers can only be used for one slot. Please remove extra slots.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    // Check if total price is valid
    double totalPrice = calculateTotalPrice();
    if (totalPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid total price!'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Check if cart items have valid data
    final validatedItems = _getValidatedCartItems();
    if (validatedItems.length != widget.cartItems.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Some cart items have invalid data and will be excluded',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    return true;
  }

  void _resetPaymentState() {
    _stage.value = PaymentStage.idle;
    _errorMessage.value = '';
    _isProcessingPayment(false);
    _paymentStatus.value = '';
    razorpayController.isPaymentInProgress(false);
    // Also reset any error states that might be lingering
    razorpayController.paymentStatus.value = '';
  }

  void _resetButtonState() {
    _isProcessingPayment(false);
    razorpayController.isPaymentInProgress(false);
    // Keep the error stage for display purposes, but ensure button is enabled
    if (_stage.value == PaymentStage.error) {
      // Don't change the stage, just ensure processing is false
    }
  }

  void _clearErrorState() {
    _stage.value = PaymentStage.idle;
    _errorMessage.value = '';
    _paymentStatus.value = '';
  }

  String _getCartItemsSummary() {
    if (widget.cartItems.isEmpty) return '';

    int totalItems = _getValidatedCartItems().fold(0, (sum, item) {
      int quantity = (item['qty'] ?? 1) as int;
      // Ensure quantity is not negative
      quantity = quantity < 0 ? 0 : quantity;
      return sum + quantity;
    });

    return '$totalItems Item${totalItems > 1 ? 's' : ''}';
  }

  List<Map<String, dynamic>> _getValidatedCartItems() {
    return widget.cartItems.where((item) {
      // Filter out items with invalid data
      if (item['name'] == null || item['name'].toString().isEmpty) {
        return false;
      }

      double itemPrice = (item['price'] ?? 0.0).toDouble();
      int quantity = (item['qty'] ?? 1) as int;

      return itemPrice >= 0 && quantity > 0;
    }).toList();
  }

  String _parseErrorMessage(dynamic error) {
    try {
      if (error is DioError) {
        final response = error.response;
        if (response != null) {
          final statusCode = response.statusCode ?? 0;
          final data = response.data;

          if (data is Map<String, dynamic>) {
            if (data.containsKey('error')) return data['error'];
            if (data.containsKey('message')) return data['message'];
          } else if (data is String) {
            final parsed = jsonDecode(data);
            if (parsed['error'] != null) return parsed['error'];
            if (parsed['message'] != null) return parsed['message'];
          }

          switch (statusCode) {
            case 400:
              return 'Invalid request. Please check your details.';
            case 401:
              return 'Authentication failed. Please login again.';
            case 403:
              return 'Access denied. Please check your permissions.';
            case 404:
              return 'Service not found. Please try again later.';
            case 422:
              return 'Invalid data. Please check your selections.';
            case 500:
            default:
              return 'Server error occurred. Please try again later.';
          }
        }
      } else if (error is http.Response) {
        final data = jsonDecode(error.body);
        if (data['error'] != null) return data['error'];
        if (data['message'] != null) return data['message'];

        switch (error.statusCode) {
          case 400:
            return 'Invalid request. Please check your details.';
          case 401:
            return 'Authentication failed. Please login again.';
          case 403:
            return 'Access denied. Please check your permissions.';
          case 404:
            return 'Service not found. Please try again later.';
          case 422:
            return 'Invalid data. Please check your selections.';
          case 500:
          default:
            return 'Server error occurred. Please try again later.';
        }
      }

      if (error is Exception) {
        final message = error.toString();
        if (message.contains('Insufficient wallet balance')) {
          return 'Insufficient wallet balance. Please add money to your wallet or choose a different payment method.';
        }
        return message.replaceAll('Exception: ', '');
      }
    } catch (e) {
      print('Error parsing exception: $e');
    }

    return 'An unexpected error occurred. Please try again.';
  }

  Future<void> handleBooking(
    BuildContext context, {
    required bool isVoucherApplied,
    required bool useWallet,
    required bool isGamePass,
    String? selectedPassId,
    required bool isPayAtCafe,
  }) async {
    if (!_validateBooking()) {
      return;
    }

    // Reset any previous error states
    _clearErrorState();

    // Start loading state
    _isProcessingPayment(true);
    _stage.value = PaymentStage.creatingBooking;

    try {
      double totalPrice = calculateTotalPrice();
      int amountInPaisa = (totalPrice * 100).toInt();

      List<int> slotIds = widget.selectedSlots
          .map((slot) => slot['slot_id'] as int)
          .toList();

      // Use the new mapping function
      _bookingIdToSlotId = await createBookingWithSlotMap(
        slotIds,
        isPayAtCafe,
        widget.selectedDate,
      );
      List<int> bookingIds = _bookingIdToSlotId.keys.toList();

      if (bookingIds.isEmpty) {
        throw Exception('Failed to create bookings,bookingIds: $bookingIds');
      }

      // Track booking started event
      final slotTime = widget.selectedSlots.first['time'] ?? 'Unknown';
      segmentService.onBookingStarted(
        cafeId: 'cafe_${widget.gameId}',
        gameId: widget.gameId.toString(),
        slotTime: slotTime,
      );
      fbEventsService.onBookingStarted(
        cafeId: 'cafe_${widget.gameId}',
        gameId: widget.gameId.toString(),
        slotTime: slotTime,
      );

      if (isPayAtCafe) {
        _stage.value = PaymentStage.confirmingPayAtCafe;
        _isProcessingPayment(false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Booking created. Please pay at café counter."),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 4),
          ),
        );
        Get.to(
          () => PaymentSuccessScreen(
            dateText: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            timeText: "",
            totalText: totalPrice.toString(),
            email: "",
            onViewInvoice: (){
              Get.to(const PastBookingsScreen());
            },
          ),
        );
        return; // short-circuit
      }
      // a) WALLET route
      if (useWallet) {
        _stage.value = PaymentStage.debitingWallet;
        await confirmBooking(
          bookingIds: bookingIds,
          paymentMode: 'wallet',
          voucherCode: isVoucherApplied ? _appliedVoucher.value!.code : null,
          totalPrice: totalPrice
        );
        return;
      }

      // b) VOUCHER route (if voucher is applied and not using Razorpay or Wallet)
      if (isVoucherApplied && _appliedVoucher.value != null) {
        _stage.value = PaymentStage.confirmingVoucher;
        await confirmBooking(
          bookingIds: bookingIds,
          paymentMode: 'voucher',
          voucherCode: _appliedVoucher.value!.code,
            totalPrice: totalPrice,
        );
        return;
      }

      //c) GAME PASS route
      if (isGamePass) {
        _stage.value = PaymentStage.confirmingGamePass;
        await confirmBooking(
          bookingIds: bookingIds,
          paymentMode: 'none',
          isGamePass: isGamePass,
          userPassId: selectedPassId,
            totalPrice: totalPrice
        );
        return;
      }
      // // // d) PAY AT CAFE route
      //       if (_selectedPayment.value == 'pay_at_cafe') {
      //         _stage.value = PaymentStage.confirmingPayAtCafe; // or PaymentStage.confirmingPayAtCafe if added
      //         // await confirmBooking(
      //         //   bookingIds: bookingIds,
      //         //   paymentMode: 'pay_at_cafe',
      //         //   voucherCode: isVoucherApplied ? _appliedVoucher.value!.code : null,
      //         // );
      //         return;
      //       }

      // d) RAZORPAY route (default)
      _stage.value = PaymentStage.initiatingGateway;
      razorpayController.bookingIdList.value = bookingIds;
      // Set the slot IDs for the razorpay controller
      razorpayController.slotIdsList.value = widget.selectedSlots
          .map((slot) => slot['slot_id'] as int)
          .toList();
      // Set the cart items for the razorpay controller
      razorpayController.cartItemsList.value = _getValidatedCartItems();
      await initiatePayment(context, amountInPaisa);
    } catch (e) {
      // Parse error message properly
      String errorMessage = _parseErrorMessage(e);

      _stage.value = PaymentStage.error;
      _errorMessage.value = errorMessage;
      _resetButtonState();

      // Show error message with better styling and action button for wallet errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          action: errorMessage.contains('Insufficient wallet balance')
              ? SnackBarAction(
                  label: 'Add Money',
                  textColor: Colors.white,
                  onPressed: () {
                    // Navigate to wallet/add money screen
                    // You can implement this navigation based on your app structure
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    // Example: Get.toNamed('/wallet');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Navigate to wallet to add money'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                )
              : null,
        ),
      );
    }
  }

  Future<void> confirmBooking({
    required List<int> bookingIds,
    required String paymentMode,
    String? voucherCode,
    bool isGamePass = false,
    String? userPassId,
    required double totalPrice,
  }) async {
    try {
      // Parse cart items to ExtraServiceItem format
      List<ExtraServiceItem> extraServices = [];
      final validatedCartItems = _getValidatedCartItems();

      if (validatedCartItems.isNotEmpty) {
        extraServices = validatedCartItems.map((item) {
          return ExtraServiceItem(
            categoryId: (item['category_id'] ?? 0) as int,
            itemId: (item['id'] ?? 0) as int,
            quantity: (item['qty'] ?? 1) as int,
          );
        }).toList();
      }

      await _remoteRepo.confirmBooking(
        bookingIds: bookingIds,
        paymentId:
            "${paymentMode.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}",
        bookDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        paymentMode: paymentMode,
        voucherCode: voucherCode,
        isGamePass: isGamePass,
        extraServices: extraServices,
        userPassId: userPassId,
      );

      // Track booking confirmed event
      final startTime = DateTime.now().toIso8601String();
      final duration = '${widget.selectedSlots.length} hour(s)';
      segmentService.onBookingConfirmed(
        bookingId: bookingIds.first.toString(),
        startTime: startTime,
        duration: duration,
      );
      fbEventsService.onBookingConfirmed(
        bookingId: bookingIds.first.toString(),
        startTime: startTime,
        duration: duration,
      );

      // Update payment stage to done
      _stage.value = PaymentStage.done;
      _isProcessingPayment(false);
      _paymentStatus.value = 'Booking confirmed successfully!';

      // Show success message
      String successMessage = 'Booking confirmed successfully!';
      if (voucherCode != null) {
        successMessage = 'Booking confirmed with voucher $voucherCode!';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
      );

      // Clear selected slots after successful booking
      bookingController.clearSelectedSlots();

      // Navigate to past bookings first
      await Get.to(
        () => PaymentSuccessScreen(
          method: paymentMode,
          dateText: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          timeText: "",
          totalText: totalPrice.toString(),
          email: "",
          onViewInvoice: () {
            Get.to(const PastBookingsScreen());
            // Then navigate back to home with arena tab selected
            // This ensures when user presses back, they go to cafe page
            final homeController = Get.find<HomeController>();
            homeController.onItemTapped(1); // Select arena/cafe tab
            Get.offAllNamed('/home'); // Replace all routes with home
          },
        ),
      );


    } catch (e) {
      // Release each booking if confirmation fails
      for (final bookingId in bookingIds) {
        try {
          final slotId = _bookingIdToSlotId[bookingId] ?? bookingId;
          await _remoteRepo.releaseBooking(
            bookings: BookingModel(
              slotId: slotId,
              bookingId: bookingId,
              bookDate: DateTime.now().toIso8601String(),
            ),
          );
        } catch (releaseError) {
          print('Error releasing booking $bookingId: $releaseError');
        }
      }

      // Parse error message properly
      String errorMessage = _parseErrorMessage(e);

      // Update payment stage to error
      _stage.value = PaymentStage.error;
      _errorMessage.value = errorMessage;
      _resetButtonState();
      _paymentStatus.value = 'Failed to confirm booking';

      // Show error message with better styling and action button for wallet errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          action: errorMessage.contains('Insufficient wallet balance')
              ? SnackBarAction(
                  label: 'Add Money',
                  textColor: Colors.white,
                  onPressed: () {
                    // Navigate to wallet/add money screen
                    // You can implement this navigation based on your app structure
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    // Example: Get.toNamed('/wallet');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Navigate to wallet to add money'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                )
              : null,
        ),
      );
    }
  }

  Future<Map<int, int>> createBookingWithSlotMap(
    List<int> slotIds,
    bool payAtCafe,
    String selectedDate,
  ) async {
    final url = '${FlavorConfig.getBaseUrl('booking')}/api/bookings';

    // Parse yyyymmdd into DateTime
    final parsed = DateTime.parse(
      "${selectedDate.substring(0, 4)}-${selectedDate.substring(4, 6)}-${selectedDate.substring(6, 8)}",
    );

    // Format as yyyy-MM-dd
    final bookDate =
        "${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}";

    final payload = {
      "slot_id": slotIds,
      "game_id": widget.gameId,
      "book_date": bookDate, // now in correct format
      "is_pay_at_cafe": payAtCafe,
    };

    debugPrint('payload: $payload');
    var jwt = await _remoteRepo.getJwtFromPreferences();
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwt",
        },
        body: jsonEncode(payload),
      );
      debugPrint('response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Map<int, int> map = {};
        if (data['bookings'] != null) {
          for (final b in data['bookings']) {
            if (b['booking_id'] != null && b['slot_id'] != null) {
              map[b['booking_id']] = b['slot_id'];
            }
          }
        } else if (data['booking_ids'] != null) {
          // fallback: assume 1:1 with slotIds order
          final ids = List<int>.from(data['booking_ids']);
          for (int i = 0; i < ids.length && i < slotIds.length; i++) {
            map[ids[i]] = slotIds[i];
          }
        }
        return map;
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  Future<void> initiatePayment(BuildContext context, int amountInPaisa) async {
    String receiptId = "order_rcpt_${DateTime.now().millisecondsSinceEpoch}";
    final url = '${FlavorConfig.getBaseUrl('booking')}/api/create_order';
    final payload = {
      "amount": amountInPaisa,
      "currency": "INR",
      "receipt": receiptId,
    };
    debugPrint('new new new new Payment ID payload: $payload');
    try {
      _stage.value = PaymentStage.openingRazorpay;
      _paymentStatus.value = 'Creating payment order...';

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('Payment order created successfully ${response.body}');
        final data = jsonDecode(response.body);
        _paymentStatus.value = 'Opening payment gateway...';

        razorpayController.openCheckout(
          orderId: data['id'],
          name: userController.user.value.name ?? 'User',
          description: "Booking for selected slots",
          amount: data['amount'] / 100,
          contact:
              userController.user.value.contact?.electronicAddress?.mobileNo ??
              '',
          email:
              userController.user.value.contact?.electronicAddress?.emailId ??
              '',
        );
      } else {
        _stage.value = PaymentStage.error;
        _errorMessage.value = 'Failed to create payment order';
        _isProcessingPayment(false);
        _paymentStatus.value = 'Payment order creation failed';
        razorpayController.isPaymentInProgress(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create payment order. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Parse error message properly
      String errorMessage = _parseErrorMessage(e);

      _stage.value = PaymentStage.error;
      _errorMessage.value = errorMessage;
      _resetButtonState();
      _paymentStatus.value = 'Payment initialization failed';
      print('Payment error: $e');

      // Show error message with better styling and action button for wallet errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          action: errorMessage.contains('Insufficient wallet balance')
              ? SnackBarAction(
                  label: 'Add Money',
                  textColor: Colors.white,
                  onPressed: () {
                    // Navigate to wallet/add money screen
                    // You can implement this navigation based on your app structure
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    // Example: Get.toNamed('/wallet');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Navigate to wallet to add money'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                )
              : null,
        ),
      );
    }
  }

  Widget buildPaymentRow(
    String label,
    String value, {
    bool bold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: Colors.white,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentChip(String label, IconData icon, String value) {
    final bool isSelected = _selectedPayment.value == value;

    return GestureDetector(
      onTap: () {
        _selectedPayment(value);
        // Clear selected game pass when changing payment method
        if (value != 'none') {
          _selectedGamePass.value = null;
        } else {
          // If switching to Hash Game Pass, refresh the passes and clear selection
          _selectedGamePass.value = null;
          _loadUserGamePasses();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF338125) : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF338125) : Colors.grey.shade700,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
