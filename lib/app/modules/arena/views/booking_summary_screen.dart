import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/app/modules/home/controllers/home_controller.dart';
import 'package:hash/app/modules/payment/razorpay_controller.dart';
import 'package:hash/app/modules/arena/views/past_booking_screen.dart';
import 'package:hash/config/flavor_config.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../core/repositories/model/get_voucher_model.dart';
import '../../../../core/repositories/model/extra_services_model.dart';
import '../../../data/services/user_controller.dart';
import '../../../../core/repositories/model/booking_model.dart';

class BookingSummaryScreen extends StatefulWidget {
  final String selectedCafeName;
  final String consoleType;
  final List<Map<String, dynamic>> selectedSlots;
  final List<Map<String, dynamic>> cartItems;
  final int gameId;
  final int userId;

  const BookingSummaryScreen({
    super.key,
    required this.selectedCafeName,
    required this.consoleType,
    required this.selectedSlots,
    required this.cartItems,
    required this.gameId,
    required this.userId,
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
  final RxString _selectedPayment =
      'wallet'.obs; // 'wallet', 'gateway' or 'none'
  final UserController userController = Get.find<UserController>();

  // Voucher related variables
  final TextEditingController _voucherController = TextEditingController();
  final RxBool _isLoadingVouchers = false.obs;
  final RxList<Voucher> _availableVouchers = <Voucher>[].obs;
  final Rx<Voucher?> _appliedVoucher = Rx<Voucher?>(null);
  final RxBool _isApplyingVoucher = false.obs;
  final RxString _voucherError = ''.obs;

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
            status.toLowerCase().contains('error')) {
          _stage.value = PaymentStage.error;
          _errorMessage.value = status;
          _isProcessingPayment(false);
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
            status.toLowerCase().contains('error')) {
          _stage.value = PaymentStage.error;
          _errorMessage.value = status;
          _isProcessingPayment(false);
        }
      }
    });
  }

  Future<void> _loadVouchers() async {
    _isLoadingVouchers(true);
    try {
      final voucherResponse = await _remoteRepo.getVoucher(
        userId: widget.userId.toString(),
      );
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

  Widget _buildPaymentProgress() {
    if (_stage.value == PaymentStage.idle) {
      return const SizedBox.shrink();
    }

    String label = switch (_stage.value) {
      PaymentStage.creatingBooking => 'Creating your booking...',
      PaymentStage.debitingWallet => 'Processing wallet payment...',
      PaymentStage.initiatingGateway => 'Initiating payment gateway...',
      PaymentStage.confirmingVoucher => 'Confirming voucher...',
      PaymentStage.openingRazorpay => 'Opening payment gateway...',
      PaymentStage.done => 'Payment completed successfully!',
      PaymentStage.error => _errorMessage.value,
      _ => '',
    };

    Color backgroundColor = switch (_stage.value) {
      PaymentStage.error => Colors.red.withOpacity(0.08),
      PaymentStage.done => Colors.green.withOpacity(0.08),
      _ => Colors.blue.withOpacity(0.08),
    };

    Color borderColor = switch (_stage.value) {
      PaymentStage.error => Colors.red.withOpacity(0.4),
      PaymentStage.done => Colors.green.withOpacity(0.4),
      _ => Colors.blue.withOpacity(0.4),
    };

    Color textColor = switch (_stage.value) {
      PaymentStage.error => Colors.red,
      PaymentStage.done => Colors.green,
      _ => Colors.blue,
    };

    IconData icon = switch (_stage.value) {
      PaymentStage.error => Icons.error,
      PaymentStage.done => Icons.check_circle,
      _ => Icons.sync,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_stage.value == PaymentStage.error)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.red),
              onPressed: () {
                _stage.value = PaymentStage.idle;
                _errorMessage.value = '';
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          'Booking Summary',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
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
              Text(
                '${widget.selectedCafeName} - ${widget.consoleType}',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.selectedSlots.length} Slot(s) Selected',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B8B8B),
                ),
              ),
              const SizedBox(height: 24),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.selectedSlots.length,
                separatorBuilder: (context, index) =>
                    Divider(color: Colors.grey.shade800),
                itemBuilder: (context, index) {
                  final slot = widget.selectedSlots[index];
                  final double slotPrice = (slot['price'] ?? 50.0).toDouble();
                  return ListTile(
                    tileColor: Color(0xFF191919),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    title: Text(
                      slot['console_label'] ?? 'PC ${slot['pc_index']}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      'Time: ${slot['start_time']} - ${slot['end_time']}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Text(
                      'Rs. ${slotPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6DFB60),
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
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

                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cartItem['name'] ?? 'Unknown Item',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (quantity > 1) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Qty: $quantity × Rs. ${itemPrice.toStringAsFixed(2)}',
                                            style: GoogleFonts.inter(
                                              color: Colors.grey.shade400,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${totalItemPrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(
                                      color: Color(0xFF6DFB60),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  : _buildMealButton(),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking User',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8B8B8B),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(
                        () => Text(
                          userController.user.value.name ?? 'User',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Change',
                        style: GoogleFonts.inter(
                          color: Colors.deepOrange,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildVoucherSection(),
              const SizedBox(height: 24),
              Text(
                'Payment Summary',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                double totalPrice = calculateTotalPrice();
                double discount = calculateDiscount();
                double subtotal = calculateSubtotal();
                double slotsSubtotal = calculateSlotsSubtotal();
                double cartSubtotal = calculateCartSubtotal();

                return Column(
                  children: [
                    // Show slots subtotal if there are slots
                    if (widget.selectedSlots.isNotEmpty) ...[
                      buildPaymentRow(
                        'Slots',
                        'Rs. ${slotsSubtotal.toStringAsFixed(2)}',
                      ),
                    ],
                    // Show cart subtotal if there are validated cart items
                    if (_getValidatedCartItems().isNotEmpty) ...[
                      buildPaymentRow(
                        'Food & Beverages',
                        'Rs. ${cartSubtotal.toStringAsFixed(2)}',
                      ),
                    ],
                    buildPaymentRow(
                      'Sub Total',
                      'Rs. ${subtotal.toStringAsFixed(2)}',
                    ),
                    if (discount > 0) ...[
                      buildPaymentRow(
                        'Discount',
                        '-₹${discount.toStringAsFixed(2)}',
                        color: Colors.green,
                      ),
                    ],
                    buildPaymentRow('GST', 'Rs. 0.00'),
                    Divider(color: Colors.grey.shade800),
                    buildPaymentRow(
                      'GRAND TOTAL',
                      'Rs. ${totalPrice.toStringAsFixed(2)}',
                      bold: true,
                      fontSize: 16,
                    ),
                  ],
                );
              }),
              // ─── Payment Method ──────────────────────────────────────────
              const SizedBox(height: 16),
              Text(
                'Choose Payment Method',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    Center(
                      child: SizedBox(
                        width: 200,
                        child: _paymentChip(
                          'UPI/CARD',
                          Icons.credit_card,
                          'gateway',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 32, color: Colors.grey.shade800),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF0F0F0F),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // New: Elegant Step Status Indicator
              // Obx(() => _buildPaymentProgress()),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(
                    () => Text(
                      'Rs. ${calculateTotalPrice().toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        (_isProcessingPayment.value ||
                            _stage.value != PaymentStage.idle)
                        ? null
                        : () => handleBooking(
                            context,
                            isVoucherApplied: _appliedVoucher.value != null,
                            useWallet: _selectedPayment.value == 'wallet',
                            isGamePass: _selectedPayment.value == 'none',
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF338125),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Obx(() {
                      if (_isProcessingPayment.value ||
                          _stage.value != PaymentStage.idle) {
                        return const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        );
                      }
                      return Text(
                        'PROCEED',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: const Color(0xFF00DC00), width: 1.5),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: Text(
            '+ Select your meal',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF75F94C),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Color(0xFF191919),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

          // Voucher Input
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
              const SizedBox(width: 24),
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
                      child: Text(
                        'Apply',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              //     Obx(
              //       () => SizedBox(
              //         height: 48,
              //         child: ElevatedButton(
              //           onPressed: _isApplyingVoucher.value ? null : _applyVoucher,
              //           style: ElevatedButton.styleFrom(
              //             backgroundColor: const Color(0xFF338125),
              //             foregroundColor: Colors.white,
              //             padding: const EdgeInsets.symmetric(horizontal: 20),
              //             shape: RoundedRectangleBorder(
              //               borderRadius: BorderRadius.circular(8),
              //             ),
              //           ),
              //           child: _isApplyingVoucher.value
              //               ? const SizedBox(
              //                   height: 16,
              //                   width: 16,
              //                   child: CircularProgressIndicator(
              //                     color: Colors.white,
              //                     strokeWidth: 2,
              //                   ),
              //                 )
              //               : Text(
              //                   'Apply',
              //                   style: GoogleFonts.inter(
              //                     fontWeight: FontWeight.w500,
              //                   ),
              //                 ),
              //         ),
              //       ),
              //     ),
              //   ],
              // ),

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

              // Available Vouchers
              Obx(() {
                if (_availableVouchers.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Your Available Vouchers (${_availableVouchers.length})',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade300,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableVouchers.length,
                          itemBuilder: (context, index) {
                            final voucher = _availableVouchers[index];
                            final isActive = voucher.isActive;
                            return GestureDetector(
                              onTap: () => _selectVoucher(voucher),
                              child: Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.deepOrange.withOpacity(0.08)
                                      : Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isActive
                                        ? Colors.deepOrange.withOpacity(0.3)
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
                                        color: isActive
                                            ? Colors.deepOrange
                                            : Colors.grey.shade500,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${voucher.discountPercentage}% OFF',
                                      style: GoogleFonts.inter(
                                        color: isActive
                                            ? Colors.white
                                            : Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isActive ? 'Active' : 'Inactive',
                                      style: GoogleFonts.inter(
                                        color: isActive
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 10,
                                      ),
                                    ),
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

  Future<void> handleBooking(
    BuildContext context, {
    required bool isVoucherApplied,
    required bool useWallet,
    required bool isGamePass,
  }) async {
    if (!_validateBooking()) {
      return;
    }

    // Reset any previous error states
    _stage.value = PaymentStage.idle;
    _errorMessage.value = '';

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
      _bookingIdToSlotId = await createBookingWithSlotMap(slotIds);
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

      // a) WALLET route
      if (useWallet) {
        _stage.value = PaymentStage.debitingWallet;
        await confirmBooking(
          bookingIds: bookingIds,
          paymentMode: 'wallet',
          voucherCode: isVoucherApplied ? _appliedVoucher.value!.code : null,
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
        );
        return;
      }

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
      _stage.value = PaymentStage.error;
      _errorMessage.value = e.toString();
      _isProcessingPayment(false);
      razorpayController.isPaymentInProgress(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> confirmBooking({
    required List<int> bookingIds,
    required String paymentMode,
    String? voucherCode,
    bool isGamePass = false,
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
      await Get.to(() => const PastBookingsScreen());

      // Then navigate back to home with arena tab selected
      // This ensures when user presses back, they go to cafe page
      final homeController = Get.find<HomeController>();
      homeController.onItemTapped(1); // Select arena/cafe tab
      Get.offAllNamed('/home'); // Replace all routes with home
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

      // Update payment stage to error
      _stage.value = PaymentStage.error;
      _errorMessage.value = e.toString();
      _isProcessingPayment(false);
      _paymentStatus.value = 'Failed to confirm booking';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to confirm booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<int, int>> createBookingWithSlotMap(List<int> slotIds) async {
    final url = '${FlavorConfig.getBaseUrl('booking')}/api/bookings';
    final today = DateTime.now();
    final bookDate =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final payload = {
      "slot_id": slotIds,
      "user_id": widget.userId,
      "game_id": widget.gameId,
      "book_date": bookDate,
    };

    debugPrint('payload: $payload');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
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
      _stage.value = PaymentStage.error;
      _errorMessage.value = e.toString();
      _isProcessingPayment(false);
      _paymentStatus.value = 'Payment initialization failed';
      razorpayController.isPaymentInProgress(false);
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: $e'),
          backgroundColor: Colors.red,
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
      onTap: () => _selectedPayment(value),
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
