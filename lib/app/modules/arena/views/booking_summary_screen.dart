import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/app/modules/arena/views/booking_summary/booking_summary_bottom_bar.dart';
import 'package:hash/app/modules/arena/views/booking_summary/booking_summary_cart_section.dart';
import 'package:hash/app/modules/arena/views/booking_summary/booking_summary_game_pass_dialog.dart';
import 'package:hash/app/modules/arena/views/booking_summary/booking_summary_payment_method_section.dart';
import 'package:hash/app/modules/arena/views/booking_summary/booking_summary_payment_summary_section.dart';
import 'package:hash/app/modules/arena/views/booking_summary/booking_summary_processing_overlay.dart';
import 'package:hash/app/modules/arena/views/booking_summary/booking_summary_slots_list.dart';
import 'package:hash/app/modules/arena/views/booking_summary/booking_summary_user_section.dart';
import 'package:hash/app/modules/arena/views/booking_summary/booking_summary_voucher_section.dart';
import 'package:hash/app/modules/arena/views/payment_success.dart';
import 'package:hash/app/modules/game_pass/view/game_pass_view.dart';
import 'package:hash/app/modules/home/controllers/home_controller.dart';
import 'package:hash/app/modules/payment/razorpay_controller.dart';
import 'package:hash/config/flavor_config.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/squad_missions_service.dart';
import 'package:hash/core/repositories/model/get_pass_model.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/repositories/model/get_voucher_model.dart';
import '../../../../core/repositories/model/extra_services_model.dart';
import '../../../data/services/user_controller.dart';
import '../../../../core/repositories/model/booking_model.dart';
import 'package:hash/core/utils/app_logger.dart';

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
  final squadMissionsService = locator<SquadMissionsService>();
  final _remoteRepo = locator<RemoteRepoInterface>();
  final _networkProvider = locator<NetworkProvider>();
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
  bool _paymentAttempted = false;
  bool _paymentCompleted = false;

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
    if (_paymentAttempted && !_paymentCompleted) {
      segmentService.onCustomEvent('Payment Abandoned', {
        'booking_id': widget.gameId.toString(),
        'step': _stage.value.name,
      });
      fbEventsService.onPaymentAbandoned(
        bookingId: widget.gameId.toString(),
        step: _stage.value.name,
      );
    }
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
          // _isProcessingPayment(false);
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
          // _isProcessingPayment(false);
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

        AppLogger.d("🎯 Loading game passes for userId: $userId");

        final gamePasses = await _remoteRepo.getUserActiveGamePass(
          userId: userId,
        );

        AppLogger.d("✅ Raw gamePasses count: ${gamePasses.length}");

        // Filter passes based on vendor ID match
        final filteredPasses = _filterPassesByVendor(gamePasses);

        AppLogger.d("🎯 Filtered passes count: ${filteredPasses.length}");

        _userGamePasses.value = filteredPasses;
      } else {
        AppLogger.d("❌ User not found in preferences");

        _userGamePasses.value = [];
        _gamePassError.value = 'User not found';
      }
    } catch (e, st) {
      _userGamePasses.value = [];

      // ───── DIO-SPECIFIC DEBUG ─────
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        AppLogger.d("❌ Dio error while loading game passes");
        AppLogger.d("   ➤ Status code: $statusCode");
        AppLogger.d("   ➤ URL: ${e.requestOptions.uri}");
        AppLogger.d("   ➤ Method: ${e.requestOptions.method}");
        AppLogger.d("   ➤ Response data: $responseData");
        AppLogger.d("   ➤ Message: ${e.message}");
        AppLogger.d("   ➤ Type: ${e.type}");
      } else {
        AppLogger.d("❌ Non-Dio error while loading game passes: $e");
      }

      AppLogger.d("🧵 StackTrace: $st");

      _gamePassError.value = 'Failed to load game passes';
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
              _voucherError.value =
                  '100% vouchers can only be used for one slot. Please remove extra slots.';
              _isApplyingVoucher(false);
              return;
            }
          }

          _appliedVoucher.value = voucher;
          _voucherError.value = '';
          segmentService.onCustomEvent('Coupon Applied', {
            'coupon_code': voucher.code,
            'discount_value': voucher.discountPercentage,
          });
          fbEventsService.onCouponApplied(
            couponCode: voucher.code,
            discountAmount: voucher.discountPercentage.toDouble(),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Voucher applied! ${voucher.discountPercentage}% discount',
              ),
              backgroundColor: const Color(0xff00DC00),
            ),
          );
        } else {
          segmentService.onCustomEvent('Coupon Failed', {
            'coupon_code': voucher.code,
            'reason': 'inactive',
          });
          fbEventsService.onCouponFailed(
            couponCode: voucher.code,
            reason: 'inactive',
          );
          _voucherError.value = 'This voucher is not active';
        }
      } else {
        segmentService.onCustomEvent('Coupon Failed', {
          'coupon_code': _voucherController.text.trim(),
          'reason': 'invalid',
        });
        fbEventsService.onCouponFailed(
          couponCode: _voucherController.text.trim(),
          reason: 'invalid',
        );
        _voucherError.value = 'Invalid voucher code';
      }
    } catch (e) {
      segmentService.onCustomEvent('Coupon Failed', {
        'coupon_code': _voucherController.text.trim(),
        'reason': 'exception',
      });
      fbEventsService.onCouponFailed(
        couponCode: _voucherController.text.trim(),
        reason: 'exception',
      );
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
            content: Text(
              '100% vouchers can only be used for one slot. Please remove extra slots.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      _voucherController.text = voucher.code;
      _applyVoucher();
    } else {
      segmentService.onCustomEvent('Coupon Failed', {
        'coupon_code': voucher.code,
        'reason': 'inactive',
      });
      fbEventsService.onCouponFailed(
        couponCode: voucher.code,
        reason: 'inactive',
      );
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

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
        return BookingSummaryGamePassDialog(
          isLoading: _isLoadingGamePasses,
          errorMessage: _gamePassError,
          userGamePasses: _userGamePasses,
          selectedGamePass: _selectedGamePass,
          onRefresh: _loadUserGamePasses,
          onProceed: _proceedWithGamePass,
          onPurchasePasses: () => Get.to(() => const GamePassViewPage()),
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
                style: TextStyle(color: const Color(0xff00DC00)),
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

  void _onPaymentSelected(String value) {
    _selectedPayment(value);
    if (value != 'none') {
      _selectedGamePass.value = null;
      return;
    }

    _selectedGamePass.value = null;
    _loadUserGamePasses();
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
    final validatedCartItems = _getValidatedCartItems();
    final cartSummary = _getCartItemsSummary();

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop || _paymentCompleted) return;
        segmentService.onCustomEvent('Booking Cancelled', {
          'booking_id': widget.gameId.toString(),
          'reason': 'back_pressed',
        });
        fbEventsService.onBookingCancelled(
          bookingId: widget.gameId.toString(),
          reason: 'back_pressed',
        );
      },
      child: Scaffold(
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
        body: Obx(
          () => Stack(
            children: [
              SingleChildScrollView(
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

                      BookingSummarySlotsList(
                        selectedSlots: widget.selectedSlots,
                      ),
                      const SizedBox(height: 5),
                      BookingSummaryCartSection(
                        cartItems: validatedCartItems,
                        summaryText: cartSummary,
                      ),
                      // : _buildMealButton(),
                      const SizedBox(height: 1),
                      Obx(
                        () => BookingSummaryUserSection(
                          userName: userController.user.value.name ?? 'User',
                          onChangeUser: () {
                            // Add change logic here
                          },
                        ),
                      ),

                      const SizedBox(height: 1),
                      BookingSummaryPaymentMethodSection(
                        selectedPayment: _selectedPayment,
                        selectedGamePass: _selectedGamePass,
                        onSelectPayment: _onPaymentSelected,
                        onClearSelectedPass: () =>
                            _selectedGamePass.value = null,
                      ),
                      const SizedBox(height: 1),
                      BookingSummaryVoucherSection(
                        voucherController: _voucherController,
                        isLoadingVouchers: _isLoadingVouchers,
                        availableVouchers: _availableVouchers,
                        appliedVoucher: _appliedVoucher,
                        isApplyingVoucher: _isApplyingVoucher,
                        voucherError: _voucherError,
                        onReload: _loadVouchers,
                        onApply: _applyVoucher,
                        onRemove: _removeVoucher,
                        onSelectVoucher: _selectVoucher,
                        canApplyVoucher: _canApplyVoucher,
                      ),
                      const SizedBox(height: 1),

                      Obx(() {
                        final totalPrice = calculateTotalPrice();
                        final discount = calculateDiscount();
                        final subtotal = calculateSubtotal();
                        final slotsSubtotal = calculateSlotsSubtotal();
                        final cartSubtotal = calculateCartSubtotal();

                        return BookingSummaryPaymentSummarySection(
                          totalPrice: totalPrice,
                          discount: discount,
                          subtotal: subtotal,
                          slotsSubtotal: slotsSubtotal,
                          cartSubtotal: cartSubtotal,
                          hasSlots: widget.selectedSlots.isNotEmpty,
                          hasCartItems: validatedCartItems.isNotEmpty,
                        );
                      }),

                      // ─── Payment Method ──────────────────────────────────────────
                    ],
                  ),
                ),
              ),
              BookingSummaryProcessingOverlay(
                isProcessing: _isProcessingPayment.value,
                status: _paymentStatus.value,
              ),
            ],
          ),
        ),
        bottomNavigationBar: Obx(() {
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

          return BookingSummaryBottomBar(
            totalPrice: calculateTotalPrice(),
            isProcessing: isProcessing,
            showSelectPass: showSelectPass,
            onPressed: () {
              if (_stage.value == PaymentStage.error) {
                segmentService.onCustomEvent('Payment Retry', {
                  'booking_id': widget.gameId.toString(),
                  'method': _selectedPayment.value,
                });
                fbEventsService.onPaymentRetry(
                  bookingId: widget.gameId.toString(),
                  paymentMethod: _selectedPayment.value,
                );
              }
              _paymentAttempted = true;
              segmentService.onPaymentInitiated(
                bookingId: widget.gameId.toString(),
                amount: calculateTotalPrice(),
                paymentMethodSelected: _selectedPayment.value,
              );
              fbEventsService.onPaymentInitiated(
                bookingId: widget.gameId.toString(),
                amount: calculateTotalPrice(),
                paymentMethodSelected: _selectedPayment.value,
              );
              if (showSelectPass) {
                _showGamePassSelectionDialog();
              } else if (_selectedPayment.value == 'pay_at_cafe') {
                handleBooking(
                  context,
                  isVoucherApplied: _appliedVoucher.value != null,
                  useWallet: false,
                  isGamePass: false,
                  selectedPassId: null,
                  isPayAtCafe: true,
                );
              } else {
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
          );
        }),
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
  //         border: Border.all(color: const Color(0xff00DC00), width: 1.5),
  //         borderRadius: BorderRadius.circular(50),
  //       ),
  //       child: Center(
  //         child: Text(
  //           '+ Select your meal',
  //           style: GoogleFonts.inter(
  //             fontSize: 16,
  //             color: const Color(0xff00DC00),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

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
    if (_appliedVoucher.value != null &&
        _isHundredPercentVoucher(_appliedVoucher.value!)) {
      if (!_canApplyVoucher(_appliedVoucher.value!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '100% vouchers can only be used for one slot. Please remove extra slots.',
            ),
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
      if (error is DioException) {
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
        if (error is Exception) {
          final message = error.toString();
          if (message.contains('Insufficient wallet balance')) {
            return 'Insufficient wallet balance. Please add money to your wallet or choose a different payment method.';
          }
          if (message.contains("name 'Decimal' is not defined")) {
            return 'Wallet service is temporarily unavailable. Please try another payment method or retry in a moment.';
          }
          if (message.contains('Wallet payment is temporarily unavailable')) {
            return 'Wallet service is temporarily unavailable. Please use UPI/Card or Pay at Cafe.';
          }
          return message.replaceAll('Exception: ', '');
        }
      }
    } catch (e) {
      AppLogger.d('Error parsing exception: $e');
    }

    return 'An unexpected error occurred. Please try again.';
  }

  bool _isInsufficientWalletError(String errorMessage) {
    return errorMessage.toLowerCase().contains('insufficient wallet balance');
  }

  bool _isWalletServiceError(String errorMessage) {
    final lower = errorMessage.toLowerCase();
    return lower.contains('wallet service is temporarily unavailable') ||
        lower.contains("name 'decimal' is not defined");
  }

  Future<void> _showPaymentErrorUx(
    String errorMessage, {
    required bool fromWallet,
  }) async {
    if (!mounted) return;

    final showWalletSheet =
        fromWallet &&
        (_isInsufficientWalletError(errorMessage) ||
            _isWalletServiceError(errorMessage));

    if (showWalletSheet) {
      final isLowBalance = _isInsufficientWalletError(errorMessage);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF111111),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (_) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isLowBalance
                              ? 'Low Wallet Balance'
                              : 'Wallet Unavailable',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isLowBalance
                        ? 'Your wallet balance is not enough for this booking. Switch to UPI/Card to complete payment now.'
                        : 'Wallet payment is currently unavailable. Switch to UPI/Card to continue.',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Close',
                            style: GoogleFonts.inter(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _selectedPayment.value = 'gateway';
                            Navigator.of(context).pop();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Switched to UPI/Card payment.',
                                ),
                                backgroundColor: const Color(0xff00DC00),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff00DC00),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Use UPI/Card',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
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
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
        email:
            userController.user.value.contact?.electronicAddress?.emailId ?? '',
        consoleType: widget.consoleType,
        consoleAmount: widget.selectedSlots.length,
      );
      fbEventsService.onBookingStarted(
        cafeId: 'cafe_${widget.gameId}',
        gameId: widget.gameId.toString(),
        slotTime: slotTime,
      );

      if (isPayAtCafe) {
        _stage.value = PaymentStage.confirmingPayAtCafe;
        _isProcessingPayment(false);
        _paymentCompleted = true;
        segmentService.onPaymentSuccess(
          transactionId: 'PAY_AT_CAFE_${DateTime.now().millisecondsSinceEpoch}',
          bookingId: bookingIds.first.toString(),
          paymentGateway: 'pay_at_cafe',
        );
        fbEventsService.onPaymentSuccess(
          transactionId: 'PAY_AT_CAFE_${DateTime.now().millisecondsSinceEpoch}',
          bookingId: bookingIds.first.toString(),
          paymentGateway: 'pay_at_cafe',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Booking created. Please pay at café counter."),
            backgroundColor: const Color(0xff00DC00),
            duration: const Duration(seconds: 4),
          ),
        );
        Get.to(
          () => PaymentSuccessScreen(
            isBookingCreatedOnly: true,
            dateText: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            timeText: "",
            totalText: totalPrice.toString(),
            email: "",
            onViewInvoice: () {
              Get.offAllNamed('/home', arguments: {'tabIndex': 2});
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
          totalPrice: totalPrice,
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
          totalPrice: totalPrice,
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
      segmentService.onPaymentFailed(
        reason: errorMessage,
        paymentGateway: _selectedPayment.value,
      );
      fbEventsService.onPaymentFailed(
        reason: errorMessage,
        paymentGateway: _selectedPayment.value,
      );
      if (useWallet &&
          (errorMessage.toLowerCase().contains(
                'wallet service is temporarily unavailable',
              ) ||
              errorMessage.contains("name 'Decimal' is not defined"))) {
        _selectedPayment.value = 'gateway';
      }

      _stage.value = PaymentStage.error;
      _errorMessage.value = errorMessage;
      _resetButtonState();
      await _showPaymentErrorUx(errorMessage, fromWallet: useWallet);
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
      final slotTime = widget.selectedSlots.first['time'] ?? 'Unknown';
      final startTime = DateTime.now().toIso8601String();
      final duration = '${widget.selectedSlots.length} hour(s)';
      segmentService.onBookingConfirmed(
        bookingId: bookingIds.first.toString(),
        startTime: startTime,
        duration: duration,
        slotTime: slotTime,
        email:
            userController.user.value.contact?.electronicAddress?.emailId ?? '',
        consoleType: widget.consoleType,
        consoleAmount: widget.selectedSlots.length,
        paymentMethod: paymentMode,
      );
      fbEventsService.onBookingConfirmed(
        bookingId: bookingIds.first.toString(),
        startTime: startTime,
        duration: duration,
      );
      squadMissionsService.trackAction(action: SquadMissionAction.playSession);
      _paymentCompleted = true;
      segmentService.onPaymentSuccess(
        transactionId: "${paymentMode.toUpperCase()}_${bookingIds.first}",
        bookingId: bookingIds.first.toString(),
        paymentGateway: paymentMode,
      );
      fbEventsService.onPaymentSuccess(
        transactionId: "${paymentMode.toUpperCase()}_${bookingIds.first}",
        bookingId: bookingIds.first.toString(),
        paymentGateway: paymentMode,
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
        SnackBar(
          content: Text(successMessage),
          backgroundColor: const Color(0xff00DC00),
        ),
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
            Get.offAllNamed('/home', arguments: {'tabIndex': 2});
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
          AppLogger.d('Error releasing booking $bookingId: $releaseError');
        }
      }

      // Parse error message properly
      String errorMessage = _parseErrorMessage(e);
      segmentService.onPaymentFailed(
        reason: errorMessage,
        paymentGateway: paymentMode,
      );
      fbEventsService.onPaymentFailed(
        reason: errorMessage,
        paymentGateway: paymentMode,
      );
      if (paymentMode == 'wallet' &&
          (errorMessage.toLowerCase().contains(
                'wallet service is temporarily unavailable',
              ) ||
              errorMessage.contains("name 'Decimal' is not defined"))) {
        _selectedPayment.value = 'gateway';
      }

      // Update payment stage to error
      _stage.value = PaymentStage.error;
      _errorMessage.value = errorMessage;
      _resetButtonState();
      _paymentStatus.value = 'Failed to confirm booking';
      await _showPaymentErrorUx(
        errorMessage,
        fromWallet: paymentMode == 'wallet',
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
    try {
      final dio = await _networkProvider.auth();
      final response = await dio.post(url, data: payload);
      debugPrint('response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
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

      final dio = _networkProvider.noAuth();
      final response = await dio.post(url, data: payload);

      if (response.statusCode == 200) {
        debugPrint('Payment order created successfully ${response.data}');
        final data = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
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
        await _showPaymentErrorUx(
          'Failed to create payment order. Please try again.',
          fromWallet: false,
        );
      }
    } catch (e) {
      // Parse error message properly
      String errorMessage = _parseErrorMessage(e);
      segmentService.onPaymentFailed(
        reason: errorMessage,
        paymentGateway: 'gateway',
      );
      fbEventsService.onPaymentFailed(
        reason: errorMessage,
        paymentGateway: 'gateway',
      );

      _stage.value = PaymentStage.error;
      _errorMessage.value = errorMessage;
      _resetButtonState();
      _paymentStatus.value = 'Payment initialization failed';
      AppLogger.d('Payment error: $e');
      await _showPaymentErrorUx(errorMessage, fromWallet: false);
    }
  }
}
