import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/game_pass/view/game_pass_view.dart';
import 'package:hash/app/modules/wallet/cubit/transaction_cubit.dart';
import 'package:hash/core/repositories/model/transaction_history_model.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart'; // <-- free neon-style icon set
import '../../../../utils/widgets/loader.dart';
import '../controllers/razorpay_wallet_controller.dart';
import '../controllers/wallet_controller.dart';
import '../../../data/models/wallet_model.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TransactionCubit(),
      child: _WalletPage(),
    );
  }
}

class _WalletPage extends StatefulWidget {
  const _WalletPage();

  @override
  State<_WalletPage> createState() => __WalletPageState();
}

class __WalletPageState extends State<_WalletPage> {
  @override
  void initState() {
    BlocProvider.of<TransactionCubit>(context).getTransactionHistory();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) {
          return const WalletScreen(
            transactions: <TransactionHistoryModel>[],
            isTransactionLoading: true,
          );
        }
        if (state is TransactionLoaded) {
          return WalletScreen(transactions: state.transactions);
        }
        if (state is TransactionError) {
          return WalletScreen(
            transactions: const <TransactionHistoryModel>[],
            transactionError: _normalizeTransactionError(state.message),
          );
        }
        return const WalletScreen(transactions: <TransactionHistoryModel>[]);
      },
    );
  }

  String _normalizeTransactionError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('unauthorized') || lower.contains('401')) {
      return 'Your session has expired. Please log in again to view your transaction history.';
    }
    if (message.trim().isEmpty) {
      return 'Something went wrong while loading your transactions.';
    }
    return message;
  }
}

class WalletScreen extends StatefulWidget {
  final List<TransactionHistoryModel> transactions;
  final bool isTransactionLoading;
  final String? transactionError;

  const WalletScreen({
    super.key,
    required this.transactions,
    this.isTransactionLoading = false,
    this.transactionError,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final walletCtr = Get.find<WalletController>();
  final razorpayCtr = Get.put(RazorpayWalletController());
  final TextEditingController amountController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey _transactionsKey = GlobalKey();
  String _transactionFilter = 'all';
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  @override
  void initState() {
    super.initState();
    searchController.addListener(_refreshTransactionSearch);
    // Track wallet viewed event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        segmentService.onWalletViewed(userId: currentUser.uid);
        fbEventsService.onWalletViewed(userId: currentUser.uid);
      }
    });
  }

  @override
  void dispose() {
    searchController.removeListener(_refreshTransactionSearch);
    amountController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _refreshTransactionSearch() {
    if (mounted) setState(() {});
  }

  // ───────────────────────── UI BUILD ──────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Wallet",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Obx(() {
        if (walletCtr.isLoading) {
          return const Center(child: AppLinearLoader());
        }

        // Show error if any
        if (walletCtr.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Error loading wallet',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  walletCtr.errorMessage,
                  style: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => walletCtr.refreshWallet(),
                  icon: Icon(Icons.refresh, color: Colors.black),
                  label: Text(
                    'Retry',
                    style: GoogleFonts.inter(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00DC00),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            walletCtr.refreshWallet();
            BlocProvider.of<TransactionCubit>(context).getTransactionHistory();
          },
          color: const Color(0xff00DC00),
          backgroundColor: Colors.black,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _balanceCard(),
                const SizedBox(height: 32),
                _quickActionButtons(),
                const SizedBox(height: 32),
                _recentTransactions(),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ────────────────────────── WIDGETS ──────────────────────────
  Widget _balanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        children: [
          // Simple balance display
          Column(
            children: [
              Text(
                "Balance",
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                walletCtr.formattedBalance,
                style: GoogleFonts.orbitron(
                  fontSize: 32,
                  color: const Color(0xff00DC00),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _actionButton(
                icon: Icons.account_balance_wallet,
                label: "Add Funds",
                onTap: () => _showAddMoneyBottomSheet(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionButton(
                icon: Icons.history,
                label: "Transactions",
                onTap: _scrollToTransactions,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionButton(
                icon: Icons.card_membership,
                label: "Hash Pass",
                onTap: () {
                  Get.to(() => GamePassViewPage());
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentTransactions() {
    final transactions = _visibleTransactions();

    return Column(
      key: _transactionsKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Filter button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Transactions",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: _showTransactionFilter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF222222)),
                ),
                child: Row(
                  children: [
                    Text(
                      _transactionFilter == 'all'
                          ? "Filter"
                          : _transactionFilter.capitalizeFirst!,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF222222)),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[400], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: searchController,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Search Transactions",
                    hintStyle: GoogleFonts.inter(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (widget.isTransactionLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: AppLinearLoader()),
          )
        else if (widget.transactionError != null)
          _transactionErrorCard(widget.transactionError!)
        else if (transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF222222)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long, color: Colors.grey[500], size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: GoogleFonts.inter(
                      color: Colors.grey[300],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your transaction history will appear here',
                    style: GoogleFonts.inter(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...transactions.map(
            (transaction) => _transactionCardFromHistoryModel(transaction),
          ),
      ],
    );
  }

  List<TransactionHistoryModel> _visibleTransactions() {
    final query = searchController.text.trim().toLowerCase();
    return widget.transactions.where((transaction) {
      final type = transaction.type.toLowerCase();
      final matchesFilter = switch (_transactionFilter) {
        'credit' => _isCreditTransaction(transaction),
        'debit' => !_isCreditTransaction(transaction),
        _ => true,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return type.contains(query) ||
          transaction.referenceId.toLowerCase().contains(query) ||
          transaction.id.toLowerCase().contains(query) ||
          transaction.amount.toString().contains(query);
    }).toList();
  }

  void _scrollToTransactions() {
    final target = _transactionsKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showTransactionFilter() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          color: const Color(0xFF111111),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <String>['all', 'credit', 'debit'].map((filter) {
              final selected = filter == _transactionFilter;
              return ListTile(
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? const Color(0xff00DC00) : Colors.white54,
                ),
                title: Text(
                  filter.capitalizeFirst!,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  setState(() => _transactionFilter = filter);
                  Get.back();
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _transactionErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey[300]),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => BlocProvider.of<TransactionCubit>(
              context,
            ).getTransactionHistory(),
            icon: const Icon(Icons.refresh, color: Color(0xff00DC00)),
            label: const Text(
              'Retry transactions',
              style: TextStyle(color: Color(0xff00DC00)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionCardFromHistoryModel(TransactionHistoryModel transaction) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        children: [
          // Transaction icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getTransactionIconColorFromHistory(transaction),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getTransactionIconFromHistoryModel(transaction),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTransactionDescription(transaction),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getTransactionSubtitleFromHistory(transaction),
                  style: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.time,
                  style: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Amount and date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${_isCreditTransaction(transaction) ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}",
                style: GoogleFonts.inter(
                  color: _isCreditTransaction(transaction)
                      ? const Color(0xff00DC00)
                      : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transaction.date,
                style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTransactionIconColorFromHistory(
    TransactionHistoryModel transaction,
  ) {
    // Different colors for different transaction types
    switch (transaction.type.toLowerCase()) {
      case 'credit':
      case 'add':
      case 'topup':
        return const Color(0xff00DC00);
      case 'debit':
      case 'withdraw':
      case 'deduct':
        return Colors.red;
      case 'refund':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getTransactionDescription(TransactionHistoryModel transaction) {
    // Generate description based on transaction type
    switch (transaction.type.toLowerCase()) {
      case 'credit':
      case 'wallet_credit':
      case 'add':
      case 'topup':
        return 'Wallet Recharge';
      case 'debit':
      case 'wallet_debit':
      case 'withdraw':
      case 'deduct':
        return 'Payment';
      case 'refund':
        return 'Refund';
      default:
        return 'Transaction';
    }
  }

  String _getTransactionSubtitleFromHistory(
    TransactionHistoryModel transaction,
  ) {
    // Return transaction reference or type
    if (transaction.referenceId.isNotEmpty) {
      return 'Ref: ${transaction.referenceId}';
    }
    return transaction.type.toUpperCase();
  }

  IconData _getTransactionIconFromHistoryModel(
    TransactionHistoryModel transaction,
  ) {
    switch (transaction.type.toLowerCase()) {
      case 'credit':
      case 'wallet_credit':
      case 'add':
      case 'topup':
        return PhosphorIconsFill.arrowDown;
      case 'debit':
      case 'wallet_debit':
      case 'withdraw':
      case 'deduct':
        return PhosphorIconsFill.arrowUp;
      case 'refund':
        return PhosphorIconsFill.arrowCounterClockwise;
      default:
        return PhosphorIconsFill.wallet;
    }
  }

  bool _isCreditTransaction(TransactionHistoryModel transaction) {
    return [
      'credit',
      'wallet_credit',
      'add',
      'topup',
      'refund',
    ].contains(transaction.type.toLowerCase());
  }

  // Keep the existing _transactionCardFromModel method for backward compatibility
  // ignore: unused_element
  Widget _transactionCardFromModel(WalletTransaction transaction) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        children: [
          // Transaction icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getTransactionIconColor(transaction),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getTransactionIconFromModel(transaction),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getTransactionSubtitle(transaction),
                  style: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getTransactionTime(transaction),
                  style: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Amount and date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${transaction.type == TransactionType.credit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}",
                style: GoogleFonts.inter(
                  color: transaction.type == TransactionType.credit
                      ? const Color(0xff00DC00)
                      : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTransactionDate(transaction.timestamp),
                style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTransactionIconColor(WalletTransaction transaction) {
    // Different colors for different transaction types
    switch (transaction.type) {
      case TransactionType.credit:
        return const Color(0xff00DC00);
      case TransactionType.debit:
        return Colors.red;
      case TransactionType.withdrawal:
        return Colors.orange;
      case TransactionType.refund:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getTransactionSubtitle(WalletTransaction transaction) {
    // Return cafe name or transaction category
    if (transaction.description.toLowerCase().contains('slot booking')) {
      return 'Dragon Gaming Cafe'; // or extract from description
    } else if (transaction.description.toLowerCase().contains('hash pass')) {
      return 'Monthly Global Hash Pass';
    }
    return transaction.description;
  }

  String _getTransactionTime(WalletTransaction transaction) {
    // Return time slot for bookings or validity for passes
    if (transaction.description.toLowerCase().contains('slot booking')) {
      return '2:00 pm - 3:00 pm';
    } else if (transaction.description.toLowerCase().contains('hash pass')) {
      return 'Validity: June - July';
    }
    return _formatTransactionDate(transaction.timestamp);
  }

  IconData _getTransactionIconFromModel(WalletTransaction transaction) {
    switch (transaction.type) {
      case TransactionType.credit:
        return PhosphorIconsFill.arrowDown;
      case TransactionType.debit:
        return PhosphorIconsFill.arrowUp;
      case TransactionType.withdrawal:
        return PhosphorIconsFill.bank;
      case TransactionType.refund:
        return PhosphorIconsFill.arrowCounterClockwise;
      default:
        return PhosphorIconsFill.wallet;
    }
  }

  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAddMoneyBottomSheet() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Add Money to Wallet",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF222222)),
              ),
              child: TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Enter amount (Min ₹50)",
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    PhosphorIcons.currencyInr(),
                    color: const Color(0xff00DC00),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: razorpayCtr.isPaying.value
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.flash_on, color: Colors.black),
                  label: Text(
                    razorpayCtr.isPaying.value ? "PLEASE WAIT" : "ADD MONEY",
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00DC00),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: razorpayCtr.isPaying.value
                      ? null
                      : () async {
                          final amt = int.tryParse(
                            amountController.text.trim(),
                          );
                          if (amt == null || amt < 50) {
                            Get.snackbar(
                              "Invalid",
                              "Minimum top-up is ₹50",
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }
                          final success = await razorpayCtr.pay(amt);
                          if (!mounted) return;
                          if (Get.isBottomSheetOpen == true) Get.back();
                          if (success) {
                            amountController.clear();
                            await walletCtr.refreshWallet();
                            if (mounted) {
                              BlocProvider.of<TransactionCubit>(
                                context,
                              ).getTransactionHistory();
                            }
                          }
                        },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
