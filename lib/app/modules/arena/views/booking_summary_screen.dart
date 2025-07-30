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
import 'package:hash/core/network/api_endpoints.dart';
import 'package:http/http.dart' as http;
import '../../../../core/repositories/model/get_voucher_model.dart';
import '../../../data/services/user_controller.dart';
import '../../../../core/repositories/model/booking_model.dart';

class BookingSummaryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedSlots;
  final int gameId;
  final int userId;

  const BookingSummaryScreen({
    super.key,
    required this.selectedSlots,
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
  openingRazorpay,
  done,
  error,
}

final Rx<PaymentStage> _stage = PaymentStage.idle.obs;
final RxString _errorMessage = ''.obs;

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  final BookingController bookingController = Get.put(BookingController());
  final RazorpayController razorpayController = Get.put(RazorpayController());
  final HomeController homeController = Get.find();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();
  final _remoteRepo = locator<RemoteRepoInterface>();
  final RxString _selectedPayment = 'wallet'.obs; // 'wallet'  or  'gateway'
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
    super.dispose();
  }

  void _setupPaymentListeners() {
    // Listen to booking controller loading state
    ever(bookingController.isLoading, (bool loading) {
      if (!loading && _isProcessingPayment.value) {
        // Booking creation completed, payment will be initiated
        _paymentStatus.value = 'Initiating payment...';
      }
    });

    // Listen to Razorpay controller payment status
    ever(razorpayController.paymentStatus, (String status) {
      if (status.isNotEmpty) {
        _paymentStatus.value = status;
      }
    });

    // Listen to Razorpay controller payment progress
    ever(razorpayController.isPaymentInProgress, (bool inProgress) {
      if (!inProgress && _isProcessingPayment.value) {
        // Payment completed (success or failure)
        _isProcessingPayment(false);
        _paymentStatus.value = '';
      }
    });
  }

  Future<void> _loadVouchers() async {
    _isLoadingVouchers(true);
    try {
      final voucherResponse =
          await _remoteRepo.getVoucher(userId: widget.userId.toString());
      if (voucherResponse.isNotEmpty) {
        _availableVouchers.value = voucherResponse.first.vouchers;
      } else {
        _availableVouchers.value = [];
      }
    } catch (e) {
      print('Error loading vouchers: $e');
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
      final voucher = _availableVouchers.firstWhereOrNull((v) =>
          v.code.toLowerCase() == _voucherController.text.trim().toLowerCase());

      if (voucher != null) {
        if (voucher.isActive) {
          _appliedVoucher.value = voucher;
          _voucherError.value = '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Voucher applied! ${voucher.discountPercentage}% discount'),
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
    // Calculate subtotal using actual prices from selected slots
    double subtotal = widget.selectedSlots.fold(0.0, (sum, slot) {
      double slotPrice = (slot['price'] ?? 50.0).toDouble();
      return sum + slotPrice;
    });

    if (_appliedVoucher.value != null) {
      double discount =
          subtotal * (_appliedVoucher.value!.discountPercentage / 100);
      return subtotal - discount;
    }

    return subtotal;
  }

  double calculateDiscount() {
    if (_appliedVoucher.value != null) {
      double subtotal = widget.selectedSlots.fold(0.0, (sum, slot) {
        double slotPrice = (slot['price'] ?? 50.0).toDouble();
        return sum + slotPrice;
      });
      return subtotal * (_appliedVoucher.value!.discountPercentage / 100);
    }
    return 0.0;
  }

  double calculateSubtotal() {
    return widget.selectedSlots.fold(0.0, (sum, slot) {
      double slotPrice = (slot['price'] ?? 50.0).toDouble();
      return sum + slotPrice;
    });
  }

  Widget _buildPaymentProgress() {
    if (_stage.value == PaymentStage.idle ||
        _stage.value == PaymentStage.done) {
      return const SizedBox.shrink();
    }

    String label = switch (_stage.value) {
      PaymentStage.creatingBooking => 'Creating your booking...',
      PaymentStage.debitingWallet => 'Processing wallet payment...',
      PaymentStage.initiatingGateway => 'Initiating Razorpay...',
      PaymentStage.confirmingVoucher => 'Confirming voucher...',
      PaymentStage.openingRazorpay => 'Opening Razorpay...',
      PaymentStage.error => _errorMessage.value,
      _ => ''
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _stage.value == PaymentStage.error
            ? Colors.red.withOpacity(0.08)
            : Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _stage.value == PaymentStage.error
              ? Colors.red.withOpacity(0.4)
              : Colors.blue.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _stage.value == PaymentStage.error ? Icons.error : Icons.sync,
            color:
                _stage.value == PaymentStage.error ? Colors.red : Colors.blue,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: _stage.value == PaymentStage.error
                    ? Colors.red
                    : Colors.blue,
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
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text('Booking Summary',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.selectedSlots.length} Slot(s) Selected',
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const SizedBox(height: 16),
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
                    tileColor: Colors.grey.shade900,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    title: Text(
                        slot['console_label'] ?? 'PC ${slot['pc_index']}',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(
                        'Time: ${slot['start_time']} - ${slot['end_time']}',
                        style: GoogleFonts.inter(color: Colors.white70)),
                    trailing: Text('₹${slotPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16)),
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booking User',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              color: Colors.white70)),
                      const SizedBox(height: 4),
                      Obx(() => Text(userController.user.value.name ?? 'User',
                          style: GoogleFonts.inter(
                              fontSize: 16, color: Colors.white))),
                    ],
                  ),
                  TextButton(
                      onPressed: () {},
                      child: Text('Change',
                          style: GoogleFonts.inter(color: Colors.deepOrange)))
                ],
              ),
              Divider(height: 32, color: Colors.grey.shade800),

              // Voucher Section
              _buildVoucherSection(),
              const SizedBox(height: 24),

              Text('Payment Summary',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const SizedBox(height: 12),
              Obx(() {
                double totalPrice = calculateTotalPrice();
                double discount = calculateDiscount();
                double subtotal = calculateSubtotal();

                return Column(
                  children: [
                    buildPaymentRow(
                        'Sub Total', '₹${subtotal.toStringAsFixed(2)}'),
                    if (discount > 0) ...[
                      buildPaymentRow(
                          'Discount', '-₹${discount.toStringAsFixed(2)}',
                          color: Colors.green),
                    ],
                    buildPaymentRow('GST', '₹0.00'),
                    Divider(color: Colors.grey.shade800),
                    buildPaymentRow(
                        'GRAND TOTAL', '₹${totalPrice.toStringAsFixed(2)}',
                        bold: true, fontSize: 16),
                  ],
                );
              }),
              // ─── Payment Method ──────────────────────────────────────────
              const SizedBox(height: 16),
              Text('Choose Payment Method',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const SizedBox(height: 12),

              Obx(() => Row(
                    children: [
                      _paymentChip(
                          'Wallet', Icons.account_balance_wallet, 'wallet'),
                      const SizedBox(width: 12),
                      _paymentChip('UPI/CARD', Icons.credit_card, 'gateway'),
                    ],
                  )),
              Divider(height: 32, color: Colors.grey.shade800),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF0F0F0F),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // New: Elegant Step Status Indicator
              Obx(() => _buildPaymentProgress()),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => Text(
                        '₹${calculateTotalPrice().toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      )),
                  ElevatedButton(
                    onPressed: _isProcessingPayment.value
                        ? null
                        : () => handleBooking(
                              context,
                              isVoucherApplied: _appliedVoucher.value != null,
                              useWallet: _selectedPayment.value == 'wallet',
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF338125),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Obx(() {
                      if (_isProcessingPayment.value) {
                        return const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2));
                      }
                      return Text('PROCEED',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.bold));
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

  Widget _buildVoucherSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
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
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                height: 20,
                child: Obx(() => _isLoadingVouchers.value
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
                      )),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Applied Voucher Info
          Obx(() {
            final applied = _appliedVoucher.value;
            if (applied != null) {
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
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
                      icon: const Icon(Icons.close,
                          size: 18, color: Colors.green),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Remove Voucher',
                    )
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
                  height: 48,
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
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFF338125), width: 1.5),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(() => SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          _isApplyingVoucher.value ? null : _applyVoucher,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF338125),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isApplyingVoucher.value
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Apply',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500),
                            ),
                    ),
                  )),
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
                      color: Colors.red.shade300, fontSize: 12),
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
                                    color:
                                        isActive ? Colors.white : Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: GoogleFonts.inter(
                                    color: isActive ? Colors.green : Colors.red,
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
    );
  }

  Future<void> handleBooking(BuildContext context,
      {required bool isVoucherApplied, required bool useWallet}) async {
    if (widget.selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No slots selected!')),
      );
      return;
    }

    // Start loading state
    _isProcessingPayment(true);
    _stage.value = PaymentStage.creatingBooking;

    razorpayController.isPaymentInProgress(true);

    try {
      double totalPrice = calculateTotalPrice();
      int amountInPaisa = (totalPrice * 100).toInt();

      List<int> slotIds =
          widget.selectedSlots.map((slot) => slot['slot_id'] as int).toList();

      // Use the new mapping function
      _bookingIdToSlotId = await createBookingWithSlotMap(slotIds);
      List<int> bookingIds = _bookingIdToSlotId.keys.toList();
      print(slotIds);

      // Track booking started event
      if (bookingIds.isNotEmpty) {
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
      }

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

// ✅ Razorpay flow should be checked before voucher-only path
      if (_selectedPayment.value == 'gateway') {
        _stage.value = PaymentStage.initiatingGateway;
        razorpayController.bookingIdList.value = bookingIds;
        await initiatePayment(context, amountInPaisa);
        return;
      }

// Only if voucher is applied and not using Razorpay or Wallet
      if (isVoucherApplied && _appliedVoucher.value != null) {
        _stage.value = PaymentStage.confirmingVoucher;
        razorpayController.isPaymentInProgress(false);
        await confirmBooking(
          bookingIds: bookingIds,
          paymentMode: 'voucher',
          voucherCode: _appliedVoucher.value!.code,
        );
        return;
      } else {
        // Normal payment flow with Razorpay
        _stage.value = PaymentStage.initiatingGateway;
        razorpayController.bookingIdList.value = bookingIds;
        await initiatePayment(context, amountInPaisa);
      }
    } catch (e) {
      print('Error in handleBooking: $e');
      _isProcessingPayment(false);
      _paymentStatus.value = '';
      razorpayController.isPaymentInProgress(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> confirmBooking(
      {required List<int> bookingIds,
      required String paymentMode, //  "wallet" | "voucher" | "gateway"
      String? voucherCode}) async {
    try {
      await _remoteRepo.confirmBooking(
        bookingIds: bookingIds,
        paymentId:
            "${paymentMode.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}",
        bookDate: DateTime.now().toIso8601String(),
        paymentMode: paymentMode, // <-- NEW field
        voucherCode: voucherCode, // null unless a voucher really applied
      );
      print('payment mode : $paymentMode');

      // Track booking confirmed event
      if (bookingIds.isNotEmpty) {
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
      }

      print('✅ Booking confirmation with voucher successful!');

      // Stop loading
      _isProcessingPayment(false);
      _paymentStatus.value = '';

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking confirmed with voucher $voucherCode!'),
          backgroundColor: Colors.green,
        ),
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
      print('🔥 Error confirming booking with voucher: $e');

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

      // Stop loading
      _isProcessingPayment(false);
      _paymentStatus.value = '';

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
      "book_date": bookDate
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      print(response.body);

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
        print('Failed to create booking. Response: ${response.body}');
        return {};
      }
    } catch (e) {
      print('Exception during booking: $e');
      return {};
    }
  }

  Future<void> initiatePayment(BuildContext context, int amountInPaisa) async {
    String receiptId = "order_rcpt_${DateTime.now().millisecondsSinceEpoch}";
    final url = Uri.parse("https://api.razorpay.com/v1/orders");
    String basicAuth =
        'Basic ${base64Encode(utf8.encode(ApiEndpoints.razorpayKey))}';

    Map<String, dynamic> payload = {
      "amount": amountInPaisa,
      "currency": "INR",
      "receipt": receiptId,
      "payment_capture": 1,
    };

    try {
      _paymentStatus.value = 'Creating payment order...';
      final response = await http.post(url,
          headers: {
            "Authorization": basicAuth,
            "Content-Type": "application/json"
          },
          body: jsonEncode(payload));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _paymentStatus.value = 'Opening payment gateway...';

        razorpayController.openCheckout(
          orderId: data['id'],
          name: userController.user.value.name ?? 'User',
          description: "Booking for selected slots",
          amount: amountInPaisa / 100,
          contact:
              userController.user.value.contact?.electronicAddress?.mobileNo ??
                  '',
          email:
              userController.user.value.contact?.electronicAddress?.emailId ??
                  '',
        );
      } else {
        print('Error creating Razorpay order: ${response.body}');
        _isProcessingPayment(false);
        _paymentStatus.value = '';
        razorpayController.isPaymentInProgress(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create payment order. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Payment error: $e');
      _isProcessingPayment(false);
      _paymentStatus.value = '';
      razorpayController.isPaymentInProgress(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildPaymentRow(String label, String value,
      {bool bold = false, double fontSize = 14, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: fontSize,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: Colors.white)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: fontSize,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? Colors.white)),
        ],
      ),
    );
  }

  Widget _paymentChip(String label, IconData icon, String value) {
    final bool isSelected = _selectedPayment.value == value;

    return GestureDetector(
      onTap: () => _selectedPayment(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF338125) : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? Color(0xFF338125) : Colors.grey.shade700),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 13))
          ],
        ),
      ),
    );
  }
}
