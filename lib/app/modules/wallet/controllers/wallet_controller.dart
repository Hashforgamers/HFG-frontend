import 'package:get/get.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import '../../../data/services/user_controller.dart';
import '../../../data/models/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:hash/core/utils/haptics.dart';

/// WalletController manages wallet operations including balance fetching,
/// top-up, and withdrawal functionality with proper error handling and analytics.
class WalletController extends GetxController {
  // Dependencies
  final UserController _userController = Get.find<UserController>();
  final RemoteRepoInterface _remoteRepo = locator<RemoteRepoInterface>();
  final SegmentSdkService _segmentService = locator<SegmentSdkService>();
  final FbEventsService _fbEventsService = locator<FbEventsService>();

  // Observable state
  final Rx<WalletModel?> _wallet = Rx<WalletModel?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _isRefreshing = false.obs;
  final RxString _errorMessage = ''.obs;
  Future<void>? _walletRequest;

  // Getters
  WalletModel? get wallet => _wallet.value;
  double get balance => _wallet.value?.balance ?? 0.0;
  bool get isLoading => _isLoading.value;
  bool get isRefreshing => _isRefreshing.value;
  String get errorMessage => _errorMessage.value;
  bool get hasError => _errorMessage.value.isNotEmpty;
  bool get isWalletReady => _userController.userId.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _initializeWallet();
  }

  @override
  void onClose() {
    _clearError();
    super.onClose();
  }

  /// Initialize wallet by setting up listeners and fetching initial data
  void _initializeWallet() {
    try {
      // Listen to user ID changes and fetch wallet when available
      ever(_userController.id, (String userId) {
        if (userId.isNotEmpty) {
          // Use Future.microtask to avoid calling during build
          Future.microtask(() => fetchWallet(forceRefresh: false));
        }
      });

      // Fetch wallet immediately if user ID is already available
      if (_userController.userId.isNotEmpty) {
        // Use Future.microtask to avoid calling during build
        Future.microtask(() => fetchWallet(forceRefresh: false));
      } else {
        _setupRetryMechanism();
      }
    } catch (e) {
      _handleError('Failed to initialize wallet: $e');
      _setupRetryMechanism();
    }
  }

  /// Set up retry mechanism for wallet initialization
  void _setupRetryMechanism() {
    Future.delayed(const Duration(seconds: 2), () {
      try {
        if (_userController.userId.isNotEmpty && _wallet.value == null) {
          fetchWallet(forceRefresh: false);
        }
      } catch (e) {
        _handleError('Retry failed: $e');
        // Final retry after another delay
        Future.delayed(const Duration(seconds: 3), () {
          try {
            if (_userController.userId.isNotEmpty && _wallet.value == null) {
              fetchWallet(forceRefresh: false);
            }
          } catch (e) {
            _handleError('Final retry failed: $e');
          }
        });
      }
    });
  }

  /// Fetch wallet balance and transaction history
  Future<void> fetchWallet({bool forceRefresh = true}) {
    if (!forceRefresh && _wallet.value != null && !hasError) {
      return Future.value();
    }

    final inFlight = _walletRequest;
    if (inFlight != null) return inFlight;

    final request = _loadWallet(forceRefresh: forceRefresh);
    _walletRequest = request;
    return request.whenComplete(() {
      if (identical(_walletRequest, request)) {
        _walletRequest = null;
      }
    });
  }

  Future<void> _loadWallet({required bool forceRefresh}) async {
    if (_isLoading.value) return;

    final userId = _userController.userId.trim();
    if (userId.isEmpty) {
      _handleError('User ID not available');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await _remoteRepo.fetchWallet(userId: userId);
      final walletModel = WalletModel.fromJson(result);
      _wallet.value = walletModel;

      // Track wallet viewed event (safely)
      Future.microtask(() => _trackWalletViewed());
    } catch (e) {
      if (_wallet.value == null || forceRefresh) {
        _handleError('Error fetching wallet: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh wallet data (used for pull-to-refresh)
  Future<void> refreshWallet() async {
    if (_isRefreshing.value) return;

    _isRefreshing.value = true;
    await fetchWallet(forceRefresh: true);
    _isRefreshing.value = false;
  }

  /// Confirm top-up and refresh wallet balance
  Future<bool> confirmTopUp({
    required double amount,
    required String paymentId,
    String? description,
  }) async {
    final userId = _userController.userId.trim();
    if (userId.isEmpty) {
      _handleError('User ID missing, cannot confirm top-up');
      return false;
    }

    if (amount <= 0) {
      _handleError('Invalid amount for top-up');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _remoteRepo.addFunds(
        userId: userId,
        amount: amount.toInt(),
        paymentId: paymentId,
      );
      // Track successful top-up
      _trackTopUpSuccess(amount, paymentId);

      // Refresh wallet balance
      await fetchWallet();

      // _showSuccessMessage('Wallet credited successfully');
      return true;
    } catch (e) {
      _handleError('Error confirming top-up: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Initiate withdrawal request
  Future<bool> initiateWithdrawal({
    required double amount,
    required String bankAccount,
    String? description,
  }) async {
    if (amount <= 0) {
      _handleError('Invalid withdrawal amount');
      return false;
    }

    if (amount > balance) {
      _handleError('Insufficient balance for withdrawal');
      return false;
    }

    if (bankAccount.isEmpty) {
      _handleError('Bank account details required');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Track withdrawal initiated event
      _trackWithdrawalInitiated(amount, bankAccount);

      // TODO: Replace with actual withdrawal API call when available
      // For now, simulate withdrawal success
      await Future.delayed(const Duration(seconds: 1));

      // Track withdrawal success event
      final payoutId = 'payout_${DateTime.now().millisecondsSinceEpoch}';
      _trackWithdrawalSuccess(payoutId, amount);

      // Refresh wallet balance
      await fetchWallet();

      _showSuccessMessage('Withdrawal initiated successfully');
      return true;
    } catch (e) {
      _handleError('Failed to initiate withdrawal: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> claimDropCrate() async {
    String userId = _userController.userId.trim();

    if (userId.isEmpty) {
      _handleError('User ID missing');
      return false;
    }

    try {
      await _remoteRepo.claimDropCrateBonus(userId: userId, amount: 30);
      await fetchWallet(); // Refresh balance
      // _showSuccessMessage("🎉 ₹30 Drop Crate claimed!");
      return true;
    } catch (e) {
      _showErrorMessage("❌ Claim failed: ${e.toString()}");
      return false;
    }
  }

  /// Validate funds after payment
  Future<bool> validateFunds(String paymentLinkId) async {
    if (paymentLinkId.isEmpty) {
      _handleError('Invalid payment link ID');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _remoteRepo.validateFunds(paymentLinkId);
      // Refresh wallet balance after successful validation
      await fetchWallet();
      return true;
    } catch (e) {
      _handleError('Error validating funds: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get recent transactions (if available in wallet model)
  List<WalletTransaction> get recentTransactions {
    final transactions = _wallet.value?.transactions ?? [];
    return transactions.take(10).toList(); // Return last 10 transactions
  }

  /// Check if user has sufficient balance
  bool hasSufficientBalance(double amount) {
    return balance >= amount;
  }

  /// Format balance for display
  String get formattedBalance {
    return '₹${balance.toStringAsFixed(2)}';
  }

  // Private helper methods

  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _clearError() {
    _errorMessage.value = '';
  }

  void _handleError(String message) {
    _errorMessage.value = message;
    Haptics.error();
    AppLogger.d('❌ WalletController Error: $message');
  }

  void _showSuccessMessage(String message) {
    // Use Future.microtask to avoid calling during build
    Future.microtask(() {
      Haptics.success();
      Get.snackbar(
        'Success',
        message,
        backgroundColor: const Color(0xff00DC00),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    });
  }

  void _showErrorMessage(String message) {
    // Use Future.microtask to avoid calling during build
    Future.microtask(() {
      Haptics.error();
      Get.snackbar(
        'Error',
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    });
  }

  // Analytics tracking methods

  void _trackWalletViewed() {
    try {
      final userId = _userController.userId;
      if (userId.isNotEmpty) {
        _segmentService.onWalletViewed(userId: userId);
        _fbEventsService.onWalletViewed(userId: userId);
      }
    } catch (e) {
      AppLogger.d('Error tracking wallet viewed: $e');
    }
  }

  void _trackTopUpSuccess(double amount, String paymentId) {
    Future.microtask(() {
      try {
        _segmentService.onAddMoneySuccess(
          amountAdded: amount,
          txnId: paymentId,
        );
        _fbEventsService.onAddMoneySuccess(
          amountAdded: amount,
          txnId: paymentId,
        );
      } catch (e) {
        AppLogger.d('Error tracking top-up success: $e');
      }
    });
  }

  void _trackWithdrawalInitiated(double amount, String bankAccount) {
    Future.microtask(() {
      try {
        _segmentService.onWithdrawalInitiated(
          amount: amount,
          bankAccount: bankAccount,
        );
        _fbEventsService.onWithdrawalInitiated(
          amount: amount,
          bankAccount: bankAccount,
        );
      } catch (e) {
        AppLogger.d('Error tracking withdrawal initiated: $e');
      }
    });
  }

  void _trackWithdrawalSuccess(String payoutId, double amount) {
    Future.microtask(() {
      try {
        _segmentService.onWithdrawalSuccess(payoutId: payoutId, amount: amount);
        _fbEventsService.onWithdrawalSuccess(
          payoutId: payoutId,
          amount: amount,
        );
      } catch (e) {
        AppLogger.d('Error tracking withdrawal success: $e');
      }
    });
  }
}
