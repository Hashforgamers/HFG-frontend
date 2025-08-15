// BookingSummaryScreen - Optimized & Polished
// - Improved Voucher UI/UX (banner, paste/clear, apply loader, better cards)
// - Defensive calculations & null-safety
// - Lean GetX reactivity, fewer rebuilds
// - Consistent colors & spacing
// - Clear payment stage messaging

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Controllers / Services
  final BookingController bookingController = Get.put(BookingController());
  final RazorpayController razorpayController = Get.put(RazorpayController());
  final HomeController homeController = Get.find();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();
  final _remoteRepo = locator<RemoteRepoInterface>();
  final UserController userController = Get.find<UserController>();

  // Payment selection
  final RxString _selectedPayment = 'wallet'.obs; // 'wallet', 'gateway', 'none'

  // Voucher
  final TextEditingController _voucherController = TextEditingController();
  final RxBool _isLoadingVouchers = false.obs;
  final RxList<Voucher> _availableVouchers = <Voucher>[].obs;
  final Rx<Voucher?> _appliedVoucher = Rx<Voucher?>(null);
  final RxBool _isApplyingVoucher = false.obs;
  final RxString _voucherError = ''.obs;

  // Payment state
  final RxBool _isProcessingPayment = false.obs;
  final RxString _paymentStatus = ''.obs;
  final Rx<PaymentStage> _stage = PaymentStage.idle.obs;
  final RxString _errorMessage = ''.obs;

  // BookingId -> SlotId Map (to release on failure)
  Map<int, int> _bookingIdToSlotId = {};

  @override
  void initState() {
    super.initState();
    _loadVouchers();
    _setupPaymentListeners();

    // Track booking summary viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final amount = calculateTotalPrice();
      segmentService.onBookingSummaryViewed(
        bookingId: tempId,
        cafeId: 'cafe_${widget.gameId}',
        amount: amount,
      );
      fbEventsService.onBookingSummaryViewed(
        bookingId: tempId,
        cafeId: 'cafe_${widget.gameId}',
        amount: amount,
      );
    });
  }

  @override
  void dispose() {
    _voucherController.dispose();
    _resetPaymentState();
    super.dispose();
  }

  // ─────────────────────────── Listeners ───────────────────────────

  void _setupPaymentListeners() {
    ever(bookingController.isLoading, (bool loading) {
      if (!loading && _isProcessingPayment.value) {
        _paymentStatus.value = 'Initiating payment...';
        _stage.value = PaymentStage.initiatingGateway;
      }
    });

    ever(razorpayController.paymentStatus, (String status) {
      if (status.isEmpty) return;
      _paymentStatus.value = status;
      final s = status.toLowerCase();
      if (s.contains('success') || s.contains('successful')) {
        _stage.value = PaymentStage.done;
        _isProcessingPayment(false);
      } else if (s.contains('failed') || s.contains('error') || s.contains('cancelled')) {
        _stage.value = PaymentStage.error;
        _errorMessage.value = status;
        _isProcessingPayment(false);
        razorpayController.isPaymentInProgress(false);
      }
    });

    ever(razorpayController.isPaymentInProgress, (bool inProgress) {
      if (!inProgress && _isProcessingPayment.value) {
        if (_stage.value != PaymentStage.done && _stage.value != PaymentStage.error) {
          _stage.value = PaymentStage.idle;
        }
        _isProcessingPayment(false);
        _paymentStatus.value = '';
      }
    });
  }

  // ─────────────────────────── Vouchers ───────────────────────────

  Future<void> _loadVouchers() async {
    _isLoadingVouchers(true);
    try {
      final res = await _remoteRepo.getVoucher(userId: widget.userId.toString());
      _availableVouchers.value = res.isNotEmpty ? res.first.vouchers : [];
    } catch (_) {
      _availableVouchers.clear();
    } finally {
      _isLoadingVouchers(false);
    }
  }

  Future<void> _applyVoucher() async {
    final code = _voucherController.text.trim();
    if (code.isEmpty) {
      _voucherError.value = 'Please enter a voucher code';
      return;
    }

    _isApplyingVoucher(true);
    _voucherError.value = '';

    try {
      final voucher = _availableVouchers.firstWhereOrNull(
            (v) => v.code.toLowerCase() == code.toLowerCase(),
      );

      if (voucher == null) {
        _voucherError.value = 'Invalid voucher code';
      } else if (!voucher.isActive) {
        _voucherError.value = 'This voucher is not active';
      } else {
        _appliedVoucher.value = voucher;
        _voucherError.value = '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voucher applied! ${voucher.discountPercentage}% discount'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      _voucherError.value = 'Error applying voucher';
    } finally {
      _isApplyingVoucher(false);
    }
  }

  void _selectVoucher(Voucher voucher) {
    if (!voucher.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This voucher is not active'), backgroundColor: Colors.red),
      );
      return;
    }
    _voucherController.text = voucher.code.toUpperCase();
    _applyVoucher();
  }

  void _removeVoucher() {
    _appliedVoucher.value = null;
    _voucherController.clear();
    _voucherError.value = '';
  }

  // ─────────────────────────── Money ───────────────────────────

  String _inr(num v) => 'Rs. ${v.toStringAsFixed(2)}';

  // ─────────────────────────── Totals ───────────────────────────

  double calculateTotalPrice() {
    final subtotal = calculateSubtotal();
    if (_appliedVoucher.value == null) return subtotal;
    final d = subtotal * (_appliedVoucher.value!.discountPercentage / 100);
    final total = subtotal - d;
    return total < 0 ? 0.0 : total;
  }

  double calculateDiscount() {
    if (_appliedVoucher.value == null) return 0.0;
    final subtotal = calculateSubtotal();
    final d = subtotal * (_appliedVoucher.value!.discountPercentage / 100);
    return d > subtotal ? subtotal : d;
  }

  double calculateSubtotal() => calculateSlotsSubtotal() + calculateCartSubtotal();

  double calculateSlotsSubtotal() {
    return widget.selectedSlots.fold<double>(0.0, (sum, slot) {
      double price = (slot['price'] ?? 50.0).toDouble();
      if (price.isNaN || price < 0) price = 0.0;
      return sum + price;
    });
  }

  double calculateCartSubtotal() {
    return _getValidatedCartItems().fold<double>(0.0, (sum, item) {
      double price = (item['price'] ?? 0.0).toDouble();
      int qty = (item['qty'] ?? 1) as int;
      if (price.isNaN || price < 0) price = 0.0;
      if (qty < 0) qty = 0;
      return sum + (price * qty);
    });
  }

  // ─────────────────────────── UI Helpers ───────────────────────────

  Widget _buildPaymentProgress() {
    if (_stage.value == PaymentStage.idle) return const SizedBox.shrink();

    final (label, bg, br, tc, icon) = switch (_stage.value) {
      PaymentStage.creatingBooking => ('Creating your booking...', Colors.blue.withOpacity(0.08), Colors.blue.withOpacity(0.4), Colors.blue, Icons.sync),
      PaymentStage.debitingWallet => ('Processing wallet payment...', Colors.blue.withOpacity(0.08), Colors.blue.withOpacity(0.4), Colors.blue, Icons.account_balance_wallet),
      PaymentStage.initiatingGateway => ('Initiating payment gateway...', Colors.blue.withOpacity(0.08), Colors.blue.withOpacity(0.4), Colors.blue, Icons.sync),
      PaymentStage.confirmingVoucher => ('Confirming voucher...', Colors.blue.withOpacity(0.08), Colors.blue.withOpacity(0.4), Colors.blue, Icons.confirmation_number),
      PaymentStage.confirmingGamePass => ('Confirming Hash Game Pass...', Colors.blue.withOpacity(0.08), Colors.blue.withOpacity(0.4), Colors.blue, Icons.gamepad),
      PaymentStage.openingRazorpay => ('Opening payment gateway...', Colors.blue.withOpacity(0.08), Colors.blue.withOpacity(0.4), Colors.blue, Icons.credit_card),
      PaymentStage.done => ('Payment completed successfully!', Colors.green.withOpacity(0.08), Colors.green.withOpacity(0.4), Colors.green, Icons.check_circle),
      // PaymentStage.error => (_errorMessage.value.isNotEmpty ? _errorMessage.value : 'Something went wrong'), Colors.red.withOpacity(0.08), Colors.red.withOpacity(0.4), Colors.red, Icons.error,
    _ => ('', Colors.transparent, Colors.transparent, Colors.white, Icons.info),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: br)),
      child: Row(
        children: [
          Icon(icon, color: tc, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: GoogleFonts.inter(color: tc, fontSize: 14, fontWeight: FontWeight.w500)),
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

  Widget _paymentChip(String label, IconData icon, String value) {
    final bool isSelected = _selectedPayment.value == value;
    return GestureDetector(
      onTap: () => _selectedPayment(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF338125) : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF338125) : Colors.grey.shade700),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white70, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(color: isSelected ? Colors.white : Colors.white70, fontSize: 13),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPaymentRow(String label, String value, {bool bold = false, double fontSize = 14, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: Colors.white)),
        Text(value, style: GoogleFonts.inter(fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.white)),
      ]),
    );
  }

  // ─────────────────────────── Build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text('Booking Summary', style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.black,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final slots = widget.selectedSlots;
          final validatedCart = _getValidatedCartItems();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.selectedCafeName} - ${widget.consoleType}', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 4),
              Text('${slots.length} Slot(s) Selected', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF8B8B8B))),
              const SizedBox(height: 16),

              // Payment Progress Banner
              _buildPaymentProgress(),

              // Selected slots
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: slots.length,
                separatorBuilder: (context, _) => Divider(color: Colors.grey.shade800),
                itemBuilder: (_, i) {
                  final s = slots[i];
                  final double price = (s['price'] ?? 50.0).toDouble();
                  return ListTile(
                    tileColor: const Color(0xFF191919),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: Text(s['console_label'] ?? 'PC ${s['pc_index']}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text('Time: ${s['start_time']} - ${s['end_time']}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                    trailing: Text(_inr(price), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF6DFB60), fontSize: 12)),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Extras (Cart)
              validatedCart.isNotEmpty
                  ? Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFF191919), borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('Food & Beverages', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF338125).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: Text(_getCartItemsSummary(), style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6DFB60), fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: validatedCart.length,
                    itemBuilder: (_, i) {
                      final item = validatedCart[i];
                      final int q = (item['qty'] ?? 1) as int;
                      final double unit = (item['price'] ?? 0.0).toDouble();
                      final double line = unit * q;
                      return Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item['name'] ?? 'Unknown Item', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            if (q > 1) ...[
                              const SizedBox(height: 2),
                              Text('Qty: $q × ${_inr(unit)}', style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12)),
                            ],
                          ]),
                        ),
                        Text(_inr(line), style: GoogleFonts.inter(color: const Color(0xFF6DFB60), fontSize: 12, fontWeight: FontWeight.bold)),
                      ]);
                    },
                  ),
                ]),
              )
                  : _buildMealButton(),

              const SizedBox(height: 16),

              // User row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Booking User', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: const Color(0xFF8B8B8B), fontSize: 14)),
                    const SizedBox(height: 4),
                    Obx(() => Text(userController.user.value.name ?? 'User', style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold))),
                  ]),
                  TextButton(onPressed: () {}, child: Text('Change', style: GoogleFonts.inter(color: Colors.deepOrange, fontSize: 14))),
                ],
              ),

              const SizedBox(height: 10),

              // Voucher Section (improved)
              _buildVoucherSection(),

              const SizedBox(height: 16),

              // Payment Summary
              Text('Payment Summary', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 10),
              Builder(builder: (_) {
                final total = calculateTotalPrice();
                final discount = calculateDiscount();
                final subtotal = calculateSubtotal();
                final slotsSubtotal = calculateSlotsSubtotal();
                final cartSubtotal = calculateCartSubtotal();

                return Column(children: [
                  if (slotsSubtotal > 0) buildPaymentRow('Slots', _inr(slotsSubtotal)),
                  if (cartSubtotal > 0) buildPaymentRow('Food & Beverages', _inr(cartSubtotal)),
                  buildPaymentRow('Sub Total', _inr(subtotal)),
                  if (discount > 0) buildPaymentRow('Discount', '-${_inr(discount)}', color: Colors.green),
                  buildPaymentRow('GST', _inr(0)),
                  Divider(color: Colors.grey.shade800),
                  buildPaymentRow('GRAND TOTAL', _inr(total), bold: true, fontSize: 16),
                ]);
              }),

              const SizedBox(height: 16),

              // Payment Method
              Text('Choose Payment Method', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 12),
              Column(children: [
                Row(children: [
                  Expanded(child: _paymentChip('Wallet', Icons.account_balance_wallet, 'wallet')),
                  const SizedBox(width: 12),
                  Expanded(child: _paymentChip('Hash Game Pass', Icons.gamepad, 'none')),
                ]),
                const SizedBox(height: 12),
                Center(child: SizedBox(width: 200, child: _paymentChip('UPI/CARD', Icons.credit_card, 'gateway'))),
              ]),

              Divider(height: 32, color: Colors.grey.shade800),
            ],
          );
        }),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF0F0F0F),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child:Obx(() {
            final isBusy = _isProcessingPayment.value ||
                {
                  PaymentStage.creatingBooking,
                  PaymentStage.debitingWallet,
                  PaymentStage.initiatingGateway,
                  PaymentStage.confirmingVoucher,
                  PaymentStage.confirmingGamePass,
                  PaymentStage.openingRazorpay,
                }.contains(_stage.value);

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _inr(calculateTotalPrice()),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: isBusy
                      ? null
                      : () => handleBooking(
                    context,
                    isVoucherApplied: _appliedVoucher.value != null,
                    useWallet: _selectedPayment.value == 'wallet',
                    isGamePass: _selectedPayment.value == 'none',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF338125),
                    // show a distinct disabled color to make button outline visible
                    disabledBackgroundColor: Colors.white12,
                    foregroundColor: Colors.white, // text & icon color
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    minimumSize: const Size(120, 44), // ensures it's visible/tappable
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: isBusy
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    'Pay',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      // don't force black; let foregroundColor (white) apply
                    ),
                  ),
                ),
              ],
            );
          })

        ),
      ),
    );
  }

  // ─────────────────────────── UI Pieces ───────────────────────────

  Widget _buildMealButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: const Color(0xFF00DC00), width: 1.5),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(child: Text('+ Select your meal', style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF75F94C)))),
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Icon(CupertinoIcons.tickets, size: 18, color: Colors.green.shade400),
          const SizedBox(width: 8),
          Text('Have a Voucher?', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const Spacer(),
          Obx(() {
            final isLoading = _isLoadingVouchers.value;
            return InkWell(
              onTap: isLoading ? null : _loadVouchers,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedRotation(
                turns: isLoading ? 1 : 0,
                duration: const Duration(milliseconds: 600),
                child: Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle),
                  child: const Icon(CupertinoIcons.refresh, color: Colors.green, size: 16),
                ),
              ),
            );
          }),
        ]),

        const SizedBox(height: 12),

        // Applied banner
        Obx(() {
          final applied = _appliedVoucher.value;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: (applied == null)
                ? const SizedBox.shrink()
                : Container(
              key: const ValueKey('applied_banner'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
                  Colors.green.withOpacity(0.18),
                  Colors.green.withOpacity(0.08),
                ]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.35)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Applied: ${applied.code}', style: GoogleFonts.inter(color: Colors.green.shade400, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${applied.discountPercentage}% discount active',
                        style: GoogleFonts.inter(color: Colors.green.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w500)),
                  ]),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.green.shade300, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                  onPressed: _removeVoucher,
                  child: const Text('Remove'),
                ),
              ]),
            ),
          );
        }),

        const SizedBox(height: 12),

        // Input + Apply
        Row(children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: _voucherController,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')), _UpperCaseTextFormatter()],
                onSubmitted: (_) {
                  if (!_isApplyingVoucher.value && _voucherController.text.trim().isNotEmpty) {
                    _applyVoucher();
                  }
                },
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixIcon: const Icon(CupertinoIcons.ticket, size: 18, color: Colors.white54),
                  suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(visualDensity:VisualDensity.compact,
                      tooltip: 'Paste',
                      icon: const Icon(CupertinoIcons.doc_on_clipboard, size: 18, color: Colors.white54),
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        final text = (data?.text ?? '').trim();
                        if (text.isNotEmpty) _voucherController.text = text.toUpperCase();
                      },
                    ),
                    IconButton(visualDensity:VisualDensity.compact,

                      tooltip: 'Clear',
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 18, color: Colors.white30),
                      onPressed: () => _voucherController.clear(),
                    ),
                  ]),
                  hintText: 'Enter voucher code',
                  hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF338125), width: 1.5)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Obx(() {
            final busy = _isApplyingVoucher.value;
            final disabled = busy || _voucherController.text.trim().isEmpty;
            return SizedBox(
              height: 45,
              child: ElevatedButton(
                onPressed: disabled ? null : _applyVoucher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF338125),
                  disabledBackgroundColor: Colors.white12,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Apply', style: GoogleFonts.inter(fontWeight: FontWeight.normal,fontSize: 12)),
              ),
            );
          }),
        ]),

        // Error
        Obx(() {
          final err = _voucherError.value;
          return AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: err.isNotEmpty ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                const Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.redAccent, size: 14),
                const SizedBox(width: 6),
                Expanded(child: Text(err, style: GoogleFonts.inter(color: Colors.red.shade300, fontSize: 12))),
              ]),
            ),
            secondChild: const SizedBox(height: 0),
          );
        }),

        const SizedBox(height: 12),

        // Available vouchers
        Obx(() {
          final list = _availableVouchers;
          if (list.isEmpty) return const SizedBox.shrink();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your Available Vouchers (${list.length})', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            SizedBox(
              height: 122,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final v = list[i];
                  return _VoucherCard(
                    code: v.code,
                    discount: v.discountPercentage,
                    active: v.isActive,
                    onTap: () => _selectVoucher(v),
                    onApply: v.isActive
                        ? () {
                      _voucherController.text = v.code.toUpperCase();
                      _applyVoucher();
                    }
                        : null,
                  );
                },
              ),
            ),
          ]);
        }),
      ]),
    );
  }

  // ─────────────────────────── Validation / Utils ───────────────────────────

  bool _validateBooking() {
    if (widget.selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No slots selected!'), backgroundColor: Colors.red));
      return false;
    }

    final total = calculateTotalPrice();
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid total price!'), backgroundColor: Colors.red));
      return false;
    }

    final validatedItems = _getValidatedCartItems();
    if (validatedItems.length != widget.cartItems.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Some cart items have invalid data and will be excluded'),
        backgroundColor: Colors.orange,
      ));
    }

    return true;
  }

  void _resetPaymentState() {
    _stage.value = PaymentStage.idle;
    _errorMessage.value = '';
    _isProcessingPayment(false);
    _paymentStatus.value = '';
    razorpayController.isPaymentInProgress(false);
    razorpayController.paymentStatus.value = '';
  }

  void _resetButtonState() {
    _isProcessingPayment(false);
    razorpayController.isPaymentInProgress(false);
  }

  void _clearErrorState() {
    _stage.value = PaymentStage.idle;
    _errorMessage.value = '';
    _paymentStatus.value = '';
  }

  String _getCartItemsSummary() {
    if (widget.cartItems.isEmpty) return '';
    final total = _getValidatedCartItems().fold<int>(0, (sum, it) {
      int q = (it['qty'] ?? 1) as int;
      return sum + (q < 0 ? 0 : q);
    });
    return '$total Item${total > 1 ? 's' : ''}';
  }

  List<Map<String, dynamic>> _getValidatedCartItems() {
    return widget.cartItems.where((item) {
      if (item['name'] == null || item['name'].toString().isEmpty) return false;
      double price = (item['price'] ?? 0.0).toDouble();
      int qty = (item['qty'] ?? 1) as int;
      if (price.isNaN || price < 0) return false;
      if (qty <= 0) return false;
      return true;
    }).toList();
  }

  String _parseErrorMessage(dynamic error) {
    String errorMessage = 'An error occurred';
    final s = error.toString();

    if (s.contains('DioError') || s.contains('DioException')) {
      try {
        if (s.contains('"error"')) {
          final m = RegExp(r'"error":\s*"([^"]+)"').firstMatch(s);
          if (m != null) errorMessage = m.group(1) ?? errorMessage;
        } else if (s.contains('Insufficient wallet balance')) {
          errorMessage = 'Insufficient wallet balance. Please add money to your wallet or choose a different payment method.';
        } else if (s.contains('500')) {
          errorMessage = 'Server error occurred. Please try again later.';
        } else if (s.contains('400')) {
          errorMessage = 'Invalid request. Please check your details.';
        } else if (s.contains('401')) {
          errorMessage = 'Authentication failed. Please login again.';
        } else if (s.contains('403')) {
          errorMessage = 'Access denied. Please check your permissions.';
        } else if (s.contains('404')) {
          errorMessage = 'Service not found. Please try again later.';
        } else if (s.contains('422')) {
          errorMessage = 'Invalid data. Please check your selections.';
        }
      } catch (e) {
        debugPrint('Error parsing DioError: $e');
        errorMessage = 'An unexpected error occurred. Please try again.';
      }
    } else {
      errorMessage = s.replaceAll('Exception: ', '').replaceAll('Error: ', '');
    }
    return errorMessage;
  }

  // ─────────────────────────── Booking Flow ───────────────────────────

  Future<void> handleBooking(
      BuildContext context, {
        required bool isVoucherApplied,
        required bool useWallet,
        required bool isGamePass,
      }) async {
    if (!_validateBooking()) return;

    _clearErrorState();
    _isProcessingPayment(true);
    _stage.value = PaymentStage.creatingBooking;

    try {
      final totalPrice = calculateTotalPrice();
      final amountInPaisa = (totalPrice * 100).toInt();

      final slotIds = widget.selectedSlots.map((s) => s['slot_id'] as int).toList();
      _bookingIdToSlotId = await createBookingWithSlotMap(slotIds);
      final bookingIds = _bookingIdToSlotId.keys.toList();

      if (bookingIds.isEmpty) throw Exception('Failed to create bookings, bookingIds: $bookingIds');

      final slotTime = widget.selectedSlots.first['time'] ?? 'Unknown';
      segmentService.onBookingStarted(cafeId: 'cafe_${widget.gameId}', gameId: widget.gameId.toString(), slotTime: slotTime);
      fbEventsService.onBookingStarted(cafeId: 'cafe_${widget.gameId}', gameId: widget.gameId.toString(), slotTime: slotTime);

      if (useWallet) {
        _stage.value = PaymentStage.debitingWallet;
        await confirmBooking(
          bookingIds: bookingIds,
          paymentMode: 'wallet',
          voucherCode: isVoucherApplied ? _appliedVoucher.value!.code : null,
        );
        return;
      }

      if (isVoucherApplied && _appliedVoucher.value != null) {
        _stage.value = PaymentStage.confirmingVoucher;
        await confirmBooking(bookingIds: bookingIds, paymentMode: 'voucher', voucherCode: _appliedVoucher.value!.code);
        return;
      }

      if (isGamePass) {
        _stage.value = PaymentStage.confirmingGamePass;
        await confirmBooking(bookingIds: bookingIds, paymentMode: 'none', isGamePass: true);
        return;
      }

      // Razorpay
      _stage.value = PaymentStage.initiatingGateway;
      razorpayController.bookingIdList.value = bookingIds;
      razorpayController.slotIdsList.value = slotIds;
      razorpayController.cartItemsList.value = _getValidatedCartItems();
      await initiatePayment(context, amountInPaisa);
    } catch (e) {
      final msg = _parseErrorMessage(e);
      _stage.value = PaymentStage.error;
      _errorMessage.value = msg;
      _resetButtonState();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
        ]),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        action: msg.contains('Insufficient wallet balance')
            ? SnackBarAction(
          label: 'Add Money',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigate to wallet to add money'), backgroundColor: Colors.blue));
          },
        )
            : null,
      ));
    }
  }

  Future<void> confirmBooking({
    required List<int> bookingIds,
    required String paymentMode,
    String? voucherCode,
    bool isGamePass = false,
  }) async {
    try {
      // Extras payload
      List<ExtraServiceItem> extraServices = [];
      final items = _getValidatedCartItems();
      if (items.isNotEmpty) {
        extraServices = items
            .map((it) => ExtraServiceItem(
          categoryId: (it['category_id'] ?? 0) as int,
          itemId: (it['id'] ?? 0) as int,
          quantity: (it['qty'] ?? 1) as int,
        ))
            .toList();
      }

      await _remoteRepo.confirmBooking(
        bookingIds: bookingIds,
        paymentId: "${paymentMode.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}",
        bookDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        paymentMode: paymentMode,
        voucherCode: voucherCode,
        isGamePass: isGamePass,
        extraServices: extraServices,
      );

      // Track
      final startTime = DateTime.now().toIso8601String();
      final duration = '${widget.selectedSlots.length} hour(s)';
      segmentService.onBookingConfirmed(bookingId: bookingIds.first.toString(), startTime: startTime, duration: duration);
      fbEventsService.onBookingConfirmed(bookingId: bookingIds.first.toString(), startTime: startTime, duration: duration);

      _stage.value = PaymentStage.done;
      _isProcessingPayment(false);
      _paymentStatus.value = 'Booking confirmed successfully!';

      final msg = voucherCode != null ? 'Booking confirmed with voucher $voucherCode!' : 'Booking confirmed successfully!';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

      bookingController.clearSelectedSlots();

      await Get.to(() => const PastBookingsScreen());
      Get.find<HomeController>().onItemTapped(1);
      Get.offAllNamed('/home');
    } catch (e) {
      // Release reserved bookings on failure
      for (final id in bookingIds) {
        try {
          final slotId = _bookingIdToSlotId[id] ?? id;
          await _remoteRepo.releaseBooking(
            bookings: BookingModel(slotId: slotId, bookingId: id, bookDate: DateTime.now().toIso8601String()),
          );
        } catch (re) {
          debugPrint('Error releasing booking $id: $re');
        }
      }

      final msg = _parseErrorMessage(e);
      _stage.value = PaymentStage.error;
      _errorMessage.value = msg;
      _resetButtonState();
      _paymentStatus.value = 'Failed to confirm booking';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
        ]),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        action: msg.contains('Insufficient wallet balance')
            ? SnackBarAction(
          label: 'Add Money',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigate to wallet to add money'), backgroundColor: Colors.blue));
          },
        )
            : null,
      ));
    }
  }

  Future<Map<int, int>> createBookingWithSlotMap(List<int> slotIds) async {
    final url = '${FlavorConfig.getBaseUrl('booking')}/api/bookings';
    final today = DateTime.now();
    final bookDate = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final payload = {"slot_id": slotIds, "user_id": widget.userId, "game_id": widget.gameId, "book_date": bookDate};

    try {
      final response = await http.post(Uri.parse(url), headers: {"Content-Type": "application/json"}, body: jsonEncode(payload));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final map = <int, int>{};
        if (data['bookings'] != null) {
          for (final b in data['bookings']) {
            if (b['booking_id'] != null && b['slot_id'] != null) {
              map[b['booking_id']] = b['slot_id'];
            }
          }
        } else if (data['booking_ids'] != null) {
          final ids = List<int>.from(data['booking_ids']);
          for (int i = 0; i < ids.length && i < slotIds.length; i++) {
            map[ids[i]] = slotIds[i];
          }
        }
        return map;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<void> initiatePayment(BuildContext context, int amountInPaisa) async {
    final receiptId = "order_rcpt_${DateTime.now().millisecondsSinceEpoch}";
    final url = '${FlavorConfig.getBaseUrl('booking')}/api/create_order';
    final payload = {"amount": amountInPaisa, "currency": "INR", "receipt": receiptId};

    try {
      _stage.value = PaymentStage.openingRazorpay;
      _paymentStatus.value = 'Creating payment order...';

      final response = await http.post(Uri.parse(url), headers: {"Content-Type": "application/json"}, body: jsonEncode(payload));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _paymentStatus.value = 'Opening payment gateway...';

        razorpayController.openCheckout(
          orderId: data['id'],
          name: userController.user.value.name ?? 'User',
          description: "Booking for selected slots",
          amount: (data['amount'] ?? amountInPaisa) / 100,
          contact: userController.user.value.contact?.electronicAddress?.mobileNo ?? '',
          email: userController.user.value.contact?.electronicAddress?.emailId ?? '',
        );
      } else {
        _stage.value = PaymentStage.error;
        _errorMessage.value = 'Failed to create payment order';
        _isProcessingPayment(false);
        _paymentStatus.value = 'Payment order creation failed';
        razorpayController.isPaymentInProgress(false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create payment order. Please try again.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      final msg = _parseErrorMessage(e);
      _stage.value = PaymentStage.error;
      _errorMessage.value = msg;
      _resetButtonState();
      _paymentStatus.value = 'Payment initialization failed';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
        ]),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }
}

// ─────────────────────────── Voucher helpers ───────────────────────────

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.code,
    required this.discount,
    required this.active,
    this.onTap,
    this.onApply,
  });

  final String code;
  final int discount;
  final bool active;
  final VoidCallback? onTap;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final border = active ? Colors.green.withOpacity(0.35) : Colors.white12;
    final bg = active ? Colors.green.withOpacity(0.08) : Colors.white.withOpacity(0.04);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: active ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(active ? 'ACTIVE' : 'INACTIVE',
                style: GoogleFonts.inter(color: active ? Colors.green : Colors.redAccent, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
          const Spacer(),
          Text('$discount% OFF', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(code, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 10,color: active ? Colors.green.shade300 : Colors.white60, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 6),
          SizedBox(
            height: 26,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onApply,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: active ? Colors.green : Colors.white12),
                foregroundColor: active ? Colors.green : Colors.white38,
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(active ? 'Apply' : 'Locked',style: TextStyle(fontSize: 12),),
            ),
          ),
        ]),
      ),
    );
  }
}
