import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/config/flavor_config.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:http/http.dart' as http;
import '../../../../config/flavor_config.dart';
import '../../payment/razorpay_controller.dart';
import '../controllers/booking_controller.dart';
import '../../../../core/repositories/model/get_voucher_model.dart';
import '../../../../core/repositories/remote/remote_repo_interface.dart';
import '../../../../core/service_locator.dart';
import '../../home/controllers/home_controller.dart';
import 'past_booking_screen.dart';

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

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  final BookingController bookingController = Get.put(BookingController());
  final RazorpayController razorpayController = Get.put(RazorpayController());
  final _remoteRepo = locator<RemoteRepoInterface>();
  final RxString _selectedPayment = 'wallet'.obs;  // 'wallet'  or  'gateway'

  final String userName = "Shen";

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

  @override
  void initState() {
    super.initState();
    _loadVouchers();
    // Listen to payment events
    _setupPaymentListeners();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Booking Summary',
            style: TextStyle(color: Colors.white)),
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
                  style: const TextStyle(
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
                    title: Text('PC ${slot['pc_index']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(
                        'Time: ${slot['start_time']} - ${slot['end_time']}',
                        style: const TextStyle(color: Colors.white70)),
                    trailing: Text('₹${slotPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
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
                      const Text('Booking User',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text(userName,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white)),
                    ],
                  ),
                  TextButton(
                      onPressed: () {},
                      child: const Text('Change',
                          style: TextStyle(color: Colors.deepOrange)))
                ],
              ),
              Divider(height: 32, color: Colors.grey.shade800),

              // Voucher Section
              _buildVoucherSection(),
              const SizedBox(height: 24),

              const Text('Payment Summary',
                  style: TextStyle(
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
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const SizedBox(height: 12),

              Obx(() => Row(
                children: [
                  _paymentChip('Wallet', Icons.account_balance_wallet, 'wallet'),
                  const SizedBox(width: 12),
                  _paymentChip('Gateway', Icons.credit_card, 'gateway'),
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
              // Payment status indicator
              Obx(() {
                if (_isProcessingPayment.value &&
                    _paymentStatus.value.isNotEmpty) {
                  return Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            color: Colors.blue,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _paymentStatus.value,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => Text(
                        '₹${calculateTotalPrice().toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      )),
                  ElevatedButton(
                    onPressed: _isProcessingPayment.value
                        ? null
                        : // Normal button tap
                        () => handleBooking(
                      context,
                      isVoucherApplied: _appliedVoucher.value != null,
                      useWallet: _selectedPayment.value == 'wallet',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffDE3A3A),
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
                      return const Text('PROCEED',
                          style: TextStyle(
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Have a Voucher?',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              Obx(() => _isLoadingVouchers.value
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          color: Colors.deepOrange, strokeWidth: 2))
                  : IconButton(
                      onPressed: _loadVouchers,
                      icon: const Icon(Icons.refresh, color: Colors.deepOrange),
                      iconSize: 20,
                    )),
            ],
          ),
          const SizedBox(height: 12),

          // Applied voucher display
          Obx(() {
            if (_appliedVoucher.value != null) {
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voucher Applied: ${_appliedVoucher.value!.code}',
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${_appliedVoucher.value!.discountPercentage}% discount applied',
                            style: TextStyle(
                                color: Colors.green.withOpacity(0.8),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _removeVoucher,
                      icon: const Icon(Icons.close,
                          color: Colors.green, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Voucher input field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _voucherController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter voucher code',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
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
                      borderSide: const BorderSide(color: Colors.deepOrange),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(() => ElevatedButton(
                    onPressed: _isApplyingVoucher.value ? null : _applyVoucher,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isApplyingVoucher.value
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Apply'),
                  )),
            ],
          ),

          // Error message
          Obx(() {
            if (_voucherError.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _voucherError.value,
                  style: TextStyle(color: Colors.red.shade300, fontSize: 12),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Available vouchers
          Obx(() {
            if (_availableVouchers.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Your Available Vouchers (${_availableVouchers.length})',
                    style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableVouchers.length,
                      itemBuilder: (context, index) {
                        final voucher = _availableVouchers[index];
                        return GestureDetector(
                          onTap: () => _selectVoucher(voucher),
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: voucher.isActive
                                  ? Colors.deepOrange.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: voucher.isActive
                                    ? Colors.deepOrange.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  voucher.code,
                                  style: TextStyle(
                                    color: voucher.isActive
                                        ? Colors.deepOrange
                                        : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${voucher.discountPercentage}% OFF',
                                  style: TextStyle(
                                    color: voucher.isActive
                                        ? Colors.white
                                        : Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  voucher.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: voucher.isActive
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
    _paymentStatus.value = 'Creating booking...';
    razorpayController.isPaymentInProgress(true);

    try {
      double totalPrice = calculateTotalPrice();
      int amountInPaisa = (totalPrice * 100).toInt();

      List<int> slotIds =
          widget.selectedSlots.map((slot) => slot['slot_id'] as int).toList();

      List<int> bookingIds = await createBooking(slotIds);
      print(slotIds);
      // a) WALLET route
      if (useWallet) {
        _paymentStatus.value = 'Debiting wallet…';
        await confirmBooking(
          bookingIds: bookingIds,
          paymentMode: 'wallet',
          voucherCode: isVoucherApplied ? _appliedVoucher.value!.code : null,
        );
        return;
      }

// ✅ Razorpay flow should be checked before voucher-only path
      if (_selectedPayment.value == 'gateway') {
        _paymentStatus.value = 'Initiating payment gateway...';
        razorpayController.bookingIdList.value = bookingIds;
        await initiatePayment(context, amountInPaisa);
        return;
      }

// Only if voucher is applied and not using Razorpay or Wallet
      if (isVoucherApplied && _appliedVoucher.value != null) {
        _paymentStatus.value = 'Confirming booking with voucher…';
        razorpayController.isPaymentInProgress(false);
        await confirmBooking(
          bookingIds: bookingIds,
          paymentMode: 'voucher',
          voucherCode: _appliedVoucher.value!.code,
        );
        return;
      }


      else {
        // Normal payment flow with Razorpay
        _paymentStatus.value = 'Initiating payment gateway...';
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
        required String paymentMode,     //  "wallet" | "voucher" | "gateway"
        String? voucherCode}) async {
    try {
      await _remoteRepo.confirmBooking(
        bookingIds : bookingIds,
        paymentId  : "${paymentMode.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}",
        bookDate   : DateTime.now().toIso8601String(),
        paymentMode: paymentMode,           // <-- NEW field
        voucherCode: voucherCode,           // null unless a voucher really applied
      );
      print('payment mode : $paymentMode');

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

  Future<List<int>> createBooking(List<int> slotIds) async {
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
        return List<int>.from(data['booking_ids']);
      } else {
        print('Failed to create booking. Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception during booking: $e');
      return [];
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
          name: "HashForGamers",
          description: "Booking for selected slots",
          amount: amountInPaisa / 100,
          contact: "9876543210",
          email: "user@example.com",
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
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: Colors.white)),
          Text(value,
              style: TextStyle(
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
          color: isSelected ? Colors.deepOrange : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? Colors.deepOrange : Colors.grey.shade700),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color:
                    isSelected ? Colors.white : Colors.white70, fontSize: 13))
          ],
        ),
      ),
    );
  }

}
